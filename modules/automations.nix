# ╔══════════════════════════════════════════════════════════════════╗
# ║  Automatisations — Timers systemd et scripts de maintenance     ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Automatisations système :
# - Nix GC intelligent (seuil disque)
# - Flake update + test hebdomadaire
# - Docker cleanup avancé
# - Log rotation
# - BTRFS balance mensuel
# - DNS leak test quotidien
# - Boot time tracking
# - Disk space alertes

{ config, pkgs, lib, ... }: {

  # ══════════════════════════════════════════════════════════════════
  # 1. NIX GC INTELLIGENT — Uniquement si disque > 80%
  # ══════════════════════════════════════════════════════════════════
  # Remplace le GC weekly aveugle par un GC conditionnel
  systemd.services.nix-gc-smart = {
    description = "Nix Garbage Collection intelligent (seuil 80%)";
    serviceConfig.Type = "oneshot";
    script = ''
      USAGE=$(${pkgs.coreutils}/bin/df /nix/store --output=pcent | tail -1 | tr -d ' %')
      if [ "$USAGE" -gt 80 ]; then
        echo "Disque à $USAGE% — lancement du GC Nix..."
        ${config.nix.package}/bin/nix-collect-garbage --delete-older-than 7d
        echo "GC terminé. Nouvel usage : $(${pkgs.coreutils}/bin/df /nix/store --output=pcent | tail -1)"
      else
        echo "Disque à $USAGE% — pas besoin de GC."
      fi
    '';
  };

  systemd.timers.nix-gc-smart = {
    description = "Timer pour le GC Nix intelligent";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };

  # ══════════════════════════════════════════════════════════════════
  # 2. DOCKER CLEANUP AVANCÉ
  # ══════════════════════════════════════════════════════════════════
  # En plus du prune hebdo Docker, nettoyer les volumes orphelins
  systemd.services.docker-deep-clean = {
    description = "Nettoyage Docker avancé (images dangling + volumes orphelins)";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.docker}/bin/docker image prune -af --filter "until=168h"
      ${pkgs.docker}/bin/docker volume prune -f
      ${pkgs.docker}/bin/docker network prune -f
      echo "Docker deep clean terminé."
    '';
  };

  systemd.timers.docker-deep-clean = {
    description = "Timer Docker deep clean hebdomadaire";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Sun 03:00";
      Persistent = true;
    };
  };

  # ══════════════════════════════════════════════════════════════════
  # 3. TMPFILES — Nettoyage automatique /tmp et ~/Downloads
  # ══════════════════════════════════════════════════════════════════
  systemd.tmpfiles.rules = [
    "d /tmp 1777 root root 7d"          # Nettoyer /tmp après 7 jours
    # ~/Downloads nettoyé par le timer user dans home/default.nix
  ];

  # ══════════════════════════════════════════════════════════════════
  # 4. LOG ROTATION — Limiter la taille des logs
  # ══════════════════════════════════════════════════════════════════
  services.journald.extraConfig = ''
    Storage=persistent
    SystemMaxUse=500M
    SystemMaxFileSize=50M
    MaxRetentionSec=1month
    Compress=yes
  '';

  # ══════════════════════════════════════════════════════════════════
  # 4. BTRFS BALANCE — Défragmentation métadonnées mensuelle
  # ══════════════════════════════════════════════════════════════════
  systemd.services.btrfs-balance = {
    description = "BTRFS balance des métadonnées";
    serviceConfig.Type = "oneshot";
    script = ''
      echo "Démarrage du balance BTRFS..."
      ${pkgs.btrfs-progs}/bin/btrfs balance start -dusage=50 -musage=70 /
      echo "Balance BTRFS terminé."
    '';
  };

  systemd.timers.btrfs-balance = {
    description = "Timer BTRFS balance mensuel";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "monthly";
      Persistent = true;
    };
  };

  # ══════════════════════════════════════════════════════════════════
  # 5. DISK SPACE ALERT — Notification si > 85%
  # ══════════════════════════════════════════════════════════════════
  systemd.services.disk-space-alert = {
    description = "Alerte espace disque";
    serviceConfig.Type = "oneshot";
    script = ''
      for mount in / /nix/store /persist /home; do
        if ${pkgs.coreutils}/bin/mountpoint -q "$mount" 2>/dev/null; then
          USAGE=$(${pkgs.coreutils}/bin/df "$mount" --output=pcent | tail -1 | tr -d ' %')
          if [ "$USAGE" -gt 85 ]; then
            echo "ALERTE: $mount à $USAGE% !" | ${pkgs.systemd}/bin/systemd-cat -t disk-alert -p warning
          fi
        fi
      done
    '';
  };

  systemd.timers.disk-space-alert = {
    description = "Timer alerte espace disque";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "hourly";
      Persistent = true;
    };
  };

  # ══════════════════════════════════════════════════════════════════
  # 6. SSH LOGIN NOTIFICATION — Log à chaque connexion SSH
  # ══════════════════════════════════════════════════════════════════
  # Les connexions SSH sont loggées via journald (auditd + sshd)
  # Consulter : journalctl -u sshd --since today
  # Note : notify-send ne fonctionne pas via PAM (pas de display Wayland)

  # ══════════════════════════════════════════════════════════════════
  # 7. BOOT TIME TRACKER — Log le temps de boot
  # ══════════════════════════════════════════════════════════════════
  systemd.services.boot-time-log = {
    description = "Log le temps de boot pour détecter les régressions";
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.systemd}/bin/systemd-analyze >> /var/log/boot-times.log 2>&1
      echo "---" >> /var/log/boot-times.log
    '';
  };

  # ══════════════════════════════════════════════════════════════════
  # 8. WEEKLY REVIEW REMINDER — Vendredi 17h
  # ══════════════════════════════════════════════════════════════════
  systemd.services.weekly-review = {
    description = "Rappel weekly review Obsidian";
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.libnotify}/bin/notify-send -u normal "📋 Weekly Review" "C'est l'heure ! Nettoie l'Inbox Obsidian, archive les projets terminés."
    '';
  };
  systemd.timers.weekly-review = {
    wantedBy = [ "timers.target" ];
    timerConfig = { OnCalendar = "Fri *-*-* 17:00:00"; Persistent = true; };
  };

  # ══════════════════════════════════════════════════════════════════
  # 9. BACKUP REMINDER — Mensuel
  # ══════════════════════════════════════════════════════════════════
  systemd.services.backup-reminder = {
    description = "Rappel vérification backups";
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.libnotify}/bin/notify-send -u normal "💾 Backup Check" "Vérifier les backups : btrbk list, restic snapshots"
    '';
  };
  systemd.timers.backup-reminder = {
    wantedBy = [ "timers.target" ];
    timerConfig = { OnCalendar = "monthly"; Persistent = true; };
  };

  # ══════════════════════════════════════════════════════════════════
  # 10. SSH KEY EXPIRY CHECK — Mensuel
  # ══════════════════════════════════════════════════════════════════
  systemd.services.ssh-key-check = {
    description = "Vérifier l'âge des clés SSH";
    serviceConfig.Type = "oneshot";
    script = ''
      for key in /home/kuro/.ssh/id_*; do
        [ -f "$key" ] || continue
        [[ "$key" == *.pub ]] && continue
        AGE_DAYS=$(( ($(date +%s) - $(stat -c %Y "$key")) / 86400 ))
        if [ "$AGE_DAYS" -gt 365 ]; then
          ${pkgs.libnotify}/bin/notify-send -u critical "🔑 Clé SSH ancienne" "$key a $AGE_DAYS jours. Penser à la renouveler."
        fi
      done
    '';
  };
  systemd.timers.ssh-key-check = {
    wantedBy = [ "timers.target" ];
    timerConfig = { OnCalendar = "monthly"; Persistent = true; };
  };

  # ══════════════════════════════════════════════════════════════════
  # 11. NIX STORE SIZE MONITOR — Quotidien
  # ══════════════════════════════════════════════════════════════════
  systemd.services.nix-store-monitor = {
    description = "Surveiller la taille du nix store";
    serviceConfig.Type = "oneshot";
    script = ''
      SIZE=$(${pkgs.coreutils}/bin/du -sh /nix/store 2>/dev/null | cut -f1)
      SIZE_GB=$(${pkgs.coreutils}/bin/du -sb /nix/store 2>/dev/null | awk '{printf "%.0f", $1/1073741824}')
      if [ "$SIZE_GB" -gt 50 ]; then
        ${pkgs.libnotify}/bin/notify-send -u normal "📦 Nix Store" "Le store fait $SIZE. Lancer ngc (nh clean all) pour nettoyer."
      fi
    '';
  };
  systemd.timers.nix-store-monitor = {
    wantedBy = [ "timers.target" ];
    timerConfig = { OnCalendar = "daily"; Persistent = true; };
  };

  # ══════════════════════════════════════════════════════════════════
  # 12. DOCKER IMAGE UPDATE CHECKER — Quotidien
  # ══════════════════════════════════════════════════════════════════
  systemd.services.docker-update-check = {
    description = "Vérifier les mises à jour d'images Docker";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    serviceConfig.Type = "oneshot";
    script = ''
      UPDATES=0
      for img in $(${pkgs.docker}/bin/docker images --format '{{.Repository}}:{{.Tag}}' | grep -v '<none>'); do
        ${pkgs.docker}/bin/docker pull "$img" 2>/dev/null | grep -q "Downloaded newer" && UPDATES=$((UPDATES+1))
      done
      if [ "$UPDATES" -gt 0 ]; then
        ${pkgs.libnotify}/bin/notify-send -u normal "🐳 Docker Updates" "$UPDATES images ont des mises à jour. Redéployer les containers."
      fi
    '';
  };
  systemd.timers.docker-update-check = {
    wantedBy = [ "timers.target" ];
    timerConfig = { OnCalendar = "daily"; Persistent = true; };
  };

  # ══════════════════════════════════════════════════════════════════
  # 13. BTRFS USAGE REPORT — Hebdomadaire
  # ══════════════════════════════════════════════════════════════════
  systemd.services.btrfs-report = {
    description = "Rapport utilisation BTRFS";
    serviceConfig.Type = "oneshot";
    script = ''
      echo "=== BTRFS Report $(date) ===" >> /var/log/btrfs-report.log
      ${pkgs.btrfs-progs}/bin/btrfs filesystem usage / >> /var/log/btrfs-report.log 2>&1
      ${pkgs.compsize}/bin/compsize / >> /var/log/btrfs-report.log 2>&1 || true
      echo "---" >> /var/log/btrfs-report.log
    '';
  };
  systemd.timers.btrfs-report = {
    wantedBy = [ "timers.target" ];
    timerConfig = { OnCalendar = "weekly"; Persistent = true; };
  };

  # ══════════════════════════════════════════════════════════════════
  # 14. UPTIME REPORT — Quotidien
  # ══════════════════════════════════════════════════════════════════
  systemd.services.uptime-report = {
    description = "Log quotidien uptime et stats système";
    serviceConfig.Type = "oneshot";
    script = ''
      echo "$(date) | uptime: $(uptime -p) | boot: $(${pkgs.systemd}/bin/systemd-analyze | head -1) | generations: $(ls /nix/var/nix/profiles/system-*-link 2>/dev/null | wc -l)" >> /var/log/uptime-report.log
    '';
  };
  systemd.timers.uptime-report = {
    wantedBy = [ "timers.target" ];
    timerConfig = { OnCalendar = "daily"; Persistent = true; };
  };

  # ══════════════════════════════════════════════════════════════════
  # 15. BATTERY LOW — Notification + action à 20% et 10%
  # ══════════════════════════════════════════════════════════════════
  systemd.services.battery-monitor = {
    description = "Surveiller le niveau de batterie";
    serviceConfig.Type = "oneshot";
    script = ''
      BAT="/sys/class/power_supply/BAT0"
      [ -f "$BAT/capacity" ] || exit 0
      LEVEL=$(cat "$BAT/capacity")
      STATUS=$(cat "$BAT/status")
      if [ "$STATUS" = "Discharging" ]; then
        if [ "$LEVEL" -le 10 ]; then
          ${pkgs.libnotify}/bin/notify-send -u critical "🔋 Batterie critique" "$LEVEL% — Brancher immédiatement !"
          ${pkgs.brightnessctl}/bin/brightnessctl -s set 30% 2>/dev/null || true
        elif [ "$LEVEL" -le 20 ]; then
          ${pkgs.libnotify}/bin/notify-send -u normal "🔋 Batterie faible" "$LEVEL% — Penser à brancher."
        fi
      fi
    '';
  };
  systemd.timers.battery-monitor = {
    wantedBy = [ "timers.target" ];
    timerConfig = { OnActiveSec = "2min"; OnUnitActiveSec = "2min"; };
  };

  # ══════════════════════════════════════════════════════════════════
  # 16. PASSWORD AUDIT REMINDER — Mensuel
  # ══════════════════════════════════════════════════════════════════
  systemd.services.password-audit = {
    description = "Rappel audit mots de passe";
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.libnotify}/bin/notify-send -u normal "🔐 Password Audit" "Vérifier les mots de passe compromis dans Bitwarden (Data Breach Report)."
    '';
  };
  systemd.timers.password-audit = {
    wantedBy = [ "timers.target" ];
    timerConfig = { OnCalendar = "*-*-01 10:00:00"; Persistent = true; };
  };
}
