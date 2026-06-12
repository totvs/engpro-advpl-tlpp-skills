#!/usr/bin/env bash
#
# Validacao leve do plugin Claude Code (.claude-plugin/plugin.json e marketplace.json)
# e das skills referenciadas. Nao depende do CLI do Claude — usa apenas jq/bash, de
# forma consistente com os demais scripts em ci/scripts/.
#
# Antes de submeter ao marketplace da comunidade, rode tambem `claude plugin validate`.

set -euo pipefail

# Raiz do repo: GITHUB_WORKSPACE na CI, ou dois niveis acima deste script localmente.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="${GITHUB_WORKSPACE:-$(cd "$SCRIPT_DIR/../.." && pwd)}"

PLUGIN_JSON="$BASE_DIR/.claude-plugin/plugin.json"
MARKETPLACE_JSON="$BASE_DIR/.claude-plugin/marketplace.json"
# Manifesto equivalente para VS Code / GitHub Copilot (formato compartilhado).
GH_PLUGIN_JSON="$BASE_DIR/.github/plugin/plugin.json"

errors=0
fail() { echo "::error::$1"; errors=$((errors + 1)); }
pass() { echo "  OK   $1"; }

command -v jq >/dev/null 2>&1 || { echo "jq nao encontrado no PATH"; exit 1; }

echo "== Validando plugin.json =="
if [ ! -f "$PLUGIN_JSON" ]; then
  fail "arquivo ausente: .claude-plugin/plugin.json"
else
  if ! jq empty "$PLUGIN_JSON" 2>/dev/null; then
    fail "JSON invalido: .claude-plugin/plugin.json"
  else
    name="$(jq -r '.name // empty' "$PLUGIN_JSON")"
    [ -n "$name" ] && pass "campo obrigatorio name = '$name'" || fail "campo obrigatorio 'name' ausente em plugin.json"

    [ -n "$(jq -r '.description // empty' "$PLUGIN_JSON")" ] && pass "description presente" || echo "  WARN description ausente (recomendado p/ submissao)"
    [ -n "$(jq -r '.version // empty' "$PLUGIN_JSON")" ] && pass "version presente" || echo "  WARN version ausente (recomendado p/ submissao)"

    # Campos que precisam ser arrays (jq retorna erro de tipo no load do Claude se forem string).
    if [ "$(jq -r '.keywords | type' "$PLUGIN_JSON")" != "array" ]; then
      fail "campo 'keywords' deve ser array em plugin.json"
    fi

    # O campo skills aponta para o diretorio que contem <nome>/SKILL.md
    skills_path="$(jq -r '.skills // empty' "$PLUGIN_JSON")"
    if [ -n "$skills_path" ]; then
      resolved="$BASE_DIR/${skills_path#./}"
      [ -d "$resolved" ] && pass "skills -> '$skills_path' existe" || fail "skills aponta para diretorio inexistente: $skills_path"
    fi
  fi
fi

echo ""
echo "== Validando .github/plugin/plugin.json (VS Code / Copilot) =="
if [ ! -f "$GH_PLUGIN_JSON" ]; then
  fail "arquivo ausente: .github/plugin/plugin.json"
else
  if ! jq empty "$GH_PLUGIN_JSON" 2>/dev/null; then
    fail "JSON invalido: .github/plugin/plugin.json"
  else
    gh_name="$(jq -r '.name // empty' "$GH_PLUGIN_JSON")"
    [ -n "$gh_name" ] && pass "campo obrigatorio name = '$gh_name'" || fail "campo obrigatorio 'name' ausente em .github/plugin/plugin.json"

    # name Copilot deve ser kebab-case (letras minusculas, numeros, hifens; max 64).
    if [ -n "$gh_name" ] && ! printf '%s' "$gh_name" | grep -qE '^[a-z0-9-]{1,64}$'; then
      fail "name '$gh_name' nao e kebab-case valido (Copilot exige [a-z0-9-], max 64)"
    fi

    gh_skills="$(jq -r '.skills // empty' "$GH_PLUGIN_JSON")"
    if [ -n "$gh_skills" ]; then
      resolved="$BASE_DIR/${gh_skills#./}"
      [ -d "$resolved" ] && pass "skills -> '$gh_skills' existe" || fail "skills aponta para diretorio inexistente: $gh_skills"
    fi

    # Sincronia com o manifesto do Claude (name/version/skills devem coincidir).
    if [ -f "$PLUGIN_JSON" ] && jq empty "$PLUGIN_JSON" 2>/dev/null; then
      sync_diverged=0
      for field in name version skills; do
        a="$(jq -r ".$field // empty" "$PLUGIN_JSON")"
        b="$(jq -r ".$field // empty" "$GH_PLUGIN_JSON")"
        if [ "$a" != "$b" ]; then
          fail "campo '$field' divergente: .claude-plugin='$a' vs .github/plugin='$b' (mantenha os manifestos em sincronia)"
          sync_diverged=1
        fi
      done
      [ "$sync_diverged" -eq 0 ] && pass "manifestos .claude-plugin e .github/plugin em sincronia (name/version/skills)"
    fi
  fi
fi

echo ""
echo "== Validando marketplace.json =="
if [ ! -f "$MARKETPLACE_JSON" ]; then
  fail "arquivo ausente: .claude-plugin/marketplace.json"
else
  if ! jq empty "$MARKETPLACE_JSON" 2>/dev/null; then
    fail "JSON invalido: .claude-plugin/marketplace.json"
  else
    [ -n "$(jq -r '.name // empty' "$MARKETPLACE_JSON")" ] && pass "name presente" || fail "campo obrigatorio 'name' ausente em marketplace.json"
    [ -n "$(jq -r '.owner.name // empty' "$MARKETPLACE_JSON")" ] && pass "owner.name presente" || fail "campo obrigatorio 'owner.name' ausente em marketplace.json"

    count="$(jq -r '.plugins | length' "$MARKETPLACE_JSON")"
    [ "$count" -ge 1 ] && pass "$count plugin(s) listado(s)" || fail "array 'plugins' vazio em marketplace.json"

    # Cada entrada precisa de name + source; sources relativos devem existir.
    for i in $(seq 0 $((count - 1))); do
      pname="$(jq -r ".plugins[$i].name // empty" "$MARKETPLACE_JSON")"
      psource="$(jq -r ".plugins[$i].source" "$MARKETPLACE_JSON")"
      [ -n "$pname" ] || fail "plugins[$i].name ausente"
      if jq -e ".plugins[$i].source | type == \"string\"" "$MARKETPLACE_JSON" >/dev/null; then
        case "$psource" in
          ./*)
            resolved="$BASE_DIR/${psource#./}"
            [ -d "$resolved" ] && pass "plugin '$pname' source '$psource' existe" || fail "plugin '$pname' source inexistente: $psource" ;;
          *) fail "plugin '$pname' source relativo deve comecar com './' (valor: $psource)" ;;
        esac
      else
        pass "plugin '$pname' source remoto (github/url)"
      fi
    done
  fi
fi

echo ""
echo "== Validando skills referenciadas =="
SKILLS_DIR="$BASE_DIR/skills/advpl-tlpp"
skill_count=0
for d in "$SKILLS_DIR"/*/; do
  base="$(basename "$d")"
  case "$base" in
    references|scripts|assets) continue ;;
  esac
  skill_md="${d}SKILL.md"
  if [ ! -f "$skill_md" ]; then
    fail "skill '$base' sem SKILL.md"
    continue
  fi
  # Frontmatter precisa declarar name e description.
  front="$(awk 'NR==1 && $0=="---"{f=1;next} f && $0=="---"{exit} f{print}' "$skill_md")"
  echo "$front" | grep -qE '^name:' || fail "skill '$base': frontmatter sem 'name:'"
  echo "$front" | grep -qE '^description:' || fail "skill '$base': frontmatter sem 'description:'"
  skill_count=$((skill_count + 1))
done
pass "$skill_count skill(s) com SKILL.md valido"

echo ""
if [ "$errors" -gt 0 ]; then
  echo "Validacao do plugin FALHOU com $errors erro(s)."
  exit 1
fi
echo "Validacao do plugin concluida com sucesso!"
