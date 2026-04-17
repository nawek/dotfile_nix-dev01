# Tor — Navigation anonyme on-demand
# Usage : tor-start / tor-stop / tor-ip (aliases dans shell.nix)
# Activation : citadel.security.tor.enable (default: true)
{ config, lib, ... }:

let
  inherit (lib) mkIf;
in
{
  config = mkIf config.citadel.security.tor.enable {
    services.tor = {
      enable = true;
      client.enable = true;
      settings.SocksPort = [ "9050" ];
    };
  };
}
