# ClamAV — Antivirus à la demande
# Usage : clamscan ~/Downloads/ | freshclam (update signatures)
# Activation : citadel.security.clamav.enable (default: true)
{ config, lib, ... }:

let
  inherit (lib) mkIf;
in
{
  config = mkIf config.citadel.security.clamav.enable {
    services.clamav = {
      daemon.enable = true;
      updater = {
        enable = true;
        interval = "daily";
        frequency = 1;
      };
    };
  };
}
