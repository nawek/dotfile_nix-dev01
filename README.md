# NixOS Configuration — Kuro

Configuration NixOS **complète, modulaire et reproductible** pour PC de développement (laptop).
NixOS 25.05 stable, Hyprland, Catppuccin Mocha, impermanence, LUKS, Secure Boot.

## Fonctionnalités

| Catégorie | Composants |
|---|---|
| **Desktop** | Hyprland + SDDM, Waybar (CSS Catppuccin), Rofi, SwayNC, Hyprlock, wlogout |
| **Rice** | swww (wallpapers animés), animations bezier, scratchpad, submaps, zen mode |
| **Thème** | Stylix Catppuccin Mocha global (GTK, QT, terminal, waybar, éditeurs) |
| **Éditeurs** | Neovim (LSP, Treesitter, Telescope), Helix, VSCode |
| **Terminal** | Kitty, Wezterm, Zellij, Tmux (tous Catppuccin) |
| **Shell** | ZSH + Starship + Atuin + Direnv + FZF + Zoxide + Navi |
| **Dev** | 6 devShells (Python, Node, Rust, Go, C/C++, Infra), 5 templates, Mise |
| **Sécurité** | LUKS, Lanzaboote (Secure Boot), firewall, fail2ban, ClamAV, DNS-over-TLS, audit |
| **Réseau** | Tailscale VPN, Mosh, WireGuard (template), dnsmasq (.local/.test) |
| **Monitoring** | smartmontools, thermald, earlyoom, lm_sensors |
| **Apps** | Chromium (ungoogled + uBlock + Bitwarden), Thunderbird, Obsidian, Spotify (Spicetify) |
| **Multimédia** | MPV, Zathura (PDF), cava (visualiseur audio), PipeWire |
| **Stockage** | BTRFS 6 subvolumes, impermanence (wipe root au boot), btrbk snapshots, Syncthing |

## Architecture

```
nixos-config/
├── flake.nix                          # Inputs, outputs, devShells, templates
├── flake.lock                         # Versions verrouillées (25.05 stable)
├── .sops.yaml                         # Règles de chiffrement SOPS
├── .pre-commit-config.yaml            # Hooks pre-commit (alejandra, shellcheck)
├── treefmt.nix                        # Formatage multi-langages
├── hosts/kuro/
│   ├── configuration.nix              # Config système principale
│   └── hardware-configuration.nix     # Hardware (placeholder → nixos-generate-config)
├── modules/
│   ├── disko.nix                      # Partitionnement BTRFS + LUKS
│   ├── impermanence.nix               # Effacement root + persistance centralisée
│   ├── lanzaboote.nix                 # Secure Boot
│   ├── nvidia.nix                     # GPU NVIDIA propriétaire (Wayland)
│   ├── hyprland.nix                   # Compositeur Wayland + SDDM + paquets WM
│   ├── stylix.nix                     # Thème Catppuccin Mocha global
│   ├── plymouth.nix                   # Boot splash (rings)
│   ├── security.nix                   # Firewall, fail2ban, ClamAV, DNS-over-TLS, audit
│   ├── networking.nix                 # Tailscale, Mosh, WireGuard, dnsmasq
│   ├── monitoring.nix                 # S.M.A.R.T., thermald, earlyoom
│   └── sops.nix                       # Secrets chiffrés (age)
├── home/
│   ├── default.nix                    # HM principal, persistance user, GTK, Chromium
│   ├── shell.nix                      # ZSH, starship, atuin, direnv, fzf, zoxide, navi
│   ├── git.nix                        # Git, delta, SSH (multiplexing, homelab matchBlocks)
│   ├── hyprland.nix                   # Hyprland user, waybar CSS, rofi, swaync, hyprlock
│   ├── vscode.nix                     # VSCode + extensions déclaratives
│   ├── neovim.nix                     # Neovim complet (LSP, treesitter, telescope)
│   ├── helix.nix                      # Helix (éditeur Rust alternatif)
│   ├── tmux.nix                       # Tmux + Catppuccin + resurrect
│   ├── terminals.nix                  # Wezterm, Zellij (alternatives)
│   ├── yazi.nix                       # File manager TUI
│   ├── spotify.nix                    # Spotify via Spicetify + Catppuccin
│   ├── dev-tools.nix                  # Outils CLI + Mise + Ansible
│   └── cheatsheet.md                  # Raccourcis clavier ($mod+F1)
├── devshells/
│   ├── python.nix / node.nix / rust.nix / go.nix / cc.nix / infra.nix
│   └── example.envrc
├── templates/
│   ├── python/ / node/ / rust/ / go/ / cc/
├── scripts/
│   ├── validate-config.sh             # Validation avant déploiement
│   ├── disko-test-vm.sh               # Test partitionnement en VM
│   └── nixos-anywhere-deploy.sh       # Déploiement distant
└── secrets/
    └── secrets.yaml                   # Placeholder (chiffrer avec sops)
```

## Installation

### 1. Booter sur l'ISO NixOS

### 2. Connexion réseau
```bash
sudo nmcli device wifi connect "SSID" password "mot-de-passe"
```

### 3. Préparer le dépôt
```bash
nix-shell -p git --run "git clone https://github.com/nawek/dotfile_nix-dev01.git"
cd dotfile_nix-dev01
```

### 4. Adapter la config
```bash
# Voir toutes les valeurs à personnaliser
grep -r "ADAPTER" --include="*.nix" .

# Générer la config hardware
sudo nixos-generate-config --show-hardware-config > hosts/kuro/hardware-configuration.nix
# ⚠️ Supprimer les sections fileSystems (Disko les gère)

# Adapter le device dans modules/disko.nix (lsblk pour vérifier)
```

### 5. Partitionner avec Disko
```bash
sudo nix --extra-experimental-features "nix-command flakes" run \
  github:nix-community/disko -- --mode disko --flake .#kuro
```

### 6. Installer
```bash
sudo nixos-install --flake .#kuro
sudo reboot
```

### 7. Post-installation
```bash
# SOPS — secrets
mkdir -p /persist/system
age-keygen -o /persist/system/sops-age-keys.txt
# Copier la clé publique dans .sops.yaml
# mkpasswd -m sha-512 "mot_de_passe" → coller dans secrets.yaml
sops secrets/secrets.yaml

# Secure Boot — Lanzaboote
sudo sbctl create-keys
sudo sbctl enroll-keys --microsoft

# Tailscale
sudo tailscale up
```

## Usage quotidien

### NixOS
```bash
nrs          # nh os switch (rebuild)
nfu          # nix flake update
ngc          # nh clean all (GC)
nsg firefox  # nix search nixpkgs
```

### Dev Shells
```bash
nix develop .#python    # Python 3.12 + ruff + pyright
nix develop .#node      # Node 22 + pnpm + TypeScript
nix develop .#rust      # Rust stable + rust-analyzer
nix develop .#go        # Go + gopls + delve
nix develop .#cc        # GCC + Clang + CMake + GDB
nix develop .#infra     # OpenTofu + Ansible + kubectl
```

### Templates (nouveau projet)
```bash
mkdir mon-projet && cd mon-projet
nix flake init -t /home/kuro/dotfile_nix-dev01#python
direnv allow
```

### Raccourcis clavier
`Super + F1` pour afficher la cheatsheet complète, ou voir `home/cheatsheet.md`.

### Monitoring
```bash
ts           # tailscale status
jdash        # erreurs système 24h
jboot        # warnings du boot
temps        # températures CPU/GPU
sudo smartctl -a /dev/nvme0n1  # santé SSD
```

## Rollback
```bash
# Lister les générations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Revenir en arrière
sudo nixos-rebuild switch --rollback

# Snapshots btrbk
sudo btrbk list
ls /.snapshots/persist/
ls /.snapshots/home/
```
