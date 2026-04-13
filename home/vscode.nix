# ╔══════════════════════════════════════════════════════════════════╗
# ║  VSCode — Éditeur de code avec extensions déclaratives         ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Configuration déclarative de Visual Studio Code.
# Les extensions sont gérées par Nix (pas le marketplace intégré).
#
# ⚠️ Stylix gère le thème de couleurs automatiquement.
#    Ne PAS installer d'extension de thème sauf si vous désactivez
#    le ciblage Stylix pour VSCode :
#    stylix.targets.vscode.enable = false;

{ config, pkgs, ... }: {

  programs.vscode = {
    enable = true;
    package = pkgs.vscode; # Version officielle Microsoft (pas OSS)

    # ── Extensions ─────────────────────────────────────────────────
    # Installées de manière déclarative via nixpkgs
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
      # Pour les extensions non disponibles dans nixpkgs, utiliser :
      # ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
      #   {
      #     name = "extension-name";
      #     publisher = "publisher-name";
      #     version = "1.0.0";
      #     sha256 = "sha256-..."; # nix-prefetch-url <vsix-url>
      #   }
    ];

    # ── Paramètres utilisateur ─────────────────────────────────────
    userSettings = {
      # Police — gérée par Stylix, on ajoute seulement les fallbacks et la taille
      # "editor.fontFamily" est injecté par Stylix — ne PAS le redéfinir
      "editor.fontSize" = 14;
      "editor.fontLigatures" = true;  # Ligatures (=> → ≠ etc.)
      "editor.minimap.enabled" = false; # Désactiver la minimap

      # Comportement de l'éditeur
      "editor.formatOnSave" = true;   # Formater automatiquement à la sauvegarde
      "editor.tabSize" = 2;
      "editor.wordWrap" = "on";

      # Barre de titre Wayland (custom pour intégration native)
      "window.titleBarStyle" = "custom";

      # Terminal intégré
      "terminal.integrated.defaultProfile.linux" = "zsh";

      # ── Nix — LSP via nil ─────────────────────────────────────
      "nix.enableLanguageServer" = true;
      "nix.serverPath" = "nil";              # Utilise nil du PATH (installé via systemPackages)
      "nix.serverSettings" = {
        "nil" = {
          formatting = {
            command = [ "nixfmt" ];          # Formateur nixfmt-rfc-style
          };
        };
      };

      # ← ADAPTER : paramètres supplémentaires
      # "python.defaultInterpreterPath" = "python3";
      # "rust-analyzer.check.command" = "clippy";
    };
  };
}
