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
  # 3. LOG ROTATION — Limiter la taille des logs
  # ══════════════════════════════════════════════════════════════════
  services.journald.extraConfig = ''
    SystemMaxUse=500M
    SystemMaxFileSize=50M
    MaxRetentionSec=1month
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
  # 6. SSH LOGIN NOTIFICATION — Alerte à chaque connexion SSH
  # ══════════════════════════════════════════════════════════════════
  # Envoie une notification quand quelqu'un se connecte en SSH
  programs.ssh.extraConfig = ''
    # Log des connexions SSH
  '';

  # Notification via PAM à chaque login SSH
  security.pam.services.sshd.text = lib.mkDefault ''
    session optional ${pkgs.libnotify}/lib/security/pam_exec.so /run/current-system/sw/bin/notify-send "Connexion SSH" "Nouvelle connexion SSH détectée"
  '';

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
}
