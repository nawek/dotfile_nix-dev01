# ╔══════════════════════════════════════════════════════════════════╗
# ║  UX — Confort quotidien et automatisations utilisateur          ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Améliorations UX pour un Linux agréable au quotidien :
# - Auto-mount USB (udiskie)
# - Screen recording (wf-recorder)
# - Noise cancellation micro (PipeWire)
# - CUPS imprimante
# - Flatpak pour les apps propriétaires
# - Wine/Bottles pour les apps Windows
# - Auto-login après LUKS
# - XDG default apps déclaratifs
# - Firmware updates (fwupd)
# - Kernel tuning laptop

{ config, pkgs, lib, ... }: {

  # ══════════════════════════════════════════════════════════════════
  # 1. AUTO-MOUNT USB — udiskie + udisks2
  # ══════════════════════════════════════════════════════════════════
  # Les clés USB se montent automatiquement avec notification
  services.udisks2.enable = true;
  # udiskie est lancé dans l'autostart Hyprland (home/hyprland.nix)

  # ══════════════════════════════════════════════════════════════════
  # 2. CUPS — Support imprimante
  # ══════════════════════════════════════════════════════════════════
  services.printing = {
    enable = true;
    drivers = with pkgs; [
      gutenprint          # Drivers génériques
      # hplip             # Optionnel : décommenter pour imprimantes HP
    ];
  };
  # Interface web : http://localhost:631

  # ══════════════════════════════════════════════════════════════════
  # 3. FLATPAK — Apps propriétaires isolées
  # ══════════════════════════════════════════════════════════════════
  # Pour les apps pas dans nixpkgs (Slack desktop, Figma, etc.)
  # Usage : flatpak install flathub com.slack.Slack
  services.flatpak.enable = true;

  # ══════════════════════════════════════════════════════════════════
  # 4. AUTO-LOGIN après LUKS
  # ══════════════════════════════════════════════════════════════════
  # Le mot de passe LUKS est déjà tapé au boot — pas besoin de
  # le retaper sur SDDM. Hyprlock verrouille quand on s'absente.
  services.displayManager.autoLogin = {
    enable = true;
    user = "kuro"; # ← ADAPTER
  };

  # ══════════════════════════════════════════════════════════════════
  # 5. NOISE CANCELLATION — PipeWire
  # ══════════════════════════════════════════════════════════════════
  # Suppression du bruit de fond du micro pour les visioconférences
  # Activé automatiquement pour toutes les applications
  # Optionnel : décommenter si le paquet est dispo dans votre nixpkgs
  # environment.systemPackages = [ pkgs.noise-suppression-for-voice ];

  # ══════════════════════════════════════════════════════════════════
  # 6. FIRMWARE UPDATES — fwupd
  # ══════════════════════════════════════════════════════════════════
  # Met à jour le firmware UEFI/SSD/périphériques automatiquement
  # Usage : sudo fwupdmgr refresh && sudo fwupdmgr update
  services.fwupd.enable = true;

  # ══════════════════════════════════════════════════════════════════
  # 7. KERNEL TUNING — Optimisations laptop dev
  # ══════════════════════════════════════════════════════════════════
  boot.kernel.sysctl = {
    # Réduire le swappiness (garder plus en RAM, moins de swap)
    "vm.swappiness" = 10;
    # Augmenter les watchers inotify (gros projets Node/VSCode)
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 1024;
    # Augmenter le nombre max de fichiers ouverts
    "fs.file-max" = 2097152;
  };

  # ══════════════════════════════════════════════════════════════════
  # 8. WINE — Apps Windows (via Bottles)
  # ══════════════════════════════════════════════════════════════════
  environment.systemPackages = with pkgs; [
    bottles             # GUI pour gérer les prefix Wine
    wf-recorder         # Screen recording Wayland
    udiskie             # Auto-mount USB (GUI-less, tray icon)
    tesseract           # OCR (extraction de texte depuis images)
    translate-shell     # Traduction en CLI (trad "texte")
    qrencode            # Générateur de QR codes
    wakeonlan           # Wake-on-LAN pour le homelab
    # newsboat est géré par programs.newsboat dans home/default.nix
    cowsay              # Message du jour fun
    fortune             # Citations aléatoires
  ];
}
