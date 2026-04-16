# SSH hardening — algorithmes modernes uniquement
{ config, pkgs, lib, ... }: {

  services.openssh.settings = {
    KexAlgorithms = [ "curve25519-sha256" "curve25519-sha256@libssh.org" ];
    Ciphers = [ "chacha20-poly1305@openssh.com" "aes256-gcm@openssh.com" "aes128-gcm@openssh.com" ];
    Macs = [ "hmac-sha2-512-etm@openssh.com" "hmac-sha2-256-etm@openssh.com" ];
    HostKeyAlgorithms = "ssh-ed25519";
    AllowAgentForwarding = false;
    X11Forwarding = false;
    ClientAliveInterval = 600;
    ClientAliveCountMax = 0;
    MaxAuthTries = 3;
  };
}
