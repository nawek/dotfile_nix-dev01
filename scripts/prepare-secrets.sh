#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  Préparation des secrets — Guide interactif                     ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Ce script guide la création de tous les secrets nécessaires
# AVANT le déploiement. À exécuter sur n'importe quelle machine
# avec nix-shell -p age sops mkpasswd

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; NC='\033[0m'
info() { echo -e "${BLUE}→${NC} $1"; }
ok() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }

FLAKE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$FLAKE_DIR"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  Préparation des secrets — CITADEL            ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# ── 1. Clé age ──────────────────────────────────────────────────
info "Étape 1/4 — Clé age pour SOPS"

AGE_DIR="/tmp/citadel-secrets"
mkdir -p "$AGE_DIR"

if [ -f "$AGE_DIR/age-keys.txt" ]; then
  warn "Clé age déjà générée dans $AGE_DIR/age-keys.txt"
else
  age-keygen -o "$AGE_DIR/age-keys.txt" 2>&1
  ok "Clé age générée"
fi

AGE_PUB=$(grep "public key:" "$AGE_DIR/age-keys.txt" | cut -d: -f2 | tr -d ' ')
echo ""
echo -e "  Clé publique : ${GREEN}$AGE_PUB${NC}"
echo ""

# Mettre la clé dans .sops.yaml
info "Mise à jour de .sops.yaml avec la clé publique..."
sed -i "s|age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx|$AGE_PUB|" "$FLAKE_DIR/.sops.yaml"
ok ".sops.yaml mis à jour"

# ── 2. Mot de passe utilisateur ──────────────────────────────────
echo ""
info "Étape 2/4 — Mot de passe utilisateur"
echo -e "  Entrez le mot de passe pour l'utilisateur kuro :"
read -rsp "  Mot de passe : " USER_PASSWORD
echo ""
USER_HASH=$(echo "$USER_PASSWORD" | mkpasswd -m sha-512 -s)
ok "Hash SHA-512 généré"

# ── 3. Mot de passe WiFi ────────────────────────────────────────
echo ""
info "Étape 3/4 — Mot de passe WiFi"
read -rp "  SSID du réseau WiFi : " WIFI_SSID
read -rsp "  Mot de passe WiFi : " WIFI_PASSWORD
echo ""
ok "WiFi configuré : $WIFI_SSID"

# Mettre le SSID dans configuration.nix
sed -i "s|ssid = \"MonWiFi\"|ssid = \"$WIFI_SSID\"|" "$FLAKE_DIR/hosts/kuro/configuration.nix"

# ── 4. Écrire et chiffrer les secrets ────────────────────────────
echo ""
info "Étape 4/4 — Chiffrement des secrets avec SOPS"

# Écrire le fichier secrets en clair temporairement
cat > "$FLAKE_DIR/secrets/secrets.yaml" << SECRETS_EOF
user-password: "$USER_HASH"
wifi-password: "HOME_WIFI_PASSWORD=$WIFI_PASSWORD"
SECRETS_EOF

# Chiffrer avec sops
export SOPS_AGE_KEY_FILE="$AGE_DIR/age-keys.txt"
sops --encrypt --in-place "$FLAKE_DIR/secrets/secrets.yaml"
ok "Secrets chiffrés avec SOPS"

# ── Résumé ───────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════════════"
echo -e "${GREEN}✓ Secrets prêts !${NC}"
echo ""
echo "  Clé age     : $AGE_DIR/age-keys.txt"
echo "  Clé publique: $AGE_PUB"
echo "  Secrets     : $FLAKE_DIR/secrets/secrets.yaml (chiffré)"
echo ""
echo "  ⚠ IMPORTANT — Le jour du déploiement :"
echo "    1. Copier la clé age sur le laptop :"
echo "       cp $AGE_DIR/age-keys.txt /persist/system/sops-age-keys.txt"
echo "    2. Garder une copie de sauvegarde de la clé age !"
echo "══════════════════════════════════════════════════════════════"
