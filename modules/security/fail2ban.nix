# Fail2ban — Protection brute-force SSH
{ config, pkgs, lib, ... }: {

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
}
