#!/bin/bash
# Validação dos critérios de aceitação da S0-02
# Uso: ./scripts/validate_s0_02.sh
# Requer: terraform instalado e inicializado, AWS configurada

set -euo pipefail

PASS=0
FAIL=0
INFRA_DIR="$(cd "$(dirname "$0")/../infra" && pwd)"

check() {
  local desc="$1"
  local result="$2"
  if [ "$result" = "ok" ]; then
    echo "  [PASS] $desc"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] $desc — $result"
    FAIL=$((FAIL + 1))
  fi
}

echo ""
echo "=== S0-02 — Infraestrutura via Terraform ==="
echo ""

# 1. Arquivos Terraform existem
echo "1. Estrutura de arquivos Terraform"
for f in main.tf variables.tf vpc.tf security.tf ec2.tf outputs.tf cloud-init.sh terraform.tfvars.example; do
  if [ -f "$INFRA_DIR/$f" ]; then
    check "$f existe" "ok"
  else
    check "$f existe" "arquivo não encontrado"
  fi
done

# 2. terraform.tfvars não commitado (.gitignore)
echo ""
echo "2. terraform.tfvars ignorado pelo git"
if grep -q "terraform.tfvars" "$INFRA_DIR/../.gitignore" 2>/dev/null; then
  check "terraform.tfvars no .gitignore" "ok"
else
  check "terraform.tfvars no .gitignore" "não encontrado no .gitignore"
fi

# 3. Terraform instalado
echo ""
echo "3. Terraform CLI"
if command -v terraform &>/dev/null; then
  TF_VERSION=$(terraform version -json 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin)['terraform_version'])" 2>/dev/null || terraform version | head -1)
  check "terraform instalado ($TF_VERSION)" "ok"
else
  check "terraform instalado" "terraform não encontrado — instale via https://developer.hashicorp.com/terraform/install"
fi

# 4. Configuração do provider AWS está presente
echo ""
echo "4. Configuração do provider AWS"
if grep -q 'hashicorp/aws' "$INFRA_DIR/main.tf"; then
  check "provider AWS declarado em main.tf" "ok"
else
  check "provider AWS declarado em main.tf" "não encontrado"
fi

# 5. Terraform Cloud backend configurado
echo ""
echo "5. Terraform Cloud (remote state)"
if grep -q 'cloud {' "$INFRA_DIR/main.tf"; then
  check "backend Terraform Cloud configurado em main.tf" "ok"
else
  check "backend Terraform Cloud configurado em main.tf" "bloco 'cloud {}' não encontrado"
fi

# 6. Elastic IP declarado
echo ""
echo "6. Recursos críticos declarados"
if grep -q 'aws_eip' "$INFRA_DIR/ec2.tf"; then
  check "Elastic IP (aws_eip) declarado" "ok"
else
  check "Elastic IP (aws_eip) declarado" "não encontrado em ec2.tf"
fi

# 7. Security Group com portas 22, 80, 443
if grep -q '22' "$INFRA_DIR/security.tf" && grep -q '80' "$INFRA_DIR/security.tf" && grep -q '443' "$INFRA_DIR/security.tf"; then
  check "Security Group com portas 22, 80, 443" "ok"
else
  check "Security Group com portas 22, 80, 443" "portas não declaradas em security.tf"
fi

# 8. cloud-init instala Docker e Nginx
if grep -q 'docker' "$INFRA_DIR/cloud-init.sh" && grep -q 'nginx' "$INFRA_DIR/cloud-init.sh"; then
  check "cloud-init instala Docker e Nginx" "ok"
else
  check "cloud-init instala Docker e Nginx" "não encontrado em cloud-init.sh"
fi

# 9. Output elastic_ip e ssh_command declarados
if grep -q 'elastic_ip' "$INFRA_DIR/outputs.tf" && grep -q 'ssh_command' "$INFRA_DIR/outputs.tf"; then
  check "Outputs elastic_ip e ssh_command declarados" "ok"
else
  check "Outputs declarados" "não encontrado em outputs.tf"
fi

# Resultado
echo ""
echo "================================"
echo "  PASS: $PASS  |  FAIL: $FAIL"
echo "================================"
echo ""

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
