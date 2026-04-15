# CITADEL — NixOS Configuration

Configuration NixOS **complète, modulaire et reproductible** pour PC de développement et administration de homelab.

NixOS 25.05 stable · Hyprland · Catppuccin Mocha · Impermanence · LUKS · Secure Boot · ANSSI hardening

## Installation — One-liner

Booter sur l'ISO NixOS, connecter au WiFi, puis :

```bash
bash <(curl -sL https://raw.githubusercontent.com/nawek/dotfile_nix-dev01/claude/nixos-dev-config-1pd8G/scripts/install.sh)
```

Le script guide interactivement : WiFi → profil → secrets → partitionnement → installation → reboot.

## Stats

```
118 commits · 97 fichiers · NixOS 25.05 stable
13 modules système · 12 modules home · 14 scripts · 6 devShells · 6 templates
12 flake checks automatisés · Hardening ANSSI R7-R14
```

## Fonctionnalités

| Catégorie | Composants |
|---|---|
| **Desktop** | Hyprland, SDDM, Waybar (CSS Catppuccin complet), Rofi, SwayNC, Hyprlock, wlogout, swww |
| **Rice** | Animations bezier, blur layers, shadow glow bleu, dim inactive, border breathing, scratchpad, submaps |
| **Thème** | Stylix Catppuccin Mocha global (GTK, QT, tous les terminaux, éditeurs, waybar, notifications) |
| **Éditeurs** | Neovim (LSP 5 langages, Treesitter, Telescope, 15+ plugins), Helix, VSCode (25+ extensions) |
| **Terminal** | Kitty (tabs, blur, remote control), Tmux (Catppuccin, resurrect, continuum) |
| **Shell** | ZSH, Starship (transient prompt), Atuin, Direnv, FZF, Zoxide, Navi, 60+ aliases |
| **Dev** | 6 devShells (Python, Node, Rust, Go, C/C++, Infra), 6 templates, Mise, pre-commit |
| **Sécurité** | LUKS, Lanzaboote, ANSSI R7-R14, AppArmor, firewall, fail2ban, ClamAV, DNS-over-TLS AdGuard, audit, Tor, AIDE, YubiKey |
| **Réseau** | Tailscale VPN, Mosh, WireGuard (template), dnsmasq, MAC WiFi random |
| **Monitoring** | smartmontools, thermald, earlyoom, lm_sensors, battery monitor, disk alerts |
| **Apps** | Chromium (ungoogled + uBlock + Bitwarden), Firefox, Thunderbird, Obsidian (PARA vault), Spotify (Spicetify), Signal, Telegram, Remmina, qBittorrent |
| **Multimédia** | MPV, Zathura, cava, PipeWire, wf-recorder, Flameshot |
| **Stockage** | BTRFS 6 subvolumes, impermanence (root éphémère), btrbk snapshots, Syncthing |
| **Automatisations** | 30+ timers systemd, routines morning/eod/deploy/cleanup/backup, Obsidian auto-commit |
| **Notes** | Vault Obsidian PARA (7 templates, 2 MOCs, daily note auto, git sync) |

## Architecture

```
citadel/
├── flake.nix                          # 12 inputs, nixosConfigurations, devShells, templates, checks
├── flake.lock                         # Versions verrouillées (25.05 stable)
├── .sops.yaml                         # Règles de chiffrement SOPS
├── .pre-commit-config.yaml            # Hooks : alejandra, shellcheck, deadnix, statix, flake check
├── treefmt.nix                        # Formatage : alejandra, shfmt, prettier
│
├── hosts/kuro/
│   ├── configuration.nix              # Config système (user, réseau, audio, Docker, btrbk, auto-cpufreq...)
│   └── hardware-configuration.nix     # Hardware (placeholder → nixos-generate-config)
│
├── modules/                           # 13 modules système
│   ├── disko.nix                      # BTRFS + LUKS partitionnement déclaratif
│   ├── impermanence.nix               # Root éphémère + persistence centralisée
│   ├── lanzaboote.nix                 # Secure Boot
│   ├── nvidia.nix                     # GPU NVIDIA propriétaire (Wayland)
│   ├── hyprland.nix                   # Compositeur Wayland + SDDM + paquets WM
│   ├── stylix.nix                     # Catppuccin Mocha global
│   ├── plymouth.nix                   # Boot splash CITADEL
│   ├── security.nix                   # Firewall, fail2ban, ClamAV, ANSSI, AppArmor, SSH hardening, Tor, AIDE, YubiKey
│   ├── networking.nix                 # Tailscale, Mosh, WireGuard, dnsmasq
│   ├── monitoring.nix                 # S.M.A.R.T., thermald, earlyoom
│   ├── sops.nix                       # Secrets chiffrés (age)
│   ├── ux.nix                         # USB auto-mount, CUPS, Flatpak, fwupd, Wine, kernel tuning
│   └── automations.nix                # Timers : GC smart, Docker cleanup, BTRFS balance, battery, Lynis, drift detection
│
├── home/                              # 12 modules Home Manager
│   ├── default.nix                    # HM principal, persistence user, GTK, Chromium, XDG, Obsidian, btop, Syncthing, Espanso
│   ├── shell.nix                      # ZSH, Starship, Atuin, Direnv, FZF, Zoxide, Navi, 60+ aliases, routines
│   ├── git.nix                        # Git, Delta, SSH (multiplexing, homelab matchBlocks)
│   ├── hyprland.nix                   # Hyprland user, Waybar CSS, Rofi, SwayNC, Hyprlock, wlogout, cava, Kitty, Kanshi, Gammastep
│   ├── vscode.nix                     # VSCode (25+ extensions, remote SSH, Markdown, IA)
│   ├── neovim.nix                     # Neovim (LSP, Treesitter, Telescope, 15+ plugins)
│   ├── helix.nix                      # Helix éditeur modal
│   ├── tmux.nix                       # Tmux + Catppuccin + resurrect
│   ├── yazi.nix                       # File manager TUI Catppuccin
│   ├── spotify.nix                    # Spotify Spicetify (Catppuccin + adblock)
│   ├── dev-tools.nix                  # CLI tools, Nix tools, monitoring, easter eggs, Ansible
│   ├── cheatsheet.md                  # Raccourcis clavier ($mod+F1)
│   ├── fastfetch.jsonc                # Config CITADEL Catppuccin
│   └── direnvrc                       # Layouts custom (python, node, docker)
│
├── devshells/                         # 6 environnements de développement
│   ├── python.nix                     # Python 3.12, ruff, pyright, virtualenv
│   ├── node.nix                       # Node 22, pnpm, TypeScript
│   ├── rust.nix                       # Rust stable (fenix), rust-analyzer
│   ├── go.nix                         # Go, gopls, delve, golangci-lint
│   ├── cc.nix                         # GCC, Clang, CMake, GDB, Valgrind
│   └── infra.nix                      # OpenTofu, Ansible, kubectl, k9s
│
├── templates/                         # 6 templates (nix flake init -t .#<lang>)
│   ├── python/ node/ rust/ go/ cc/    # Chaque template : flake.nix + .envrc + .gitignore
│   └── docker/                        # 3 docker-compose stacks (web, monitoring, dev-db)
│
├── scripts/                           # 14 scripts lifecycle
│   ├── install.sh                     # Onboarding interactif one-liner (WiFi → profil → install)
│   ├── prepare-secrets.sh             # Guide création secrets (age, password, WiFi, SOPS)
│   ├── pre-flight-check.sh            # Vérification pré-déploiement
│   ├── deploy.sh                      # Installation all-in-one (disko → nixos-install)
│   ├── post-install.sh                # Post-boot (Secure Boot, Tailscale, AIDE, pre-commit)
│   ├── health-check.sh                # Dashboard TUI (uptime, disque, Docker, Tailscale, Lynis)
│   ├── update.sh                      # Flake update → check → rebuild → log Obsidian
│   ├── backup-export.sh               # Archive chiffrée age (clés, SSH, GPG, Obsidian)
│   ├── audit.sh                       # Audit complet (Lynis, AIDE, ports, drift, fail2ban)
│   ├── rescue.sh                      # Procédure de récupération (rollback, chroot, BTRFS)
│   ├── new-machine.sh                 # Adapter la config pour un autre PC
│   ├── validate-config.sh             # Validation complète de la config
│   ├── disko-test-vm.sh               # Test partitionnement en VM
│   └── nixos-anywhere-deploy.sh       # Déploiement distant via SSH
│
├── home/obsidian-vault/               # Structure vault Obsidian PARA
│   ├── Inbox/                         # Capture rapide
│   ├── Journal/                       # Daily notes (auto-générées)
│   ├── Projects/                      # Projets actifs
│   ├── Areas/                         # NixOS, Docker, Homelab, Sécurité, Réseau (+ MOCs)
│   ├── Resources/                     # Cheatsheets, Runbooks, ADRs
│   ├── Archive/                       # Projets terminés
│   └── Templates/                     # 7 templates (Daily, Runbook, ADR, Project, Meeting, Bug, Cheatsheet)
│
├── tests/default.nix                  # 12 checks automatisés (nix flake check)
└── secrets/secrets.yaml               # Secrets (placeholder → chiffrer avec SOPS)
```

## Raccourcis clavier

| Raccourci | Action |
|---|---|
| `Super + Entrée` | Terminal (Kitty) |
| `Super + D` | Lanceur d'apps (Rofi) |
| `Super + Q` | Fermer la fenêtre |
| `Super + F` | Plein écran |
| `Super + L` | Verrouiller (Hyprlock) |
| `Super + X` | Menu power (wlogout) |
| `Super + N` | Panneau notifications (SwayNC) |
| `Super + W` | Wallpaper aléatoire |
| `Super + C` | Historique clipboard |
| `Super + .` | Emoji picker |
| `Super + F1` | Cheatsheet complète |
| `Super + \`` | Scratchpad (terminal dropdown) |
| `Super + R` | Mode resize |
| `Super + Z` | Zen mode (toggle waybar) |
| `Super + Shift+N` | Note rapide Obsidian |
| `Super + Shift+O` | OCR screenshot → clipboard |
| `Super + Shift+R` | Screen recording toggle |
| `Super + Shift+P` | Color picker |
| `Print` | Screenshot → clipboard |

## Aliases essentiels

| Alias | Action |
|---|---|
| `nrs` | NixOS rebuild switch |
| `nfu` | Flake update |
| `ngc` | Nix garbage collect |
| `morning` | Pull notes + daily note |
| `eod` | Commit notes + résumé + lock |
| `deploy` | Check → update → rebuild |
| `hcheck` | Ping serveurs homelab |
| `backup` | btrbk snapshot |
| `cleanup` | GC + Docker prune + clear Downloads |
| `ts` | Tailscale status |
| `lg` | lazygit |
| `ld` | lazydocker |
| `y` | Yazi (file manager) |

## DevShells & Templates

```bash
# Environnements de développement
nix develop .#python    # Python 3.12 + ruff + pyright
nix develop .#node      # Node 22 + pnpm + TypeScript
nix develop .#rust      # Rust stable + rust-analyzer
nix develop .#go        # Go + gopls + delve
nix develop .#cc        # GCC + Clang + CMake + GDB
nix develop .#infra     # OpenTofu + Ansible + kubectl

# Bootstrapper un nouveau projet
nix flake init -t .#python    # Crée flake.nix + .envrc + .gitignore
nix flake init -t .#rust
direnv allow
```

## Sécurité

```
LUKS2 chiffrement · Lanzaboote Secure Boot · IOMMU
50+ sysctl ANSSI R7-R14 · AppArmor · Firewall 0 port
fail2ban · ClamAV · DNS-over-TLS AdGuard · auditd
MAC WiFi random · SSH Ed25519-only · YubiKey
Tor on-demand · AIDE file integrity · Lynis auto
rkhunter · rage chiffrement · Nix drift detection
```

## Scripts lifecycle

| Quand | Script | Action |
|---|---|---|
| **Avant** | `install.sh` | Onboarding interactif complet |
| **Avant** | `prepare-secrets.sh` | Créer clé age, password, WiFi |
| **Avant** | `pre-flight-check.sh` | Vérifier que tout est prêt |
| **Jour J** | `deploy.sh` | disko → nixos-install |
| **Après** | `post-install.sh` | Secure Boot, Tailscale, AIDE |
| **Quotidien** | `health-check.sh` | Dashboard TUI |
| **Hebdo** | `update.sh` | Flake update + rebuild + log |
| **Mensuel** | `backup-export.sh` | Archive chiffrée USB |
| **Mensuel** | `audit.sh` | Audit sécurité complet |
| **Urgence** | `rescue.sh` | Procédure de récupération |
| **Multi** | `new-machine.sh` | Adapter pour un autre PC |
