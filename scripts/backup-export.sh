#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  Backup Export — Exporte les données critiques sur USB chiffrée  ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Crée une archive chiffrée avec age contenant :
# - Clé age (sops)
# - Clés SSH
# - Config GPG
# - Vault Obsidian
# - Secrets NixOS

set -euo pipefail

GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; NC='\033[0m'
info() { echo -e "${BLUE}→${NC} $1"; }
ok() { echo -e "${GREEN}✓${NC} $1"; }

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  Backup Export — CITADEL                      ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

BACKUP_DIR="/tmp/citadel-backup-$(date +%Y%m%d)"
ARCHIVE="/tmp/citadel-backup-$(date +%Y%m%d).tar.age"
mkdir -p "$BACKUP_DIR"

# Collecter les fichiers critiques
info "Collecte des données critiques..."

# Clé age
cp /persist/system/sops-age-keys.txt "$BACKUP_DIR/" 2>/dev/null && ok "Clé age" || echo "  ⏭ Clé age non trouvée"

# Clés SSH
cp -r ~/.ssh "$BACKUP_DIR/ssh" 2>/dev/null && ok "Clés SSH" || echo "  ⏭ SSH non trouvé"

# GPG
cp -r ~/.gnupg "$BACKUP_DIR/gnupg" 2>/dev/null && ok "GPG" || echo "  ⏭ GPG non trouvé"

# Config NixOS (secrets chiffrés)
cp -r /etc/nixos/secrets "$BACKUP_DIR/nixos-secrets" 2>/dev/null || \
  cp -r ~/dotfile_nix-dev01/secrets "$BACKUP_DIR/nixos-secrets" 2>/dev/null && ok "Secrets NixOS" || echo "  ⏭ Secrets non trouvés"

# Vault Obsidian
if [ -d ~/Documents/Obsidian ]; then
  cp -r ~/Documents/Obsidian "$BACKUP_DIR/obsidian"
  ok "Vault Obsidian"
fi

# Créer l'archive
info "Création de l'archive..."
tar cf - -C /tmp "$(basename "$BACKUP_DIR")" | \
  age -p > "$ARCHIVE"
ok "Archive chiffrée : $ARCHIVE"

# Nettoyer
rm -rf "$BACKUP_DIR"

echo ""
echo "══════════════════════════════════════════════════════════════"
echo -e "${GREEN}✓ Backup exporté : $ARCHIVE${NC}"
echo ""
echo "  Copier sur une clé USB :"
echo "    cp $ARCHIVE /media/usb/"
echo ""
echo "  Pour restaurer :"
echo "    age -d < citadel-backup-*.tar.age | tar xf -"
echo ""
echo -e "  ${YELLOW}⚠ Stocker cette archive dans un endroit sûr !${NC}"
echo "══════════════════════════════════════════════════════════════"
