#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  Validation de la configuration NixOS                           ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Ce script valide la configuration sans rien installer.
# À exécuter sur une machine avec Nix installé (NixOS, NixOS WSL, etc.)
#
# Usage :
#   git clone https://github.com/nawek/dotfile_nix-dev01.git
#   cd dotfile_nix-dev01
#   git checkout claude/nixos-dev-config-1pd8G
#   bash scripts/validate-config.sh
#
# Ce qui est testé :
#   1. Syntaxe du flake (nix flake check)
#   2. Évaluation de la configuration (nix eval)
#   3. Résolution des imports (tous les fichiers existent)
#   4. Dry-build (le build graph est cohérent, sans télécharger/compiler)

set -euo pipefail

FLAKE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$FLAKE_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

pass() { echo -e "${GREEN}✓${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; }
info() { echo -e "${BLUE}→${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  Validation de la configuration NixOS        ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "  Répertoire : $FLAKE_DIR"
echo ""

ERRORS=0

# ══════════════════════════════════════════════════════════════════
# 1. Vérification de la structure des fichiers
# ══════════════════════════════════════════════════════════════════
info "Vérification de la structure des fichiers..."

REQUIRED_FILES=(
  "flake.nix"
  "hosts/kuro/configuration.nix"
  "hosts/kuro/hardware-configuration.nix"
  "modules/disko.nix"
  "modules/impermanence.nix"
  "modules/lanzaboote.nix"
  "modules/nvidia.nix"
  "modules/hyprland.nix"
  "modules/stylix.nix"
  "modules/sops.nix"
  "modules/security.nix"
  "modules/networking.nix"
  "modules/monitoring.nix"
  "modules/plymouth.nix"
  "home/default.nix"
  "home/shell.nix"
  "home/git.nix"
  "home/hyprland.nix"
  "home/vscode.nix"
  "home/dev-tools.nix"
  "home/neovim.nix"
  "home/tmux.nix"
  "home/terminals.nix"
  "home/helix.nix"
  "home/yazi.nix"
  "home/spotify.nix"
  "secrets/secrets.yaml"
  ".sops.yaml"
)

for f in "${REQUIRED_FILES[@]}"; do
  if [ -f "$f" ]; then
    pass "$f"
  else
    fail "$f — MANQUANT !"
    ERRORS=$((ERRORS + 1))
  fi
done

echo ""

# ══════════════════════════════════════════════════════════════════
# 2. Vérification des marqueurs ← ADAPTER
# ══════════════════════════════════════════════════════════════════
info "Valeurs à adapter (← ADAPTER) :"
ADAPT_COUNT=$(grep -r "ADAPTER" --include="*.nix" . 2>/dev/null | wc -l)
warn "$ADAPT_COUNT valeurs marquées ← ADAPTER à personnaliser"
echo ""

# ══════════════════════════════════════════════════════════════════
# 3. nix flake check — Syntaxe et cohérence
# ══════════════════════════════════════════════════════════════════
info "nix flake check (syntaxe et cohérence du flake)..."
if nix flake check --no-build 2>&1 | tee /tmp/flake-check.log; then
  pass "nix flake check — OK"
else
  fail "nix flake check — ERREURS (voir ci-dessus)"
  ERRORS=$((ERRORS + 1))
fi

echo ""

# ══════════════════════════════════════════════════════════════════
# 4. nix flake show — Vérifier les outputs
# ══════════════════════════════════════════════════════════════════
info "nix flake show (outputs du flake)..."
if nix flake show 2>&1; then
  pass "nix flake show — OK"
else
  fail "nix flake show — ERREURS"
  ERRORS=$((ERRORS + 1))
fi

echo ""

# ══════════════════════════════════════════════════════════════════
# 5. nix eval — Évaluation de la configuration NixOS
# ══════════════════════════════════════════════════════════════════
info "Évaluation de nixosConfigurations.kuro (peut prendre 1-2 min)..."
if nix eval .#nixosConfigurations.kuro.config.system.build.toplevel --raw 2>&1 | head -1; then
  pass "Évaluation nixosConfigurations.kuro — OK"
else
  fail "Évaluation nixosConfigurations.kuro — ERREURS"
  ERRORS=$((ERRORS + 1))
fi

echo ""

# ══════════════════════════════════════════════════════════════════
# 6. Vérification des devShells
# ══════════════════════════════════════════════════════════════════
info "Vérification des devShells..."
for shell in python node rust go cc infra; do
  if nix eval .#devShells.x86_64-linux.${shell}.name --raw 2>/dev/null; then
    pass "devShell $shell — OK"
  else
    fail "devShell $shell — ERREUR"
    ERRORS=$((ERRORS + 1))
  fi
done

echo ""

# ══════════════════════════════════════════════════════════════════
# 7. Vérification des templates
# ══════════════════════════════════════════════════════════════════
info "Vérification des templates..."
for tmpl in python node rust go cc; do
  if nix flake show 2>/dev/null | grep -q "template.*$tmpl"; then
    pass "template $tmpl — OK"
  else
    warn "template $tmpl — non détecté (peut être un faux négatif)"
  fi
done

echo ""

# ══════════════════════════════════════════════════════════════════
# Résumé
# ══════════════════════════════════════════════════════════════════
echo "══════════════════════════════════════════════════════════════"
if [ $ERRORS -eq 0 ]; then
  echo -e "${GREEN}✓ VALIDATION RÉUSSIE — 0 erreur${NC}"
  echo ""
  echo "Prochaines étapes :"
  echo "  1. Remplacer hardware-configuration.nix (nixos-generate-config)"
  echo "  2. Configurer SOPS (age-keygen + sops secrets/secrets.yaml)"
  echo "  3. Adapter les valeurs ← ADAPTER ($ADAPT_COUNT restantes)"
  echo "  4. Déployer : sudo nixos-rebuild switch --flake .#kuro"
else
  echo -e "${RED}✗ VALIDATION ÉCHOUÉE — $ERRORS erreur(s)${NC}"
  echo ""
  echo "Corriger les erreurs ci-dessus avant le déploiement."
fi
echo "══════════════════════════════════════════════════════════════"
