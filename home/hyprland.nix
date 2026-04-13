# ╔══════════════════════════════════════════════════════════════════╗
# ║  Hyprland — Configuration utilisateur                          ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Ce fichier configure Hyprland côté utilisateur :
# - Keybinds, moniteurs, workspaces, input, apparence
# - Waybar, Rofi, Dunst, Hyprlock, Hypridle
# - Kitty (terminal), swww (wallpaper animé)
#
# ⚠️ La config SYSTÈME de Hyprland est dans modules/hyprland.nix
#    (SDDM, polkit, portails XDG, paquets système)
#
# ⚠️ Les couleurs sont gérées par Stylix — ne PAS hardcoder de hex ici
#    sauf mention explicite (ex: gradient de bordure)

{ config, pkgs, lib, ... }: {

  # ── Hyprland — Compositeur Wayland ───────────────────────────────
  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      # ── Variable du modificateur ─────────────────────────────────
      "$mod" = "SUPER";

      # ── Moniteurs ───────────────────────────────────────────────
      # ← ADAPTER : ajuster selon votre configuration d'écrans
      # Format : nom, résolution, position, échelle
      # Utiliser `hyprctl monitors` pour voir les noms disponibles
      monitor = [
        "eDP-1, preferred, 0x0, 1"       # Écran laptop (principal)
        ", preferred, auto-right, 1"      # Écran externe auto-détecté à droite
      ];

      # ── Workspaces ──────────────────────────────────────────────
      # Workspaces 1-5 sur le laptop, 6-9 sur l'écran externe
      workspace = [
        "1, monitor:eDP-1, default:true"
        "2, monitor:eDP-1"
        "3, monitor:eDP-1"
        "4, monitor:eDP-1"
        "5, monitor:eDP-1"
        "6, monitor:, default:true"  # Premier workspace écran externe
        "7, monitor:"
        "8, monitor:"
        "9, monitor:"
      ];

      # ── Input ───────────────────────────────────────────────────
      input = {
        kb_layout = "fr"; # ← ADAPTER : disposition clavier
        follow_mouse = 1;

        touchpad = {
          natural_scroll = true;     # Scroll naturel (comme macOS)
          tap-to-click = true;       # Tap = clic
          drag_lock = true;          # Maintenir le drag après relâchement
          disable_while_typing = true; # Désactiver le touchpad en tapant
        };

        # Sensibilité (-1.0 à 1.0)
        sensitivity = 0;
      };

      # ── Gestures ────────────────────────────────────────────────
      gestures = {
        workspace_swipe = true;          # Swipe 3 doigts pour changer de workspace
        workspace_swipe_fingers = 3;
      };

      # ── Apparence ───────────────────────────────────────────────
      # Les couleurs de base sont injectées par Stylix
      general = {
        gaps_in = 4;       # Espace entre les fenêtres
        gaps_out = 8;      # Espace entre fenêtres et bord d'écran
        border_size = 2;
        # Gradient bleu-violet Catppuccin pour la bordure active
        # ← ADAPTER : couleurs Catppuccin Mocha (blue → mauve)
        "col.active_border" = "rgba(89b4faee) rgba(cba6f7ee) 45deg";
        "col.inactive_border" = "rgba(585b70aa)";
        layout = "dwindle";
      };

      decoration = {
        rounding = 8; # Coins arrondis des fenêtres

        blur = {
          enabled = true;
          size = 5;
          passes = 2;
          new_optimizations = true;
        };

        # Ombres
        shadow = {
          enabled = true;
          range = 10;
          render_power = 3;
        };
      };

      animations = {
        enabled = true;
        # Animations fluides
        animation = [
          "windows, 1, 4, default, slide"
          "windowsOut, 1, 4, default, slide"
          "border, 1, 5, default"
          "fade, 1, 4, default"
          "workspaces, 1, 3, default"
        ];
      };

      dwindle = {
        pseudotile = true;   # Permet le pseudo-tiling
        preserve_split = true; # Garder l'orientation du split
      };

      # ── Keybinds ────────────────────────────────────────────────
      bind = [
        # Applications
        "$mod, Return, exec, kitty"              # Terminal
        "$mod, D, exec, wofi --show drun"        # Lanceur d'apps
        "$mod, E, exec, nautilus"                 # Gestionnaire de fichiers
        "$mod, L, exec, hyprlock"                 # Verrouiller l'écran

        # Gestion des fenêtres
        "$mod, Q, killactive,"                   # Fermer la fenêtre
        "$mod, V, togglefloating,"               # Basculer flottant
        "$mod, F, fullscreen,"                   # Plein écran
        "$mod, P, pseudo,"                       # Pseudo-tile
        "$mod, S, togglesplit,"                  # Changer l'orientation du split

        # Focus entre fenêtres (vim-like)
        "$mod, h, movefocus, l"     # Gauche
        "$mod, j, movefocus, d"     # Bas
        "$mod, k, movefocus, u"     # Haut
        "$mod, l, movefocus, r"     # Droite

        # Déplacer les fenêtres
        "$mod SHIFT, h, movewindow, l"
        "$mod SHIFT, j, movewindow, d"
        "$mod SHIFT, k, movewindow, u"
        "$mod SHIFT, l, movewindow, r"

        # Focus entre écrans
        "$mod CTRL, h, focusmonitor, l"    # Écran de gauche
        "$mod CTRL, l, focusmonitor, r"    # Écran de droite

        # Déplacer fenêtre vers un autre écran
        "$mod CTRL SHIFT, h, movewindow, mon:l"
        "$mod CTRL SHIFT, l, movewindow, mon:r"

        # Redimensionner les fenêtres
        "$mod ALT, h, resizeactive, -20 0"
        "$mod ALT, j, resizeactive, 0 20"
        "$mod ALT, k, resizeactive, 0 -20"
        "$mod ALT, l, resizeactive, 20 0"

        # Captures d'écran
        ", Print, exec, grim - | wl-copy"                                    # Tout l'écran → clipboard
        "$mod, Print, exec, grim -g \"$(slurp)\" - | wl-copy"               # Zone → clipboard
        "$mod SHIFT, Print, exec, grim -g \"$(slurp)\" ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png" # Zone → fichier

        # Changer de wallpaper aléatoirement (depuis ~/Pictures/wallpapers/)
        "$mod, W, exec, swww img $(find ~/Pictures/wallpapers/ -type f | shuf -n 1) --transition-type random --transition-duration 1"

        # Scroll à travers les workspaces
        "$mod, mouse_down, workspace, e+1"
        "$mod, mouse_up, workspace, e-1"
      ]
      # Workspaces 1-9 : switch et move (généré dynamiquement)
      ++ (builtins.concatLists (builtins.genList (x:
        let ws = toString (x + 1);
        in [
          "$mod, ${ws}, workspace, ${ws}"
          "$mod SHIFT, ${ws}, movetoworkspace, ${ws}"
        ]
      ) 9));

      # Keybinds qui se répètent quand on maintient la touche
      binde = [
        # ── Touches média ─────────────────────────────────────────
        # Volume (wpctl — PipeWire)
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"

        # Luminosité (light)
        ", XF86MonBrightnessUp, exec, light -A 5"
        ", XF86MonBrightnessDown, exec, light -U 5"
      ];

      # Keybinds sans répétition
      bindl = [
        # Mute
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"

        # Lecture multimédia (playerctl)
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPrev, exec, playerctl previous"
      ];

      # Déplacer/redimensionner avec la souris
      bindm = [
        "$mod, mouse:272, movewindow"    # $mod + clic gauche = déplacer
        "$mod, mouse:273, resizewindow"  # $mod + clic droit = redimensionner
      ];

      # ── Règles de fenêtres ──────────────────────────────────────
      # Certaines fenêtres doivent être flottantes par défaut
      windowrulev2 = [
        "float, class:^(pavucontrol)$"              # Contrôle du son
        "float, class:^(.blueman-manager-wrapped)$" # Bluetooth
        "float, class:^(nm-connection-editor)$"     # Réseau
        "float, title:^(Open File)$"                # Dialogues de fichiers
        "float, title:^(Save File)$"
        "float, title:^(Open Folder)$"
        "float, title:^(Picture-in-Picture)$"       # PiP vidéo
        "pin, title:^(Picture-in-Picture)$"         # PiP toujours visible
        "float, class:^(xdg-desktop-portal-gtk)$"   # Portail GTK
        "float, class:^(org.gnome.Nautilus)$"       # Nautilus (optionnel)
        # ← ADAPTER : ajouter vos règles ici
      ];

      # ── Autostart ───────────────────────────────────────────────
      exec-once = [
        "waybar"                    # Barre de statut
        "dunst"                     # Notifications
        # Fond d'écran — swww avec transition animée
        "swww-daemon"
        "sleep 1 && swww img ~/Pictures/wallpaper.jpg --transition-type grow --transition-pos center --transition-duration 1" # ← ADAPTER : chemin wallpaper
        "hypridle"                  # Gestion de l'inactivité
        "nm-applet --indicator"     # Applet réseau (tray)
        "blueman-applet"            # Applet Bluetooth (tray)
        # Agent polkit (pop-up mot de passe pour les actions admin)
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
      ];
    };
  };

  # ── Hypridle — Gestion de l'inactivité ──────────────────────────
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock"; # Éviter de lancer 2 instances
        before_sleep_cmd = "loginctl lock-session"; # Verrouiller avant suspend
        after_sleep_cmd = "hyprctl dispatch dpms on"; # Rallumer les écrans au réveil
      };

      listener = [
        # Après 2.5 minutes — réduire la luminosité
        {
          timeout = 150;
          on-timeout = "light -S 10";    # Baisser à 10%
          on-resume = "light -I";         # Restaurer la luminosité précédente
        }
        # Après 5 minutes — verrouiller l'écran
        {
          timeout = 300;
          on-timeout = "loginctl lock-session";
        }
        # Après 10 minutes — éteindre les écrans
        {
          timeout = 600;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
        # Après 20 minutes — suspendre le système
        {
          timeout = 1200;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };

  # ── Hyprlock — Écran de verrouillage ─────────────────────────────
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        hide_cursor = true;
        grace = 5; # 5 secondes de grâce après verrouillage
      };

      # ← ADAPTER : personnaliser l'apparence de l'écran de verrouillage
      background = [{
        monitor = "";
        blur_passes = 3;
        blur_size = 8;
      }];

      input-field = [{
        monitor = "";
        size = "200, 50";
        outline_thickness = 2;
        fade_on_empty = false;
        placeholder_text = "Mot de passe...";
      }];
    };
  };

  # ── Waybar — Barre de statut ─────────────────────────────────────
  # Les couleurs et la police sont gérées par Stylix
  programs.waybar = {
    enable = true;

    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 34;

      modules-left = [
        "hyprland/workspaces"
      ];

      modules-center = [
        "hyprland/window"
      ];

      modules-right = [
        "tray"
        "network"
        "bluetooth"
        "pulseaudio"
        "backlight"
        "battery"
        "clock"
      ];

      # ── Modules ────────────────────────────────────────────────

      "hyprland/workspaces" = {
        format = "{name}";
        on-click = "activate";
        sort-by-number = true;
      };

      "hyprland/window" = {
        max-length = 50;
        separate-outputs = true;
      };

      clock = {
        format = "{:%H:%M  %a %d %b}";
        tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
      };

      battery = {
        states = {
          warning = 30;
          critical = 15;
        };
        format = "{icon}  {capacity}%";
        format-charging = "⚡ {capacity}%";
        format-plugged = " {capacity}%";
        format-icons = [ "" "" "" "" "" ];
      };

      network = {
        format-wifi = "  {signalStrength}%";
        format-ethernet = " ";
        format-disconnected = "⚠ ";
        tooltip-format = "{ifname}: {ipaddr}/{cidr}\n{essid}";
      };

      bluetooth = {
        format = " {status}";
        format-connected = " {device_alias}";
        format-disabled = "";
        on-click = "blueman-manager";
      };

      pulseaudio = {
        format = "{icon}  {volume}%";
        format-muted = " ";
        format-icons = {
          default = [ "" "" "" ];
        };
        on-click = "pavucontrol";
      };

      backlight = {
        format = "{icon} {percent}%";
        format-icons = [ "" "" "" "" "" "" "" "" "" ];
      };

      tray = {
        spacing = 10;
      };
    };
  };

  # ── Wofi — Lanceur d'applications ───────────────────────────────
  # Les couleurs sont gérées par Stylix
  programs.wofi = {
    enable = true;
    settings = {
      show = "drun";
      width = 600;
      height = 400;
      allow_images = true;
      insensitive = true;     # Recherche insensible à la casse
      prompt = "Rechercher...";
    };
  };

  # ── Dunst — Notifications ───────────────────────────────────────
  # Les couleurs et la police sont gérées par Stylix
  services.dunst = {
    enable = true;
    settings = {
      global = {
        width = 300;
        height = 100;
        offset = "30x50";
        origin = "top-right";
        corner_radius = 10;
        frame_width = 2;
        # Transparence
        transparency = 10;
        # Temps d'affichage (en secondes)
        timeout = 5;
      };
    };
  };

  # ── Kitty — Terminal ─────────────────────────────────────────────
  # Le thème de couleurs est géré par Stylix
  programs.kitty = {
    enable = true;
    settings = {
      # Police — la famille est gérée par Stylix, on ajuste la taille
      font_size = 12;

      # Apparence
      window_padding_width = 8;
      confirm_os_window_close = 0; # Pas de confirmation à la fermeture

      # Performance
      repaint_delay = 10;
      input_delay = 3;

      # Comportement
      enable_audio_bell = false;  # Pas de son de cloche
      copy_on_select = "clipboard"; # Copier automatiquement la sélection
      scrollback_lines = 10000;
    };
  };
}
