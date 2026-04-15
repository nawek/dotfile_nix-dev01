# Audit logging + USBGuard
{ config, pkgs, lib, ... }: {

  # Journalisation des accès système
  security.auditd.enable = true;
  security.audit = {
    enable = true;
    rules = [
      "-w /etc/passwd -p wa -k identity"
      "-w /etc/group -p wa -k identity"
      "-w /etc/shadow -p wa -k identity"
      "-w /etc/sudoers -p wa -k sudoers"
      "-w /usr/bin/sudo -p x -k privilege_escalation"
      "-w /usr/bin/su -p x -k privilege_escalation"
      "-w /etc/nixos -p wa -k nixos_config"
    ];
  };

  # USBGuard — désactivé par défaut (activer après generate-policy)
  services.usbguard = {
    enable = false;
    rules = null;
    presentDevicePolicy = "keep";
    insertedDevicePolicy = "apply-policy";
    IPCAllowedUsers = [ "root" "kuro" ];
  };
}
