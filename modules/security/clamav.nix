# ClamAV — Antivirus à la demande
# Usage : clamscan ~/Downloads/ | freshclam (update signatures)
{ config, pkgs, lib, ... }: {

  services.clamav = {
    daemon.enable = true;
    updater = {
      enable = true;
      interval = "daily";
      frequency = 1;
    };
  };
}
