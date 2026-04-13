# ╔══════════════════════════════════════════════════════════════════╗
# ║  Plymouth — Boot splash screen                                 ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Affiche un écran de démarrage élégant au lieu d'un écran noir
# avec du texte de log pendant le boot.
#
# Le thème utilise les plymouth themes de adi1090x qui offrent
# de nombreuses animations (rings, loader, spin, etc.)
#
# ⚠️ Pour un boot complètement silencieux, les kernel params
#    "quiet" et "splash" sont ajoutés automatiquement.

{ config, pkgs, lib, ... }:
let
  # Thèmes Plymouth avec de nombreuses animations
  # ← ADAPTER : changer le thème parmi : rings, loader, spin, hexa_retro, etc.
  plymouthTheme = "rings";
in
{
  boot.plymouth = {
    enable = true;
    theme = plymouthTheme;
    themePackages = [
      # Collection de thèmes Plymouth stylisés
      (pkgs.adi1090x-plymouth-themes.override {
        selected_themes = [ plymouthTheme ];
      })
    ];
  };

  # ── Boot silencieux ──────────────────────────────────────────────
  # Masquer les messages de log pendant le démarrage pour un boot propre
  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;
  boot.kernelParams = [
    "quiet"
    "splash"
    "boot.shell_on_fail"       # Shell de secours en cas d'échec (utile pour le debug)
    "loglevel=3"               # Réduire la verbosité du noyau
    "udev.log_level=3"         # Réduire la verbosité d'udev
    "rd.systemd.show_status=false" # Masquer le statut systemd dans l'initrd
  ];
}
