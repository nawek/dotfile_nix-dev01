# ╔══════════════════════════════════════════════════════════════════╗
# ║  Monitoring — S.M.A.R.T., températures, earlyoom                ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Surveillance proactive du matériel :
# - S.M.A.R.T. : santé du SSD (prédiction de défaillance)
# - lm_sensors : températures CPU/GPU
# - thermald : gestion thermique Intel
# - earlyoom : tuer les processus avant OOM (le système ne freeze plus)
#
# Commandes utiles :
#   sudo smartctl -a /dev/nvme0n1   → état complet du SSD
#   sensors                          → températures actuelles
#   earlyoom --dry-run               → tester sans tuer

{ config, pkgs, lib, ... }: {

  # ══════════════════════════════════════════════════════════════════
  # 1. SMARTMONTOOLS — Surveillance santé SSD/HDD
  # ══════════════════════════════════════════════════════════════════
  services.smartd = {
    enable = true;
    # Vérifier tous les disques, alerter si problème
    defaults.monitored = "-a -o on -S on -s (S/../.././02|L/../../7/03)";
    # -a : tous les attributs
    # -o on : tests offline activés
    # -S on : sauvegarde des attributs
    # -s : test court quotidien à 2h, test long hebdo dimanche à 3h

    notifications = {
      wall.enable = true;   # Alerte sur tous les terminaux
      # Optionnel : configurer les notifications par email si besoin
      # mail.enable = true;
      # mail.recipient = "votre@email.com";
    };
  };

  # ══════════════════════════════════════════════════════════════════
  # 2. LM_SENSORS — Monitoring des températures
  # ══════════════════════════════════════════════════════════════════
  # Première utilisation : sudo sensors-detect (une seule fois)
  # Puis : sensors (pour voir les températures)
  hardware.sensor.iio.enable = true; # Capteurs matériels

  # ══════════════════════════════════════════════════════════════════
  # 3. THERMALD — Gestion thermique Intel
  # ══════════════════════════════════════════════════════════════════
  # Gère automatiquement le throttling CPU pour éviter la surchauffe.
  # ← ADAPTER : désactiver si processeur AMD (utiliser auto-cpufreq seul)
  services.thermald.enable = true;

  # ══════════════════════════════════════════════════════════════════
  # 4. EARLYOOM — OOM killer proactif
  # ══════════════════════════════════════════════════════════════════
  # Tue les processus les plus gourmands en mémoire AVANT que le
  # système ne freeze complètement (ce que fait le OOM killer du noyau
  # trop tard, rendant le PC inutilisable).
  services.earlyoom = {
    enable = true;
    freeMemThreshold = 5;      # Agir quand < 5% RAM libre
    freeSwapThreshold = 10;    # Agir quand < 10% swap libre
    enableNotifications = true; # Notification quand un processus est tué

    # Processus à ne JAMAIS tuer (regex)
    extraArgs = [
      "--prefer '(firefox|chromium|electron)'" # Tuer en priorité les navigateurs gourmands
      "--avoid '(sshd|systemd|nixos-rebuild)'"  # Ne jamais tuer les services critiques
    ];
  };

  # ══════════════════════════════════════════════════════════════════
  # Paquets monitoring
  # ══════════════════════════════════════════════════════════════════
  # Résoudre le conflit earlyoom (true) vs smartd (false)
  services.systembus-notify.enable = lib.mkForce true;

  environment.systemPackages = with pkgs; [
    smartmontools    # CLI S.M.A.R.T.
    lm_sensors       # Lecture des capteurs de température
    lsof             # Fichiers ouverts par processus
    iotop            # I/O par processus (comme htop pour le disque)
    bandwhich        # Bande passante par processus (TUI)
  ];
}
