# Paquets de sécurité
{ config, pkgs, lib, ... }: {

  environment.systemPackages = with pkgs; [
    usbguard
    lynis
    yubikey-personalization
    yubikey-manager
    yubico-pam
    age-plugin-yubikey
    aide
    rage
    tomb
    tor
    privoxy
  ];
}
