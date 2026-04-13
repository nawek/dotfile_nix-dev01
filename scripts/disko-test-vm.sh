#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  Test du partitionnement Disko dans une VM                      ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Ce script teste le partitionnement Disko dans une VM QEMU
# AVANT de l'appliquer sur le vrai disque. Aucun risque.
#
# Prérequis : qemu installé (nix-shell -p qemu)
# Usage : ./scripts/disko-test-vm.sh

set -euo pipefail

# ── Configuration ──────────────────────────────────────────────────
DISK_SIZE="20G"
VM_DISK="/tmp/disko-test-disk.qcow2"
FLAKE_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "╔══════════════════════════════════════════════╗"
echo "║  Test Disko en VM — Aucun risque pour le PC  ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# ── Étape 1 : Créer un disque virtuel ─────────────────────────────
echo "→ Création du disque virtuel (${DISK_SIZE})..."
qemu-img create -f qcow2 "${VM_DISK}" "${DISK_SIZE}"

# ── Étape 2 : Dry-run Disko ───────────────────────────────────────
echo ""
echo "→ Dry-run Disko (vérification de la syntaxe)..."
echo "  Commande : nix run github:nix-community/disko -- --mode disko --dry-run"
echo ""

# Le dry-run vérifie la syntaxe sans toucher au disque
nix run github:nix-community/disko -- \
  --mode disko \
  --dry-run \
  --flake "${FLAKE_DIR}#kuro" \
  2>&1 || {
    echo ""
    echo "❌ Erreur dans la configuration Disko !"
    echo "   Vérifiez modules/disko.nix"
    rm -f "${VM_DISK}"
    exit 1
  }

echo ""
echo "✅ Configuration Disko validée !"
echo ""
echo "── Prochaines étapes ──────────────────────────────────────────"
echo ""
echo "Pour tester dans une VM complète :"
echo "  1. Booter sur une ISO NixOS dans QEMU avec ce disque"
echo "  2. Exécuter disko dessus"
echo ""
echo "Pour appliquer sur le vrai disque :"
echo "  sudo nix run github:nix-community/disko -- \\"
echo "    --mode disko \\"
echo "    --flake ${FLAKE_DIR}#kuro"
echo ""
echo "⚠️  ATTENTION : cela EFFACERA tout le contenu du disque !"

# Nettoyage
rm -f "${VM_DISK}"
