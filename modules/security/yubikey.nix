# YubiKey — Support clé de sécurité matérielle
{ config, pkgs, lib, ... }: {

  services.pcscd.enable = true;
  hardware.gpgSmartcards.enable = true;

  # PAM FIDO2 — décommenter pour login par YubiKey :
  # security.pam.u2f = {
  #   enable = true;
  #   cue = true;
  #   control = "sufficient";
  # };
}
