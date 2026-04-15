# ╔══════════════════════════════════════════════════════════════════╗
# ║  Sécurité — Point d'entrée (importe tous les sous-modules)      ║
# ╚══════════════════════════════════════════════════════════════════╝

{ ... }: {
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
}
