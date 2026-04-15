#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  CITADEL — Installation NixOS interactive one-liner              ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Script d'onboarding complet. À lancer depuis l'ISO NixOS :
#
#   bash <(curl -sL https://raw.githubusercontent.com/nawek/dotfile_nix-dev01/claude/nixos-dev-config-1pd8G/scripts/install.sh)
#
# Ce script guide interactivement :
#   1. Connexion WiFi
#   2. Configuration du profil (hostname, username, disk, GPU)
#   3. Préparation des secrets (password, WiFi, clé age)
#   4. Partitionnement (Disko + LUKS)
#   5. Installation NixOS
#   6. Post-configuration
#   7. Reboot

set -euo pipefail

# ── Couleurs ─────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'
YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

info() { echo -e "${BLUE}→${NC} $1"; }
ok() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
err() { echo -e "${RED}✗${NC} $1"; }
section() { echo ""; echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; echo -e "${BOLD}  $1${NC}"; echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; echo ""; }

# ── Banner ───────────────────────────────────────────────────────
clear
echo -e "${BLUE}"
cat << 'BANNER'

     ██████╗██╗████████╗ █████╗ ██████╗ ███████╗██╗
    ██╔════╝██║╚══██╔══╝██╔══██╗██╔══██╗██╔════╝██║
    ██║     ██║   ██║   ███████║██║  ██║█████╗  ██║
    ██║     ██║   ██║   ██╔══██║██║  ██║██╔══╝  ██║
    ╚██████╗██║   ██║   ██║  ██║██████╔╝███████╗███████╗
     ╚═════╝╚═╝   ╚═╝   ╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝

              NixOS — Installation interactive

BANNER
echo -e "${NC}"
echo "  Bienvenue dans l'installeur CITADEL."
echo "  Ce script va configurer et installer NixOS sur cette machine."
echo ""
echo -e "  ${YELLOW}⚠ ATTENTION : Le disque sélectionné sera ENTIÈREMENT EFFACÉ.${NC}"
echo ""
read -rp "  Appuyer sur Entrée pour commencer..."

# ══════════════════════════════════════════════════════════════════
section "1/7 — Connexion réseau"
# ══════════════════════════════════════════════════════════════════

# Vérifier si déjà connecté
if ping -c1 -W3 nixos.org &>/dev/null; then
  ok "Déjà connecté à Internet"
else
  info "Connexion WiFi nécessaire"
  echo ""

  # Lister les réseaux disponibles
  info "Réseaux WiFi disponibles :"
  nmcli device wifi list 2>/dev/null | head -15
  echo ""

  read -rp "  SSID du réseau WiFi : " WIFI_SSID
  read -rsp "  Mot de passe WiFi : " WIFI_PASS
  echo ""

  info "Connexion à $WIFI_SSID..."
  nmcli device wifi connect "$WIFI_SSID" password "$WIFI_PASS" 2>/dev/null || {
    # Fallback iwctl
    warn "nmcli échoué, tentative avec iwctl..."
    iwctl station wlan0 connect "$WIFI_SSID" 2>/dev/null || {
      err "Impossible de se connecter au WiFi."
      echo "  Connecter manuellement puis relancer ce script."
      exit 1
    }
  }

  # Attendre la connexion
  sleep 3
  if ping -c1 -W3 nixos.org &>/dev/null; then
    ok "Connecté à Internet via $WIFI_SSID"
  else
    err "Pas de connexion Internet. Vérifier le réseau."
    exit 1
  fi
fi

# ══════════════════════════════════════════════════════════════════
section "2/7 — Configuration du profil"
# ══════════════════════════════════════════════════════════════════

# Hostname
echo -e "  Nom de la machine (hostname) :"
read -rp "  [kuro] : " INPUT_HOSTNAME
HOSTNAME="${INPUT_HOSTNAME:-kuro}"
ok "Hostname : $HOSTNAME"

# Username
echo ""
echo -e "  Nom d'utilisateur :"
read -rp "  [kuro] : " INPUT_USER
USERNAME="${INPUT_USER:-kuro}"
ok "Username : $USERNAME"

# Email
echo ""
echo -e "  Email (pour Git) :"
read -rp "  : " INPUT_EMAIL
EMAIL="${INPUT_EMAIL:-kuro@$HOSTNAME.local}"
ok "Email : $EMAIL"

# Disque
echo ""
info "Disques disponibles :"
lsblk -d -o NAME,SIZE,TYPE,MODEL | grep disk
echo ""
echo -e "  Disque cible (sera EFFACÉ) :"
read -rp "  [/dev/nvme0n1] : " INPUT_DISK
DISK="${INPUT_DISK:-/dev/nvme0n1}"
ok "Disque : $DISK"

# GPU
echo ""
echo -e "  Type de GPU :"
echo "    1) NVIDIA (propriétaire)"
echo "    2) AMD (open source)"
echo "    3) Intel (intégré)"
read -rp "  [1] : " INPUT_GPU
GPU_CHOICE="${INPUT_GPU:-1}"

# CPU
echo ""
echo -e "  Type de CPU :"
echo "    1) Intel"
echo "    2) AMD"
read -rp "  [1] : " INPUT_CPU
CPU_CHOICE="${INPUT_CPU:-1}"

# Swap size
echo ""
echo -e "  Taille du swap (en Go) :"
read -rp "  [8] : " INPUT_SWAP
SWAP_SIZE="${INPUT_SWAP:-8}"
ok "Swap : ${SWAP_SIZE}G"

# Timezone
echo ""
echo -e "  Fuseau horaire :"
read -rp "  [Europe/Paris] : " INPUT_TZ
TIMEZONE="${INPUT_TZ:-Europe/Paris}"
ok "Timezone : $TIMEZONE"

# Keyboard layout
echo ""
echo -e "  Disposition clavier :"
read -rp "  [fr] : " INPUT_KB
KB_LAYOUT="${INPUT_KB:-fr}"
ok "Clavier : $KB_LAYOUT"

# WiFi à pré-configurer
echo ""
echo -e "  SSID WiFi à pré-configurer (pour le premier boot) :"
if [ -n "${WIFI_SSID:-}" ]; then
  read -rp "  [$WIFI_SSID] : " INPUT_WIFI_SSID
  WIFI_SSID="${INPUT_WIFI_SSID:-$WIFI_SSID}"
else
  read -rp "  : " WIFI_SSID
fi

if [ -z "${WIFI_PASS:-}" ]; then
  read -rsp "  Mot de passe WiFi : " WIFI_PASS
  echo ""
fi
ok "WiFi : $WIFI_SSID"

# ══════════════════════════════════════════════════════════════════
section "3/7 — Clonage de la configuration"
# ══════════════════════════════════════════════════════════════════

INSTALL_DIR="/tmp/citadel-install"
rm -rf "$INSTALL_DIR"

info "Clonage du dépôt..."
nix-shell -p git --run "git clone https://github.com/nawek/dotfile_nix-dev01.git $INSTALL_DIR"
cd "$INSTALL_DIR"
nix-shell -p git --run "git checkout claude/nixos-dev-config-1pd8G"
ok "Dépôt cloné"

# ══════════════════════════════════════════════════════════════════
section "4/7 — Personnalisation de la configuration"
# ══════════════════════════════════════════════════════════════════

info "Application du profil..."

# Hostname
sed -i "s/networking.hostName = \"kuro\"/networking.hostName = \"$HOSTNAME\"/" hosts/kuro/configuration.nix
ok "Hostname → $HOSTNAME"

# Username (dans tous les fichiers)
if [ "$USERNAME" != "kuro" ]; then
  find . -name "*.nix" -not -path "./.git/*" -exec sed -i "s/kuro/$USERNAME/g" {} \;
  ok "Username → $USERNAME (global)"
fi

# Email Git
sed -i "s/votre@email.com/$EMAIL/" home/git.nix
ok "Email Git → $EMAIL"

# Disque
sed -i "s|device = \"/dev/nvme0n1\"|device = \"$DISK\"|" modules/disko.nix
ok "Disque → $DISK"

# Swap size
sed -i "s/swapfile.size = \"8G\"/swapfile.size = \"${SWAP_SIZE}G\"/" modules/disko.nix
ok "Swap → ${SWAP_SIZE}G"

# Timezone
sed -i "s|Europe/Paris|$TIMEZONE|" hosts/kuro/configuration.nix
ok "Timezone → $TIMEZONE"

# Keyboard
sed -i "s/kb_layout = \"fr\"/kb_layout = \"$KB_LAYOUT\"/" home/hyprland.nix
if [ "$KB_LAYOUT" != "fr" ]; then
  sed -i "s/console.keyMap = \"fr\"/console.keyMap = \"$KB_LAYOUT\"/" hosts/kuro/configuration.nix
fi
ok "Clavier → $KB_LAYOUT"

# WiFi SSID
sed -i "s/ssid = \"MonWiFi\"/ssid = \"$WIFI_SSID\"/" hosts/kuro/configuration.nix
ok "WiFi SSID → $WIFI_SSID"

# GPU
case "$GPU_CHOICE" in
  2) # AMD — désactiver NVIDIA, pas besoin de module
    sed -i 's|../../modules/nvidia.nix|# ../../modules/nvidia.nix  # Désactivé (AMD)|' hosts/kuro/configuration.nix
    ok "GPU → AMD (module NVIDIA désactivé)"
    ;;
  3) # Intel — désactiver NVIDIA
    sed -i 's|../../modules/nvidia.nix|# ../../modules/nvidia.nix  # Désactivé (Intel)|' hosts/kuro/configuration.nix
    ok "GPU → Intel intégré (module NVIDIA désactivé)"
    ;;
  *) # NVIDIA
    ok "GPU → NVIDIA (module actif)"
    ;;
esac

# CPU
case "$CPU_CHOICE" in
  2) # AMD
    sed -i 's/kvm-intel/kvm-amd/' hosts/kuro/hardware-configuration.nix
    ok "CPU → AMD"
    ;;
  *) ok "CPU → Intel" ;;
esac

# Hardware config
info "Génération de la configuration hardware..."
nixos-generate-config --show-hardware-config --root /mnt 2>/dev/null > hosts/kuro/hardware-configuration.nix || {
  warn "nixos-generate-config non disponible (le disque n'est pas encore monté)"
  warn "Le hardware-configuration.nix sera généré après le partitionnement"
}

# ══════════════════════════════════════════════════════════════════
section "5/7 — Préparation des secrets"
# ══════════════════════════════════════════════════════════════════

# Clé age
info "Génération de la clé age pour SOPS..."
mkdir -p /tmp/citadel-secrets
nix-shell -p age --run "age-keygen -o /tmp/citadel-secrets/age-keys.txt 2>&1"
AGE_PUB=$(grep "public key:" /tmp/citadel-secrets/age-keys.txt | cut -d: -f2 | tr -d ' ')
ok "Clé age générée"
echo -e "  Clé publique : ${GREEN}$AGE_PUB${NC}"

# Mettre la clé dans .sops.yaml
sed -i "s|age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx|$AGE_PUB|" .sops.yaml
ok ".sops.yaml configuré"

# Mot de passe utilisateur
echo ""
info "Mot de passe pour l'utilisateur $USERNAME :"
while true; do
  read -rsp "  Mot de passe : " USER_PASS
  echo ""
  read -rsp "  Confirmer : " USER_PASS2
  echo ""
  if [ "$USER_PASS" = "$USER_PASS2" ]; then
    break
  else
    warn "Les mots de passe ne correspondent pas. Réessayer."
  fi
done

USER_HASH=$(echo "$USER_PASS" | nix-shell -p mkpasswd --run "mkpasswd -m sha-512 -s")
ok "Hash du mot de passe généré"

# Écrire les secrets
cat > secrets/secrets.yaml << SECRETS_EOF
user-password: "$USER_HASH"
wifi-password: "HOME_WIFI_PASSWORD=$WIFI_PASS"
SECRETS_EOF

# Chiffrer avec sops
export SOPS_AGE_KEY_FILE="/tmp/citadel-secrets/age-keys.txt"
nix-shell -p sops --run "sops --encrypt --in-place secrets/secrets.yaml" 2>/dev/null || {
  warn "Chiffrement SOPS échoué — les secrets resteront en clair"
  warn "Chiffrer manuellement après l'installation : sops secrets/secrets.yaml"
}
ok "Secrets préparés"

# ══════════════════════════════════════════════════════════════════
section "6/7 — Installation NixOS"
# ══════════════════════════════════════════════════════════════════

echo ""
echo -e "  ${BOLD}Récapitulatif :${NC}"
echo "  ─────────────────────────────────"
echo "  Hostname  : $HOSTNAME"
echo "  Username  : $USERNAME"
echo "  Email     : $EMAIL"
echo "  Disque    : $DISK (sera EFFACÉ)"
echo "  Swap      : ${SWAP_SIZE}G"
echo "  Timezone  : $TIMEZONE"
echo "  Clavier   : $KB_LAYOUT"
echo "  WiFi      : $WIFI_SSID"
echo "  GPU       : $([ "$GPU_CHOICE" = "1" ] && echo "NVIDIA" || ([ "$GPU_CHOICE" = "2" ] && echo "AMD" || echo "Intel"))"
echo "  CPU       : $([ "$CPU_CHOICE" = "1" ] && echo "Intel" || echo "AMD")"
echo "  ─────────────────────────────────"
echo ""
echo -e "  ${RED}⚠ DERNIÈRE CHANCE — Le disque $DISK va être EFFACÉ !${NC}"
echo ""
read -rp "  Taper 'INSTALLER' pour confirmer : " CONFIRM
if [ "$CONFIRM" != "INSTALLER" ]; then
  echo "  Installation annulée."
  exit 0
fi

echo ""

# Partitionnement
info "Partitionnement avec Disko (LUKS + BTRFS)..."
nix --extra-experimental-features "nix-command flakes" run \
  github:nix-community/disko -- --mode disko --flake "$INSTALL_DIR#$HOSTNAME" 2>&1 || \
  nix --extra-experimental-features "nix-command flakes" run \
  github:nix-community/disko -- --mode disko --flake "$INSTALL_DIR#kuro"
ok "Partitionnement terminé"

# Regénérer hardware-config maintenant que le disque est monté
info "Génération de la configuration hardware..."
nixos-generate-config --show-hardware-config --root /mnt > "$INSTALL_DIR/hosts/kuro/hardware-configuration.nix" 2>/dev/null || {
  warn "Impossible de générer hardware-configuration.nix automatiquement"
}
# Supprimer les fileSystems générés (Disko les gère)
sed -i '/fileSystems\./,/};/d' "$INSTALL_DIR/hosts/kuro/hardware-configuration.nix" 2>/dev/null || true
sed -i '/swapDevices/,/];/d' "$INSTALL_DIR/hosts/kuro/hardware-configuration.nix" 2>/dev/null || true
ok "Hardware configuration générée"

# Copier la clé age
info "Copie de la clé age..."
mkdir -p /mnt/persist/system
cp /tmp/citadel-secrets/age-keys.txt /mnt/persist/system/sops-age-keys.txt
chmod 600 /mnt/persist/system/sops-age-keys.txt
ok "Clé age copiée dans /mnt/persist/system/"

# Copier la config dans /mnt
info "Copie de la configuration..."
mkdir -p /mnt/etc/nixos
cp -r "$INSTALL_DIR"/* /mnt/etc/nixos/ 2>/dev/null || true
cp -r "$INSTALL_DIR"/.* /mnt/etc/nixos/ 2>/dev/null || true
ok "Configuration copiée"

# Installation
info "Installation de NixOS (15-30 minutes selon la connexion)..."
echo ""
nixos-install --flake "$INSTALL_DIR#kuro" --no-root-password 2>&1
ok "NixOS installé !"

# ══════════════════════════════════════════════════════════════════
section "7/7 — Terminé !"
# ══════════════════════════════════════════════════════════════════

echo -e "${GREEN}"
cat << 'DONE'

    ╔══════════════════════════════════════════╗
    ║                                          ║
    ║   CITADEL est installé avec succès !     ║
    ║                                          ║
    ╚══════════════════════════════════════════╝

DONE
echo -e "${NC}"

echo "  Prochaines étapes :"
echo ""
echo "  1. Redémarrer :"
echo "     sudo reboot"
echo ""
echo "  2. Au boot, taper le mot de passe LUKS"
echo ""
echo "  3. Après le premier login, lancer :"
echo "     bash ~/dotfile_nix-dev01/scripts/post-install.sh"
echo ""
echo "  4. Configurer Secure Boot :"
echo "     sudo sbctl create-keys"
echo "     sudo sbctl enroll-keys --microsoft"
echo ""
echo "  ─────────────────────────────────────────"
echo "  Config : /etc/nixos/"
echo "  Secrets: /persist/system/sops-age-keys.txt"
echo "  Vault  : ~/Documents/Obsidian/"
echo "  ─────────────────────────────────────────"
echo ""
echo -e "  ${BOLD}Bienvenue dans CITADEL, $USERNAME.${NC}"
echo ""
read -rp "  Appuyer sur Entrée pour redémarrer..."
sudo reboot
