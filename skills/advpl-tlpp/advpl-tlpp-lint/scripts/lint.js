#!/usr/bin/env node
// Lint avulso de fontes AdvPL/TLPP para qualquer agente (Codex, Gemini, Copilot,
// Claude): roda pelo shell depois de editar um fonte. Sobe o `advpls
// language-server`, abre os fontes e imprime os diagnosticos do linter do LSP.
// O linter do LSP pega mais que o `advpls appre`, que devolve exit 0 para um
// Catch sem variavel que o LSP recusa.
//
//   node lint.js [--includes <a;b>] [--timeout <seg>] <fonte> [<fonte>...]
//
// Autocontido: so modulos nativos do Node, sem variavel de ambiente nem arquivo
// de configuracao do Claude Code, para que este arquivo possa ser copiado sozinho
// para outro repositorio.
//
// Quem usa este modulo como biblioteca (ex.: um wrapper de LSP) reaproveita daqui a
// busca de binario, a busca de includes, a conversao de caminho para URI e a
// injecao de includes no initialize. Por isso nenhuma funcao deste arquivo sai do
// processo: quem chama decide o exit code.
//
// Medido em 2026-10-13 nas duas pontas (tds-ls 2.2.0 e 2.2.7): cada fonte
// recebeu exatamente um publishDiagnostics, e nada mais nos 15 s seguintes —
// o primeiro publish e' o resultado final. Fonte limpo sai com publish de
// lista vazia, o que tambem conta como "recebido".
"use strict";
const { spawn, spawnSync } = require("child_process");
const fs = require("fs");
const os = require("os");
const path = require("path");

const TIMEOUT_PADRAO_SEG = 120;
const TIMEOUT_MAX_SEG = 3600;
const USO = "uso: node lint.js [--includes <a;b>] [--timeout <seg>] <fonte> [<fonte>...]";
// Diagnostico com esta mensagem = o linter NAO analisou o arquivo. Silencio
// nunca e' saida limpa: o servidor avisa "outside the workspace" com severidade 3
// (info), e so esta checagem transforma isso em falha.
const FORA_DO_WORKSPACE = /outside the workspace/i;

// --- argumentos (puro)
function lerArgs(argv) {
  const r = { includes: null, timeout: TIMEOUT_PADRAO_SEG, fontes: [], autoteste: false };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--autoteste") r.autoteste = true;
    else if (a === "--includes" || a === "--timeout") {
      const v = argv[++i];
      if (v === undefined || v.startsWith("--")) return { erro: `${a} pede um valor` };
      if (a === "--includes") r.includes = v;
      else {
        const n = Number(v);
        if (!(Number.isFinite(n) && n >= 1 && n <= TIMEOUT_MAX_SEG)) {
          return { erro: `--timeout pede segundos entre 1 e ${TIMEOUT_MAX_SEG}, veio "${v}"` };
        }
        r.timeout = n;
      }
    } else if (a.startsWith("--")) return { erro: `opcao desconhecida: ${a}` };
    else r.fontes.push(a);
  }
  return r;
}

function pastasDeEnv(texto) {
  return (texto || "").split(";").map(s => s.trim()).filter(Boolean);
}

// --- includes
// Sobe de `dirInicio` ate a raiz do disco e devolve as pastas do PRIMEIRO
// diretorio que tenha `includes` ou `.workflow/includes`. Para ali: nao arrasta
// `includes` de pastas alheias que estejam acima do repositorio.
function buscaIncludes(dirInicio) {
  for (let dir = path.resolve(dirInicio), ant = null; dir !== ant; ant = dir, dir = path.dirname(dir)) {
    const achadas = ["includes", path.join(".workflow", "includes")]
      .map(p => path.join(dir, p))
      .filter(p => fs.existsSync(p));
    if (achadas.length) return achadas;
  }
  return [];
}

// Ordem: argumento (--includes), variavel ADVPL_INCLUDES, busca a partir de dirInicio.
// Le o ambiente na hora da chamada, nao no carregamento do modulo.
function acharIncludes({ argumento, env, dirInicio }) {
  const arg = pastasDeEnv(argumento);
  if (arg.length) return { pastas: arg, origem: "--includes" };
  const e = pastasDeEnv(env);
  if (e.length) return { pastas: e, origem: "ADVPL_INCLUDES" };
  return { pastas: buscaIncludes(dirInicio), origem: "busca" };
}

// Grava a chave linter/includes em initializationOptions.settings. Substitui a
// entrada que ja existir (nao duplica), preserva as outras, e transforma
// initializationOptions que nao seja objeto em objeto.
function injetaIncludes(params, pastas) {
  let io = params.initializationOptions;
  if (!io || typeof io !== "object" || Array.isArray(io)) io = params.initializationOptions = {};
  const outras = Array.isArray(io.settings)
    ? io.settings.filter(s => !(s && s.scope === "linter" && s.key === "includes"))
    : [];
  io.settings = outras.concat([{ scope: "linter", key: "includes", value: pastas.join(";") }]);
  return params;
}

// --- binario
// Ordem: ADVPLS_BIN, senao `npm root -g`/@totvs/tds-ls/bin/<so>/advpls.
// Devolve {bin} ou {erro}.
function acharBinario() {
  if (process.env.ADVPLS_BIN) return { bin: process.env.ADVPLS_BIN };
  const exe = process.platform === "win32" ? "advpls.exe" : "advpls";
  const so = { win32: "windows", darwin: "mac" }[process.platform] || "linux";
  // No Windows o npm e' npm.cmd, que o spawn sem shell nao executa. O comando
  // vai sem argumentos dentro do shell: com argumentos, o Node 24 emite
  // DEP0190 no stderr. O cwd e' a pasta do proprio node, onde mora o npm.cmd
  // verdadeiro: o cmd.exe procura o comando na pasta atual antes do PATH, e o
  // lint roda de dentro do repositorio do cliente — um npm.cmd plantado ali
  // seria executado no lugar do npm.
  const opcoes = { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"], cwd: path.dirname(process.execPath) };
  const r = process.platform === "win32"
    ? spawnSync("npm root -g", Object.assign({ shell: true }, opcoes))
    : spawnSync("npm", ["root", "-g"], opcoes);
  const raiz = !r.error && r.status === 0 ? String(r.stdout).trim() : "";
  if (!raiz) return { erro: "npm nao encontrado no PATH; instale o Node.js ou aponte ADVPLS_BIN para o advpls." };
  const bin = path.join(raiz, "@totvs", "tds-ls", "bin", so, exe);
  if (!fs.existsSync(bin)) return { erro: `advpls nao encontrado em ${bin}. Rode: npm install -g @totvs/tds-ls` };
  return { bin };
}

// --- URI e caminho
// file:///C:/a/b.prw com espacos e acentos codificados. Sem barra final: o
// advpls trata uri com barra final como fora do workspace.
function paraUri(caminhoAbs) {
  const p = caminhoAbs.split(path.sep).join("/");
  return "file://" + (p.startsWith("/") ? "" : "/") + encodeURI(p);
}

function deUri(uri) {
  if (typeof uri !== "string" || !uri.startsWith("file://")) return null;
  let p = decodeURIComponent(uri.slice("file://".length));
  if (/^\/[a-zA-Z]:/.test(p)) p = p.slice(1);
  return p.split("/").join(path.sep);
}

function normaliza(caminho) {
  if (typeof caminho !== "string") return "";
  return path.resolve(caminho).replace(/[\\/]+$/, "").toLowerCase();
}

// --- saida (puro)
const SEVERIDADE = { 1: "erro", 2: "aviso" };

function formatarDiagnostico(caminho, d) {
  const sev = SEVERIDADE[d.severity] || "info";
  return `${caminho}:${d.range.start.line + 1}:${d.range.start.character + 1}: ${sev} ${d.message}`;
}

function resumo(erros, avisos, fontes) {
  return `${erros} erro(s), ${avisos} aviso(s) em ${fontes} fonte(s)`;
}

function semIncludesMsg(dir) {
  return `nenhuma pasta de includes encontrada a partir de ${path.resolve(dir)}.\n` +
    "  Procurei `includes` e `.workflow/includes` nesta pasta e nas acima dela.\n" +
    "  Sem includes o linter nao reporta nada. Informe com --includes \"<pasta>\" ou defina ADVPL_INCLUDES.";
}

// --- cliente LSP
// Sobe `bin language-server` (sem --includes: derruba a tds-ls 2.2.7), manda o
// initialize com as pastas dos fontes como workspace e os includes em settings,
// abre cada fonte e espera UM publishDiagnostics por fonte. Resolve sempre, com
// {ok, porFonte} ou {erro, stderr}; mata o filho em toda saida.
function rodaLsp({ bin, pastas, fontes, timeoutMs }) {
  return new Promise(resolve => {
    const pastasFonte = [...new Set(fontes.map(f => path.dirname(f)))];
    const filho = spawn(bin, ["language-server"], { stdio: ["pipe", "pipe", "pipe"] });
    const porFonte = new Map(fontes.map(f => [normaliza(f), null]));
    let stderr = "", buf = Buffer.alloc(0), id = 0, fechado = false, relogio = null;

    const fim = r => {
      if (fechado) return;
      fechado = true;
      clearTimeout(relogio);
      try { filho.kill(); } catch (e) { /* ja morreu */ }
      resolve(Object.assign({ stderr }, r));
    };
    process.once("exit", () => { try { filho.kill(); } catch (e) { /* ja morreu */ } });
    for (const s of ["SIGINT", "SIGTERM"]) process.once(s, () => fim({ erro: `interrompido por ${s}` }));
    relogio = setTimeout(() => {
      // Lista os fontes que ficaram sem diagnostico, com o caminho como foi passado.
      const falta = fontes.filter(f => porFonte.get(normaliza(f)) === null);
      fim({ erro: `timeout de ${timeoutMs / 1000} s sem diagnostico de ${falta.length} fonte(s): ${falta.join(", ")}` });
    }, timeoutMs);

    filho.stderr.on("data", d => { stderr += d; });
    filho.stdin.on("error", () => { /* servidor caiu: o 'exit' abaixo reporta */ });
    filho.on("error", e => fim({ erro: `nao consegui subir ${bin}: ${e.message}` }));
    filho.on("exit", code => fim({ erro: `servidor saiu com codigo ${code} antes do diagnostico` }));

    const envia = (method, params, req = true) => {
      const m = { jsonrpc: "2.0", method, params };
      if (req) m.id = ++id;
      const b = Buffer.from(JSON.stringify(m), "utf8");
      filho.stdin.write("Content-Length: " + b.length + "\r\n\r\n");
      filho.stdin.write(b);
    };

    function trata(m) {
      if (m.id === 1 && m.method === undefined) {
        if (m.error) return fim({ erro: "initialize recusado: " + JSON.stringify(m.error) });
        // Le todos antes de mandar qualquer didOpen: se um fonte nao puder ser
        // lido (permissao, arquivo que sumiu depois da checagem), sai com a
        // mensagem do fonte, sem stack e sem resultado parcial.
        const textos = [];
        for (const f of fontes) {
          try { textos.push(fs.readFileSync(f, "latin1")); } catch (e) {
            return fim({ erro: `nao consegui ler o fonte ${f}: ${e.code || e.message}` });
          }
        }
        envia("initialized", {}, false);
        fontes.forEach((f, i) => {
          envia("textDocument/didOpen", {
            textDocument: { uri: paraUri(f), languageId: "advpl", version: 1, text: textos[i] },
          }, false);
        });
        return;
      }
      if (m.method === "textDocument/publishDiagnostics") {
        const k = normaliza(deUri(m.params && m.params.uri));
        if (!porFonte.has(k) || porFonte.get(k) !== null) return; // so o primeiro publish de cada fonte
        const ds = Array.isArray(m.params.diagnostics) ? m.params.diagnostics : [];
        const fora = ds.find(d => d && typeof d.message === "string" && FORA_DO_WORKSPACE.test(d.message));
        if (fora) return fim({ erro: `fonte fora do workspace: ${k}. O lint NAO rodou neste arquivo.` });
        porFonte.set(k, ds);
        if ([...porFonte.values()].every(v => v !== null)) fim({ ok: true, porFonte });
      }
    }

    filho.stdout.on("data", d => {
      buf = Buffer.concat([buf, d]);
      for (;;) {
        const i = buf.indexOf("\r\n\r\n");
        if (i < 0) break;
        const cab = /Content-Length:\s*(\d+)/i.exec(buf.slice(0, i).toString("ascii"));
        if (!cab) return fim({ erro: "cabecalho LSP sem Content-Length" });
        const tam = +cab[1], ini = i + 4;
        if (buf.length < ini + tam) break;
        const corpo = buf.slice(ini, ini + tam);
        buf = buf.slice(ini + tam);
        let msg;
        try { msg = JSON.parse(corpo.toString("utf8")); } catch (e) { continue; }
        trata(msg);
        if (fechado) return;
      }
    });

    envia("initialize", injetaIncludes({
      processId: process.pid,
      rootUri: paraUri(pastasFonte[0]),
      rootPath: pastasFonte[0],
      capabilities: {},
      workspaceFolders: pastasFonte.map(p => ({ uri: paraUri(p), name: path.basename(p) || p })),
      initializationOptions: {
        launchArgs: [],
        settings: [
          { scope: "advpls", key: "fsencoding", value: "cp1252" },
          { scope: "linter", key: "behavior", value: "enable" },
        ],
      },
    }, pastas));
  });
}

// --- execucao
async function main(argv) {
  const a = lerArgs(argv);
  if (a.erro) { process.stderr.write(`[lint] ${a.erro}\n${USO}\n`); return 2; }
  if (a.autoteste) return autoteste();
  if (!a.fontes.length) { process.stderr.write(`[lint] ${USO}\n`); return 2; }

  // Mesmo fonte passado duas vezes conta uma vez: a chave e' o caminho normalizado.
  const vistos = new Set();
  const fontes = a.fontes.map(f => path.resolve(f)).filter(f => {
    if (vistos.has(normaliza(f))) return false;
    vistos.add(normaliza(f));
    return true;
  });
  for (const f of fontes) {
    if (!fs.existsSync(f)) { process.stderr.write(`[lint] fonte nao existe: ${f}\n`); return 2; }
    let arquivo = false;
    try { arquivo = fs.statSync(f).isFile(); } catch (e) { arquivo = false; }
    if (!arquivo) { process.stderr.write(`[lint] fonte nao e' um arquivo legivel: ${f}\n`); return 2; }
  }
  const bin = acharBinario();
  if (bin.erro) { process.stderr.write(`[lint] ${bin.erro}\n`); return 2; }
  const dirFonte = path.dirname(fontes[0]);
  const inc = acharIncludes({ argumento: a.includes, env: process.env.ADVPL_INCLUDES, dirInicio: dirFonte });
  if (!inc.pastas.length) { process.stderr.write(`[lint] ${semIncludesMsg(dirFonte)}\n`); return 2; }
  for (const p of inc.pastas) {
    if (!fs.existsSync(p)) { process.stderr.write(`[lint] pasta de includes nao existe: ${p}\n`); return 2; }
  }

  const r = await rodaLsp({ bin: bin.bin, pastas: inc.pastas, fontes, timeoutMs: a.timeout * 1000 });
  if (r.erro) {
    process.stderr.write(`[lint] ${r.erro}\n`);
    if (r.stderr && r.stderr.trim()) process.stderr.write(`[lint] saida do servidor:\n${r.stderr}`);
    return 2;
  }

  let erros = 0, avisos = 0;
  for (const f of fontes) {
    const ds = r.porFonte.get(normaliza(f)).slice().sort(
      (x, y) => x.range.start.line - y.range.start.line || x.range.start.character - y.range.start.character);
    for (const d of ds) {
      if (d.severity === 1) erros++;
      else if (d.severity === 2) avisos++;
      console.log(formatarDiagnostico(f, d));
    }
  }
  console.log(resumo(erros, avisos, fontes.length));
  return erros ? 1 : 0;
}

// --- autoteste: so as funcoes puras e a busca de binario; nao sobe servidor.
function autoteste() {
  const base = fs.mkdtempSync(path.join(os.tmpdir(), "lint-inc-"));
  const cria = p => { const d = path.join(base, p); fs.mkdirSync(d, { recursive: true }); return d; };
  const repoWf = cria(path.join("repo", ".workflow", "includes"));
  const cliente = cria(path.join("repo", "Cliente", "04 - Estoque"));
  const wtProprio = cria(path.join("repo2", ".claude", "worktrees", "x", "includes"));
  cria(path.join("repo2", "includes"));
  const solto = cria("solto");
  const envAntes = { ADVPL_INCLUDES: process.env.ADVPL_INCLUDES, ADVPLS_BIN: process.env.ADVPLS_BIN };
  delete process.env.ADVPL_INCLUDES;
  delete process.env.ADVPLS_BIN;

  let falhas = 0;
  const confere = (cond, nome, detalhe) => {
    console.log((cond ? "ok: " : "FALHOU: ") + nome);
    if (!cond) { falhas++; if (detalhe) console.log("  " + detalhe); }
  };
  const igual = (a, b) => JSON.stringify(a) === JSON.stringify(b);

  let r = lerArgs(["--includes", "A;B", "--timeout", "30", "f1.prw", "f2.prw"]);
  confere(r.includes === "A;B" && r.timeout === 30 && igual(r.fontes, ["f1.prw", "f2.prw"]), "argumentos: --includes, --timeout e fontes",
    JSON.stringify(r));
  confere(!!lerArgs(["--timeout", "x", "f"]).erro, "--timeout nao numerico e' erro");
  for (const t of ["0", "-5", "3601", "Infinity", "NaN", ""]) {
    confere(!!lerArgs(["--timeout", t, "f"]).erro, `--timeout "${t}" fora de 1..3600 e' erro`);
  }
  confere(lerArgs(["--timeout", "1", "f"]).timeout === 1 && lerArgs(["--timeout", "3600", "f"]).timeout === 3600,
    "--timeout 1 e 3600 sao aceitos");
  confere(!!lerArgs(["--includes"]).erro, "--includes sem valor e' erro");
  confere(!!lerArgs(["--nada", "f"]).erro, "opcao desconhecida e' erro");

  confere(igual(pastasDeEnv(" a ; b;;"), ["a", "b"]), "pastasDeEnv tira espacos e vazios");

  confere(igual(acharIncludes({ argumento: "X;Y", env: "Z", dirInicio: cliente }).pastas, ["X", "Y"]),
    "--includes vence ADVPL_INCLUDES e a busca");
  confere(igual(acharIncludes({ env: solto, dirInicio: cliente }).pastas, [solto]),
    "ADVPL_INCLUDES vence a busca");
  confere(igual(acharIncludes({ dirInicio: cliente }).pastas, [repoWf]),
    "pasta de cliente acha o .workflow/includes do repositorio");
  confere(igual(acharIncludes({ dirInicio: path.join(base, "repo2", ".claude", "worktrees", "x") }).pastas, [wtProprio]),
    "worktree usa o includes dele, nao o do repositorio acima");
  const semNada = buscaIncludes(solto).filter(p => p.startsWith(base));
  confere(semNada.length === 0, "pasta sem includes nao inventa pasta do cenario", JSON.stringify(semNada));

  const novo = injetaIncludes({}, ["A", "B"]);
  confere(igual(novo.initializationOptions.settings, [{ scope: "linter", key: "includes", value: "A;B" }]),
    "initialize sem initializationOptions ganha settings com as pastas");
  const antigo = injetaIncludes({ initializationOptions: { launchArgs: [], settings: [
    { scope: "advpls", key: "fsencoding", value: "cp1252" },
    { scope: "linter", key: "includes", value: "ANTIGO" },
  ] } }, ["C"]).initializationOptions.settings;
  confere(antigo.length === 2 && antigo[0].key === "fsencoding" && antigo[1].key === "includes" && antigo[1].value === "C",
    "chave includes ja existente e substituida, sem duplicar, outras preservadas", JSON.stringify(antigo));
  for (const torto of ["abc", 5, [1]]) {
    const x = injetaIncludes({ initializationOptions: torto }, ["D"]);
    confere(igual(x.initializationOptions.settings, [{ scope: "linter", key: "includes", value: "D" }]),
      "initializationOptions " + JSON.stringify(torto) + " vira objeto com os includes");
  }

  const ds = { severity: 1, range: { start: { line: 2, character: 0 } }, message: "C2002 x" };
  confere(formatarDiagnostico("C:/x/a.prw", ds) === "C:/x/a.prw:3:1: erro C2002 x",
    "formatacao: linha e coluna 1-based, severidade erro", formatarDiagnostico("C:/x/a.prw", ds));
  confere(formatarDiagnostico("a.prw", { severity: 2, range: { start: { line: 0, character: 4 } }, message: "w" }) === "a.prw:1:5: aviso w",
    "severidade 2 vira aviso");
  confere(formatarDiagnostico("a.prw", { severity: 3, range: { start: { line: 0, character: 0 } }, message: "i" }) === "a.prw:1:1: info i",
    "severidade 3 vira info");
  confere(resumo(1, 2, 3) === "1 erro(s), 2 aviso(s) em 3 fonte(s)", "resumo final");

  const caminhoComEspaco = path.join(base, "Ponto de Entrada", "69 - Gestão", "x.prw");
  confere(normaliza(deUri(paraUri(caminhoComEspaco))) === normaliza(caminhoComEspaco),
    "uri com espaco e acento vai e volta", paraUri(caminhoComEspaco));
  confere(!paraUri(base).endsWith("/"), "uri de pasta nao termina com barra");

  process.env.ADVPLS_BIN = "C:\\fake\\advpls.exe";
  confere(igual(acharBinario(), { bin: "C:\\fake\\advpls.exe" }), "ADVPLS_BIN vence a busca no npm");
  delete process.env.ADVPLS_BIN;
  const semVar = acharBinario();
  const verdade = semVar.bin ? fs.existsSync(semVar.bin) : typeof semVar.erro === "string";
  confere(verdade, "sem ADVPLS_BIN: ou acha o binario existente ou devolve erro", JSON.stringify(semVar));
  console.log("  sem ADVPLS_BIN -> " + JSON.stringify(semVar));

  // npm plantado na pasta atual nao pode ser executado: no Windows o cmd.exe
  // procura o comando na pasta atual antes do PATH, e o lint roda de dentro
  // do repositorio do cliente. A variavel NoDefaultCurrentDirectoryInExePath
  // desliga essa busca; alguns hosts de agente a definem, outros nao, entao o
  // teste a remove para medir o caso desprotegido.
  if (process.platform === "win32") {
    const plantada = path.join(base, "plantada");
    fs.mkdirSync(plantada, { recursive: true });
    fs.writeFileSync(path.join(plantada, "npm.cmd"), "@echo PLANTADO\r\n");
    fs.writeFileSync(path.join(plantada, "npm.bat"), "@echo PLANTADO\r\n");
    const cwdAntes = process.cwd();
    const protecao = process.env.NoDefaultCurrentDirectoryInExePath;
    delete process.env.NoDefaultCurrentDirectoryInExePath;
    process.chdir(plantada);
    let comPlantado;
    try { comPlantado = acharBinario(); } finally {
      process.chdir(cwdAntes);
      if (protecao !== undefined) process.env.NoDefaultCurrentDirectoryInExePath = protecao;
    }
    confere(!JSON.stringify(comPlantado).includes("PLANTADO"),
      "npm.cmd plantado na pasta atual nao e' executado", JSON.stringify(comPlantado));
  }

  for (const k of Object.keys(envAntes)) {
    if (envAntes[k] === undefined) delete process.env[k]; else process.env[k] = envAntes[k];
  }
  fs.rmSync(base, { recursive: true, force: true });
  console.log(falhas ? falhas + " caso(s) falharam" : "autoteste ok");
  return falhas ? 1 : 0;
}

module.exports = {
  lerArgs, pastasDeEnv, buscaIncludes, acharIncludes, injetaIncludes, acharBinario,
  paraUri, deUri, normaliza, formatarDiagnostico, resumo, rodaLsp, FORA_DO_WORKSPACE,
};

if (require.main === module) {
  main(process.argv.slice(2)).then(
    c => { process.exitCode = c; },
    e => { process.stderr.write(`[lint] erro inesperado: ${e && e.stack || e}\n`); process.exitCode = 2; },
  );
}
