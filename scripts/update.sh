#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  Update — Mise à jour NixOS en une commande                     ║
# ╚══════════════════════════════════════════════════════════════════╝

set -euo pipefail

GREEN='\033[0;32m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
info() { echo -e "${BLUE}→${NC} $1"; }
ok() { echo -e "${GREEN}✓${NC} $1"; }

FLAKE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$FLAKE_DIR"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  CITADEL Update                               ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# 1. Flake update
info "Mise à jour des inputs..."
nix flake update 2>&1 | tail -5
ok "Inputs mis à jour"

# 2. Check
info "Vérification..."
if ! nix flake check --no-build 2>&1; then
  echo -e "${RED}✗ Flake check échoué — annulation${NC}"
  git checkout flake.lock
  exit 1
fi
ok "Flake check OK"

# 3. Rebuild
info "Rebuild NixOS..."
nh os switch 2>&1
ok "Rebuild terminé"

# 4. Commit le lock file
info "Commit du flake.lock..."
git add flake.lock
git diff --cached --quiet || git commit -m "chore: flake update $(date +%Y-%m-%d)"
ok "flake.lock commité"

# 5. Log dans Obsidian
VAULT="$HOME/Documents/Obsidian"
if [ -d "$VAULT" ]; then
  mkdir -p "$VAULT/Resources/Updates"
  NOTE="$VAULT/Resources/Updates/$(date +%Y-%m-%d)-update.md"
  cat > "$NOTE" << UPDATE_EOF
# Update NixOS — $(date +%Y-%m-%d)

## Inputs mis à jour
\`\`\`
$(nix flake metadata --json 2>/dev/null | jq -r '.locks.nodes | to_entries[] | select(.value.locked.lastModified) | "\(.key): \(.value.locked.rev[0:8])"' 2>/dev/null || echo "Détails non disponibles")
\`\`\`

## Diff des paquets
\`\`\`
$(nix store diff-closures /nix/var/nix/profiles/system-$(( $(readlink /nix/var/nix/profiles/system | grep -oP 'system-\K\d+') - 1 ))-link /nix/var/nix/profiles/system 2>/dev/null | head -30 || echo "Diff non disponible")
\`\`\`

---
Tags: #update #nixos
UPDATE_EOF
  ok "Rapport dans Obsidian : $NOTE"
fi

echo ""
echo -e "${GREEN}✓ Mise à jour terminée !${NC}"
