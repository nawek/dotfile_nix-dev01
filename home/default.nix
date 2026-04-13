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
    # ./terminals.nix # Décommenté : Wezterm, Zellij (alternatives à Kitty+Tmux)
    ./spotify.nix     # Spotify thémé via Spicetify (Catppuccin + extensions)
    ./dev-tools.nix   # Outils de développement CLI

    # Note : le module impermanence Home Manager est importé automatiquement
    # par le module NixOS impermanence — pas besoin d'import manuel.
  ];

  # ── Identité utilisateur ─────────────────────────────────────────
  home = {
    username = "kuro";            # ← ADAPTER
    homeDirectory = "/home/kuro"; # ← ADAPTER
    stateVersion = "25.05";
  };

  # ── Paquets utilisateur ──────────────────────────────────────────
  home.packages = with pkgs; [
    # Navigateur : géré via programs.chromium ci-dessous

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
    imv                 # Viewer d'images minimaliste (Wayland-natif)
    p7zip               # Compression/décompression 7z
    file                # Identification de type de fichier
    neofetch            # Infos système stylisées
    # ventoy-full       # USB multi-boot — décommenter si nécessaire (marqué insecure)
    # Ajouter permittedInsecurePackages dans configuration.nix si activé
    solaar              # Gestion périphériques Logitech (clavier, souris) # Optionnel : retirer si pas de Logitech

    # ── Remote Desktop — gestion du parc informatique ───────────
    remmina               # RDP, VNC, SSH, SFTP, SPICE (comme RDM)

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
  # Le chemin ne contient PAS le home directory — il est ajouté automatiquement
  # /persist → /persist/home/kuro (ajouté par impermanence)
  home.persistence."/persist" = { # ← ADAPTER : chemin du subvolume persistant

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

      # Remmina — connexions sauvegardées (RDP, VNC, SSH)
      ".local/share/remmina"
      ".config/remmina"

      # Newsboat — articles lus, cache
      ".local/share/newsboat"

      # Données utilisateur
      "Documents"
      "Projects"
      "Pictures"
      "Downloads"
    ];

    files = [
      # Historique ZSH
      ".zsh_history"
    ];
  };

  # ── XDG — Applications par défaut ──────────────────────────────────
  # Associe chaque type de fichier à la bonne application
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/pdf" = "org.pwmt.zathura.desktop";
      "video/*" = "mpv.desktop";
      "audio/*" = "mpv.desktop";
      "image/*" = "imv.desktop";
      "text/html" = "chromium-browser.desktop";
      "x-scheme-handler/http" = "chromium-browser.desktop";
      "x-scheme-handler/https" = "chromium-browser.desktop";
      "x-scheme-handler/mailto" = "thunderbird.desktop";
      "inode/directory" = "org.gnome.Nautilus.desktop";
    };
  };

  # ── Newsboat — Lecteur RSS TUI ───────────────────────────────────
  programs.newsboat = {
    enable = true;
    urls = [
      # Optionnel : ajouter vos flux RSS
      { url = "https://nixos.org/blog/announcements-rss.xml"; title = "NixOS Announcements"; }
      { url = "https://weekly.nixos.org/feeds/all.rss.xml"; title = "NixOS Weekly"; }
      { url = "https://www.reddit.com/r/NixOS/.rss"; title = "r/NixOS"; }
      { url = "https://www.reddit.com/r/hyprland/.rss"; title = "r/Hyprland"; }
      # { url = "https://selfhosted.show/rss"; title = "Self-Hosted Show"; }
    ];
    extraConfig = ''
      color background default default
      color listnormal default default
      color listnormal_unread blue default bold
      color listfocus white blue bold
      color listfocus_unread white blue bold
      color info blue default bold
      color article default default
      browser "xdg-open %u"
      auto-reload yes
      reload-time 30
    '';
  };

  # ── Chromium — Bookmarks Homelab ───────────────────────────────────
  # Pré-configure les favoris pour l'administration du homelab
  # ← ADAPTER : remplacer les URLs par celles de votre infrastructure
  programs.chromium = {
    enable = true;
    package = pkgs.ungoogled-chromium;
    extensions = [
      # Bitwarden — gestionnaire de mots de passe
      { id = "nngceckbapebfimnlniiiahkandclblb"; }
      # uBlock Origin
      { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; }
      # Optionnel : ajouter vos extensions
    ];
  };

  # ── Cheatsheet Hyprland — raccourcis clavier ──────────────────────
  # Accessible via $mod+F1
  xdg.configFile."hypr/cheatsheet.md".source = ./cheatsheet.md;

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
        # Sysadmin snippets
        { trigger = ":ssh-config"; replace = "Host NAME\n  HostName IP\n  User USER\n  IdentityFile ~/.ssh/id_ed25519\n"; }
        { trigger = ":dc"; replace = "services:\n  app:\n    image: IMAGE\n    ports:\n      - \"8080:80\"\n    volumes:\n      - ./data:/data\n    restart: unless-stopped\n"; }
        { trigger = ":nix-shell"; replace = "nix-shell -p PKG --run 'CMD'"; }
        { trigger = ":ip"; replace = "{{output}}"; vars = [{ name = "output"; type = "shell"; params.cmd = "curl -s ifconfig.me"; }]; }
        # Optionnel : ajouter vos propres snippets
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
      # Thème sombre géré par Stylix (polarity = "dark")
      # Ne PAS redéfinir gtk-theme ici — Stylix l'injecte automatiquement
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
      };

      # Nautilus — paramètres du gestionnaire de fichiers
      "org/gnome/nautilus/preferences" = {
        default-folder-viewer = "list-view";
        show-hidden-files = true;
      };

      # Optionnel : ajouter les paramètres dconf de vos applications GTK
      # Pour découvrir les clés : dconf watch /
    };
  };

  # ── Obsidian auto-commit — Sauvegarde automatique du vault ────────
  # Commit et push le vault Obsidian toutes les heures
  # ← ADAPTER : chemin vers votre vault Obsidian
  systemd.user.services.obsidian-sync = {
    Unit.Description = "Auto-commit du vault Obsidian";
    Service = {
      Type = "oneshot";
      ExecStart = toString (pkgs.writeShellScript "obsidian-sync" ''
        VAULT="$HOME/Documents/Obsidian"
        if [ -d "$VAULT/.git" ]; then
          cd "$VAULT"
          ${pkgs.git}/bin/git add -A
          ${pkgs.git}/bin/git diff --cached --quiet || \
            ${pkgs.git}/bin/git commit -m "auto: $(date '+%Y-%m-%d %H:%M')"
          ${pkgs.git}/bin/git push 2>/dev/null || true
        fi
      '');
    };
  };

  systemd.user.timers.obsidian-sync = {
    Unit.Description = "Timer auto-commit Obsidian (1h)";
    Timer = {
      OnActiveSec = "1h";
      OnUnitActiveSec = "1h";
      Unit = "obsidian-sync.service";
    };
    Install.WantedBy = [ "timers.target" ];
  };

  # ── Fortune — Message du jour au login ──────────────────────────
  # Affiche une citation aléatoire à chaque ouverture de terminal
  # (ajouté dans initExtra/initContent de shell.nix)

  # ── Home Manager ─────────────────────────────────────────────────
  programs.home-manager.enable = true;
}
