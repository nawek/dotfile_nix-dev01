# ╔══════════════════════════════════════════════════════════════════╗
# ║  Tmux — Multiplexeur terminal avec thème Catppuccin             ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Permet de :
# - Garder des sessions en arrière-plan (survive à la déconnexion SSH)
# - Diviser le terminal en panes et fenêtres
# - Naviguer entre les panes avec des raccourcis vim-like
#
# Prefix : Ctrl+a (au lieu du Ctrl+b par défaut)
# Usage rapide :
#   tmux              → nouvelle session
#   tmux attach       → rattacher à la dernière session
#   Ctrl+a |          → split vertical
#   Ctrl+a -          → split horizontal
#   Ctrl+a h/j/k/l    → naviguer entre les panes

{ config, pkgs, ... }: {

  programs.tmux = {
    enable = true;

    # ── Options de base ────────────────────────────────────────────
    prefix = "C-a";              # Ctrl+a au lieu de Ctrl+b
    mouse = true;                # Support souris (scroll, resize, clic)
    baseIndex = 1;               # Les fenêtres commencent à 1 (pas 0)
    terminal = "tmux-256color";  # Support couleurs 24-bit
    escapeTime = 0;              # Pas de délai après Escape (important pour nvim)
    historyLimit = 50000;        # Historique scrollback
    keyMode = "vi";              # Keybinds vim dans le mode copie
    clock24 = true;              # Horloge 24h

    # ── Plugins ────────────────────────────────────────────────────
    plugins = with pkgs.tmuxPlugins; [
      # Thème Catppuccin
      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavor "mocha"
          set -g @catppuccin_window_status_style "rounded"
          set -g @catppuccin_status_modules_right "session date_time"
          set -g @catppuccin_date_time_text "%H:%M"
        '';
      }

      # Sauvegarde/restauration de sessions (survive au reboot)
      resurrect

      # Sauvegarde automatique des sessions (toutes les 15 min)
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '15'
        '';
      }

      # Copier dans le presse-papier système
      yank

      # Recherche fuzzy dans le scrollback
      tmux-fzf
    ];

    # ── Keybinds custom ────────────────────────────────────────────
    extraConfig = ''
      # Recharger la config avec Prefix + r
      bind r source-file ~/.config/tmux/tmux.conf \; display "Config rechargée"

      # Split avec | et - (plus intuitif)
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      unbind '"'
      unbind %

      # Nouvelle fenêtre dans le répertoire courant
      bind c new-window -c "#{pane_current_path}"

      # Navigation vim entre les panes
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # Redimensionner les panes avec Prefix + H/J/K/L
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      # Activer le vrai support RGB pour kitty/modern terminals
      set -ag terminal-overrides ",xterm-256color:RGB"
      set -ag terminal-overrides ",*:Tc"

      # Renommer automatiquement les fenêtres
      set -g automatic-rename on
      set -g renumber-windows on

      # Indicateur visuel d'activité dans les autres fenêtres
      set -g monitor-activity on
      set -g visual-activity off
    '';
  };
}
