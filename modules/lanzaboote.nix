# ╔══════════════════════════════════════════════════════════════════╗
# ║  Lanzaboote — Secure Boot pour NixOS                          ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Lanzaboote remplace systemd-boot pour signer les images de boot
# et permettre le Secure Boot avec NixOS.
#
# ── Procédure d'installation initiale ──────────────────────────────
#
# 1. Premier boot SANS Secure Boot (désactivé dans le BIOS)
# 2. Après nixos-install et reboot :
#      sudo sbctl create-keys
#    → Crée les clés PKI dans /persist/system/secureboot (pkiBundle)
#
# 3. Vérifier que tous les fichiers sont signés :
#      sudo sbctl verify
#
# 4. Redémarrer dans le BIOS, activer Secure Boot en mode "Setup"
#
# 5. Enrôler les clés (inclut les clés Microsoft pour l'UEFI) :
#      sudo sbctl enroll-keys --microsoft
#
# 6. Redémarrer — Secure Boot est actif !
#      bootctl status  # pour vérifier
#
# ⚠️ Le dossier /etc/secureboot est persisté via impermanence.nix

{ config, lib, pkgs, ... }: {

  # Désactiver systemd-boot — Lanzaboote le remplace
  # mkForce est nécessaire car systemd-boot est souvent activé par défaut
  boot.loader.systemd-boot.enable = lib.mkForce false;

  # Activer Lanzaboote
  boot.lanzaboote = {
    enable = true;
    # Emplacement des clés PKI (sur partition persistante)
    pkiBundle = "/etc/secureboot"; # Persisté via impermanence → /persist/system/etc/secureboot
  };

  # Garder systemd-boot comme fallback en cas de problème
  boot.loader.efi.canTouchEfiVariables = true;

  # Outil CLI pour gérer les clés Secure Boot
  environment.systemPackages = [ pkgs.sbctl ];
}
