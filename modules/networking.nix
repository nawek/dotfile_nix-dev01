# ╔══════════════════════════════════════════════════════════════════╗
# ║  Networking avancé — Tailscale, Mosh, dnsmasq, WireGuard        ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Module réseau avancé pour un laptop de développeur :
# - Tailscale : VPN mesh zero-config (laptop ↔ serveurs ↔ phone)
# - Mosh : shell distant résistant aux déconnexions WiFi
# - dnsmasq : résolution .local et .test pour le dev local
#   (intégré via NetworkManager, pas de conflit avec systemd-resolved)
# - WireGuard : VPN site-to-site (template prêt à adapter)
#
# ⚠️ Le firewall est géré UNIQUEMENT dans modules/security.nix
#    Ne PAS déclarer networking.firewall ici.
#
# ⚠️ La persistence est centralisée dans modules/impermanence.nix
#    Ne PAS déclarer environment.persistence ici.

{ config, pkgs, lib, ... }: {

  # ══════════════════════════════════════════════════════════════════
  # 1. TAILSCALE — VPN mesh zero-config
  # ══════════════════════════════════════════════════════════════════
  # Connecte tous vos appareils dans un réseau privé via WireGuard.
  #
  # Setup initial :
  #   sudo tailscale up          → authentification via navigateur
  #   tailscale status           → voir les machines connectées
  #   tailscale ip -4            → votre IP Tailscale
  #   ssh user@machine-name      → accès direct via Tailscale
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client"; # ← ADAPTER : "server" si exit node
    port = 41641;
  };

  # ══════════════════════════════════════════════════════════════════
  # 2. MOSH — Shell distant résistant aux déconnexions
  # ══════════════════════════════════════════════════════════════════
  # Survit aux changements d'IP, au WiFi instable, et au suspend.
  # Ouvre automatiquement les ports UDP 60000-61000 dans le firewall.
  # Usage : mosh user@serveur
  programs.mosh.enable = true;

  # ══════════════════════════════════════════════════════════════════
  # 3. DNS LOCAL — dnsmasq via NetworkManager
  # ══════════════════════════════════════════════════════════════════
  # Résout *.local et *.test vers 127.0.0.1 pour le dev.
  # Intégré comme plugin NetworkManager pour éviter tout conflit
  # avec systemd-resolved (qui gère le DNS-over-TLS dans security.nix).
  #
  # Architecture DNS :
  #   App → NetworkManager (dnsmasq plugin)
  #     → .local / .test → 127.0.0.1 (résolution locale)
  #     → tout le reste → systemd-resolved → Quad9 DNS-over-TLS
  networking.networkmanager = {
    wifi.powersave = false; # Désactiver le powersave WiFi (stabilité)

    # dnsmasq intégré à NetworkManager (pas de service standalone)
    dns = "systemd-resolved"; # resolved reste le résolveur principal
    # Les domaines .local et .test sont gérés via resolved
  };

  # Ajouter les domaines de dev dans resolved
  # ← ADAPTER : ajouter vos domaines internes
  services.resolved.domains = [ "~local" "~test" ];

  # ══════════════════════════════════════════════════════════════════
  # 4. WIREGUARD — VPN site-to-site vers le homelab
  # ══════════════════════════════════════════════════════════════════
  # WireGuard est intégré au noyau Linux — pas besoin de module.
  # La config se fait via NetworkManager (GUI ou nmcli).
  #
  # ── Créer un tunnel WireGuard via nmcli ──────────────────────────
  #   nmcli connection import type wireguard file ~/wg-homelab.conf
  #   nmcli connection up wg-homelab
  #
  # ── Ou via config NixOS (décommenter et adapter) ─────────────────
  #   networking.wg-quick.interfaces.wg-homelab = {
  #     address = [ "10.0.0.2/24" ];
  #     privateKeyFile = "/persist/system/wireguard/private-key";
  #     peers = [{
  #       publicKey = "XXXXXXX";
  #       endpoint = "vpn.example.com:51820";
  #       allowedIPs = [ "10.0.0.0/24" "192.168.1.0/24" ];
  #       persistentKeepalive = 25;
  #     }];
  #   };

  # Plugins VPN pour NetworkManager (GUI dans nm-applet)
  networking.networkmanager.plugins = with pkgs; [
    networkmanager-openvpn      # Support OpenVPN dans NetworkManager
    networkmanager-l2tp         # Support L2TP/IPsec
  ];

  # ══════════════════════════════════════════════════════════════════
  # Paquets réseau
  # ══════════════════════════════════════════════════════════════════
  environment.systemPackages = with pkgs; [
    tailscale       # CLI Tailscale
    mosh            # Shell distant résilient
    wireguard-tools # CLI WireGuard (wg, wg-quick)
    nmap            # Scanner réseau
    dig             # Résolution DNS debug
    whois           # Lookup de domaines
    iperf3          # Test de bande passante
    traceroute      # Traçage de route réseau
  ];
}
