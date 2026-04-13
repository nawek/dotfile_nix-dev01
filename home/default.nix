# ╔══════════════════════════════════════════════════════════════════╗
# ║  Home Manager — Point d'entrée + persistance utilisateur       ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Ce fichier est le module Home Manager principal.
# Il importe tous les sous-modules et définit la persistance
# des données utilisateur (via impermanence côté Home Manager).
#
# ⚠️ La persistance SYSTÈME est dans modules/impermanence.nix
#    Ce fichier ne gère que la persistance UTILISATEUR.

{ config, pkgs, inputs, lib, ... }: {

  # ── Imports des sous-modules ─────────────────────────────────────
  imports = [
    ./shell.nix       # ZSH, starship, atuin, direnv, fzf, zoxide
    ./git.nix         # Git, delta, gh
    ./hyprland.nix    # Config Hyprland utilisateur (waybar, wofi, dunst, etc.)
    ./vscode.nix      # VSCode + extensions
    ./neovim.nix      # Neovim avec LSP, Treesitter, Telescope
    ./tmux.nix        # Tmux multiplexeur terminal + Catppuccin
    ./dev-tools.nix   # Outils de développement CLI

    # Module impermanence côté Home Manager
    # ⚠️ C'est homeManagerModules.default, PAS nixosModules !
    inputs.impermanence.homeManagerModules.default
  ];

  # ── Identité utilisateur ─────────────────────────────────────────
  home = {
    username = "kuro";            # ← ADAPTER
    homeDirectory = "/home/kuro"; # ← ADAPTER
    stateVersion = "24.11";       # ← ADAPTER : ne pas modifier après installation
  };

  # ── Paquets utilisateur ──────────────────────────────────────────
  home.packages = with pkgs; [
    # Navigateur
    firefox

    # Communication
    vesktop           # Discord client Wayland-natif

    # Utilitaires
    p7zip             # Compression/décompression 7z
    file              # Identification de type de fichier
    neofetch          # Infos système stylisées

    # Monitoring GPU
    nvtopPackages.nvidia # Monitoring NVIDIA (htop pour GPU)

    # Git
    lazygit           # Interface TUI pour Git

    # Thème GTK/QT
    adw-gtk3                                # Thème GTK3 Adwaita dark
    papirus-icon-theme                      # Icônes Papirus
    catppuccin-kvantum                      # Thème QT Kvantum Catppuccin
    libsForQt5.qtstyleplugin-kvantum       # Plugin Kvantum QT5
    qt6Packages.qtstyleplugin-kvantum      # Plugin Kvantum QT6
  ];

  # ── Persistance utilisateur ──────────────────────────────────────
  # Données qui survivent à l'effacement de /home entre les boots
  # (bind-mount depuis /persist/home/kuro vers /home/kuro)
  home.persistence."/persist/home/kuro" = { # ← ADAPTER : nom d'utilisateur
    allowOther = true; # Nécessaire pour les bind mounts (fuse.userAllowOther)

    directories = [
      # Navigateur — profils, marque-pages, extensions, cookies
      ".mozilla/firefox"

      # SSH — clés et known_hosts
      ".ssh"

      # GPG — clés de chiffrement et signature
      ".gnupg"

      # VSCode — extensions installées, état de l'éditeur
      ".config/Code"
      ".vscode"

      # Docker — config client (credentials, etc.)
      ".docker"

      # Atuin — historique de commandes synchronisé
      ".local/share/atuin"

      # Direnv — cache des environnements
      ".local/share/direnv"

      # SOPS — configuration locale
      ".config/sops"

      # Dconf — préférences des applications GTK/GNOME
      ".config/dconf"

      # Neovim — état, undo persistant, shada
      ".local/share/nvim"
      ".local/state/nvim"

      # Tmux — sessions sauvegardées (resurrect/continuum)
      ".local/share/tmux"

      # Mise (ex-rtx) — runtimes installés et cache
      ".local/share/mise"
      ".config/mise"

      # Cliphist — historique du presse-papier (survit au reboot)
      ".cache/cliphist"

      # Rofi — cache des applications récentes
      ".cache/rofi3.druncache"

      # Données utilisateur
      "Documents"
      "Projects"
      "Pictures"
    ];

    files = [
      # Historique ZSH
      ".zsh_history"
    ];
  };

  # ── GTK — Thème Catppuccin explicite ───────────────────────────────
  # Pour les applications qui ne respectent pas Stylix
  gtk = {
    enable = true;
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };

  # ── QT — Cohérence avec le thème GTK ────────────────────────────
  # Force QT à utiliser le même thème sombre que GTK
  qt = {
    enable = true;
    platformTheme.name = "kvantum";
    style = {
      name = "kvantum";
      package = pkgs.catppuccin-kvantum;
    };
  };

  # ── Dconf — Persistance des paramètres GTK/GNOME ──────────────────
  # Les applications GTK stockent leurs préférences via dconf.
  # Sans ceci, les paramètres sont perdus à chaque reboot (impermanence).
  dconf = {
    enable = true;
    settings = {
      # Thème sombre pour toutes les applications GTK
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        gtk-theme = "adw-gtk3-dark";
      };

      # Nautilus — paramètres du gestionnaire de fichiers
      "org/gnome/nautilus/preferences" = {
        default-folder-viewer = "list-view";
        show-hidden-files = true;
      };

      # ← ADAPTER : ajouter les paramètres dconf de vos applications GTK
      # Pour découvrir les clés : dconf watch /
      # Puis modifier le paramètre dans l'application et noter la clé
    };
  };

  # ── Home Manager ─────────────────────────────────────────────────
  # Laisser Home Manager gérer sa propre installation
  programs.home-manager.enable = true;
}
