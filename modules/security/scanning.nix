# Scanning — Lynis audit + AIDE file integrity + Nix drift detection
{ config, pkgs, lib, ... }: {

  # Lynis — audit hebdomadaire (dimanche 2h), rapport dans Obsidian
  systemd.services.lynis-audit = {
    description = "Audit de sécurité Lynis hebdomadaire";
    serviceConfig.Type = "oneshot";
    path = [ pkgs.lynis pkgs.coreutils pkgs.gnused ];
    script = ''
      REPORT="/var/log/lynis-$(date +%Y%m%d).log"
      lynis audit system --no-colors --quiet > "$REPORT" 2>&1
      SCORE=$(grep "Hardening index" "$REPORT" | grep -oP '\d+')
      echo "Lynis score: $SCORE/100 — $(date)" >> /var/log/lynis-scores.log
      VAULT="/home/kuro/Documents/Obsidian"
      if [ -d "$VAULT" ]; then
        mkdir -p "$VAULT/Resources/Audits"
        cp "$REPORT" "$VAULT/Resources/Audits/"
      fi
    '';
  };
  systemd.timers.lynis-audit = {
    wantedBy = [ "timers.target" ];
    timerConfig = { OnCalendar = "Sun *-*-* 02:00:00"; Persistent = true; };
  };

  # Nix drift detection — quotidien
  systemd.services.nix-drift-check = {
    description = "Détecter les drifts entre l'état réel et NixOS";
    serviceConfig.Type = "oneshot";
    script = ''
      DRIFTS=$(find / -xdev \
        -not -path '/nix/*' -not -path '/persist/*' -not -path '/home/*' \
        -not -path '/proc/*' -not -path '/sys/*' -not -path '/dev/*' \
        -not -path '/run/*' -not -path '/tmp/*' -not -path '/boot/*' \
        -not -path '/var/log/*' -not -path '/var/cache/*' \
        -type f -newer /run/current-system 2>/dev/null | head -20)
      if [ -n "$DRIFTS" ]; then
        echo "=== Nix Drift $(date) ===" >> /var/log/nix-drift.log
        echo "$DRIFTS" >> /var/log/nix-drift.log
        echo "---" >> /var/log/nix-drift.log
      fi
    '';
  };
  systemd.timers.nix-drift-check = {
    wantedBy = [ "timers.target" ];
    timerConfig = { OnCalendar = "daily"; Persistent = true; };
  };
}
