# DNS-over-TLS — AdGuard DNS (blocklist malware + trackers)
{ config, pkgs, lib, ... }: {

  services.resolved = {
    enable = true;
    dnssec = "true";
    domains = [ "~." ];
    extraConfig = ''
      [Resolve]
      DNS=94.140.14.14#dns.adguard-dns.com 94.140.15.15#dns.adguard-dns.com
      FallbackDNS=9.9.9.9#dns.quad9.net 1.1.1.1#cloudflare-dns.com
      DNSOverTLS=yes
    '';
  };
}
