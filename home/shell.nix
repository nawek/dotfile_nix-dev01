# ╔══════════════════════════════════════════════════════════════════╗
# ║  Shell — ZSH, Starship, Atuin, Direnv, FZF, Zoxide            ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Configuration complète du shell avec :
# - ZSH comme shell principal (autosuggestion, syntax highlighting)
# - Starship comme prompt
# - Atuin pour l'historique intelligent
# - Direnv + nix-direnv pour les devShells automatiques
# - FZF pour la recherche fuzzy
# - Zoxide pour la navigation intelligente (remplace cd)
# - Bat et Eza comme remplacements de cat et ls

{ config, pkgs, ... }: {

  # ── ZSH ──────────────────────────────────────────────────────────
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;       # Suggestions basées sur l'historique
    syntaxHighlighting.enable = true;   # Coloration syntaxique des commandes
    enableCompletion = true;            # Auto-complétion avancée

    history = {
      size = 50000;
      save = 50000;
      ignoreDups = true;      # Ignorer les doublons consécutifs
      ignoreAllDups = true;   # Ignorer tous les doublons
      share = true;           # Partager l'historique entre les sessions
    };

    # Aliases — organisés par catégorie
    shellAliases = {
      # ── NixOS via nh ────────────────────────────────────────────
      nrs = "nh os switch";     # Rebuild et switch (nh affiche le diff automatiquement)
      nrt = "nh os test";       # Rebuild et test (sans switch)
      nrb = "nh os boot";       # Rebuild pour le prochain boot
      ngc = "nh clean all";     # Nettoyage complet (GC)
      nfu = "nix flake update"; # Mettre à jour les inputs du flake
      nsg = "nix search nixpkgs"; # Rechercher un paquet
      nsh = "nix-shell -p";    # Shell temporaire avec un paquet
      # Build avec nix-output-monitor (sortie colorée en arbre)
      nb  = "nix build --log-format internal-json |& nom";
      nfu-nom = "nix flake update |& nom"; # Update avec sortie colorée

      # ── Git ─────────────────────────────────────────────────────
      gs  = "git status";
      gp  = "git push";
      gpl = "git pull";
      gc  = "git commit";
      gca = "git commit --amend";
      gd  = "git diff";
      gds = "git diff --staged";
      gl  = "git log --oneline --graph --decorate -20";
      glog = "git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --all";
      gst = "git stash";
      gstp = "git stash pop";
      grb = "git rebase";
      gcp = "git cherry-pick";
      # Worktrees — travailler sur plusieurs branches en parallèle
      gwt  = "git worktree add";      # gwt ../feature-branch feature-branch
      gwtl = "git worktree list";     # Lister les worktrees
      gwtr = "git worktree remove";   # Supprimer un worktree
      # Diff entre générations NixOS (voir ce qui a changé)
      ndiff = "nix store diff-closures /nix/var/nix/profiles/system-\$(( \$(readlink /nix/var/nix/profiles/system | grep -o '[0-9]*')-1 ))-link /nix/var/nix/profiles/system";
      lg  = "lazygit";

      # ── Docker ──────────────────────────────────────────────────
      dc  = "docker compose";
      dcu = "docker compose up -d";
      dcd = "docker compose down";
      dcl = "docker compose logs -f";
      dps = "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'";
      ld  = "lazydocker";

      # ── Réseau / Tailscale ──────────────────────────────────────
      ts   = "tailscale status";           # État du VPN mesh
      tsup = "sudo tailscale up";          # Connecter Tailscale
      tsdn = "sudo tailscale down";        # Déconnecter Tailscale
      tsip = "tailscale ip -4";            # IP Tailscale
      hotspot-on  = "nmcli dev wifi hotspot ifname wlan0 ssid KuroHotspot password KuroWifi"; # ← ADAPTER
      hotspot-off = "nmcli con down Hotspot";

      # ── Monitoring système ──────────────────────────────────────
      jdash   = "journalctl --priority=err --since yesterday --no-pager | head -50";
      jboot   = "journalctl -b --priority=warning --no-pager | head -30";
      jfollow = "journalctl -f --priority=info";
      temps   = "sensors 2>/dev/null || echo 'lm_sensors non configuré'";

      # ── Homelab ────────────────────────────────────────────────
      wol-nas     = "wakeonlan AA:BB:CC:DD:EE:FF"; # ← ADAPTER : MAC address du NAS
      wol-proxmox = "wakeonlan AA:BB:CC:DD:EE:FF"; # ← ADAPTER : MAC address Proxmox
      tunnel-grafana  = "ssh -fNL 3000:localhost:3000 docker01"; # ← ADAPTER
      tunnel-portainer = "ssh -fNL 9443:localhost:9443 docker01"; # ← ADAPTER
      dlogs = "ssh docker01 docker logs -f"; # Usage: dlogs <container>

      # ── Outils ──────────────────────────────────────────────────
      trad = "trans -brief :fr";      # Traduction vers français (translate-shell)
      trad-en = "trans -brief :en";   # Traduction vers anglais
      qr = "qrencode -t UTF8";        # Générer un QR code dans le terminal
      ocr = "tesseract stdin stdout";  # OCR (pipe une image)
      boot-time = "systemd-analyze && systemd-analyze blame | head -10";
      # Impermanence debug — lister les fichiers non-persistés dans /
      impermanence-diff = "sudo find / -xdev -not -path '/nix/*' -not -path '/persist/*' -not -path '/proc/*' -not -path '/sys/*' -not -path '/dev/*' -not -path '/run/*' -not -path '/tmp/*' -not -path '/boot/*' -newer /etc/machine-id -type f 2>/dev/null | head -50";
      rss = "newsboat";               # Lecteur RSS

      # ── Safety net ─────────────────────────────────────────────
      rm  = "rm -i";                  # Confirmation avant suppression
      mv  = "mv -i";                  # Confirmation avant écrasement
      cp  = "cp -i";                  # Confirmation avant écrasement

      # ── Utilitaires ─────────────────────────────────────────────
      mkcd = "f() { mkdir -p \"$1\" && cd \"$1\"; }; f"; # mkdir + cd
      extract = "f() { case \"$1\" in *.tar.gz|*.tgz) tar xzf \"$1\";; *.tar.bz2|*.tbz2) tar xjf \"$1\";; *.tar.xz|*.txz) tar xJf \"$1\";; *.zip) unzip \"$1\";; *.7z) 7z x \"$1\";; *.rar) unrar x \"$1\";; *.gz) gunzip \"$1\";; *.xz) unxz \"$1\";; *) echo \"Format inconnu: $1\";; esac; }; f";
      login-history = "last -20 && echo '--- Échecs ---' && sudo lastb -10 2>/dev/null";

      # ── Remplacements modernes ──────────────────────────────────
      ll  = "eza -la --icons --git";  # ls amélioré
      lt  = "eza --tree --level=2 --icons"; # Arborescence
      cat = "bat";                    # cat avec coloration syntaxique
      cd  = "z";                      # cd intelligent (zoxide)
    };

    # Configuration supplémentaire ZSH
    initContent = ''
      # Charger les complétions personnalisées si elles existent
      if [ -d "$HOME/.zsh/completions" ]; then
        fpath=("$HOME/.zsh/completions" $fpath)
      fi

      # Raccourcis clavier
      bindkey '^[[A' history-search-backward  # Flèche haut : recherche historique
      bindkey '^[[B' history-search-forward   # Flèche bas : recherche historique

      # PATH — scripts personnels
      export PATH="$HOME/.local/bin:$PATH"

      # Fortune — citation aléatoire au login (fun)
      if command -v fortune &>/dev/null && command -v cowsay &>/dev/null; then
        fortune -s | cowsay -f tux 2>/dev/null
      fi
    '';
  };

  # ── Starship — Prompt élégant et rapide ──────────────────────────
  # Les couleurs sont gérées par Stylix, on configure seulement le format
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = true;

      # Format du prompt
      format = ''
        $username$hostname$directory$git_branch$git_status$nix_shell$docker_context$rust$python$nodejs$battery$cmd_duration
        $character
      '';

      # Symboles personnalisés par langage/outil
      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
      };

      directory = {
        truncation_length = 3;
        truncation_symbol = ".../";
      };

      git_branch = {
        symbol = " ";
        format = "[$symbol$branch]($style) ";
      };

      git_status = {
        format = "[$all_status$ahead_behind]($style) ";
      };

      nix_shell = {
        symbol = " ";
        format = "[$symbol$state]($style) ";
      };

      docker_context = {
        symbol = " ";
        format = "[$symbol$context]($style) ";
      };

      rust = {
        symbol = " ";
        format = "[$symbol($version)]($style) ";
      };

      python = {
        symbol = " ";
        format = "[$symbol($version)]($style) ";
      };

      nodejs = {
        symbol = " ";
        format = "[$symbol($version)]($style) ";
      };

      battery = {
        full_symbol = "🔋";
        charging_symbol = "⚡";
        discharging_symbol = "💀";
        display = [
          { threshold = 20; style = "bold red"; }
        ];
      };

      cmd_duration = {
        min_time = 2000; # Afficher uniquement si > 2s
        format = "[⏱ $duration]($style) ";
      };
    };
  };

  # ── Atuin — Historique de commandes intelligent ──────────────────
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      # Style d'affichage compact
      style = "compact";

      # Recherche fuzzy par défaut
      search_mode = "fuzzy";

      # Filtrer les commandes sensibles de l'historique
      history_filter = [
        "^sops"
        "^export.*TOKEN"
        "^export.*SECRET"
        "^export.*PASSWORD"
        "^export.*KEY"
      ];

      # Synchronisation désactivée pour l'instant
      # Optionnel : activer et configurer le serveur Atuin (CITADEL) plus tard
      sync.records = false;
      # sync_address = "https://atuin.votre-serveur.com";

      # Statistiques pour les commandes fréquentes
      stats.common_subcommands = [
        "docker"
        "git"
        "nix"
        "nh"
        "systemctl"
        "journalctl"
      ];
    };
  };

  # ── Direnv + nix-direnv — Chargement auto des devShells ─────────
  # Avec nix-direnv, les environnements sont mis en cache et chargés
  # instantanément quand on entre dans un dossier avec un .envrc
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true; # Cache intelligent pour les devShells Nix

    # Auto-autoriser les .envrc dans les dossiers de confiance
    # Plus besoin de taper "direnv allow" à chaque nouveau projet
    config.whitelist = {
      prefix = [
        "/home/kuro/Projects"   # ← ADAPTER : vos dossiers de projets
        "/home/kuro/nixos-config"
      ];
    };
  };

  # ── FZF — Recherche fuzzy dans le terminal ──────────────────────
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    # Les couleurs sont gérées par Stylix
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
    ];
  };

  # ── Zoxide — Navigation intelligente (remplace cd) ──────────────
  # Apprend les dossiers fréquemment visités
  # Usage : z <partie-du-nom> → saute au dossier le plus probable
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # ── Navi — Cheatsheet interactive dans le terminal ────────────────
  # Ctrl+G → recherche fuzzy dans vos snippets de commandes
  # Pré-configure des cheats pour NixOS, Docker, Git, systemd
  programs.navi = {
    enable = true;
    enableZshIntegration = true;
  };

  # ── Bat — cat avec coloration syntaxique ─────────────────────────
  # Le thème est géré par Stylix (via BAT_THEME)
  programs.bat = {
    enable = true;
    config = {
      style = "numbers,changes,header";
    };
  };

  # ── Eza — ls moderne avec icônes et couleurs ────────────────────
  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    icons = "auto";
    git = true; # Afficher le statut Git des fichiers
  };
}
