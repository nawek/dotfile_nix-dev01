# ╔══════════════════════════════════════════════════════════════════╗
# ║  Hardware Configuration — Placeholder                          ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# ⚠️  CE FICHIER EST UN PLACEHOLDER !
#
# Remplacez-le par la sortie de la commande suivante
# (exécutée sur la machine cible après le boot sur l'ISO NixOS) :
#
#   sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix
#
# Cette commande détecte automatiquement :
# - Les modules noyau nécessaires (chipset, stockage, réseau)
# - Le type de CPU (Intel/AMD)
# - Les périphériques PCI/USB
# - La configuration des systèmes de fichiers
#
# ⚠️ Ne PAS déclarer de fileSystems ici — Disko s'en charge !
#    Supprimez les sections fileSystems générées automatiquement.

{ config, lib, pkgs, modulesPath, ... }: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # ── Modules noyau ────────────────────────────────────────────────
  # ← ADAPTER : ces valeurs sont des exemples pour un laptop récent
  boot.initrd.availableKernelModules = [
    "xhci_pci"     # USB 3.0
    "ahci"         # SATA
    "nvme"         # NVMe SSD
    "usb_storage"  # Clés USB
    "sd_mod"       # Disques SCSI/SATA
  ];

  boot.kernelModules = [
    "kvm-intel"    # ← ADAPTER : "kvm-amd" pour processeur AMD
  ];

  # ← ADAPTER : décommenter pour firmware propriétaire (WiFi, etc.)
  # hardware.enableRedistributableFirmware = true;

  # ← ADAPTER : décommenter pour le microcode CPU
  # hardware.cpu.intel.updateMicrocode = true;   # Pour Intel
  # hardware.cpu.amd.updateMicrocode = true;     # Pour AMD
}
