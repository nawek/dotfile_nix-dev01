# ╔══════════════════════════════════════════════════════════════════╗
# ║  Sécurité — Point d'entrée (importe tous les sous-modules)      ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Interface publique :
#   citadel.security.enable              (default: true — master switch)
#   citadel.security.clamav.enable       (default: true — antivirus)
#   citadel.security.fail2ban.enable     (default: true — anti-bruteforce SSH)
#   citadel.security.tor.enable          (default: true — SOCKS5 on-demand)
#   citadel.security.yubikey.enable      (default: true — désactiver si pas de clé)
#
# Les fondamentaux (firewall, hardening ANSSI, SSH, AppArmor, audit, DNS-over-TLS,
# scanning AIDE/Lynis) sont toujours actifs quand security.enable = true.

{ config, lib, ... }:

let
  cfg = config.citadel.security;
  inherit (lib) mkOption mkIf types;
in
{
  imports = [
    ./firewall.nix      # Firewall, MAC randomization
    ./fail2ban.nix      # Protection brute-force SSH
    ./clamav.nix        # Antivirus à la demande
    ./dns.nix           # DNS-over-TLS (AdGuard)
    ./audit.nix         # Journalisation des accès + USBGuard
    ./hardening.nix     # Kernel ANSSI R7-R14 + hardening avancé
    ./ssh.nix           # SSH hardening algorithmes modernes
    ./apparmor.nix      # Confinement kernel
    ./yubikey.nix       # Support clé de sécurité
    ./tor.nix           # Navigation anonyme on-demand
    ./scanning.nix      # AIDE, Lynis, drift detection
    ./packages.nix      # Paquets de sécurité
  ];

  options.citadel.security = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Master switch pour l'ensemble du stack sécurité CITADEL.";
    };

    clamav.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Activer le daemon ClamAV (antivirus à la demande).";
    };

    fail2ban.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Activer fail2ban (protection brute-force SSH).";
    };

    tor.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Activer le client Tor (SOCKS5 sur 9050, navigation anonyme on-demand).";
    };

    yubikey.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Activer le support YubiKey (pcscd, udev rules, pam-u2f).";
    };
  };

  # Garde-fou : security.enable = false désactive explicitement tous les sous-flags.
  # Les sous-modules lisent config.citadel.security.<name>.enable directement.
  config = mkIf (!cfg.enable) {
    citadel.security = {
      clamav.enable = lib.mkDefault false;
      fail2ban.enable = lib.mkDefault false;
      tor.enable = lib.mkDefault false;
      yubikey.enable = lib.mkDefault false;
    };
  };
}
