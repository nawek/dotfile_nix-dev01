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
    ./yazi.nix        # Yazi file manager TUI
    ./helix.nix       # Helix éditeur modal (alternative à Neovim)
    ./neovim.nix      # Neovim avec LSP, Treesitter, Telescope
    ./tmux.nix        # Tmux multiplexeur terminal + Catppuccin
    ./terminals.nix   # Wezterm, Ghostty, Zellij (alternatives)
    ./spotify.nix     # Spotify thémé via Spicetify (Catppuccin + extensions)
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
    # ── Navigateur — Chromium dégoogleisé ─────────────────────────
    ungoogled-chromium  # Chromium sans télémétrie Google, Wayland natif

    # ── Communication ─────────────────────────────────────────────
    vesktop             # Discord client Wayland-natif (Vencord intégré)

    # ── Email ─────────────────────────────────────────────────────
    thunderbird         # Client email complet (IMAP, calendrier, contacts)

    # ── Notes / Second brain ──────────────────────────────────────
    obsidian            # Notes Markdown interconnectées

    # ── Bureautique ───────────────────────────────────────────────
    libreoffice-fresh   # Suite office (docs, tableurs, présentations)

    # ── Multimédia ────────────────────────────────────────────────
    bitwarden-desktop   # Gestionnaire de mots de passe (client Vaultwarden)

    # ── Utilitaires ───────────────────────────────────────────────
    p7zip               # Compression/décompression 7z
    file                # Identification de type de fichier
    neofetch            # Infos système stylisées
    ventoy-full         # USB multi-boot (NixOS, Proxmox, etc.)
    solaar              # Gestion périphériques Logitech (clavier, souris)

    # ── Monitoring GPU ────────────────────────────────────────────
    nvtopPackages.nvidia # Monitoring NVIDIA (htop pour GPU)

    # ── Git ───────────────────────────────────────────────────────
    lazygit             # Interface TUI pour Git

    # ── Thème icônes ──────────────────────────────────────────────
    papirus-icon-theme                      # Icônes Papirus-Dark
    # GTK/QT themes sont gérés par Stylix — pas de paquets manuels
  ];

  # ── Persistance utilisateur ──────────────────────────────────────
  # Données qui survivent à l'effacement de /home entre les boots
  # (bind-mount depuis /persist/home/kuro vers /home/kuro)
  home.persistence."/persist/home/kuro" = { # ← ADAPTER : nom d'utilisateur
    allowOther = true; # Nécessaire pour les bind mounts (fuse.userAllowOther)

    directories = [
      # Navigateur — profils, marque-pages, extensions, cookies
      ".config/chromium"

      # Thunderbird — profils email, comptes, calendriers
      ".thunderbird"

      # Bitwarden — cache et session
      ".config/Bitwarden"

      # Spotify — cache, login, préférences
      ".config/spotify"
      ".cache/spotify"

      # Syncthing — clés, config, index
      ".config/syncthing"
      ".local/state/syncthing"

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

      # Obsidian — vault et configuration
      ".config/obsidian"

      # Espanso — snippets text expander
      ".config/espanso"

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

  # ── Syncthing — Synchronisation P2P entre devices ─────────────────
  # Sync automatique de dossiers entre laptop ↔ homelab ↔ phone.
  # Pas de cloud, pas de serveur central, chiffré de bout en bout.
  #
  # Interface web : http://localhost:8384
  # Ajouter des devices : scanner le QR code ou copier l'ID
  #
  # Dossiers synchronisés par défaut (← ADAPTER) :
  #   ~/Documents  → entre tous les devices
  #   ~/Pictures   → entre tous les devices
  #   ~/Projects   → entre laptop et homelab uniquement
  services.syncthing = {
    enable = true;
    # Pas besoin de tray — l'interface web suffit
    # L'état est persisté via .config/syncthing ci-dessous
  };

  # ── MPV — Lecteur vidéo/audio minimaliste ──────────────────────────
  # Supporte tout, hardware decode NVIDIA, keybinds vim-like
  programs.mpv = {
    enable = true;
    config = {
      hwdec = "auto-safe";       # Décodage matériel GPU
      vo = "gpu-next";           # Rendu GPU moderne
      profile = "gpu-hq";        # Qualité maximale
      sub-auto = "fuzzy";        # Auto-détection des sous-titres
      save-position-on-quit = true; # Reprendre la lecture
      osd-font = "Inter";
      osd-font-size = 24;
    };
  };

  # ── Zathura — Lecteur PDF minimaliste (keybinds vim) ─────────────
  # Le thème est géré automatiquement par Stylix
  programs.zathura = {
    enable = true;
    options = {
      selection-clipboard = "clipboard"; # Copier dans le clipboard système
      adjust-open = "best-fit";
      recolor = true;                    # Mode sombre automatique
    };
  };

  # ── Espanso — Text expander ────────────────────────────────────────
  # Remplace des abréviations par du texte complet en tapant.
  # Config dans ~/.config/espanso/match/base.yml
  services.espanso = {
    enable = true;
    configs.default = {
      toggle_key = "ALT";
      search_shortcut = "ALT+SHIFT+SPACE";
    };
    matches.base = {
      matches = [
        # Date du jour
        { trigger = ":date"; replace = "{{date}}"; vars = [{ name = "date"; type = "date"; params.format = "%d/%m/%Y"; }]; }
        { trigger = ":now"; replace = "{{time}}"; vars = [{ name = "time"; type = "date"; params.format = "%d/%m/%Y %H:%M"; }]; }
        # Email — ← ADAPTER
        { trigger = ":mail"; replace = "votre@email.com"; }
        # Signatures
        { trigger = ":sig"; replace = "Cordialement,\nKuro"; }
        # Code snippets
        { trigger = ":shebang"; replace = "#!/usr/bin/env bash\nset -euo pipefail\n"; }
        # ← ADAPTER : ajouter vos propres snippets
      ];
    };
  };

  # ── GTK/QT — Thèmes gérés par Stylix ──────────────────────────────
  # Stylix applique automatiquement Catppuccin Mocha à GTK et QT.
  # Les icônes Papirus sont le seul ajout manuel nécessaire.
  gtk = {
    enable = true;
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    # Le thème GTK est injecté par Stylix — ne PAS le définir ici
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
