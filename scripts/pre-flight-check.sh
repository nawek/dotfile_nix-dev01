#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  Pre-flight check — Vérifier que tout est prêt avant déploiement║
# ╚══════════════════════════════════════════════════════════════════╝

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
ERRORS=0

pass() { echo -e "  ${GREEN}✓${NC} $1"; }
fail() { echo -e "  ${RED}✗${NC} $1"; ERRORS=$((ERRORS + 1)); }
warn() { echo -e "  ${YELLOW}⚠${NC} $1"; }

FLAKE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$FLAKE_DIR"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  Pre-flight check — CITADEL                  ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# ── 1. Secrets ───────────────────────────────────────────────────
echo "── Secrets ────────────────────────────────────────"
if grep -q "PLACEHOLDER" secrets/secrets.yaml 2>/dev/null; then
  fail "secrets/secrets.yaml contient des PLACEHOLDER — lancer scripts/prepare-secrets.sh"
elif grep -q "sops" secrets/secrets.yaml 2>/dev/null; then
  pass "secrets/secrets.yaml est chiffré"
else
  fail "secrets/secrets.yaml semble vide ou non chiffré"
fi

if grep -q "age1xxxx" .sops.yaml 2>/dev/null; then
  fail ".sops.yaml contient la clé placeholder — remplacer par la vraie clé publique age"
else
  pass ".sops.yaml a une clé age configurée"
fi

# ── 2. Hardware ──────────────────────────────────────────────────
echo ""
echo "── Hardware ───────────────────────────────────────"
if grep -q "PLACEHOLDER\|nixos-generate-config" hosts/kuro/hardware-configuration.nix 2>/dev/null; then
  fail "hardware-configuration.nix est un placeholder — remplacer par nixos-generate-config"
else
  pass "hardware-configuration.nix semble configuré"
fi

# ── 3. Disko ─────────────────────────────────────────────────────
echo ""
echo "── Disko ──────────────────────────────────────────"
DEVICE=$(grep 'device = ' modules/disko.nix | head -1 | grep -oP '"[^"]+"' | tr -d '"')
echo -e "  Device configuré : ${YELLOW}$DEVICE${NC}"
if [ "$DEVICE" = "/dev/nvme0n1" ]; then
  warn "Device par défaut (/dev/nvme0n1) — vérifier avec lsblk sur le laptop"
else
  pass "Device personnalisé : $DEVICE"
fi

# ── 4. ADAPTER restants ─────────────────────────────────────────
echo ""
echo "── Valeurs à adapter ──────────────────────────────"
ADAPT_COUNT=$(grep -r "← ADAPTER" --include="*.nix" . 2>/dev/null | grep -v ".git" | wc -l)
if [ "$ADAPT_COUNT" -gt 0 ]; then
  warn "$ADAPT_COUNT valeurs marquées ← ADAPTER restantes"
  grep -rn "← ADAPTER" --include="*.nix" . 2>/dev/null | grep -v ".git" | head -10 | sed 's/^/    /'
  [ "$ADAPT_COUNT" -gt 10 ] && echo "    ... et $(($ADAPT_COUNT - 10)) de plus"
else
  pass "Aucune valeur ← ADAPTER restante"
fi

# ── 5. Flake check ───────────────────────────────────────────────
echo ""
echo "── Flake check ────────────────────────────────────"
if nix --extra-experimental-features "nix-command flakes" flake check --no-build 2>/dev/null; then
  pass "nix flake check — OK"
else
  fail "nix flake check — ERREURS (corriger avant de déployer)"
fi

# ── Résumé ───────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════════════"
if [ $ERRORS -eq 0 ]; then
  echo -e "${GREEN}✓ PRE-FLIGHT CHECK PASSED — Prêt pour le déploiement${NC}"
else
  echo -e "${RED}✗ $ERRORS problème(s) à résoudre avant le déploiement${NC}"
fi
echo "══════════════════════════════════════════════════════════════"
exit $ERRORS
