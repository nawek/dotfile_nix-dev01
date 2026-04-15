# AppArmor — Confinement kernel des applications
{ config, pkgs, lib, ... }: {

  security.apparmor = {
    enable = true;
    packages = with pkgs; [ apparmor-profiles ];
  };
}
