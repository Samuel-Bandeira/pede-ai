#!/usr/bin/env bash
# Validação dos critérios de aceitação — S0-01 Repositório e estrutura base
# Uso: bash scripts/validate_s0_01.sh

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

pass() { echo -e "${GREEN}[PASS]${NC} $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}[FAIL]${NC} $1"; FAIL=$((FAIL+1)); }

echo "=== S0-01 — Repositório e estrutura base ==="; echo

# 1. Branches main e staging existem
git -C "$ROOT" branch | grep -q 'main' \
  && pass "Branch 'main' existe" \
  || fail "Branch 'main' não encontrada"

git -C "$ROOT" branch | grep -q 'staging' \
  && pass "Branch 'staging' existe" \
  || fail "Branch 'staging' não encontrada"

# 2. .gitignore configurado com entradas obrigatórias
GITIGNORE="$ROOT/.gitignore"
if [[ -f "$GITIGNORE" ]]; then
  for pattern in "node_modules" ".env" "__pycache__" ".terraform"; do
    grep -q "$pattern" "$GITIGNORE" \
      && pass ".gitignore contém '$pattern'" \
      || fail ".gitignore não contém '$pattern'"
  done
else
  fail ".gitignore não existe"
fi

# 3. README.md existe e tem conteúdo mínimo
README="$ROOT/README.md"
if [[ -f "$README" ]]; then
  pass "README.md existe"
  grep -qi "setup\|instalação\|como rodar\|getting started" "$README" \
    && pass "README.md contém instruções de setup" \
    || fail "README.md não contém instruções de setup"
else
  fail "README.md não existe"
fi

# 4. Estrutura de pastas
for dir in frontend backend infra docs; do
  [[ -d "$ROOT/$dir" ]] \
    && pass "Pasta '$dir/' existe" \
    || fail "Pasta '$dir/' não encontrada"
done

# 5. CLAUDE.md na raiz
[[ -f "$ROOT/CLAUDE.md" ]] \
  && pass "CLAUDE.md está na raiz" \
  || fail "CLAUDE.md não encontrado na raiz"

# 6. docs/PRD.md e docs/STORIES.md
[[ -f "$ROOT/docs/PRD.md" ]] \
  && pass "docs/PRD.md existe" \
  || fail "docs/PRD.md não encontrado"

[[ -f "$ROOT/docs/STORIES.md" ]] \
  && pass "docs/STORIES.md existe" \
  || fail "docs/STORIES.md não encontrado"

echo
echo "=== Resultado: ${PASS} PASS / ${FAIL} FAIL ==="
[[ $FAIL -eq 0 ]] && echo -e "${GREEN}Todos os critérios satisfeitos ✓${NC}" && exit 0
echo -e "${RED}${FAIL} critério(s) falhando${NC}" && exit 1
