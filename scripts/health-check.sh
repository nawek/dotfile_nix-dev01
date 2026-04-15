#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  Health Check — Dashboard système en un coup d'oeil              ║
# ╚══════════════════════════════════════════════════════════════════╝

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  CITADEL Health Check                         ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# ── Système ──────────────────────────────────────────────────────
echo -e "${BLUE}── Système ──────────────────────────────────────${NC}"
echo "  Uptime    : $(uptime -p)"
echo "  Boot time : $(systemd-analyze | head -1 | sed 's/Startup finished in //')"
echo "  Kernel    : $(uname -r)"
echo "  NixOS gen : $(readlink /nix/var/nix/profiles/system | grep -oP 'system-\K\d+')"

# ── Disque ───────────────────────────────────────────────────────
echo ""
echo -e "${BLUE}── Disque ───────────────────────────────────────${NC}"
df -h / /nix/store /persist /home 2>/dev/null | tail -4 | while read line; do
  USAGE=$(echo "$line" | awk '{print $5}' | tr -d '%')
  if [ "$USAGE" -gt 85 ] 2>/dev/null; then
    echo -e "  ${RED}$line${NC}"
  elif [ "$USAGE" -gt 70 ] 2>/dev/null; then
    echo -e "  ${YELLOW}$line${NC}"
  else
    echo "  $line"
  fi
done

# ── BTRFS ────────────────────────────────────────────────────────
echo ""
echo -e "${BLUE}── BTRFS ────────────────────────────────────────${NC}"
echo "  Snapshots : $(ls /.snapshots/persist/ 2>/dev/null | wc -l) persist, $(ls /.snapshots/home/ 2>/dev/null | wc -l) home"

# ── Services failed ──────────────────────────────────────────────
echo ""
echo -e "${BLUE}── Services ─────────────────────────────────────${NC}"
FAILED=$(systemctl --failed --no-legend 2>/dev/null | wc -l)
if [ "$FAILED" -gt 0 ]; then
  echo -e "  ${RED}$FAILED service(s) en échec :${NC}"
  systemctl --failed --no-legend 2>/dev/null | sed 's/^/    /'
else
  echo -e "  ${GREEN}✓ Tous les services sont OK${NC}"
fi

# ── Docker ───────────────────────────────────────────────────────
echo ""
echo -e "${BLUE}── Docker ───────────────────────────────────────${NC}"
if command -v docker &>/dev/null && docker info &>/dev/null 2>&1; then
  RUNNING=$(docker ps -q 2>/dev/null | wc -l)
  TOTAL=$(docker ps -aq 2>/dev/null | wc -l)
  echo "  Containers : $RUNNING running / $TOTAL total"
  docker ps --format '    {{.Names}}\t{{.Status}}' 2>/dev/null | head -5
else
  echo "  Docker non disponible ou non démarré"
fi

# ── Tailscale ────────────────────────────────────────────────────
echo ""
echo -e "${BLUE}── Tailscale ────────────────────────────────────${NC}"
if command -v tailscale &>/dev/null; then
  if tailscale status &>/dev/null 2>&1; then
    PEERS=$(tailscale status 2>/dev/null | grep -c "active" || echo 0)
    echo -e "  ${GREEN}✓ Connecté${NC} — $PEERS peer(s) actif(s)"
    echo "  IP : $(tailscale ip -4 2>/dev/null)"
  else
    echo -e "  ${YELLOW}⚠ Déconnecté${NC} — lancer : sudo tailscale up"
  fi
else
  echo "  Tailscale non installé"
fi

# ── Sécurité ─────────────────────────────────────────────────────
echo ""
echo -e "${BLUE}── Sécurité ─────────────────────────────────────${NC}"
# Dernier score Lynis
if [ -f /var/log/lynis-scores.log ]; then
  echo "  Lynis : $(tail -1 /var/log/lynis-scores.log)"
else
  echo "  Lynis : pas encore d'audit (dimanche prochain)"
fi
# Fail2ban
if command -v fail2ban-client &>/dev/null; then
  BANNED=$(sudo fail2ban-client status sshd 2>/dev/null | grep "Currently banned" | awk '{print $NF}' || echo "?")
  echo "  Fail2ban : $BANNED IP(s) bannies"
fi
# Ports ouverts
PORTS=$(ss -tulnp 2>/dev/null | grep LISTEN | wc -l)
echo "  Ports ouverts : $PORTS"

# ── Batterie ─────────────────────────────────────────────────────
if [ -f /sys/class/power_supply/BAT0/capacity ]; then
  echo ""
  echo -e "${BLUE}── Batterie ─────────────────────────────────────${NC}"
  BAT=$(cat /sys/class/power_supply/BAT0/capacity)
  STATUS=$(cat /sys/class/power_supply/BAT0/status)
  if [ "$BAT" -le 20 ]; then
    echo -e "  ${RED}$BAT% ($STATUS)${NC}"
  else
    echo -e "  ${GREEN}$BAT% ($STATUS)${NC}"
  fi
fi

echo ""
echo "══════════════════════════════════════════════════════════════"
