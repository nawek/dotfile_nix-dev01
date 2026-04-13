# ╔══════════════════════════════════════════════════════════════════╗
# ║  Yazi — File manager TUI ultra-rapide (Rust)                    ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Remplace ranger/lf avec des performances supérieures.
# Preview d'images dans Kitty, navigation vim, intégration ZSH.
#
# Usage :
#   y            → ouvre Yazi (avec cd-on-exit)
#   Espace       → sélectionner des fichiers
#   Enter        → ouvrir avec l'application par défaut
#   d            → supprimer
#   r            → renommer
#   /            → rechercher
#   z            → jump fuzzy (comme zoxide)
#   q            → quitter (et cd dans le dossier courant)

{ config, pkgs, ... }: {

  programs.yazi = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      manager = {
        show_hidden = true;        # Afficher les fichiers cachés
        sort_by = "natural";       # Tri naturel (1, 2, 10 au lieu de 1, 10, 2)
        sort_dir_first = true;     # Dossiers en premier
        linemode = "size";         # Afficher la taille à droite
        show_symlink = true;
      };

      preview = {
        max_width = 1000;
        max_height = 1000;
        image_filter = "lanczos3"; # Meilleur filtre pour les images
      };

      opener = {
        edit = [
          { run = "$EDITOR \"$@\""; block = true; desc = "Éditeur"; }
        ];
        open = [
          { run = "xdg-open \"$@\""; desc = "Ouvrir"; }
        ];
      };
    };

    # Thème Catppuccin Mocha
    theme = {
      manager = {
        cwd = { fg = "#89b4fa"; };        # Bleu pour le chemin courant

        hovered = { bg = "#313244"; };     # Surface0 pour la sélection
        preview_hovered = { bg = "#313244"; };

        find_keyword = { fg = "#f9e2af"; bold = true; }; # Jaune pour la recherche

        tab_active = { fg = "#1e1e2e"; bg = "#89b4fa"; }; # Tab active
        tab_inactive = { fg = "#cdd6f4"; bg = "#313244"; }; # Tab inactive
      };

      status = {
        separator_open = "";
        separator_close = "";

        mode_normal = { fg = "#1e1e2e"; bg = "#89b4fa"; bold = true; };
        mode_select = { fg = "#1e1e2e"; bg = "#a6e3a1"; bold = true; };
        mode_unset = { fg = "#1e1e2e"; bg = "#f38ba8"; bold = true; };
      };
    };
  };
}
