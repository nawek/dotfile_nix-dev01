# Scripts — CITADEL Lifecycle

Scripts couvrant le cycle de vie complet de l'installation NixOS.

## Pré-déploiement

| Script | Usage | Description |
|---|---|---|
| `install.sh` | `bash <(curl -sL ...)` | **Onboarding interactif one-liner** — WiFi, profil, secrets, disko, nixos-install, reboot |
| `prepare-secrets.sh` | `bash scripts/prepare-secrets.sh` | Guide création clé age, hash password, WiFi, chiffrement SOPS |
| `pre-flight-check.sh` | `bash scripts/pre-flight-check.sh` | Vérifie que tout est prêt : secrets, hardware-config, disko, flake check |
| `deploy.sh` | `sudo bash scripts/deploy.sh` | Installation all-in-one : disko → copie secrets → nixos-install |

## Post-déploiement

| Script | Usage | Description |
|---|---|---|
| `post-install.sh` | `bash scripts/post-install.sh` | Secure Boot (sbctl), Tailscale, Flatpak, AIDE init, pre-commit |
| `validate-config.sh` | `bash scripts/validate-config.sh` | Validation complète (structure, syntaxe, eval, devShells, templates) |

## Maintenance quotidienne

| Script | Usage | Description |
|---|---|---|
| `health-check.sh` | `bash scripts/health-check.sh` | Dashboard TUI : uptime, disque, services, Docker, Tailscale, Lynis, batterie |
| `update.sh` | `bash scripts/update.sh` | Flake update → check → rebuild → commit flake.lock → log dans Obsidian |
| `audit.sh` | `bash scripts/audit.sh` | Audit sécurité complet : Lynis, AIDE, ports, services, fail2ban, nix drift |

## Backup & Recovery

| Script | Usage | Description |
|---|---|---|
| `backup-export.sh` | `bash scripts/backup-export.sh` | Archive chiffrée age (clés SSH, GPG, age, Obsidian) → clé USB |
| `rescue.sh` | `bash scripts/rescue.sh` | Procédure de récupération : rollback, chroot, restauration BTRFS |

## Multi-machine

| Script | Usage | Description |
|---|---|---|
| `new-machine.sh` | `bash scripts/new-machine.sh` | Guide interactif pour adapter la config à un autre PC |
| `nixos-anywhere-deploy.sh` | `bash scripts/nixos-anywhere-deploy.sh <user@host>` | Déploiement NixOS distant via SSH |
| `disko-test-vm.sh` | `bash scripts/disko-test-vm.sh` | Test du partitionnement Disko dans une VM (dry-run) |
