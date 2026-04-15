#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  Audit — Tous les audits de sécurité en une commande            ║
# ╚══════════════════════════════════════════════════════════════════╝

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; NC='\033[0m'
info() { echo -e "${BLUE}→${NC} $1"; }
ok() { echo -e "${GREEN}✓${NC} $1"; }

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  Audit de sécurité — CITADEL                  ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# ── 1. Lynis ─────────────────────────────────────────────────────
info "1/7 — Lynis (audit système complet)..."
if command -v lynis &>/dev/null; then
  SCORE=$(sudo lynis audit system --quick --no-colors 2>&1 | grep "Hardening index" | grep -oP '\d+' || echo "?")
  echo -e "  Score : ${GREEN}$SCORE/100${NC}"
else
  echo "  ⏭ Lynis non disponible"
fi

# ── 2. AIDE ──────────────────────────────────────────────────────
echo ""
info "2/7 — AIDE (intégrité fichiers)..."
if command -v aide &>/dev/null && [ -f /var/lib/aide/aide.db ]; then
  CHANGES=$(sudo aide --check 2>&1 | grep -c "changed\|added\|removed" || echo "0")
  if [ "$CHANGES" -gt 0 ]; then
    echo -e "  ${YELLOW}$CHANGES fichier(s) modifié(s)${NC}"
  else
    echo -e "  ${GREEN}✓ Aucune modification détectée${NC}"
  fi
else
  echo "  ⏭ AIDE non initialisé (lancer aide-init)"
fi

# ── 3. Ports ouverts ─────────────────────────────────────────────
echo ""
info "3/7 — Ports ouverts..."
PORTS=$(ss -tulnp 2>/dev/null | grep LISTEN | wc -l)
echo "  $PORTS port(s) en écoute :"
ss -tulnp 2>/dev/null | grep LISTEN | awk '{print "    "$1" "$4" "$7}' | head -10

# ── 4. Services failed ──────────────────────────────────────────
echo ""
info "4/7 — Services systemd..."
FAILED=$(systemctl --failed --no-legend 2>/dev/null | wc -l)
if [ "$FAILED" -gt 0 ]; then
  echo -e "  ${RED}$FAILED service(s) en échec${NC}"
  systemctl --failed --no-legend 2>/dev/null | sed 's/^/    /'
else
  echo -e "  ${GREEN}✓ Tous les services OK${NC}"
fi

# ── 5. Fail2ban ──────────────────────────────────────────────────
echo ""
info "5/7 — Fail2ban..."
if command -v fail2ban-client &>/dev/null; then
  sudo fail2ban-client status sshd 2>/dev/null | grep -E "Currently|Total" | sed 's/^/  /'
else
  echo "  ⏭ Fail2ban non disponible"
fi

# ── 6. Nix drift ────────────────────────────────────────────────
echo ""
info "6/7 — Nix drift detection..."
if [ -f /var/log/nix-drift.log ]; then
  DRIFTS=$(tail -20 /var/log/nix-drift.log | grep -v "^---\|^===" | wc -l)
  if [ "$DRIFTS" -gt 0 ]; then
    echo -e "  ${YELLOW}$DRIFTS fichier(s) modifiés hors NixOS${NC}"
    tail -10 /var/log/nix-drift.log | grep -v "^---\|^===" | sed 's/^/    /' | head -5
  else
    echo -e "  ${GREEN}✓ Aucun drift détecté${NC}"
  fi
else
  echo "  ⏭ Pas encore de rapport (timer quotidien)"
fi

# ── 7. Espace disque ────────────────────────────────────────────
echo ""
info "7/7 — Espace disque..."
df -h / /nix/store /persist 2>/dev/null | tail -3 | while read line; do
  USAGE=$(echo "$line" | awk '{print $5}' | tr -d '%')
  if [ "$USAGE" -gt 85 ] 2>/dev/null; then
    echo -e "  ${RED}$line${NC}"
  else
    echo "  $line"
  fi
done

# ── Résumé ───────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════════════"
echo -e "${GREEN}✓ Audit terminé${NC}"
echo "══════════════════════════════════════════════════════════════"
