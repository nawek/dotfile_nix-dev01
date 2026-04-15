# ╔══════════════════════════════════════════════════════════════════╗
# ║  NVIDIA — Pilotes propriétaires pour Wayland                   ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Configuration des pilotes NVIDIA propriétaires optimisée pour
# un usage avec Hyprland (Wayland). Les variables d'environnement
# sont définies au niveau SYSTÈME car le display manager (SDDM)
# en a besoin avant le démarrage de la session utilisateur.
#
# ⚠️ Ne PAS dupliquer ces variables dans Home Manager !

{ config, lib, pkgs, ... }: {

  # ── Pilotes NVIDIA ───────────────────────────────────────────────

  # Toujours nécessaire même sous Wayland (charge le bon module noyau)
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # Modesetting obligatoire pour Wayland
    modesetting.enable = true;

    # Gestion de l'alimentation (important pour laptop)
    powerManagement.enable = true;
    powerManagement.finegrained = false; # ← ADAPTER : true pour NVIDIA Optimus (hybrid GPU)

    # Pilotes open-source NVIDIA (kernel module)
    # Optionnel : passer à true si GPU >= RTX 20xx (Turing+)
    # Les pilotes open sont plus stables pour suspend/resume sur les GPU récents
    open = false; # ⚠️ true recommandé pour RTX 20xx+

    # Panneau de configuration NVIDIA
    nvidiaSettings = true;

    # Version du driver — stable est le choix le plus sûr
    # .beta pour la dernière version, .production pour LTS
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # ── Accélération graphique ───────────────────────────────────────
  # Remplace hardware.opengl depuis NixOS 24.11
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Support 32 bits (Wine, Steam, etc.)
  };

  # ── Variables d'environnement Wayland + NVIDIA ───────────────────
  # Critiques pour le bon fonctionnement de Hyprland avec NVIDIA
  environment.sessionVariables = {
    # Electron/Chrome/VSCode en mode Wayland natif
    NIXOS_OZONE_WL = "1";

    # Correction du curseur invisible sur certains GPU NVIDIA
    WLR_NO_HARDWARE_CURSORS = "1";

    # Backend GBM pour NVIDIA (nécessaire pour Wayland)
    GBM_BACKEND = "nvidia-drm";

    # Forcer l'utilisation de la bibliothèque GLX NVIDIA
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";

    # Accélération vidéo matérielle via NVIDIA
    LIBVA_DRIVER_NAME = "nvidia";
  };

  # ── Paramètres noyau ─────────────────────────────────────────────
  # nvidia-drm.modeset=1 : active le modesetting DRM (obligatoire Wayland)
  # nvidia-drm.fbdev=1   : framebuffer NVIDIA pour la console TTY
  boot.kernelParams = lib.mkAfter [
    "nvidia-drm.modeset=1"
    "nvidia-drm.fbdev=1"
  ];

  # Charger les modules NVIDIA tôt dans le boot (initrd)
  # Nécessaire pour avoir un affichage dès le démarrage
  boot.initrd.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];
}
