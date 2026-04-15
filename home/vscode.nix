# ╔══════════════════════════════════════════════════════════════════╗
# ║  VSCode — Éditeur principal pimpé pour sysadmin/dev             ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Configuration complète pour : Python, JS/TS, Rust, Go, Nix, Bash,
# YAML, Docker, Terraform, Markdown. IA intégrée. Remote SSH homelab.
#
# Thème : géré par Stylix (Catppuccin Mocha)
# Police : gérée par Stylix (JetBrainsMono Nerd Font)

{ config, pkgs, lib, ... }: {

  programs.vscode = {
    enable = true;
    package = pkgs.vscode;

    profiles.default = {
      # ════════════════════════════════════════════════════════════
      # EXTENSIONS
      # ════════════════════════════════════════════════════════════
      extensions = with pkgs.vscode-extensions; [

        # ── Nix ──────────────────────────────────────────────────
        jnoortheen.nix-ide

        # ── Python ───────────────────────────────────────────────
        ms-python.python
        ms-python.vscode-pylance
        ms-python.debugpy               # Debugger Python

        # ── JavaScript / TypeScript ──────────────────────────────
        dbaeumer.vscode-eslint
        esbenp.prettier-vscode

        # ── Rust ─────────────────────────────────────────────────
        rust-lang.rust-analyzer

        # ── Go ───────────────────────────────────────────────────
        golang.go

        # ── Docker ───────────────────────────────────────────────
        ms-azuretools.vscode-docker

        # ── YAML ─────────────────────────────────────────────────
        redhat.vscode-yaml

        # ── TOML ─────────────────────────────────────────────────
        tamasfe.even-better-toml

        # ── Shell / Bash ─────────────────────────────────────────
        timonwong.shellcheck
        mads-hartmann.bash-ide-vscode

        # ── Terraform / OpenTofu ─────────────────────────────────
        hashicorp.terraform

        # ── Git ──────────────────────────────────────────────────
        eamodio.gitlens
        mhutchie.git-graph             # Graphe Git visuel

        # ── Markdown ─────────────────────────────────────────────
        yzhang.markdown-all-in-one     # Preview, TOC, shortcuts
        bierner.markdown-mermaid       # Diagrammes Mermaid dans le preview
        davidanson.vscode-markdownlint # Linter Markdown

        # ── Remote SSH ───────────────────────────────────────────
        ms-vscode-remote.remote-ssh

        # ── Qualité de code ──────────────────────────────────────
        usernamehw.errorlens           # Erreurs inline colorées
        gruntfuggly.todo-tree          # TODO/FIXME/HACK/NOTE tree
        christian-kohler.path-intellisense # Auto-complétion des chemins

        # ── UI / Productivité ────────────────────────────────────
        pkief.material-icon-theme      # Icônes de fichiers Material
        naumovs.color-highlight        # Preview des couleurs hex dans le code
        mechatroner.rainbow-csv        # Colonnes CSV colorées

      ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        # ── IA — Claude (Anthropic) ────────────────────────────
        {
          name = "claude-dev";
          publisher = "saoudrizwan";
          version = "3.9.2";
          sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # ← ADAPTER : nix-prefetch-url
        }
        # ── IA — Continue.dev (IA locale/API) ──────────────────
        # {
        #   name = "continue";
        #   publisher = "Continue";
        #   version = "1.0.0";
        #   sha256 = "sha256-AAAA..."; # ← ADAPTER
        # }
      ];

      # ════════════════════════════════════════════════════════════
      # SETTINGS
      # ════════════════════════════════════════════════════════════
      userSettings = {
        # ── Police & Apparence ─────────────────────────────────
        "editor.fontSize" = lib.mkForce 14;
        "editor.fontLigatures" = true;
        "editor.minimap.enabled" = false;
        "editor.cursorBlinking" = "smooth";
        "editor.cursorSmoothCaretAnimation" = "on";
        "editor.smoothScrolling" = true;
        "editor.stickyScroll.enabled" = true;       # Headers sticky en scroll
        "editor.bracketPairColorization.enabled" = true;
        "editor.guides.bracketPairs" = "active";    # Guide visuel des brackets
        "editor.renderWhitespace" = "boundary";     # Espaces visibles aux bords
        "editor.linkedEditing" = true;              # Renommer les tags HTML en paire
        "editor.inlayHints.enabled" = "onUnlessPressed"; # Hints type (Ctrl pour masquer)

        # ── Comportement ───────────────────────────────────────
        "editor.formatOnSave" = true;
        "editor.formatOnPaste" = true;
        "editor.tabSize" = 2;
        "editor.wordWrap" = "on";
        "editor.acceptSuggestionOnCommitCharacter" = false; # Pas de commit accidentel
        "files.autoSave" = "afterDelay";
        "files.autoSaveDelay" = 1000;               # Auto-save après 1s d'inactivité
        "files.trimTrailingWhitespace" = true;
        "files.insertFinalNewline" = true;
        "files.trimFinalNewlines" = true;

        # ── Fenêtre ────────────────────────────────────────────
        "window.titleBarStyle" = "custom";           # Wayland natif
        "window.title" = "\${activeEditorShort} — \${rootName}";
        "window.restoreWindows" = "all";

        # ── Terminal intégré ───────────────────────────────────
        "terminal.integrated.defaultProfile.linux" = "zsh";
        "terminal.integrated.scrollback" = 10000;
        "terminal.integrated.cursorBlinking" = true;

        # ── Explorateur ────────────────────────────────────────
        "explorer.confirmDelete" = false;
        "explorer.confirmDragAndDrop" = false;
        "explorer.fileNesting.enabled" = true;       # Nester les fichiers liés
        "explorer.fileNesting.patterns" = {
          "*.ts" = "\${capture}.js, \${capture}.d.ts, \${capture}.test.ts";
          "*.py" = "\${capture}.pyi, \${capture}_test.py";
          "flake.nix" = "flake.lock";
          "package.json" = "pnpm-lock.yaml, yarn.lock, package-lock.json, .npmrc";
          "Cargo.toml" = "Cargo.lock";
          "docker-compose.yml" = "docker-compose.*.yml, .dockerignore, Dockerfile*";
          ".gitignore" = ".gitattributes, .gitmodules";
        };

        # ── Icônes ─────────────────────────────────────────────
        "workbench.iconTheme" = "material-icon-theme";

        # ── Nix LSP (nil + nixfmt) ─────────────────────────────
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nil";
        "nix.serverSettings" = {
          "nil" = {
            formatting.command = [ "nixfmt" ];
          };
        };

        # ── Python ─────────────────────────────────────────────
        "python.analysis.typeCheckingMode" = "basic";
        "python.analysis.autoImportCompletions" = true;
        "[python]" = {
          "editor.defaultFormatter" = "ms-python.python";
          "editor.tabSize" = 4;
        };

        # ── Rust ───────────────────────────────────────────────
        "rust-analyzer.check.command" = "clippy";    # Clippy au lieu de check
        "rust-analyzer.inlayHints.parameterHints.enabled" = true;

        # ── TypeScript / JavaScript ────────────────────────────
        "[typescript]" = { "editor.defaultFormatter" = "esbenp.prettier-vscode"; };
        "[javascript]" = { "editor.defaultFormatter" = "esbenp.prettier-vscode"; };
        "[json]" = { "editor.defaultFormatter" = "esbenp.prettier-vscode"; };

        # ── Terraform ──────────────────────────────────────────
        "terraform.languageServer.enable" = true;

        # ── Markdown ───────────────────────────────────────────
        "[markdown]" = {
          "editor.wordWrap" = "on";
          "editor.quickSuggestions" = { "other" = true; "comments" = false; "strings" = false; };
          "editor.tabSize" = 2;
        };
        "markdown.preview.fontSize" = 14;
        "markdownlint.config" = {
          "MD033" = false;   # Autoriser le HTML inline
          "MD013" = false;   # Pas de limite de longueur de ligne
        };

        # ── YAML ───────────────────────────────────────────────
        "yaml.format.enable" = true;
        "yaml.schemaStore.enable" = true;            # Auto-complétion Docker Compose, GitHub Actions, etc.

        # ── Docker ─────────────────────────────────────────────
        "docker.showExplorer" = true;

        # ── Git ────────────────────────────────────────────────
        "git.autofetch" = true;
        "git.confirmSync" = false;
        "git.enableSmartCommit" = true;              # Stage all si rien n'est staged
        "gitlens.codeLens.enabled" = false;           # Trop de bruit, blame suffit
        "gitlens.hovers.currentLine.over" = "line";

        # ── Remote SSH ─────────────────────────────────────────
        "remote.SSH.defaultExtensions" = [
          "jnoortheen.nix-ide"
          "ms-python.python"
          "dbaeumer.vscode-eslint"
          "eamodio.gitlens"
        ];
        # Les hôtes SSH sont configurés dans home/git.nix (matchBlocks)
        # Utiliser : Ctrl+Shift+P → Remote-SSH: Connect to Host → proxmox / nas / docker01

        # ── Telemetry OFF ──────────────────────────────────────
        "telemetry.telemetryLevel" = "off";
        "workbench.enableExperiments" = false;
        "update.showReleaseNotes" = false;
      };
    };
  };
}
