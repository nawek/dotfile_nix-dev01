# ╔══════════════════════════════════════════════════════════════════╗
# ║  Disko — Partitionnement déclaratif BTRFS + LUKS               ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Ce module déclare le schéma de partitionnement du disque.
# Disko génère automatiquement les fileSystems correspondants.
# ⚠️ Ne PAS déclarer de fileSystems ailleurs dans la config !
#
# Structure :
#   /dev/nvme0n1
#   ├── p1 : ESP (512M, vfat) → /boot
#   └── p2 : LUKS (chiffré) → cryptroot
#       └── BTRFS
#           ├── @          → /          (racine, effacée à chaque boot)
#           ├── @home      → /home
#           ├── @nix       → /nix
#           ├── @persist   → /persist   (données persistantes)
#           ├── @snapshots → /.snapshots
#           └── @swap      → /swap      (swapfile 8G)
#
# ── Chiffrement LUKS ──────────────────────────────────────────────
# Le disque entier (sauf /boot) est chiffré avec LUKS2.
# Un mot de passe est demandé au démarrage pour déverrouiller.
#
# Pour ajouter une clé de déchiffrement supplémentaire :
#   sudo cryptsetup luksAddKey /dev/nvme0n1p2
#
# ⚠️ Si vous ne voulez PAS de chiffrement, remplacez le contenu
#    de la partition "root" par le type "btrfs" directement
#    (voir l'historique Git pour l'ancienne version sans LUKS).

{ ... }: {
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1"; # ← ADAPTER : chemin du disque (lsblk pour vérifier)
        content = {
          type = "gpt";
          partitions = {

            # ── Partition EFI (boot) — NON chiffrée ───────────────
            ESP = {
              size = "512M";
              type = "EF00"; # Type EFI System Partition
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "defaults" ];
              };
            };

            # ── Partition chiffrée LUKS ───────────────────────────
            root = {
              size = "100%"; # Tout l'espace restant
              content = {
                type = "luks";
                name = "cryptroot"; # Nom du device mapper → /dev/mapper/cryptroot

                # Options LUKS
                extraOpenArgs = [
                  "--allow-discards"   # Nécessaire pour TRIM sur SSD
                  "--perf-no_read_workqueue"
                  "--perf-no_write_workqueue"
                ];

                # ← ADAPTER : décommenter pour utiliser un fichier clé en plus du mot de passe
                # (utile pour éviter de taper le mot de passe à chaque boot)
                # settings.keyFile = "/path/to/keyfile";

                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ]; # Forcer le formatage

                  subvolumes = {
                    # Racine — effacée à chaque boot par impermanence
                    "@" = {
                      mountpoint = "/";
                      mountOptions = [ "compress=zstd:1" "noatime" ];
                    };

                    # Home — données utilisateur
                    "@home" = {
                      mountpoint = "/home";
                      mountOptions = [ "compress=zstd:1" "noatime" ];
                    };

                    # Nix store — paquets et dérivations
                    "@nix" = {
                      mountpoint = "/nix";
                      mountOptions = [ "compress=zstd:1" "noatime" ];
                    };

                    # Persist — données qui survivent au wipe root
                    "@persist" = {
                      mountpoint = "/persist";
                      mountOptions = [ "compress=zstd:1" "noatime" ];
                    };

                    # Snapshots — stockage des snapshots btrbk
                    "@snapshots" = {
                      mountpoint = "/.snapshots";
                      mountOptions = [ "compress=zstd:1" "noatime" ];
                    };

                    # Swap — fichier de swap
                    "@swap" = {
                      mountpoint = "/swap";
                      mountOptions = [ "noatime" ];
                      swap = {
                        swapfile.size = "8G";
                      };
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };

  # ── Auto-scrub BTRFS hebdomadaire ────────────────────────────────
  # Vérifie l'intégrité des données et corrige les erreurs
  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
    fileSystems = [ "/" ]; # Tous les subvolumes partagent le même FS
  };
}
