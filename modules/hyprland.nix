# ╔══════════════════════════════════════════════════════════════════╗
# ║  Hyprland — Compositeur Wayland (niveau système)               ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Ce module configure Hyprland au niveau système :
# - Installation du compositeur et activation de XWayland
# - SDDM comme gestionnaire de connexion (en mode Wayland)
# - Portails XDG pour screenshare, file picker, etc.
# - Paquets système nécessaires au WM
#
# ⚠️ La configuration UTILISATEUR de Hyprland est dans home/hyprland.nix
#    (keybinds, apparence, moniteurs, waybar, etc.)

{ config, pkgs, inputs, ... }: {

  # ── Hyprland ─────────────────────────────────────────────────────
  programs.hyprland = {
    enable = true;
    xwayland.enable = true; # Support des applications X11

    # ← ADAPTER : décommenter pour utiliser la version du flake Hyprland
    # (plus récente que celle de nixpkgs, mais peut être moins stable)
    # package = inputs.hyprland.packages.${pkgs.system}.hyprland;
  };

  # ── SDDM — Gestionnaire de connexion ────────────────────────────
  # Note : le thème SDDM est géré par Stylix, ne pas le définir ici
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true; # SDDM en mode Wayland natif
  };

  # ── Portails XDG ─────────────────────────────────────────────────
  # Nécessaires pour le partage d'écran, les dialogues de fichiers,
  # et l'intégration avec les applications Flatpak/Electron
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland # Portail spécifique Hyprland
      pkgs.xdg-desktop-portal-gtk      # Fallback GTK (file dialogs, etc.)
    ];
  };

  # ── Sécurité ─────────────────────────────────────────────────────
  security.polkit.enable = true;  # Authentification graphique (ex: mount disques)
  security.rtkit.enable = true;   # Priorité temps-réel pour PipeWire

  # ── Paquets système pour l'environnement Hyprland ────────────────
  environment.systemPackages = with pkgs; [
    # Terminal
    kitty

    # Barre de statut
    waybar

    # Lanceur d'applications
    wofi

    # Notifications
    dunst

    # Fond d'écran
    hyprpaper

    # Captures d'écran
    grim                    # Capture d'écran
    slurp                   # Sélection de zone
    wl-clipboard            # Presse-papier Wayland

    # Verrouillage d'écran et inactivité
    hyprlock
    hypridle

    # Gestionnaire de fichiers
    nautilus

    # Agent d'authentification Polkit (pop-up mot de passe)
    polkit_gnome

    # Applets système (tray)
    networkmanagerapplet    # Réseau
    blueman                 # Bluetooth

    # Contrôle multimédia
    playerctl               # Lecture/pause/suivant
    light                   # Luminosité écran (nécessite programs.light)
  ];

  # Permettre le contrôle de la luminosité sans sudo
  programs.light.enable = true;
}
