# ╔══════════════════════════════════════════════════════════════════╗
# ║  Networking avancé — Tailscale, Mosh, dnsmasq, portail captif  ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Module réseau avancé pour un laptop de développeur :
# - Tailscale : VPN mesh zero-config (laptop ↔ serveurs ↔ phone)
# - Mosh : shell distant résistant aux déconnexions WiFi
# - dnsmasq : résolution .local et .test pour le dev local
# - Détection de portail captif WiFi (hôtels, aéroports)

{ config, pkgs, lib, ... }: {

  # ══════════════════════════════════════════════════════════════════
  # 1. TAILSCALE — VPN mesh zero-config
  # ══════════════════════════════════════════════════════════════════
  # Connecte tous vos appareils dans un réseau privé via WireGuard.
  # Pas besoin de configurer des clés ou des tunnels manuellement.
  #
  # Setup initial :
  #   sudo tailscale up          → authentification via navigateur
  #   tailscale status           → voir les machines connectées
  #   tailscale ip -4            → votre IP Tailscale
  #   ssh user@machine-name      → accès direct via Tailscale
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client"; # ← ADAPTER : "server" si exit node
    # Port d'écoute (doit être ouvert dans le firewall)
    port = 41641;
  };

  # Ouvrir le port Tailscale dans le firewall
  networking.firewall = {
    allowedUDPPorts = [ 41641 ];
    # Tailscale utilise son propre firewall interne
    trustedInterfaces = [ "tailscale0" ];
  };

  # Persister l'état Tailscale (clés, config)
  environment.persistence."/persist/system".directories = [
    "/var/lib/tailscale"
  ];

  # ══════════════════════════════════════════════════════════════════
  # 2. MOSH — Shell distant résistant aux déconnexions
  # ══════════════════════════════════════════════════════════════════
  # Remplace SSH pour les sessions interactives longues.
  # Survit aux changements d'IP, au WiFi instable, et au suspend.
  # Ouvre automatiquement les ports UDP 60000-61000 dans le firewall.
  #
  # Usage : mosh user@serveur (au lieu de ssh user@serveur)
  programs.mosh.enable = true;

  # ══════════════════════════════════════════════════════════════════
  # 3. DNSMASQ — Résolution DNS locale pour le dev
  # ══════════════════════════════════════════════════════════════════
  # Résout *.local et *.test vers 127.0.0.1 automatiquement.
  # Utile pour Docker Compose, Traefik, dev servers, etc.
  #
  # Exemples :
  #   myapp.local    → 127.0.0.1
  #   api.test       → 127.0.0.1
  #   db.local:5432  → 127.0.0.1:5432
  services.dnsmasq = {
    enable = true;
    settings = {
      # Résolution locale pour le développement
      address = [
        "/.local/127.0.0.1"  # Tous les *.local → localhost
        "/.test/127.0.0.1"   # Tous les *.test → localhost
        # ← ADAPTER : ajouter vos domaines de dev
      ];

      # Ne pas interférer avec les DNS upstream
      no-resolv = false;
      # Écouter uniquement sur localhost
      listen-address = "127.0.0.1";
      bind-interfaces = true;
      # Cache DNS local (accélère la résolution)
      cache-size = 1000;
    };
  };

  # ══════════════════════════════════════════════════════════════════
  # 4. DÉTECTION DE PORTAIL CAPTIF
  # ══════════════════════════════════════════════════════════════════
  # NetworkManager détecte automatiquement les portails captifs
  # (WiFi d'hôtel, aéroport, café) et ouvre le navigateur.
  networking.networkmanager = {
    # Le connectivity check détecte les portails captifs
    # et ouvre automatiquement une fenêtre de navigateur
    wifi.powersave = false; # Désactiver le powersave WiFi (stabilité)
  };

  # ══════════════════════════════════════════════════════════════════
  # Paquets réseau
  # ══════════════════════════════════════════════════════════════════
  environment.systemPackages = with pkgs; [
    tailscale       # CLI Tailscale
    mosh            # Shell distant résilient
    nmap            # Scanner réseau
    dig             # Résolution DNS debug
    whois           # Lookup de domaines
    iperf3          # Test de bande passante
    traceroute      # Traçage de route réseau
  ];
}
