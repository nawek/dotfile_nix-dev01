# ╔══════════════════════════════════════════════════════════════════╗
# ║  Impermanence — Effacement root au boot + persistance          ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# À chaque démarrage, le subvolume @ (racine) est effacé et recréé.
# Seuls les fichiers/dossiers déclarés ici survivent via /persist.
# Les 3 derniers snapshots de l'ancienne racine sont conservés.
#
# ⚠️ La persistance UTILISATEUR est dans home/default.nix
#    Ce fichier ne gère que la persistance SYSTÈME.

{ config, lib, pkgs, ... }: {

  # ── Script d'effacement de la racine au boot ─────────────────────
  # Exécuté dans l'initrd, avant le montage final du système
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    mkdir -p /btrfs_tmp

    # Vérifier que le device LUKS est disponible
    if [ ! -e /dev/mapper/cryptroot ]; then
      echo "ERREUR : /dev/mapper/cryptroot introuvable. Abandon du wipe root."
      echo "Le système va démarrer avec l'ancienne racine."
    else

    # Monter la partition BTRFS (déchiffrée via LUKS) pour accéder aux subvolumes
    # Le nom "cryptroot" correspond au champ "name" dans disko.nix
    mount -o subvol=/ /dev/mapper/cryptroot /btrfs_tmp

    # Si le subvolume @ existe, le sauvegarder avant suppression
    if [[ -e /btrfs_tmp/@ ]]; then
      mkdir -p /btrfs_tmp/@.old
      timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/@)" "+%Y-%m-%d_%H:%M:%S")
      mv /btrfs_tmp/@ "/btrfs_tmp/@.old/$timestamp"
    fi

    # Garder uniquement les 3 derniers snapshots de l'ancienne racine
    # Suppression récursive des plus anciens
    delete_subvolume_recursively() {
      IFS=$'\n'
      for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
        delete_subvolume_recursively "/btrfs_tmp/$i"
      done
      btrfs subvolume delete "$1"
    }

    for i in $(find /btrfs_tmp/@.old/ -maxdepth 1 -mindepth 1 -type d | sort | head -n -3); do
      echo "Suppression de l'ancien snapshot : $i"
      delete_subvolume_recursively "$i"
    done

    # Créer un nouveau subvolume @ vierge
    echo "Création d'un nouveau subvolume @ vierge"
    btrfs subvolume create /btrfs_tmp/@
    umount /btrfs_tmp

    fi # fin du check /dev/mapper/cryptroot
  '';

  # ── Persistance système ──────────────────────────────────────────
  # Tout ce qui est listé ici est bind-mounté depuis /persist/system
  # vers son emplacement normal dans l'arborescence
  environment.persistence."/persist/system" = {
    hideMounts = true; # Cache les montages bind dans le gestionnaire de fichiers

    directories = [
      # Configuration NixOS
      "/etc/nixos"

      # Connexions réseau sauvegardées
      "/etc/NetworkManager/system-connections"

      # Logs système (important pour le debug)
      "/var/log"

      # Bluetooth — appairages sauvegardés
      "/var/lib/bluetooth"

      # État interne NixOS (UIDs/GIDs persistants)
      "/var/lib/nixos"

      # Données Docker (conteneurs, images, volumes)
      "/var/lib/docker"

      # Snapshots btrbk
      "/var/lib/btrbk"

      # État PipeWire (volumes audio, etc.)
      "/var/lib/pipewire"

      # Core dumps système
      "/var/lib/systemd/coredump"

      # Secure Boot PKI (lanzaboote)
      "/etc/secureboot"

      # ── Services réseau ──────────────────────────────────────────
      # Tailscale — clés VPN, état des peers
      "/var/lib/tailscale"

      # ── Services sécurité ────────────────────────────────────────
      # Fail2ban — base de données des bans
      "/var/lib/fail2ban"

      # ClamAV — signatures antivirus (évite de re-télécharger à chaque boot)
      "/var/lib/clamav"
    ];

    files = [
      # Identifiant unique de la machine (dbus, journald, etc.)
      "/etc/machine-id"

      # Clés SSH du serveur — DOIVENT persister sinon changent à chaque boot
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];
  };

  # ── Options critiques pour l'impermanence ────────────────────────

  # /persist doit être monté tôt dans le boot (avant les services)
  fileSystems."/persist".neededForBoot = true;

  # Nécessaire pour les bind mounts de Home Manager impermanence
  programs.fuse.userAllowOther = true;

  # Empêcher la modification des mots de passe en dehors de la config
  # Les mots de passe sont gérés via sops-nix
  users.mutableUsers = false;
}
