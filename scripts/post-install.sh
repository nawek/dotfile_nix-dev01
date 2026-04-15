#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  Post-installation — Configurer après le premier boot           ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# À exécuter après le premier boot réussi.
# Configure : Secure Boot, Tailscale, Flatpak, AIDE, pre-commit

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
info() { echo -e "${BLUE}→${NC} $1"; }
ok() { echo -e "${GREEN}✓${NC} $1"; }
skip() { echo -e "  ⏭ $1"; }

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  Post-installation — CITADEL                  ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# ── 1. Secure Boot ──────────────────────────────────────────────
info "1/6 — Secure Boot (Lanzaboote)"
if command -v sbctl &>/dev/null; then
  if [ ! -f /etc/secureboot/GUID ]; then
    sudo sbctl create-keys
    ok "Clés Secure Boot créées"
    echo "  → Redémarrer dans le BIOS, activer Secure Boot en mode Setup"
    echo "  → Puis : sudo sbctl enroll-keys --microsoft"
  else
    ok "Clés Secure Boot déjà présentes"
    sudo sbctl verify | head -5
  fi
else
  skip "sbctl non disponible"
fi

# ── 2. Tailscale ────────────────────────────────────────────────
echo ""
info "2/6 — Tailscale VPN"
if command -v tailscale &>/dev/null; then
  if tailscale status &>/dev/null; then
    ok "Tailscale déjà connecté"
    tailscale status | head -5
  else
    sudo tailscale up
    ok "Tailscale activé"
  fi
else
  skip "Tailscale non disponible"
fi

# ── 3. Flatpak ──────────────────────────────────────────────────
echo ""
info "3/6 — Flatpak (Flathub)"
if command -v flatpak &>/dev/null; then
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null
  ok "Flathub configuré"
else
  skip "Flatpak non disponible"
fi

# ── 4. AIDE — Initialiser la base d'intégrité ───────────────────
echo ""
info "4/6 — AIDE (file integrity)"
if command -v aide &>/dev/null; then
  if [ ! -f /var/lib/aide/aide.db ]; then
    echo "  Initialisation de la base AIDE (peut prendre 1-2 minutes)..."
    sudo aide --init
    sudo mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db 2>/dev/null || true
    ok "Base AIDE initialisée"
  else
    ok "Base AIDE déjà présente"
  fi
else
  skip "AIDE non disponible"
fi

# ── 5. Pre-commit hooks ─────────────────────────────────────────
echo ""
info "5/6 — Pre-commit hooks"
FLAKE_DIR="$HOME/dotfile_nix-dev01"
if [ -d "$FLAKE_DIR/.git" ] && command -v pre-commit &>/dev/null; then
  cd "$FLAKE_DIR"
  pre-commit install
  ok "Pre-commit hooks installés"
else
  skip "Repo ou pre-commit non disponible"
fi

# ── 6. Obsidian vault ───────────────────────────────────────────
echo ""
info "6/6 — Vault Obsidian"
VAULT="$HOME/Documents/Obsidian"
if [ -d "$VAULT" ]; then
  ok "Vault Obsidian présent ($VAULT)"
else
  echo "  Le vault sera initialisé au prochain login (home.activation)"
fi

# ── Résumé ───────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════════════"
echo -e "${GREEN}✓ Post-installation terminée !${NC}"
echo ""
echo "  Tu peux maintenant :"
echo "    • Ouvrir Chromium et configurer Bitwarden"
echo "    • Ouvrir Obsidian et installer les plugins recommandés"
echo "    • Lancer 'morning' pour ta première daily note"
echo "    • Lancer 'hcheck' pour vérifier le homelab"
echo "══════════════════════════════════════════════════════════════"
