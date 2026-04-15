# Hardware configuration minimale pour VM (QEMU/VirtualBox)
{ config, lib, pkgs, modulesPath, ... }: {
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "sr_mod" "virtio_blk" ];
  boot.kernelModules = [ "kvm-intel" ];

  fileSystems."/" = { device = "/dev/vda1"; fsType = "ext4"; };
  fileSystems."/boot" = { device = "/dev/vda2"; fsType = "vfat"; };
}
