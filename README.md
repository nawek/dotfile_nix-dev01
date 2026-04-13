# NixOS Configuration — Kuro

Configuration NixOS complète, modulaire et reproductible pour PC de développement (laptop).

## Architecture

```
nixos-config/
├── flake.nix                        # Point d'entrée : inputs, outputs, devShells
├── .sops.yaml                       # Règles de chiffrement SOPS
├── hosts/kuro/
│   ├── configuration.nix            # Config système principale
│   └── hardware-configuration.nix   # Hardware (placeholder → nixos-generate-config)
├── modules/
│   ├── disko.nix                    # Partitionnement BTRFS déclaratif (6 subvolumes)
│   ├── impermanence.nix             # Effacement root au boot + persistance système
│   ├── lanzaboote.nix               # Secure Boot
│   ├── nvidia.nix                   # GPU NVIDIA propriétaire (Wayland)
│   ├── hyprland.nix                 # Compositeur Wayland + SDDM
│   ├── stylix.nix                   # Thème Catppuccin Mocha global
│   └── sops.nix                     # Secrets chiffrés (age)
├── home/
│   ├── default.nix                  # Home Manager + persistance utilisateur
│   ├── shell.nix                    # ZSH, starship, atuin, direnv, fzf, zoxide
│   ├── git.nix                      # Git, delta, GitHub CLI
│   ├── hyprland.nix                 # Config Hyprland utilisateur (keybinds, waybar, etc.)
│   ├── vscode.nix                   # VSCode + extensions déclaratives
│   └── dev-tools.nix                # Outils CLI de développement
├── devshells/
│   ├── python.nix                   # Python 3.12 + ruff + pyright
│   ├── node.nix                     # Node 22 + pnpm + TypeScript
│   ├── rust.nix                     # Rust stable via Fenix + rust-analyzer
│   └── example.envrc                # Exemple pour direnv
└── secrets/
    └── secrets.yaml                 # Secrets (placeholder → chiffrer avec sops)
```

## Prérequis

- Clé USB avec l'ISO NixOS (minimal ou graphique)
- Accès Internet pour télécharger les paquets
- PC avec GPU NVIDIA (pour cette config spécifique)

## Installation

### 1. Booter sur l'ISO NixOS

Démarrer sur la clé USB NixOS. Ouvrir un terminal.

### 2. Connexion réseau

```bash
# WiFi (si nécessaire)
sudo nmcli device wifi connect "SSID" password "mot-de-passe"

# Vérifier la connexion
ping -c 3 nixos.org
```

### 3. Partitionnement avec Disko

```bash
# Cloner la configuration
sudo nix --experimental-features "nix-command flakes" run \
  github:nix-community/disko -- \
  --mode disko ./modules/disko.nix
```

> **Important** : Vérifier que le device dans `modules/disko.nix` correspond à votre disque (`lsblk`).

### 4. Générer la configuration hardware

```bash
# Générer et remplacer le placeholder
sudo nixos-generate-config --show-hardware-config > hosts/kuro/hardware-configuration.nix
```

> **Important** : Supprimer les sections `fileSystems` générées — Disko les gère.

### 5. Installer NixOS

```bash
# Copier la config dans /mnt
sudo cp -r . /mnt/etc/nixos/

# Installer
sudo nixos-install --flake /mnt/etc/nixos#kuro

# Définir le mot de passe root temporaire
# (le mot de passe utilisateur sera géré par sops après le premier boot)
```

### 6. Redémarrer

```bash
sudo reboot
```

## Post-installation

### Configurer SOPS (secrets)

```bash
# 1. Générer une clé age
sudo mkdir -p /persist/system
sudo age-keygen -o /persist/system/sops-age-keys.txt

# 2. Copier la clé publique (age1...) affichée
#    La coller dans .sops.yaml à la place du placeholder

# 3. Générer le hash du mot de passe
mkpasswd -m sha-512 "votre_mot_de_passe"

# 4. Créer/éditer les secrets (l'éditeur s'ouvre, modifier les valeurs)
sops secrets/secrets.yaml

# 5. Rebuild pour appliquer
sudo nixos-rebuild switch --flake .#kuro
```

### Configurer Lanzaboote (Secure Boot)

```bash
# 1. Première fois : créer les clés
sudo sbctl create-keys

# 2. Vérifier la signature des fichiers
sudo sbctl verify

# 3. Redémarrer dans le BIOS → activer Secure Boot en mode "Setup"

# 4. Enrôler les clés (inclut les clés Microsoft)
sudo sbctl enroll-keys --microsoft

# 5. Redémarrer → Secure Boot actif !
bootctl status
```

### Configurer le wallpaper Stylix

```bash
# Option 1 : Image locale
# Modifier modules/stylix.nix :
#   image = /persist/home/kuro/Pictures/wallpaper.jpg;

# Option 2 : URL (recalculer le hash)
nix-prefetch-url "https://url-de-votre-image.jpg"
# Mettre le hash dans modules/stylix.nix
```

## Usage quotidien

### Rebuild NixOS

```bash
# Via nh (recommandé — affichage coloré + diff)
nrs           # nh os switch (rebuild + switch)
nrt           # nh os test (rebuild sans switch permanent)
nrb           # nh os boot (rebuild pour le prochain boot)

# Via nixos-rebuild classique
sudo nixos-rebuild switch --flake .#kuro
```

### Mettre à jour les inputs

```bash
nfu           # nix flake update
nrs           # Rebuild après la mise à jour
```

### Nettoyage

```bash
ngc           # nh clean all (supprime les anciennes générations + GC)
```

### Rechercher un paquet

```bash
nsg firefox   # nix search nixpkgs firefox
nsh firefox   # nix-shell -p firefox (test temporaire sans installer)
```

### Comma — Exécuter un programme sans l'installer

```bash
, cowsay "Hello NixOS!"   # Télécharge, exécute, ne persiste pas
```

### Dev Shells — Environnements de développement isolés

```bash
# Entrer dans un shell de développement
nix develop .#python    # Python 3.12 + ruff + pyright
nix develop .#node      # Node 22 + pnpm + TypeScript
nix develop .#rust      # Rust stable + rust-analyzer

# Avec direnv (automatique en entrant dans le dossier)
cd mon-projet-python/
echo "use flake /home/kuro/nixos-config#python" > .envrc
direnv allow
# L'environnement se charge automatiquement !
```

### Docker

```bash
dc            # docker compose
dcu           # docker compose up -d
dcd           # docker compose down
dcl           # docker compose logs -f
dps           # docker ps (formaté)
ld            # lazydocker (TUI)
```

### Git

```bash
gs            # git status
gp            # git push
gpl           # git pull
gc            # git commit
gl            # git log --oneline --graph -20
lg            # lazygit (TUI)
```

## Configuration des moniteurs

Les moniteurs se configurent dans `home/hyprland.nix` :

```nix
monitor = [
  "eDP-1, preferred, 0x0, 1"       # Laptop
  ", preferred, auto-right, 1"      # Externe (auto-détecté)
];
```

Pour connaître les noms de vos moniteurs :

```bash
hyprctl monitors
```

Pour une configuration spécifique :

```nix
monitor = [
  "eDP-1, 1920x1080@60, 0x0, 1"
  "HDMI-A-1, 2560x1440@144, 1920x0, 1"
];
```

## Debug impermanence

### Vérifier ce qui est persisté

```bash
# Voir les montages bind d'impermanence
mount | grep persist

# Vérifier les snapshots de l'ancienne racine
sudo ls /.snapshots/
sudo ls /btrfs_tmp/@.old/ 2>/dev/null || echo "Pas de snapshots (normal après boot)"
```

### Si quelque chose manque après un reboot

1. Le fichier/dossier n'est probablement pas dans la liste de persistance
2. Ajouter le chemin dans :
   - `modules/impermanence.nix` (pour le système)
   - `home/default.nix` (pour l'utilisateur)
3. Rebuild : `nrs`

### Récupérer des données depuis un ancien snapshot

```bash
# Monter le subvolume racine BTRFS
sudo mount -o subvol=/ /dev/nvme0n1p2 /mnt

# Lister les anciens snapshots
ls /mnt/@.old/

# Copier le fichier nécessaire
sudo cp /mnt/@.old/<timestamp>/chemin/vers/fichier /destination/
sudo umount /mnt
```

## Rollback NixOS

```bash
# Lister les générations disponibles
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Revenir à une génération précédente au prochain boot
sudo nixos-rebuild switch --rollback

# Ou depuis le menu de boot (GRUB/systemd-boot) :
# Sélectionner une ancienne génération
```

## Snapshots btrbk

```bash
# Lister les snapshots
sudo btrbk list

# Snapshot manuel
sudo btrbk snapshot

# Les snapshots sont dans /.snapshots/persist/ et /.snapshots/home/
ls /.snapshots/persist/
ls /.snapshots/home/
```

## Valeurs à adapter

Recherchez `← ADAPTER` dans les fichiers pour trouver toutes les valeurs à personnaliser :

```bash
grep -r "ADAPTER" --include="*.nix" .
```

Éléments principaux à adapter :
- `modules/disko.nix` : device disque (`/dev/nvme0n1`)
- `modules/nvidia.nix` : `open = true` si GPU >= RTX 20xx
- `modules/stylix.nix` : wallpaper
- `hosts/kuro/hardware-configuration.nix` : remplacer par `nixos-generate-config`
- `home/git.nix` : email et clé SSH
- `.sops.yaml` : clé publique age
- `secrets/secrets.yaml` : chiffrer avec `sops`

## Raccourcis clavier Hyprland

| Raccourci | Action |
|---|---|
| `Super + Entrée` | Ouvrir Kitty (terminal) |
| `Super + D` | Lanceur d'applications (Wofi) |
| `Super + Q` | Fermer la fenêtre |
| `Super + V` | Basculer flottant |
| `Super + F` | Plein écran |
| `Super + L` | Verrouiller l'écran |
| `Super + E` | Gestionnaire de fichiers |
| `Super + H/J/K/L` | Focus gauche/bas/haut/droite |
| `Super + Shift + H/J/K/L` | Déplacer fenêtre |
| `Super + Ctrl + H/L` | Focus écran gauche/droite |
| `Super + 1-9` | Aller au workspace 1-9 |
| `Super + Shift + 1-9` | Déplacer vers workspace 1-9 |
| `Print` | Screenshot (tout l'écran) |
| `Super + Print` | Screenshot (zone) |
