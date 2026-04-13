# ╔══════════════════════════════════════════════════════════════════╗
# ║  Configuration système principale — kuro                       ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Ce fichier est le point d'entrée de la configuration NixOS.
# Il importe tous les modules et définit les options système de base.
#
# Rebuild : sudo nixos-rebuild switch --flake .#kuro
# Ou via nh : nh os switch

{ config, pkgs, inputs, lib, ... }: {

  # ── Imports ──────────────────────────────────────────────────────
  imports = [
    ./hardware-configuration.nix  # Généré par nixos-generate-config
    ../../modules/disko.nix       # Partitionnement BTRFS
    ../../modules/impermanence.nix # Effacement root + persistance
    ../../modules/lanzaboote.nix  # Secure Boot
    ../../modules/nvidia.nix      # GPU NVIDIA
    ../../modules/hyprland.nix    # Desktop Hyprland + SDDM
    ../../modules/stylix.nix      # Thème Catppuccin Mocha
    ../../modules/plymouth.nix    # Boot splash screen
    ../../modules/security.nix    # Firewall, fail2ban, ClamAV, DNS-over-TLS, audit
    ../../modules/networking.nix  # Tailscale, Mosh, dnsmasq
    ../../modules/monitoring.nix  # S.M.A.R.T., thermald, earlyoom
    ../../modules/ux.nix          # UX confort (USB, CUPS, Flatpak, Wine, fwupd)
    ../../modules/automations.nix # Timers systemd (GC, Docker, BTRFS, alertes)
    ../../modules/sops.nix        # Secrets chiffrés
  ];

  # ── Nix — Configuration du gestionnaire de paquets ───────────────
  nix = {
    settings = {
      # Activer les flakes et la nouvelle CLI nix
      experimental-features = [ "nix-command" "flakes" ];

      # Optimiser le store automatiquement (déduplique les fichiers)
      auto-optimise-store = true;

      # Garder les outputs et dérivations pour accélérer les rebuilds dev
      keep-outputs = true;
      keep-derivations = true;

      # Caches binaires — évite de recompiler les paquets
      substituters = [
        "https://cache.nixos.org"
        "https://hyprland.cachix.org"
        "https://nix-community.cachix.org"
        # Optionnel : décommenter et remplacer par votre cache Cachix privé
        # "https://kuro.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "hyprland.cachix.org-1:a7pgxzMz7+ voices5vTLqoz66srig2mvDGJR3bR454="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        # ← ADAPTER : ajouter la clé publique de votre cache Cachix
        # "kuro.cachix.org-1:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX="
      ];

      # Utilisateurs autorisés à configurer les caches et pousser vers Cachix
      trusted-users = [ "root" "kuro" ]; # ← ADAPTER : nom d'utilisateur
    };

    # Nettoyage automatique du store Nix — supprime les anciennes générations
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  # Autoriser les paquets non-libres (NVIDIA, VSCode, etc.)
  nixpkgs.config.allowUnfree = true;

  # ── Auto-upgrade — Mise à jour automatique hebdomadaire ──────────
  # Met à jour les inputs du flake et rebuild le système chaque semaine.
  # La mise à jour se fait en arrière-plan et prend effet au prochain boot.
  # Désactiver si vous préférez contrôler manuellement les mises à jour.
  system.autoUpgrade = {
    enable = true;
    flake = "github:nawek/dotfile_nix-dev01"; # ← ADAPTER : URL de votre dépôt
    flags = [ "--update-input" "nixpkgs" ];   # Met à jour nixpkgs automatiquement
    dates = "Sun *-*-* 04:00:00";             # Chaque dimanche à 4h du matin
    operation = "boot";                        # Appliqué au prochain boot (pas de switch brutal)
    allowReboot = false;                       # Ne PAS redémarrer automatiquement
    # Optionnel : passer à true si vous voulez un reboot automatique la nuit
  };

  # ── Système ──────────────────────────────────────────────────────

  # Hostname
  networking.hostName = "kuro"; # ← ADAPTER

  # Fuseau horaire
  time.timeZone = "Europe/Paris"; # ← ADAPTER

  # Langue et locale
  i18n = {
    defaultLocale = "fr_FR.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "fr_FR.UTF-8";
      LC_IDENTIFICATION = "fr_FR.UTF-8";
      LC_MEASUREMENT = "fr_FR.UTF-8";
      LC_MONETARY = "fr_FR.UTF-8";
      LC_NAME = "fr_FR.UTF-8";
      LC_NUMERIC = "fr_FR.UTF-8";
      LC_PAPER = "fr_FR.UTF-8";
      LC_TELEPHONE = "fr_FR.UTF-8";
      LC_TIME = "fr_FR.UTF-8";
    };
  };

  # Clavier français (console TTY)
  console.keyMap = "fr";

  # Version NixOS — NE PAS MODIFIER après l'installation initiale
  system.stateVersion = "25.05";

  # ── Utilisateur ──────────────────────────────────────────────────
  users.users.kuro = { # ← ADAPTER : nom d'utilisateur
    isNormalUser = true;
    description = "Kuro"; # ← ADAPTER
    extraGroups = [
      "wheel"          # Accès sudo
      "docker"         # Docker sans sudo
      "video"          # Contrôle luminosité
      "networkmanager" # Gestion réseau
    ];
    shell = pkgs.zsh;
    # Mot de passe géré par sops-nix (hash SHA-512)
    hashedPasswordFile = config.sops.secrets."user-password".path;
  };

  # ZSH doit être activé au niveau système pour être un shell de login valide
  programs.zsh.enable = true;

  # ── Firejail — Sandbox pour les applications sensibles ──────────
  # Usage : firejail chromium, firejail vesktop
  # Limite l'accès au filesystem et au réseau des applications
  programs.firejail.enable = true;

  # ── Réseau ───────────────────────────────────────────────────────
  networking.networkmanager.enable = true;

  # ── Audio — PipeWire ─────────────────────────────────────────────
  # Remplace PulseAudio avec une meilleure latence et compatibilité
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true; # Support 32 bits (Wine, Steam)
    pulse.enable = true;      # Compatibilité PulseAudio
    # jack.enable = true;     # Optionnel : décommenter pour la production audio
  };

  # ── SSH ──────────────────────────────────────────────────────────
  services.openssh = {
    enable = true;
    # Les clés hôtes sont persistées via impermanence.nix
    # (/etc/ssh/ssh_host_*_key)
    settings = {
      PasswordAuthentication = false; # Clés SSH uniquement
      PermitRootLogin = "no";
    };
  };

  # ── Docker ───────────────────────────────────────────────────────
  virtualisation.docker = {
    enable = true;
    # Nettoyage automatique des images/conteneurs inutilisés
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
    # Optionnel : décommenter pour changer l'emplacement des données Docker
    # daemon.settings = {
    #   data-root = "/persist/var/lib/docker";
    # };
  };

  # ── btrbk — Snapshots BTRFS ─────────────────────────────────────
  # Sauvegarde automatique des subvolumes /persist et /home
  services.btrbk.instances."default" = {
    onCalendar = "hourly";
    settings = {
      snapshot_preserve_min = "2h";
      snapshot_preserve = "24h 7d 4w";

      volume."/persist" = {
        snapshot_dir = "/.snapshots/persist";
        subvolume = ".";
      };

      volume."/home" = {
        snapshot_dir = "/.snapshots/home";
        subvolume = ".";
      };
    };
  };

  # ── auto-cpufreq — Gestion énergie laptop ───────────────────────
  services.auto-cpufreq = {
    enable = true;
    settings = {
      battery = {
        governor = "powersave";
        turbo = "never";
      };
      charger = {
        governor = "performance";
        turbo = "auto";
      };
    };
  };

  # ── Bluetooth ────────────────────────────────────────────────────
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true; # Bluetooth activé au démarrage
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket"; # Profils audio Bluetooth
      };
    };
  };
  services.blueman.enable = true; # Interface graphique Bluetooth

  # ── Logind — Comportement du couvercle / bouton power ────────────
  services.logind = {
    lidSwitch = "suspend";              # Fermer le couvercle → suspend (batterie)
    lidSwitchExternalPower = "ignore";  # Fermer le couvercle → rien (secteur)
    extraConfig = ''
      HandlePowerKey=suspend
    '';
  };

  # ── ZRAM — Swap compressé en RAM ──────────────────────────────────
  # Complète le swapfile BTRFS : utilise la RAM inutilisée comme swap
  # compressé (zstd). Plus rapide que le swap disque.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50; # Utilise jusqu'à 50% de la RAM pour le ZRAM
  };

  # ── D-Bus ────────────────────────────────────────────────────────
  services.dbus.enable = true;

  # ── nix-ld — Compatibilité binaires non-NixOS ───────────────────
  # Permet d'exécuter des binaires compilés pour d'autres distros
  # (AppImages, binaires téléchargés, etc.)
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib # libstdc++
      zlib
      openssl
      libGL
      glib
    ];
  };

  # ── nix-index — Remplacement de command-not-found ────────────────
  # Utilise une base pré-construite (via nix-index-database dans le flake)
  # pour suggérer le paquet à installer quand une commande est introuvable
  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.command-not-found.enable = false; # Désactivé au profit de nix-index

  # ── Variable d'environnement pour nh ─────────────────────────────
  # nh utilise $FLAKE pour savoir où trouver la config
  # ← ADAPTER : doit correspondre au chemin réel de ce dépôt sur votre machine
  environment.variables.FLAKE = "/home/kuro/dotfile_nix-dev01";

  # ── Paquets système ──────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # Essentiels
    git
    curl
    wget
    unzip
    htop
    btop
    tree
    ripgrep
    fd
    jq
    neovim

    # Nix tooling
    nil                 # LSP Nix
    nixfmt-rfc-style    # Formateur Nix (style RFC)
    alejandra           # Formateur Nix alternatif (opinionated)
    nh                  # Helper NixOS (rebuild simplifié)
    nix-index           # Base de données des paquets
    comma               # Exécuter des programmes sans les installer (,)
    nix-output-monitor  # Sortie de build colorée et lisible (nom)
    cachix              # Push/pull vers des caches binaires Cachix
    treefmt             # Formatage multi-langages (nix fmt)
    pre-commit          # Hooks de vérification avant commit
    shellcheck          # Linter de scripts shell
    shfmt               # Formateur de scripts shell

    # Docker
    docker-compose
    lazydocker

    # Secrets
    sops
    age

    # BTRFS
    btrfs-progs
    compsize            # Voir le taux de compression BTRFS

    # Compatibilité
    appimage-run        # Exécuter des AppImages
  ];
}
