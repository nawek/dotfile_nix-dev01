# ╔══════════════════════════════════════════════════════════════════╗
# ║  VSCode — Éditeur de code avec extensions déclaratives         ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Configuration déclarative de Visual Studio Code.
# Les extensions sont gérées par Nix (pas le marketplace intégré).
#
# ⚠️ Stylix gère le thème de couleurs et la police automatiquement.

{ config, pkgs, lib, ... }: {

  programs.vscode = {
    enable = true;
    package = pkgs.vscode; # Version officielle Microsoft (pas OSS)

    # ── Profil par défaut (nouvelle API Home Manager) ──────────────
    profiles.default = {
      # ── Extensions ───────────────────────────────────────────────
      extensions = with pkgs.vscode-extensions; [
        # Nix
        jnoortheen.nix-ide           # Support Nix (coloration, snippets, LSP)

        # Python
        ms-python.python             # Support Python
        ms-python.vscode-pylance     # IntelliSense Python avancé

        # JavaScript / TypeScript
        dbaeumer.vscode-eslint       # Linter JS/TS
        esbenp.prettier-vscode       # Formateur Prettier

        # Rust
        rust-lang.rust-analyzer      # LSP Rust

        # Git
        eamodio.gitlens              # Git avancé (blame, historique, etc.)

        # Qualité de code
        usernamehw.errorlens         # Affiche les erreurs inline
        gruntfuggly.todo-tree        # Trouve les TODO/FIXME

        # ← ADAPTER : ajouter vos extensions ici
      ];

      # ── Paramètres utilisateur ───────────────────────────────────
      userSettings = {
        # Police — gérée par Stylix, on override seulement la taille
        "editor.fontSize" = lib.mkForce 14;
        "editor.fontLigatures" = true;
        "editor.minimap.enabled" = false;

        # Comportement
        "editor.formatOnSave" = true;
        "editor.tabSize" = 2;
        "editor.wordWrap" = "on";

        # Barre de titre Wayland
        "window.titleBarStyle" = "custom";

        # Terminal intégré
        "terminal.integrated.defaultProfile.linux" = "zsh";

        # ── Nix — LSP via nil ───────────────────────────────────
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nil";
        "nix.serverSettings" = {
          "nil" = {
            formatting = {
              command = [ "nixfmt" ];
            };
          };
        };

        # ← ADAPTER : paramètres supplémentaires
      };
    };
  };
}
