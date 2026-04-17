# YubiKey — Support clé de sécurité matérielle
# Activation : citadel.security.yubikey.enable (default: true)
{ config, lib, ... }:

let
  inherit (lib) mkIf;
in
{
  config = mkIf config.citadel.security.yubikey.enable {
    services.pcscd.enable = true;
    hardware.gpgSmartcards.enable = true;

    # PAM FIDO2 — décommenter pour login par YubiKey :
    # security.pam.u2f = {
    #   enable = true;
    #   cue = true;
    #   control = "sufficient";
    # };
  };
}
