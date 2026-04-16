# ╔══════════════════════════════════════════════════════════════════╗
# ║  Stylix — Thème global Catppuccin Mocha                        ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Stylix applique un thème cohérent à l'ensemble du système :
# GTK, QT, SDDM, dunst, waybar, kitty, bat, fzf, etc.
#
# ⚠️ Ne PAS définir de couleurs/thèmes manuellement dans les autres
#    modules — Stylix s'en charge automatiquement.
#    Si un override est nécessaire pour une app spécifique :
#      stylix.targets.<app>.enable = false;

{ config, pkgs, ... }: {
  stylix = {
    enable = true;

    # Note : les thèmes Rofi et Hyprlock sont gérés manuellement
    # dans home/hyprland.nix (avec mkForce si conflit Stylix).

    # ── Schéma de couleurs ───────────────────────────────────────────
    # Catppuccin Mocha — palette sombre avec des accents pastel
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    polarity = "dark";

    # ── Fond d'écran ─────────────────────────────────────────────────
    # ← ADAPTER : remplacer par votre propre wallpaper
    # Exemple : image = /persist/home/kuro/Pictures/wallpaper.jpg;
    # Par défaut : image générée aux couleurs Catppuccin Mocha (pas de dépendance externe)
    image = pkgs.runCommand "catppuccin-mocha-wallpaper.png" {
      nativeBuildInputs = [ pkgs.imagemagick ];
    } ''
      magick -size 3840x2160 \
        xc:"#1e1e2e" \
        -fill "#313244" -draw "rectangle 0,1800 3840,2160" \
        -fill "#45475a" -draw "circle 3200,400 3200,550" \
        -fill "#585b70" -draw "circle 600,1400 600,1500" \
        $out
    '';

    # ── Curseur ──────────────────────────────────────────────────────
    cursor = {
      package = pkgs.catppuccin-cursors.mochaDark;
      name = "catppuccin-mocha-dark-cursors";
      size = 24;
    };

    # ── Polices ──────────────────────────────────────────────────────
    fonts = {
      # Police monospace — terminal, éditeur de code
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono; # Syntaxe post-24.11
        name = "JetBrainsMono Nerd Font";
      };

      # Police sans-serif — interfaces graphiques
      sansSerif = {
        package = pkgs.inter;
        name = "Inter";
      };

      # Police serif — documents, lecture
      serif = {
        package = pkgs.noto-fonts;
        name = "Noto Serif";
      };

      # Emoji
      emoji = {
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };

      # Tailles de police par contexte
      sizes = {
        applications = 11;  # Applications GTK/QT
        desktop = 11;       # Éléments du bureau (waybar, etc.)
        popups = 12;        # Notifications, menus
        terminal = 12;      # Terminal (kitty)
      };
    };

    # ── Opacité ──────────────────────────────────────────────────────
    opacity = {
      terminal = 0.92; # Légère transparence pour le terminal
    };
  };

  # ── Polices supplémentaires ──────────────────────────────────────
  # Noto CJK pour le support des caractères asiatiques
  fonts.packages = with pkgs; [
    noto-fonts-cjk-sans # Caractères CJK (chinois, japonais, coréen)
  ];
}
