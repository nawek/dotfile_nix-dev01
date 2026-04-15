#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  Rescue — Procédure de récupération si le système ne boot plus  ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Ce script affiche les instructions de récupération.
# À lire depuis un autre device ou imprimé.

cat << 'RESCUE'

╔══════════════════════════════════════════════════════════════════╗
║  CITADEL — Procédure de récupération                             ║
╚══════════════════════════════════════════════════════════════════╝

1. BOOTER SUR L'ISO NIXOS
   → Clé USB NixOS, booter dessus

2. OUVRIR LE VOLUME LUKS
   sudo cryptsetup open /dev/nvme0n1p2 cryptroot
   # Taper le mot de passe LUKS

3. MONTER LES SUBVOLUMES
   sudo mount -o subvol=@ /dev/mapper/cryptroot /mnt
   sudo mount -o subvol=@home /dev/mapper/cryptroot /mnt/home
   sudo mount -o subvol=@nix /dev/mapper/cryptroot /mnt/nix
   sudo mount -o subvol=@persist /dev/mapper/cryptroot /mnt/persist
   sudo mount /dev/nvme0n1p1 /mnt/boot

4A. ROLLBACK — Revenir à une génération précédente
   # Lister les générations disponibles
   ls /mnt/nix/var/nix/profiles/system-*-link

   # Activer une ancienne génération
   sudo nixos-enter --root /mnt
   nixos-rebuild switch --rollback
   exit

4B. ROLLBACK BTRFS — Restaurer un ancien snapshot root
   # Lister les anciens snapshots root
   sudo mount -o subvol=/ /dev/mapper/cryptroot /mnt2
   ls /mnt2/@.old/

   # Restaurer un snapshot
   sudo mv /mnt2/@ /mnt2/@.broken
   sudo btrfs subvolume snapshot /mnt2/@.old/<TIMESTAMP> /mnt2/@
   sudo umount /mnt2

4C. CHROOT — Réparer manuellement
   sudo nixos-enter --root /mnt
   # Tu es maintenant dans le système installé
   # Éditer la config, rebuild, etc.
   nixos-rebuild switch --flake /etc/nixos#kuro
   exit

5. REBOOT
   sudo umount -R /mnt
   sudo reboot

── RÉCUPÉRER LES DONNÉES ──────────────────────────────────────

Si le système est irrécupérable mais les données sont intactes :
   # Les données persistantes sont dans /mnt/persist/
   # Le home est dans /mnt/home/
   # Copier sur une clé USB :
   sudo cp -r /mnt/persist/home/kuro/Documents /media/usb/backup/

── CONTACTS ───────────────────────────────────────────────────

Config NixOS : https://github.com/nawek/dotfile_nix-dev01
NixOS Manual : https://nixos.org/manual/nixos/stable/

RESCUE
