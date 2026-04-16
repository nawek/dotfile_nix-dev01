# ╔══════════════════════════════════════════════════════════════════╗
# ║  vm-test — Configuration minimale pour tests en VM               ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Host minimal pour tester la config dans une VM (QEMU, VirtualBox, etc.)
# Sans NVIDIA, sans Lanzaboote, sans impermanence.
#
# Usage : nixosConfigurations.vm-test dans flake.nix
# Build : nix build .#nixosConfigurations.vm-test.config.system.build.vm

{ config, pkgs, inputs, lib, username ? "kuro", hostname ? "vm-test", ... }: {

  imports = [
    ./hardware-configuration.nix
    ../../modules/hyprland.nix
    ../../modules/stylix.nix
    # Pas de sops.nix en VM (pas de clé age)
  ];

  # ── Nix ──────────────────────────────────────────────────────────
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };
  nixpkgs.config.allowUnfree = true;

  # ── Système ──────────────────────────────────────────────────────
  networking.hostName = hostname;
  time.timeZone = "Europe/Paris";
  i18n.defaultLocale = "fr_FR.UTF-8";
  system.stateVersion = "25.05";

  # ── Utilisateur ──────────────────────────────────────────────────
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "networkmanager" ];
    shell = pkgs.zsh;
    initialPassword = "changeme"; # Mot de passe temporaire pour la VM
  };
  programs.zsh.enable = true;

  # ── Boot — systemd-boot (pas Lanzaboote pour la VM) ─────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ── Réseau ───────────────────────────────────────────────────────
  networking.networkmanager.enable = true;

  # ── Audio ────────────────────────────────────────────────────────
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # ── Variable FLAKE pour nh ───────────────────────────────────────
  environment.variables.FLAKE = "/home/${username}/dotfile_nix-dev01";

  # ── Paquets minimaux ─────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    git curl wget htop neovim
  ];
}
