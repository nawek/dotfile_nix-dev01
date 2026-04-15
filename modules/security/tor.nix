# Tor — Navigation anonyme on-demand
# Usage : tor-start / tor-stop / tor-ip (aliases dans shell.nix)
{ config, pkgs, lib, ... }: {

  services.tor = {
    enable = true;
    client.enable = true;
    settings.SocksPort = [ "9050" ];
  };
}
