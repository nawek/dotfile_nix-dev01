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
#
# Interface publique :
#   citadel.monitoring.enable          (default: true)
#   citadel.monitoring.smartd.enable   (default: true)
#   citadel.monitoring.thermald.enable (default: true — désactiver sur AMD)
#   citadel.monitoring.earlyoom.enable (default: true)

{ config, pkgs, lib, ... }:

let
  cfg = config.citadel.monitoring;
  inherit (lib) mkOption mkEnableOption mkIf types;
in
{
  options.citadel.monitoring = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Activer la surveillance proactive du matériel (S.M.A.R.T., températures, earlyoom).";
    };

    smartd.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Activer smartd pour la surveillance S.M.A.R.T. des disques.";
    };

    thermald.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Activer thermald (Intel-only). Désactiver sur processeur AMD.";
    };

    earlyoom.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Activer earlyoom (OOM killer proactif pour éviter les freezes).";
    };

    earlyoom.freeMemThreshold = mkOption {
      type = types.ints.between 1 100;
      default = 5;
      description = "Pourcentage de RAM libre en-dessous duquel earlyoom intervient.";
    };

    earlyoom.freeSwapThreshold = mkOption {
      type = types.ints.between 1 100;
      default = 10;
      description = "Pourcentage de swap libre en-dessous duquel earlyoom intervient.";
    };
  };

  config = mkIf cfg.enable {

    # ════════════════════════════════════════════════════════════════
    # 1. SMARTMONTOOLS — Surveillance santé SSD/HDD
    # ════════════════════════════════════════════════════════════════
    services.smartd = mkIf cfg.smartd.enable {
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

    # ════════════════════════════════════════════════════════════════
    # 2. LM_SENSORS — Monitoring des températures
    # ════════════════════════════════════════════════════════════════
    # Première utilisation : sudo sensors-detect (une seule fois)
    # Puis : sensors (pour voir les températures)
    hardware.sensor.iio.enable = true; # Capteurs matériels

    # ════════════════════════════════════════════════════════════════
    # 3. THERMALD — Gestion thermique Intel
    # ════════════════════════════════════════════════════════════════
    # Gère automatiquement le throttling CPU pour éviter la surchauffe.
    # Désactiver via citadel.monitoring.thermald.enable = false sur AMD.
    services.thermald.enable = cfg.thermald.enable;

    # ════════════════════════════════════════════════════════════════
    # 4. EARLYOOM — OOM killer proactif
    # ════════════════════════════════════════════════════════════════
    # Tue les processus les plus gourmands en mémoire AVANT que le
    # système ne freeze complètement (ce que fait le OOM killer du noyau
    # trop tard, rendant le PC inutilisable).
    services.earlyoom = mkIf cfg.earlyoom.enable {
      enable = true;
      freeMemThreshold = cfg.earlyoom.freeMemThreshold;
      freeSwapThreshold = cfg.earlyoom.freeSwapThreshold;
      enableNotifications = true;

      # Processus à ne JAMAIS tuer (regex)
      extraArgs = [
        "--prefer '(firefox|chromium|electron)'" # Tuer en priorité les navigateurs gourmands
        "--avoid '(sshd|systemd|nixos-rebuild)'"  # Ne jamais tuer les services critiques
      ];
    };

    # ════════════════════════════════════════════════════════════════
    # Paquets monitoring
    # ════════════════════════════════════════════════════════════════
    # Résoudre le conflit earlyoom (true) vs smartd (false)
    services.systembus-notify.enable = lib.mkForce true;

    environment.systemPackages = with pkgs; [
      smartmontools    # CLI S.M.A.R.T.
      lm_sensors       # Lecture des capteurs de température
      lsof             # Fichiers ouverts par processus
      iotop            # I/O par processus (comme htop pour le disque)
      bandwhich        # Bande passante par processus (TUI)
    ];
  };
}
