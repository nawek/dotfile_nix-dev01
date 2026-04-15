#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  Déploiement NixOS — Script all-in-one                          ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# À exécuter depuis l'ISO NixOS bootée sur le laptop.
# Enchaîne : pre-flight → disko → nixos-install → copie secrets
#
# Usage : sudo bash scripts/deploy.sh

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; NC='\033[0m'
info() { echo -e "${BLUE}→${NC} $1"; }
ok() { echo -e "${GREEN}✓${NC} $1"; }

FLAKE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$FLAKE_DIR"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  Déploiement CITADEL NixOS                    ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "  ⚠ Ce script va EFFACER le disque et installer NixOS."
echo ""
read -rp "Continuer ? (oui/non) : " CONFIRM
[ "$CONFIRM" = "oui" ] || { echo "Annulé."; exit 0; }

# ── 1. Partitionnement avec Disko ────────────────────────────────
echo ""
info "Étape 1/4 — Partitionnement avec Disko..."
nix --extra-experimental-features "nix-command flakes" run \
  github:nix-community/disko -- --mode disko --flake "$FLAKE_DIR#kuro"
ok "Partitionnement terminé"

# ── 2. Copier les secrets ────────────────────────────────────────
echo ""
info "Étape 2/4 — Copie des secrets..."
mkdir -p /mnt/persist/system
if [ -f "/tmp/citadel-secrets/age-keys.txt" ]; then
  cp /tmp/citadel-secrets/age-keys.txt /mnt/persist/system/sops-age-keys.txt
  chmod 600 /mnt/persist/system/sops-age-keys.txt
  ok "Clé age copiée dans /mnt/persist/system/"
else
  echo -e "${YELLOW}⚠${NC} Clé age non trouvée dans /tmp/citadel-secrets/"
  echo "  Copier manuellement : cp /chemin/age-keys.txt /mnt/persist/system/sops-age-keys.txt"
  read -rp "  Appuyer sur Entrée quand c'est fait..."
fi

# ── 3. Installation NixOS ────────────────────────────────────────
echo ""
info "Étape 3/4 — Installation NixOS (peut prendre 15-30 minutes)..."
nixos-install --flake "$FLAKE_DIR#kuro" --no-root-password
ok "NixOS installé !"

# ── 4. Post-install ──────────────────────────────────────────────
echo ""
info "Étape 4/4 — Nettoyage..."
ok "Déploiement terminé !"

echo ""
echo "══════════════════════════════════════════════════════════════"
echo -e "${GREEN}✓ CITADEL est installé !${NC}"
echo ""
echo "  Prochaines étapes :"
echo "    1. sudo reboot"
echo "    2. Taper le mot de passe LUKS au boot"
echo "    3. Lancer scripts/post-install.sh"
echo "══════════════════════════════════════════════════════════════"
