# Firewall + MAC randomization WiFi
{ config, pkgs, lib, ... }: {

  # Source unique de vérité pour le firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ ];
    allowedUDPPorts = [ 41641 ]; # Tailscale
    trustedInterfaces = [ "tailscale0" ];
    allowPing = true;
    logRefusedConnections = true;
    logRefusedPackets = false;
  };

  # MAC randomization WiFi (anti-tracking)
  networking.networkmanager.wifi.macAddress = "random";
  networking.networkmanager.ethernet.macAddress = "preserve";
}
