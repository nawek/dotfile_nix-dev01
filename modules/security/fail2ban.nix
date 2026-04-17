# Fail2ban — Protection brute-force SSH
# Activation : citadel.security.fail2ban.enable (default: true)
{ config, lib, ... }:

let
  inherit (lib) mkIf;
in
{
  config = mkIf config.citadel.security.fail2ban.enable {
    services.fail2ban = {
      enable = true;
      bantime = "10m";

      jails.sshd.settings = {
        enabled = true;
        port = "ssh";
        filter = "sshd";
        maxretry = 3;
        findtime = "10m";
        bantime = "1h";
      };

      bantime-increment = {
        enable = true;
        maxtime = "48h";
        factor = "4";
      };
    };
  };
}
