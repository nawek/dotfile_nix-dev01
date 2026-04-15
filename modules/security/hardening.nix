# Kernel hardening — ANSSI R7-R14 + avancé
# Référence : https://www.ssi.gouv.fr/guide/recommandations-de-securite-relatives-a-un-systeme-gnulinux/
# Inspiré de cloud-gouv/securix (DINUM)
{ config, pkgs, lib, ... }: {

  # ── R7-R8 : Boot params ────────────────────────────────────────
  boot.kernelParams = lib.mkAfter [
    "iommu=force"
    "page_poison=on" "slab_nomerge" "slub_debug=FZP"
    "pti=on" "spectre_v2=on" "spec_store_bypass_disable=seccomp"
    "mce=0" "page_alloc.shuffle=1" "l1tf=full,force" "mds=full,nosmt"
    "module.sig_enforce=1" "lockdown=integrity"
  ];

  # ── R9-R14 : Sysctl ───────────────────────────────────────────
  boot.kernel.sysctl = {
    "kernel.dmesg_restrict" = 1;
    "kernel.kptr_restrict" = 2;
    "kernel.pid_max" = 1048576;
    "kernel.perf_event_paranoid" = 3;
    "kernel.randomize_va_space" = 2;
    "kernel.sysrq" = 0;
    "kernel.unprivileged_bpf_disabled" = 1;
    "net.core.bpf_jit_harden" = 2;
    "kernel.panic_on_oops" = 1;
    "kernel.yama.ptrace_scope" = 1;        # R11
    "kernel.kexec_load_disabled" = 1;
    # R12 — IPv4
    "net.ipv4.ip_forward" = 0;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.secure_redirects" = 0;
    "net.ipv4.conf.default.secure_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.conf.all.log_martians" = 1;
    "net.ipv4.conf.default.log_martians" = 1;
    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv4.tcp_rfc1337" = 1;
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
    "net.ipv4.tcp_timestamps" = 0;
    "net.ipv4.conf.all.arp_ignore" = 1;
    "net.ipv4.conf.all.arp_announce" = 2;
    # R13 — IPv6
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_source_route" = 0;
    "net.ipv6.conf.default.accept_source_route" = 0;
    # R14 — Filesystem
    "fs.protected_fifos" = 2;
    "fs.protected_regular" = 2;
    "fs.protected_symlinks" = 1;
    "fs.protected_hardlinks" = 1;
    "fs.suid_dumpable" = 0;
  };

  # ── Avancé ─────────────────────────────────────────────────────
  boot.specialFileSystems."/proc".options = [ "hidepid=2" "gid=0" ];
  systemd.coredump.enable = false;
  security.pam.loginLimits = [
    { domain = "*"; type = "hard"; item = "core"; value = "0"; }
  ];

  boot.blacklistedKernelModules = [
    "firewire-core" "firewire-ohci" "firewire-sbp2"
    "dccp" "sctp" "rds" "tipc"
    "cramfs" "freevxfs" "hfs" "hfsplus" "jffs2" "squashfs" "udf"
  ];

  boot.tmp = { useTmpfs = true; tmpfsSize = "50%"; cleanOnBoot = true; };
}
