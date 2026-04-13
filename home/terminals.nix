# ╔══════════════════════════════════════════════════════════════════╗
# ║  Terminaux alternatifs — Wezterm, Ghostty, Zellij               ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# En plus de Kitty (terminal par défaut dans home/hyprland.nix),
# ce module installe des alternatives pour les essayer :
#
# - Wezterm : multiplexing intégré, config Lua, ligatures GPU
# - Ghostty : ultra-performant (Zig), nouveau venu prometteur
# - Zellij : multiplexeur alternatif à tmux, UX modernisée
#
# Tous utilisent le thème Catppuccin Mocha pour la cohérence.

{ config, pkgs, ... }: {

  # ── Wezterm — Terminal avec multiplexing intégré ─────────────────
  # Alternative à Kitty + tmux en un seul programme
  # Config en Lua, tabs, splits, ligatures, images
  programs.wezterm = {
    enable = true;
    extraConfig = ''
      local config = wezterm.config_builder()

      -- Thème Catppuccin Mocha
      config.color_scheme = "Catppuccin Mocha"

      -- Police
      config.font = wezterm.font("JetBrainsMono Nerd Font")
      config.font_size = 12.0

      -- Apparence
      config.window_background_opacity = 0.92
      config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }
      config.hide_tab_bar_if_only_one_tab = true
      config.use_fancy_tab_bar = true
      config.window_decorations = "RESIZE" -- Pas de barre de titre (Wayland)

      -- Performances
      config.front_end = "WebGpu" -- Rendu GPU
      config.webgpu_power_preference = "HighPerformance"

      -- Multiplexing intégré (comme tmux mais natif)
      config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }
      config.keys = {
        -- Leader + | → split horizontal
        { key = "|", mods = "LEADER|SHIFT", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
        -- Leader + - → split vertical
        { key = "-", mods = "LEADER", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
        -- Leader + z → zoom pane (toggle)
        { key = "z", mods = "LEADER", action = wezterm.action.TogglePaneZoomState },
        -- Leader + c → nouveau tab
        { key = "c", mods = "LEADER", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
      }

      return config
    '';
  };

  # ── Ghostty — Terminal ultra-performant (Zig) ───────────────────
  # Nouveau terminal minimaliste et rapide. Config simple via fichier texte.
  # ← ADAPTER : décommenter quand le paquet sera stable dans nixpkgs
  # home.packages = [ pkgs.ghostty ];
  # xdg.configFile."ghostty/config".text = ''
  #   font-family = JetBrainsMono Nerd Font
  #   font-size = 12
  #   theme = catppuccin-mocha
  #   window-padding-x = 8
  #   window-padding-y = 8
  #   background-opacity = 0.92
  #   window-decoration = false
  #   copy-on-select = clipboard
  # '';

  # ── Zellij — Multiplexeur terminal moderne ──────────────────────
  # Alternative à tmux avec une UX plus intuitive :
  # - Panneaux nommés et modes affichés à l'écran
  # - Pas besoin de mémoriser les raccourcis (hints visibles)
  # - Plugins WASM
  programs.zellij = {
    enable = true;
    settings = {
      theme = "catppuccin-mocha";
      default_layout = "compact"; # Layout minimaliste par défaut
      pane_frames = false;         # Pas de bordures entre les panes
      simplified_ui = true;       # UI simplifiée
      default_shell = "zsh";

      # Thème Catppuccin Mocha custom
      themes.catppuccin-mocha = {
        bg = "#1e1e2e";        # base
        fg = "#cdd6f4";        # text
        red = "#f38ba8";
        green = "#a6e3a1";
        blue = "#89b4fa";
        yellow = "#f9e2af";
        magenta = "#cba6f7";
        orange = "#fab387";
        cyan = "#94e2d5";
        black = "#181825";     # mantle
        white = "#cdd6f4";     # text
      };
    };
  };
}
