# ╔══════════════════════════════════════════════════════════════════╗
# ║  Helix — Éditeur modal post-vim (Rust)                         ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Alternative moderne à Neovim avec :
# - LSP natif (pas de plugin à configurer)
# - Treesitter natif (coloration intelligente)
# - Zero config pour démarrer
# - Paradigme "select then act" (inverse de vim)
#
# Usage : hx fichier.rs
# Tutoriel intégré : hx --tutor
#
# Neovim reste l'éditeur par défaut ($EDITOR).
# Helix est disponible comme alternative via `hx`.

{ config, pkgs, ... }: {

  programs.helix = {
    enable = true;
    # Ne PAS mettre defaultEditor = true (Neovim reste par défaut)

    settings = {
      # Thème Catppuccin Mocha
      theme = "catppuccin_mocha";

      editor = {
        # Numéros de ligne relatifs (comme vim)
        line-number = "relative";

        # Curseur
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };

        # Barre de statut
        statusline = {
          left = [ "mode" "spinner" "file-name" "file-modification-indicator" ];
          center = [ "diagnostics" ];
          right = [ "selections" "position" "file-encoding" "file-line-ending" "file-type" ];
        };

        # Auto-format à la sauvegarde
        auto-format = true;

        # Indentation intelligente
        indent-guides.render = true;

        # File picker
        file-picker = {
          hidden = false; # Afficher les fichiers cachés
        };

        # LSP
        lsp = {
          display-messages = true;
          display-inlay-hints = true;
        };

        # Soft wrap pour les fichiers longs
        soft-wrap.enable = true;
      };

      # Keybinds custom (mode normal)
      keys.normal = {
        # Espace comme leader (comme vim)
        space = {
          f = "file_picker";
          b = "buffer_picker";
          s = ":write";          # Sauvegarder
          q = ":quit";           # Quitter
          "/" = "global_search"; # Recherche globale
        };

        # Navigation rapide
        "C-h" = "jump_view_left";
        "C-l" = "jump_view_right";
        "C-j" = "jump_view_down";
        "C-k" = "jump_view_up";
      };
    };

    # Les LSP sont auto-détectés si les serveurs sont dans le PATH :
    # nil (Nix), pyright (Python), rust-analyzer (Rust), gopls (Go)
    # Pas besoin de les configurer explicitement ici.
    languages = {
      language-server = {
        nil = { command = "nil"; };
      };

      language = [
        { name = "nix"; auto-format = true; formatter = { command = "alejandra"; }; }
      ];
    };
  };
}
