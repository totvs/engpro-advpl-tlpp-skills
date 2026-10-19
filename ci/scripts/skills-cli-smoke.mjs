import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { existsSync, mkdtempSync, mkdirSync, readFileSync, readdirSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { delimiter, dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

// Execute via npx --package=skills@1.7.2 para disponibilizar a CLI no PATH.
// Invocar o módulo com Node evita diferenças entre shims .cmd e scripts Unix.
const cli = (process.env.PATH ?? '').split(delimiter)
  .map((bin) => resolve(bin, '..', 'skills', 'bin', 'cli.mjs'))
  .find((candidate) => existsSync(candidate));
assert.ok(cli, 'CLI não encontrada. Execute com npx --package=skills@1.7.2 -c "node ci/scripts/skills-cli-smoke.mjs".');

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const registry = JSON.parse(readFileSync(join(root, 'skills-registry.json'), 'utf8').replace(/^\uFEFF/, ''));
const skills = registry.skills;
const names = skills.map((skill) => skill.name).sort();
assert.equal(new Set(names).size, names.length, 'Existem nomes duplicados no catálogo.');

// Descoberta independente do registro para detectar skills novas não cadastradas.
const sourceSkills = [];
for (const collection of readdirSync(join(root, 'skills'), { withFileTypes: true })) {
  if (!collection.isDirectory()) continue;
  for (const skill of readdirSync(join(root, 'skills', collection.name), { withFileTypes: true })) {
    if (skill.isDirectory() && existsSync(join(root, 'skills', collection.name, skill.name, 'SKILL.md'))) {
      sourceSkills.push(`${collection.name}/${skill.name}`);
    }
  }
}
assert.deepEqual(sourceSkills.sort(), skills.map((skill) => skill.path).sort(), 'Registro e pastas de skills divergentes.');

const temporary = mkdtempSync(join(tmpdir(), 'engpro skills cli '));
const env = { ...process.env, DISABLE_TELEMETRY: '1', DO_NOT_TRACK: '1', NO_COLOR: '1' };

function run(cwd, ...args) {
  try {
    return execFileSync(process.execPath, [cli, ...args], {
      cwd, env, encoding: 'utf8', timeout: 120_000, stdio: ['ignore', 'pipe', 'pipe'],
    });
  } catch (error) {
    console.error(error.stdout?.toString(), error.stderr?.toString());
    throw error;
  }
}

function verifyFiles(source, installed) {
  for (const entry of readdirSync(source, { withFileTypes: true })) {
    const original = join(source, entry.name);
    const copy = join(installed, entry.name);
    if (entry.isDirectory()) {
      verifyFiles(original, copy);
    } else {
      assert.deepEqual(readFileSync(copy), readFileSync(original), `Arquivo ausente ou alterado: ${copy}`);
      if (entry.name.endsWith('.md')) {
        const markdown = readFileSync(copy, 'utf8');
        for (const match of markdown.matchAll(/\]\(([^)\s]*sonarqube-rules-reference\.md)(?:#[^)]*)?\)/g)) {
          const target = match[1];
          if (!target.startsWith('https://')) {
            assert.ok(existsSync(resolve(dirname(copy), target)), `Referência compartilhada quebrada: ${copy} -> ${target}`);
          }
        }
      }
    }
  }
}

try {
  assert.equal(run(temporary, '--version').trim(), '1.7.2', 'Use a versão 1.7.2 da CLI para este teste.');
  const listing = run(temporary, 'add', root, '--list');
  for (const name of names) assert.ok(listing.includes(name), `Skill não descoberta: ${name}`);
  assert.ok(!existsSync(join(temporary, '.agents')), '--list não deve instalar skills.');
  console.log(`Catálogo: ${names.length} skills descobertas.`);

  const single = join(temporary, 'individual');
  mkdirSync(single);
  run(single, 'add', root, '--skill', 'mvc-generator', '--agent', 'github-copilot', '--copy', '--yes');
  assert.deepEqual(readdirSync(join(single, '.agents', 'skills')), ['mvc-generator']);
  verifyFiles(join(root, 'skills', 'advpl-tlpp', 'mvc-generator'), join(single, '.agents', 'skills', 'mvc-generator'));
  console.log('Seleção individual: somente mvc-generator instalada.');

  // Projetos separados comprovam que cada agente funciona sem depender dos demais.
  for (const [agent, agentDir] of [
    ['github-copilot', '.agents'],
    ['codex', '.agents'],
    ['claude-code', '.claude'],
  ]) {
    const complete = join(temporary, agent);
    mkdirSync(complete);
    run(complete, 'add', root, '--skill', '*', '--agent', agent, '--copy', '--yes');
    const destination = join(complete, agentDir, 'skills');
    assert.deepEqual(readdirSync(destination).sort(), names, `Catálogo instalado divergente para ${agent}.`);
    for (const skill of skills) {
      verifyFiles(join(root, 'skills', skill.path), join(destination, skill.name));
    }
    assert.ok(!existsSync(join(complete, 'AGENTS.md')), 'Instruções de contexto não devem ser instaladas pela CLI.');
    assert.ok(!existsSync(join(complete, 'CLAUDE.md')), 'Instruções de contexto não devem ser instaladas pela CLI.');
    console.log(`${agent}: ${names.length} skills instaladas, com referências e scripts preservados.`);
  }
} finally {
  rmSync(temporary, { recursive: true, force: true });
}