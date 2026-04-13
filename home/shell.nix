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
      nrs = "nh os switch";     # Rebuild et switch
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
      gl  = "git log --oneline --graph --decorate -20";
      lg  = "lazygit";

      # ── Docker ──────────────────────────────────────────────────
      dc  = "docker compose";
      dcu = "docker compose up -d";
      dcd = "docker compose down";
      dcl = "docker compose logs -f";
      dps = "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'";
      ld  = "lazydocker";

      # ── Remplacements modernes ──────────────────────────────────
      ll  = "eza -la --icons --git";  # ls amélioré
      lt  = "eza --tree --level=2 --icons"; # Arborescence
      cat = "bat";                    # cat avec coloration syntaxique
      cd  = "z";                      # cd intelligent (zoxide)
    };

    # Configuration supplémentaire ZSH
    initExtra = ''
      # Charger les complétions personnalisées si elles existent
      if [ -d "$HOME/.zsh/completions" ]; then
        fpath=("$HOME/.zsh/completions" $fpath)
      fi

      # Raccourcis clavier
      bindkey '^[[A' history-search-backward  # Flèche haut : recherche historique
      bindkey '^[[B' history-search-forward   # Flèche bas : recherche historique
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
      # ← ADAPTER : activer et configurer le serveur Atuin (CITADEL) plus tard
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
