#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  New Machine — Adapter la config pour une autre machine          ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Guide interactif pour déployer CITADEL sur un second PC.

set -euo pipefail

BLUE='\033[0;34m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info() { echo -e "${BLUE}→${NC} $1"; }
ok() { echo -e "${GREEN}✓${NC} $1"; }

FLAKE_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  New Machine — Adapter CITADEL                ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

read -rp "Hostname de la nouvelle machine : " NEW_HOST
read -rp "Username : " NEW_USER
read -rp "Device disque (lsblk pour vérifier, ex: /dev/sda) : " NEW_DISK

echo ""
info "Création de la config pour $NEW_HOST..."

# Copier la structure
NEW_DIR="$FLAKE_DIR/hosts/$NEW_HOST"
mkdir -p "$NEW_DIR"
cp "$FLAKE_DIR/hosts/kuro/configuration.nix" "$NEW_DIR/configuration.nix"
cp "$FLAKE_DIR/hosts/kuro/hardware-configuration.nix" "$NEW_DIR/hardware-configuration.nix"

# Adapter les valeurs
sed -i "s/kuro/$NEW_USER/g" "$NEW_DIR/configuration.nix"
sed -i "s/networking.hostName = \"kuro\"/networking.hostName = \"$NEW_HOST\"/" "$NEW_DIR/configuration.nix"

ok "Config créée dans hosts/$NEW_HOST/"

echo ""
echo "══════════════════════════════════════════════════════════════"
echo -e "${GREEN}✓ Structure créée${NC}"
echo ""
echo "  Prochaines étapes :"
echo "    1. Ajouter la nixosConfiguration dans flake.nix :"
echo "       nixosConfigurations.$NEW_HOST = nixpkgs.lib.nixosSystem { ... };"
echo "    2. Adapter hosts/$NEW_HOST/hardware-configuration.nix"
echo "       sudo nixos-generate-config --show-hardware-config"
echo "    3. Adapter le device dans modules/disko.nix : $NEW_DISK"
echo "    4. Déployer : sudo bash scripts/deploy.sh"
echo "══════════════════════════════════════════════════════════════"
