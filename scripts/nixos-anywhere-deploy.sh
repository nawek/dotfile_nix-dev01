#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  Déploiement NixOS distant via nixos-anywhere                   ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Déploie cette configuration NixOS sur un serveur distant
# en une seule commande via SSH. Le serveur distant est
# reformaté et installé automatiquement.
#
# ⚠️ ATTENTION : cela EFFACE TOUT sur le serveur distant !
#
# Prérequis :
#   - Accès SSH root au serveur distant
#   - Le serveur doit booter sur un live environment (ISO NixOS, kexec)
#   - Connexion internet sur les deux machines
#
# Usage :
#   ./scripts/nixos-anywhere-deploy.sh <IP_OU_HOSTNAME>
#
# Exemple :
#   ./scripts/nixos-anywhere-deploy.sh root@192.168.1.100
#   ./scripts/nixos-anywhere-deploy.sh root@mon-serveur.tailscale

set -euo pipefail

# ── Vérification des arguments ─────────────────────────────────────
if [ $# -lt 1 ]; then
  echo "Usage : $0 <user@host>"
  echo ""
  echo "Exemples :"
  echo "  $0 root@192.168.1.100"
  echo "  $0 root@mon-serveur.local"
  exit 1
fi

TARGET="$1"
FLAKE_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "╔══════════════════════════════════════════════╗"
echo "║  Déploiement NixOS via nixos-anywhere        ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "  Cible  : ${TARGET}"
echo "  Config : ${FLAKE_DIR}#kuro"
echo ""

# ── Checklist pré-déploiement ──────────────────────────────────────
echo "── Checklist ──────────────────────────────────────────────────"
echo "  [ ] Accès SSH root fonctionnel : ssh ${TARGET}"
echo "  [ ] Backup des données importantes effectué"
echo "  [ ] La cible est sur un live environment (ISO NixOS / kexec)"
echo "  [ ] hardware-configuration.nix adapté pour la cible"
echo "  [ ] modules/disko.nix : device correct pour la cible"
echo "  [ ] Clé age SOPS disponible ou à copier après"
echo ""

read -rp "Continuer le déploiement ? (oui/non) : " confirm
if [ "$confirm" != "oui" ]; then
  echo "Déploiement annulé."
  exit 0
fi

echo ""
echo "→ Lancement de nixos-anywhere..."
echo ""

# ── Déploiement ────────────────────────────────────────────────────
nix run github:nix-community/nixos-anywhere -- \
  --flake "${FLAKE_DIR}#kuro" \
  "${TARGET}"

echo ""
echo "✅ Déploiement terminé !"
echo ""
echo "── Post-déploiement ──────────────────────────────────────────"
echo ""
echo "1. Copier la clé age SOPS sur la cible :"
echo "   scp /persist/system/sops-age-keys.txt ${TARGET}:/persist/system/sops-age-keys.txt"
echo ""
echo "2. Configurer Secure Boot (si applicable) :"
echo "   ssh ${TARGET} 'sudo sbctl create-keys && sudo sbctl enroll-keys --microsoft'"
echo ""
echo "3. Redémarrer la cible :"
echo "   ssh ${TARGET} 'sudo reboot'"
