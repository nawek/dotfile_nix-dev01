# ╔══════════════════════════════════════════════════════════════════╗
# ║  Hyprland — Configuration utilisateur                          ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Ce fichier configure Hyprland côté utilisateur :
# - Keybinds, moniteurs, workspaces, input, apparence
# - Waybar, Rofi, SwayNC, Hyprlock, Hypridle
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
      # Workspace spécial "scratchpad" pour le terminal dropdown
      workspace = [
        "special:scratchpad, on-created-empty:kitty --class scratchpad"
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

        # Courbes bezier custom pour des animations fluides et naturelles
        bezier = [
          "smoothOut, 0.36, 0, 0.66, -0.56"   # Sortie avec léger rebond inversé
          "smoothIn, 0.25, 1, 0.5, 1"          # Entrée douce et progressive
          "overshot, 0.05, 0.9, 0.1, 1.05"     # Dépassement léger (bounce)
        ];

        animation = [
          # Fenêtres — effet popin (zoom depuis le centre)
          "windows, 1, 5, overshot, popin 80%"
          "windowsOut, 1, 5, smoothOut, popin 80%"

          # Bordures — transition lente et douce
          "border, 1, 10, default"

          # Fondu — apparition/disparition progressive
          "fade, 1, 5, smoothIn"
          "fadeDim, 1, 5, smoothIn"

          # Layers (waybar, rofi, notifications) — fondu
          "layers, 1, 5, smoothIn, fade"
          "layersIn, 1, 5, smoothIn, fade"
          "layersOut, 1, 5, smoothOut, fade"

          # Workspaces — slide avec léger dépassement
          "workspaces, 1, 5, overshot, slide"

          # Workspace spécial (scratchpad) — fondu
          "specialWorkspace, 1, 5, smoothIn, fade"
        ];
      };

      dwindle = {
        pseudotile = true;   # Permet le pseudo-tiling
        preserve_split = true; # Garder l'orientation du split
      };

      # Onglets groupés — barre de titre quand des fenêtres sont groupées
      group = {
        "col.border_active" = "rgba(89b4faee)";
        "col.border_inactive" = "rgba(585b70aa)";
        groupbar = {
          font_size = 11;
          gradients = false;
          "col.active" = "rgba(89b4faee)";
          "col.inactive" = "rgba(313244aa)";
        };
      };

      # ── Keybinds ────────────────────────────────────────────────
      bind = [
        # Applications
        "$mod, Return, exec, kitty"              # Terminal
        "$mod, D, exec, rofi -show drun -show-icons" # Lanceur d'apps
        "$mod, E, exec, nautilus"                 # Gestionnaire de fichiers
        "$mod, L, exec, hyprlock"                 # Verrouiller l'écran
        "$mod, X, exec, wlogout"                  # Menu power (logout, reboot, shutdown)

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

        # Captures d'écran via grimblast (outil all-in-one Hyprland)
        ", Print, exec, grimblast --notify copy screen"                      # Tout l'écran → clipboard
        "$mod, Print, exec, grimblast --notify copy area"                    # Zone → clipboard
        "$mod SHIFT, Print, exec, grimblast --notify save area ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png" # Zone → fichier
        "$mod ALT, Print, exec, grimblast --notify save area - | satty --filename -" # Zone → annotation satty

        # Color picker — copie le hex dans le clipboard
        "$mod SHIFT, P, exec, hyprpicker -a"

        # Emoji picker via rofimoji
        "$mod, period, exec, rofimoji --action copy --skin-tone neutral"

        # Notification center — toggle le panneau SwayNC
        "$mod, N, exec, swaync-client -t -sw"

        # ── Scratchpad — Terminal dropdown (style Quake) ──────────
        "$mod, grave, togglespecialworkspace, scratchpad"
        "$mod SHIFT, grave, movetoworkspace, special:scratchpad"

        # ── Window grouping — onglets ─────────────────────────────
        "$mod, T, togglegroup,"              # Créer/dissoudre un groupe
        "$mod, Tab, changegroupactive, f"    # Onglet suivant dans le groupe
        "$mod SHIFT, Tab, changegroupactive, b" # Onglet précédent

        # ── Submaps — Modes spéciaux (comme i3 modes) ────────────
        # Mode resize : $mod+R puis h/j/k/l, Escape pour sortir
        "$mod, R, submap, resize"
        # Mode move : $mod+M puis h/j/k/l, Escape pour sortir
        # (Le submap indicator Waybar affiche le mode actif)

        # ── Zen mode — Focus coding ──────────────────────────────
        # Toggle : masque waybar, augmente les gaps, désactive les notifs
        "$mod, Z, exec, pkill waybar || waybar &"
        "$mod SHIFT, Z, exec, swaync-client -d"

        # ── Keybind cheatsheet — Affiche les raccourcis ───────────
        "$mod, F1, exec, kitty --class cheatsheet -e sh -c 'cat ~/.config/hypr/cheatsheet.md 2>/dev/null || echo \"Créer ~/.config/hypr/cheatsheet.md avec vos raccourcis\" ; read'"

        # Presse-papier — historique via cliphist + rofi
        "$mod, C, exec, cliphist list | rofi -dmenu -p Clipboard | cliphist decode | wl-copy"

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
        # ── Touches média via SwayOSD ─────────────────────────────
        # SwayOSD affiche un OSD natif Wayland à chaque action
        # Volume
        ", XF86AudioRaiseVolume, exec, swayosd-client --output-volume raise"
        ", XF86AudioLowerVolume, exec, swayosd-client --output-volume lower"

        # Luminosité
        ", XF86MonBrightnessUp, exec, swayosd-client --brightness raise"
        ", XF86MonBrightnessDown, exec, swayosd-client --brightness lower"
      ];

      # Keybinds sans répétition
      bindl = [
        # Mute via SwayOSD
        ", XF86AudioMute, exec, swayosd-client --output-volume mute-toggle"
        ", XF86AudioMicMute, exec, swayosd-client --input-volume mute-toggle"

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

      # ── Submaps — Modes resize et move ──────────────────────────
      # Le nom du submap s'affiche dans Waybar via le module hyprland/submap
    };

    # Les submaps doivent être définis via extraConfig (pas settings)
    extraConfig = ''
      # ── Submap : Resize ──────────────────────────────────────────
      submap = resize
      binde = , h, resizeactive, -30 0
      binde = , j, resizeactive, 0 30
      binde = , k, resizeactive, 0 -30
      binde = , l, resizeactive, 30 0
      binde = , left, resizeactive, -30 0
      binde = , down, resizeactive, 0 30
      binde = , up, resizeactive, 0 -30
      binde = , right, resizeactive, 30 0
      bind = , escape, submap, reset
      bind = , Return, submap, reset
      submap = reset
    '';

    settings = {
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
        "float, class:^(wlogout)$"                # wlogout flottant
        "fullscreen, class:^(wlogout)$"           # wlogout plein écran
        # Scratchpad — flottant centré 80%x70%
        "float, class:^(scratchpad)$"
        "size 80% 70%, class:^(scratchpad)$"
        "center, class:^(scratchpad)$"
        # Cheatsheet — flottant centré
        "float, class:^(cheatsheet)$"
        "size 60% 70%, class:^(cheatsheet)$"
        "center, class:^(cheatsheet)$"
        # ← ADAPTER : ajouter vos règles ici
      ];

      # ── Autostart ───────────────────────────────────────────────
      exec-once = [
        "waybar"                    # Barre de statut
        "swaync"                    # Centre de notifications
        # Fond d'écran — swww avec transition animée
        "swww-daemon"
        "sleep 1 && swww img ~/Pictures/wallpaper.jpg --transition-type grow --transition-pos center --transition-duration 1" # ← ADAPTER : chemin wallpaper
        "hypridle"                  # Gestion de l'inactivité
        "swayosd-server"            # Serveur OSD (volume, brightness, caps)
        # Historique presse-papier (cliphist écoute wl-paste)
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
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

  # ── Hyprlock — Écran de verrouillage thémé ────────────────────────
  # Écran de verrouillage élégant avec horloge, date, greeting et blur
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        hide_cursor = true;
        grace = 5;               # Secondes de grâce après verrouillage
        no_fade_in = false;
        no_fade_out = false;
      };

      # ── Fond — blur du wallpaper actuel ──────────────────────────
      background = [{
        monitor = "";
        blur_passes = 4;
        blur_size = 10;
        brightness = 0.5;        # Assombrir le fond
        vibrancy = 0.2;
        vibrancy_darkness = 0.0;
      }];

      # ── Horloge — grande heure centrée ───────────────────────────
      label = [
        {
          monitor = "";
          text = "$TIME";        # Heure dynamique (HH:MM)
          font_size = 120;
          font_family = "JetBrainsMono Nerd Font";
          color = "rgba(205, 214, 244, 1.0)"; # Catppuccin text
          position = "0, 200";
          halign = "center";
          valign = "center";
          shadow_passes = 2;
          shadow_size = 3;
        }

        # ── Date — sous l'horloge ──────────────────────────────────
        {
          monitor = "";
          text = ''cmd[update:1000] date "+%A %d %B %Y"'';
          font_size = 22;
          font_family = "Inter";
          color = "rgba(186, 194, 222, 0.8)"; # Catppuccin subtext0
          position = "0, 100";
          halign = "center";
          valign = "center";
        }

        # ── Message d'accueil ──────────────────────────────────────
        {
          monitor = "";
          text = "Bienvenue, Kuro"; # ← ADAPTER : votre nom
          font_size = 16;
          font_family = "Inter";
          color = "rgba(137, 180, 250, 0.9)"; # Catppuccin blue
          position = "0, -80";
          halign = "center";
          valign = "center";
        }
      ];

      # ── Champ de saisie du mot de passe ──────────────────────────
      input-field = [{
        monitor = "";
        size = "300, 55";
        outline_thickness = 2;
        dots_size = 0.25;
        dots_spacing = 0.2;
        dots_center = true;
        dots_rounding = -1;      # Cercles parfaits
        outer_color = "rgba(137, 180, 250, 0.7)";  # Catppuccin blue
        inner_color = "rgba(30, 30, 46, 0.8)";     # Catppuccin base
        font_color = "rgba(205, 214, 244, 1.0)";   # Catppuccin text
        fade_on_empty = false;
        placeholder_text = "<i>  Mot de passe...</i>";
        hide_input = false;
        rounding = 15;
        check_color = "rgba(166, 227, 161, 0.7)";  # Catppuccin green (succès)
        fail_color = "rgba(243, 139, 168, 0.7)";   # Catppuccin red (échec)
        fail_text = "<i>$FAIL <b>($ATTEMPTS)</b></i>";
        capslock_color = "rgba(250, 179, 135, 0.7)"; # Catppuccin peach (caps lock)
        position = "0, -30";
        halign = "center";
        valign = "center";
      }];
    };
  };

  # ── Waybar — Barre de statut Catppuccin ────────────────────────────
  programs.waybar = {
    enable = true;

    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 38;
      margin-top = 4;
      margin-left = 8;
      margin-right = 8;

      modules-left = [
        "hyprland/workspaces"
        "hyprland/submap"        # Mode actif (resize, move, etc.)
        "custom/media"
      ];

      modules-center = [
        "hyprland/window"
      ];

      modules-right = [
        "custom/weather"
        "tray"
        "network"
        "bluetooth"
        "pulseaudio"
        "backlight"
        "battery"
        "clock"
      ];

      # ── Modules standard ────────────────────────────────────────

      "hyprland/workspaces" = {
        format = "{icon}";
        format-icons = {
          "1" = ""; "2" = ""; "3" = ""; "4" = ""; "5" = "";
          "6" = ""; "7" = ""; "8" = ""; "9" = "";
          active = ""; default = "";
        };
        on-click = "activate";
        sort-by-number = true;
        persistent-workspaces = { "*" = 5; };
      };

      "hyprland/submap" = {
        format = "  {}";
        tooltip = false;
      };

      "hyprland/window" = {
        max-length = 40;
        separate-outputs = true;
        rewrite = { "(.*) — Mozilla Firefox" = " $1"; "(.*) - Visual Studio Code" = " $1"; };
      };

      clock = {
        format = "  {:%H:%M}";
        format-alt = "  {:%A %d %B %Y}";
        tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
      };

      battery = {
        states = { warning = 30; critical = 15; };
        format = "{icon}  {capacity}%";
        format-charging = "  {capacity}%";
        format-plugged = "  {capacity}%";
        format-icons = [ "" "" "" "" "" ];
      };

      network = {
        format-wifi = "  {signalStrength}%";
        format-ethernet = "  {ifname}";
        format-disconnected = "  Déconnecté";
        tooltip-format = "{ifname}: {ipaddr}/{cidr}\n  {essid} ({signalStrength}%)";
        on-click = "nm-connection-editor";
      };

      bluetooth = {
        format = " {status}";
        format-connected = "  {device_alias}";
        format-disabled = "";
        on-click = "blueman-manager";
        tooltip-format = "{controller_alias}\n{num_connections} connecté(s)";
      };

      pulseaudio = {
        format = "{icon}  {volume}%";
        format-muted = "  Muet";
        format-icons = { default = [ "" "" "" ]; };
        on-click = "pavucontrol";
        scroll-step = 5;
      };

      backlight = {
        format = "{icon} {percent}%";
        format-icons = [ "" "" "" "" "" "" "" "" "" ];
      };

      tray = { spacing = 8; };

      # ── Modules custom ──────────────────────────────────────────

      "custom/weather" = {
        format = "{}";
        interval = 900; # 15 minutes
        exec = "curl -s 'wttr.in/?format=%c+%t' 2>/dev/null || echo ''";
        tooltip = false;
      };

      "custom/media" = {
        format = "{}";
        interval = 3;
        exec = ''playerctl metadata --format "{{artist}} — {{title}}" 2>/dev/null || echo ""'';
        max-length = 30;
        on-click = "playerctl play-pause";
        tooltip = false;
      };
    };

    # ── CSS Catppuccin Mocha complet ──────────────────────────────
    style = ''
      /* ═══ Palette Catppuccin Mocha ═══ */
      @define-color base   #1e1e2e;
      @define-color mantle #181825;
      @define-color crust  #11111b;
      @define-color text   #cdd6f4;
      @define-color subtext0 #a6adc8;
      @define-color subtext1 #bac2de;
      @define-color surface0 #313244;
      @define-color surface1 #45475a;
      @define-color surface2 #585b70;
      @define-color overlay0 #6c7086;
      @define-color blue    #89b4fa;
      @define-color lavender #b4befe;
      @define-color sapphire #74c7ec;
      @define-color sky     #89dceb;
      @define-color teal    #94e2d5;
      @define-color green   #a6e3a1;
      @define-color yellow  #f9e2af;
      @define-color peach   #fab387;
      @define-color maroon  #eba0ac;
      @define-color red     #f38ba8;
      @define-color mauve   #cba6f7;
      @define-color pink    #f5c2e7;
      @define-color flamingo #f2cdcd;
      @define-color rosewater #f5e0dc;

      /* ═══ Barre principale ═══ */
      * {
        font-family: "JetBrainsMono Nerd Font";
        font-size: 13px;
        min-height: 0;
      }

      window#waybar {
        background: rgba(30, 30, 46, 0.85);
        border-radius: 12px;
        border: 1px solid @surface0;
        color: @text;
      }

      /* ═══ Pills (modules) ═══ */
      #workspaces,
      #submap,
      #custom-media,
      #window,
      #custom-weather,
      #tray,
      #network,
      #bluetooth,
      #pulseaudio,
      #backlight,
      #battery,
      #clock {
        padding: 2px 10px;
        margin: 4px 2px;
        border-radius: 8px;
        background: @surface0;
        color: @text;
        transition: all 0.3s ease;
      }

      /* ═══ Hover ═══ */
      #workspaces button:hover,
      #network:hover,
      #bluetooth:hover,
      #pulseaudio:hover,
      #backlight:hover,
      #battery:hover,
      #clock:hover,
      #tray:hover,
      #custom-weather:hover {
        background: @surface1;
        color: @blue;
      }

      /* ═══ Workspaces ═══ */
      #workspaces {
        padding: 2px 4px;
      }

      #workspaces button {
        color: @overlay0;
        padding: 2px 6px;
        margin: 0 2px;
        border-radius: 6px;
        background: transparent;
        border: none;
        transition: all 0.3s ease;
      }

      #workspaces button.active {
        color: @blue;
        background: @surface1;
        font-weight: bold;
      }

      #workspaces button.urgent {
        color: @red;
        background: rgba(243, 139, 168, 0.15);
      }

      /* ═══ Submap (mode actif) ═══ */
      #submap {
        background: @mauve;
        color: @base;
        font-weight: bold;
      }

      /* ═══ Fenêtre active ═══ */
      #window {
        background: transparent;
        color: @subtext1;
        font-style: italic;
      }

      /* ═══ Modules droite — couleurs individuelles ═══ */
      #clock {
        color: @lavender;
      }

      #battery {
        color: @green;
      }

      #battery.warning {
        color: @yellow;
      }

      #battery.critical {
        color: @red;
        animation: blink 1s infinite alternate;
      }

      @keyframes blink {
        to { color: @base; background: @red; }
      }

      #battery.charging {
        color: @green;
      }

      #network {
        color: @sapphire;
      }

      #network.disconnected {
        color: @red;
      }

      #bluetooth {
        color: @blue;
      }

      #pulseaudio {
        color: @mauve;
      }

      #pulseaudio.muted {
        color: @overlay0;
      }

      #backlight {
        color: @yellow;
      }

      #custom-weather {
        color: @sky;
      }

      #custom-media {
        color: @pink;
        background: transparent;
        font-style: italic;
      }

      /* ═══ Tray ═══ */
      #tray {
        color: @text;
      }

      #tray > .passive {
        -gtk-icon-effect: dim;
      }

      #tray > .needs-attention {
        -gtk-icon-effect: highlight;
        background: rgba(243, 139, 168, 0.15);
      }

      /* ═══ Tooltips ═══ */
      tooltip {
        background: @base;
        border: 1px solid @surface1;
        border-radius: 8px;
        color: @text;
      }

      tooltip label {
        color: @text;
        padding: 4px;
      }
    '';
  };

  # ── Rofi — Lanceur d'applications ──────────────────────────────
  # Remplace Wofi — beaucoup plus customisable (thèmes RASI)
  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland; # Version Wayland-native
    terminal = "kitty";

    extraConfig = {
      show-icons = true;
      icon-theme = "Papirus-Dark";
      drun-display-format = "{name}";
      disable-history = false;
      sorting-method = "fzf";
    };

    # Thème Catppuccin Mocha intégré
    theme = let
      # Palette Catppuccin Mocha
      mkLiteral = config.lib.formats.rasi.mkLiteral;
    in {
      "*" = {
        bg = mkLiteral "#1e1e2e";       # base
        bg-alt = mkLiteral "#313244";    # surface0
        fg = mkLiteral "#cdd6f4";        # text
        accent = mkLiteral "#89b4fa";    # blue
        urgent = mkLiteral "#f38ba8";    # red
      };

      window = {
        width = mkLiteral "600px";
        border = mkLiteral "2px";
        border-color = mkLiteral "@accent";
        border-radius = mkLiteral "12px";
        background-color = mkLiteral "@bg";
      };

      mainbox = {
        background-color = mkLiteral "transparent";
      };

      inputbar = {
        background-color = mkLiteral "@bg-alt";
        border-radius = mkLiteral "8px";
        padding = mkLiteral "8px 16px";
        margin = mkLiteral "12px";
        children = map mkLiteral [ "prompt" "entry" ];
      };

      prompt = {
        background-color = mkLiteral "transparent";
        text-color = mkLiteral "@accent";
      };

      entry = {
        background-color = mkLiteral "transparent";
        text-color = mkLiteral "@fg";
        placeholder = "Rechercher...";
        placeholder-color = mkLiteral "#6c7086"; # overlay0
      };

      listview = {
        columns = 1;
        lines = 8;
        background-color = mkLiteral "transparent";
        padding = mkLiteral "0 12px 12px";
      };

      element = {
        padding = mkLiteral "8px 16px";
        border-radius = mkLiteral "8px";
        background-color = mkLiteral "transparent";
      };

      "element selected" = {
        background-color = mkLiteral "@bg-alt";
        text-color = mkLiteral "@accent";
      };

      element-text = {
        text-color = mkLiteral "inherit";
        background-color = mkLiteral "transparent";
      };

      element-icon = {
        size = mkLiteral "24px";
        background-color = mkLiteral "transparent";
      };
    };
  };

  # ── SwayNC — Centre de notifications ──────────────────────────────
  # Remplace Dunst — panneau latéral avec historique, DND, groupement
  # Toggle le panneau : swaync-client -t
  # DND : swaync-client -d
  services.swaync = {
    enable = true;
    settings = {
      positionX = "right";
      positionY = "top";
      layer = "overlay";
      control-center-layer = "top";
      layer-shell = true;
      cssPriority = "application";
      control-center-margin-top = 8;
      control-center-margin-right = 8;
      control-center-width = 380;
      notification-icon-size = 48;
      notification-window-width = 380;
      timeout = 5;
      timeout-low = 3;
      timeout-critical = 0; # Les notifications critiques ne disparaissent pas
      fit-to-screen = true;
      widgets = [ "inhibitors" "title" "dnd" "notifications" ];
      widget-config = {
        title = { text = "Notifications"; clear-all-button = true; button-text = "Tout effacer"; };
        dnd = { text = "Ne pas déranger"; };
      };
    };

    # Style Catppuccin Mocha
    style = ''
      .notification-row {
        outline: none;
      }

      .notification {
        border-radius: 12px;
        margin: 4px 8px;
        padding: 0;
        border: 1px solid #313244;
        background: #1e1e2e;
        color: #cdd6f4;
      }

      .notification-content {
        padding: 8px 12px;
      }

      .close-button {
        background: #313244;
        color: #cdd6f4;
        border-radius: 50%;
        margin: 8px;
        padding: 2px;
      }

      .close-button:hover {
        background: #f38ba8;
        color: #1e1e2e;
      }

      .control-center {
        background: rgba(30, 30, 46, 0.95);
        border-radius: 16px;
        border: 1px solid #313244;
        color: #cdd6f4;
        padding: 8px;
      }

      .control-center .notification {
        background: #181825;
      }

      .widget-title {
        font-size: 16px;
        font-weight: bold;
        color: #89b4fa;
        margin: 8px 12px;
      }

      .widget-title > button {
        background: #313244;
        color: #cdd6f4;
        border-radius: 8px;
        padding: 4px 12px;
        border: none;
      }

      .widget-title > button:hover {
        background: #f38ba8;
        color: #1e1e2e;
      }

      .widget-dnd {
        margin: 4px 12px;
        color: #cdd6f4;
      }

      .widget-dnd > switch {
        background: #313244;
        border-radius: 12px;
      }

      .widget-dnd > switch:checked {
        background: #89b4fa;
      }
    '';
  };

  # ── wlogout — Menu power graphique ────────────────────────────────
  # Menu élégant pour lock, logout, suspend, reboot, shutdown
  programs.wlogout = {
    enable = true;

    layout = [
      { label = "lock";     text = "Verrouiller"; keybind = "l"; action = "hyprlock"; }
      { label = "logout";   text = "Déconnexion"; keybind = "e"; action = "hyprctl dispatch exit"; }
      { label = "suspend";  text = "Veille";      keybind = "s"; action = "systemctl suspend"; }
      { label = "reboot";   text = "Redémarrer";  keybind = "r"; action = "systemctl reboot"; }
      { label = "shutdown"; text = "Éteindre";    keybind = "p"; action = "systemctl poweroff"; }
      { label = "hibernate"; text = "Hiberner";   keybind = "h"; action = "systemctl hibernate"; }
    ];

    # Style Catppuccin Mocha
    style = ''
      * {
        background-image: none;
        font-family: "JetBrainsMono Nerd Font";
        font-size: 14px;
      }

      window {
        background-color: rgba(30, 30, 46, 0.85);
      }

      button {
        color: #cdd6f4;
        background-color: #313244;
        border: 2px solid #45475a;
        border-radius: 16px;
        background-repeat: no-repeat;
        background-position: center;
        background-size: 25%;
        margin: 8px;
      }

      button:hover {
        background-color: #45475a;
        border-color: #89b4fa;
      }

      button:focus {
        background-color: #45475a;
        border-color: #cba6f7;
      }

      #lock {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/lock.png"));
      }
      #logout {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/logout.png"));
      }
      #suspend {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/suspend.png"));
      }
      #reboot {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/reboot.png"));
      }
      #shutdown {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/shutdown.png"));
      }
      #hibernate {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/hibernate.png"));
      }
    '';
  };

  # ── Cava — Visualiseur audio dans le terminal ─────────────────────
  # Affiche des barres audio réactives à la musique (pur esthétique)
  # Lancer avec : cava
  programs.cava = {
    enable = true;
    settings = {
      general = {
        framerate = 60;
        bars = 12;
        bar_width = 2;
        bar_spacing = 1;
      };

      input = {
        method = "pipewire";
        source = "auto";
      };

      output = {
        method = "ncurses";
      };

      # Gradient Catppuccin Mocha (rosewater → mauve)
      color = {
        gradient = 1;
        gradient_count = 6;
        gradient_color_1 = "'#f5e0dc'"; # rosewater
        gradient_color_2 = "'#f2cdcd'"; # flamingo
        gradient_color_3 = "'#f5c2e7'"; # pink
        gradient_color_4 = "'#cba6f7'"; # mauve
        gradient_color_5 = "'#89b4fa'"; # blue
        gradient_color_6 = "'#94e2d5'"; # teal
      };

      smoothing = {
        noise_reduction = 77;
      };
    };
  };

  # ── Wallpaper timer — Rotation automatique toutes les 30min ───────
  systemd.user.services.wallpaper-rotation = {
    Unit = {
      Description = "Rotation automatique du wallpaper via swww";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      # ← ADAPTER : chemin vers votre dossier de wallpapers
      ExecStart = toString (pkgs.writeShellScript "wallpaper-rotate" ''
        WALLPAPER=$(find ~/Pictures/wallpapers/ -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.webp" \) | shuf -n 1)
        if [ -n "$WALLPAPER" ]; then
          ${pkgs.swww}/bin/swww img "$WALLPAPER" \
            --transition-type random \
            --transition-duration 2 \
            --transition-fps 60
        fi
      '');
    };
  };

  systemd.user.timers.wallpaper-rotation = {
    Unit.Description = "Timer pour la rotation de wallpaper";
    Timer = {
      OnActiveSec = "30min";    # Première exécution 30min après le login
      OnUnitActiveSec = "30min"; # Puis toutes les 30min
      Unit = "wallpaper-rotation.service";
    };
    Install.WantedBy = [ "timers.target" ];
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
