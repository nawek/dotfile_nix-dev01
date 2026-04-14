# ╔══════════════════════════════════════════════════════════════════╗
# ║  Sécurité — Firewall, Fail2ban, ClamAV, DNS-over-TLS,         ║
# ║              Audit logging, USBGuard                            ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Module de hardening système pour un laptop de développement.
# Chaque section peut être désactivée individuellement si nécessaire.
#
# ⚠️ USBGuard bloque par défaut TOUTES les nouvelles clés USB.
#    Lire les commentaires avant de l'activer.

{ config, pkgs, lib, ... }: {

  # ══════════════════════════════════════════════════════════════════
  # 1. FIREWALL — Filtrage réseau minimal
  # ══════════════════════════════════════════════════════════════════
  # ⚠️ Ce module est la SOURCE UNIQUE de vérité pour le firewall.
  #    Ne PAS déclarer networking.firewall dans d'autres modules.
  networking.firewall = {
    enable = true;

    # Ports TCP ouverts en entrée
    # Par défaut : rien d'ouvert (sécurité maximale)
    allowedTCPPorts = [
      # 22    # SSH — décommenter si accès distant nécessaire
      # 80    # HTTP — décommenter pour un serveur web local
      # 443   # HTTPS — idem
      # 8080  # Dev server — décommenter temporairement si besoin
    ];

    # Ports UDP ouverts en entrée
    allowedUDPPorts = [
      41641  # Tailscale (VPN mesh)
      # 51820 # WireGuard — décommenter si VPN site-to-site utilisé
    ];

    # Plages de ports (Mosh ouvre 60000-61000 automatiquement via programs.mosh)
    # allowedTCPPortRanges = [{ from = 3000; to = 3100; }]; # Dev servers

    # Tailscale utilise son propre firewall interne
    trustedInterfaces = [ "tailscale0" ];

    # Autoriser le ping (ICMP) — utile pour le diagnostic réseau
    allowPing = true;

    # Logging des paquets refusés (utile pour le debug)
    logRefusedConnections = true;
    logRefusedPackets = false; # true = très verbeux, activer temporairement si besoin
  };

  # ══════════════════════════════════════════════════════════════════
  # 2. FAIL2BAN — Protection contre le brute-force SSH
  # ══════════════════════════════════════════════════════════════════
  services.fail2ban = {
    enable = true;

    # Durée du bannissement par défaut
    bantime = "10m";

    # Configuration des jails (services surveillés)
    jails = {
      # SSH — protection contre les tentatives de connexion brute-force
      sshd = {
        settings = {
          enabled = true;
          port = "ssh";
          filter = "sshd";
          maxretry = 3;       # 3 tentatives max avant ban
          findtime = "10m";   # Fenêtre d'observation de 10 minutes
          bantime = "1h";     # Ban d'1 heure pour SSH
        };
      };

      # Optionnel : ajouter des jails pour d'autres services
      # sshd-aggressive = {
      #   settings = {
      #     enabled = true;
      #     port = "ssh";
      #     filter = "sshd[mode=aggressive]";
      #     maxretry = 2;
      #     bantime = "24h";
      #   };
      # };
    };

    bantime-increment = {
      enable = true;        # Augmenter le ban à chaque récidive
      maxtime = "48h";      # Durée maximale de bannissement
      factor = "4";         # Multiplicateur à chaque récidive
    };
  };

  # Persister la base Fail2ban pour ne pas perdre les bans au reboot
  # (géré par impermanence via /var/lib)

  # ══════════════════════════════════════════════════════════════════
  # 3. CLAMAV — Antivirus à la demande
  # ══════════════════════════════════════════════════════════════════
  # ClamAV ne scanne PAS en temps réel par défaut (trop lourd).
  # Utilisation manuelle :
  #   clamscan ~/Downloads/          # Scanner un dossier
  #   clamscan -r --bell ~/Projects/ # Scanner récursivement
  #   freshclam                      # Mettre à jour les signatures
  services.clamav = {
    daemon.enable = true;
    updater = {
      enable = true;
      interval = "daily";     # Mise à jour des signatures quotidienne
      frequency = 1;          # 1 fois par jour
    };
  };

  # ══════════════════════════════════════════════════════════════════
  # 4. DNS-OVER-TLS — Résolution DNS chiffrée et vie privée
  # ══════════════════════════════════════════════════════════════════
  # Utilise systemd-resolved pour chiffrer les requêtes DNS
  # Empêche le FAI de voir les domaines visités
  services.resolved = {
    enable = true;

    # DNSSEC — validation de l'authenticité des réponses DNS
    dnssec = "true";

    # Domaines à résoudre via resolved
    domains = [ "~." ];

    # Configuration DNS-over-TLS via settings
    # ← ADAPTER : remplacer par vos serveurs DNS préférés
    #   Cloudflare : 1.1.1.1#cloudflare-dns.com  (rapide)
    #   Mullvad :    194.242.2.2#dns.mullvad.net  (pas de logs, suédois)
    #   AdGuard :    94.140.14.14#dns.adguard.com (bloque pubs + trackers)
    # DNS-over-TLS via extraConfig (compatible stable + unstable)
    # AdGuard DNS — bloque malware + trackers + pubs au niveau DNS
    # En plus du DNS-over-TLS (chiffrement), AdGuard filtre les domaines
    # malveillants avant même que le navigateur les charge.
    # Alternative : Quad9 (9.9.9.9#dns.quad9.net) — anti-malware sans blocage pubs
    extraConfig = ''
      [Resolve]
      DNS=94.140.14.14#dns.adguard-dns.com 94.140.15.15#dns.adguard-dns.com
      FallbackDNS=9.9.9.9#dns.quad9.net 1.1.1.1#cloudflare-dns.com
      DNSOverTLS=yes
    '';
  };

  # Note : networking.networkmanager.dns est défini dans networking.nix
  # pour éviter les doublons.

  # ══════════════════════════════════════════════════════════════════
  # 5. AUDIT — Journalisation des accès système
  # ══════════════════════════════════════════════════════════════════
  # Trace les accès fichiers, les changements de permissions,
  # les exécutions de programmes, etc.
  # Consulter les logs : sudo ausearch -ts recent
  #                      sudo aureport --summary
  security.auditd.enable = true;
  security.audit = {
    enable = true;
    rules = [
      # Surveiller les modifications des fichiers système critiques
      "-w /etc/passwd -p wa -k identity"
      "-w /etc/group -p wa -k identity"
      "-w /etc/shadow -p wa -k identity"
      "-w /etc/sudoers -p wa -k sudoers"

      # Surveiller les exécutions de programmes sensibles
      "-w /usr/bin/sudo -p x -k privilege_escalation"
      "-w /usr/bin/su -p x -k privilege_escalation"

      # Surveiller les changements de la configuration NixOS
      "-w /etc/nixos -p wa -k nixos_config"

      # Optionnel : ajouter vos propres règles d'audit
      # Voir : man auditctl
    ];
  };

  # ══════════════════════════════════════════════════════════════════
  # 6. USBGUARD — Protection contre les clés USB malveillantes
  # ══════════════════════════════════════════════════════════════════
  #
  # ⚠️ ATTENTION : USBGuard bloque TOUS les périphériques USB
  #    non autorisés ! Cela inclut clavier/souris USB.
  #
  # ── Procédure de configuration initiale ──────────────────────────
  #
  # 1. D'abord, lister les périphériques USB actuellement connectés :
  #      sudo usbguard list-devices
  #
  # 2. Générer une politique initiale qui autorise les périphériques actuels :
  #      sudo usbguard generate-policy > /persist/system/usbguard/rules.conf
  #
  # 3. Activer USBGuard (décommenter ci-dessous)
  #
  # 4. Pour autoriser un nouveau périphérique temporairement :
  #      sudo usbguard allow-device <id>
  #
  # 5. Pour autoriser un nouveau périphérique définitivement :
  #      sudo usbguard allow-device <id> -p
  #
  services.usbguard = {
    enable = false; # ⚠️ Mettre à true APRÈS avoir généré la politique initiale
    rules = null;   # Utilise le fichier de règles par défaut
    presentDevicePolicy = "keep";       # Garder les périphériques déjà connectés
    insertedDevicePolicy = "apply-policy"; # Appliquer la politique aux nouveaux
    IPCAllowedUsers = [ "root" "kuro" ]; # ← ADAPTER : utilisateurs autorisés
  };

  # ⚠️ La persistence (fail2ban, clamav) est centralisée dans
  #    modules/impermanence.nix — ne PAS la déclarer ici.

  # ══════════════════════════════════════════════════════════════════
  # 7. HARDENING KERNEL ANSSI (R7-R14)
  # ══════════════════════════════════════════════════════════════════
  # Recommandations ANSSI pour le durcissement des systèmes GNU/Linux
  # Inspiré du projet Securix (cloud-gouv/securix, DINUM)
  # Référence : https://www.ssi.gouv.fr/guide/recommandations-de-securite-relatives-a-un-systeme-gnulinux/

  # ── R7 — IOMMU (protection DMA contre les attaques physiques) ────
  # ── R8 — Protections mémoire au boot ─────────────────────────────
  boot.kernelParams = lib.mkAfter [
    "iommu=force"                        # R7 : forcer l'IOMMU (anti-DMA attack)
    "page_poison=on"                     # R8 : empoisonner les pages mémoire libérées
    "slab_nomerge"                       # R8 : ne pas fusionner les slabs (anti-heap spray)
    "slub_debug=FZP"                     # R8 : debug allocateur SLUB (free/zombie/poison)
    "pti=on"                             # R8 : Page Table Isolation (anti-Meltdown)
    "spectre_v2=on"                      # R8 : mitigation Spectre v2
    "spec_store_bypass_disable=seccomp"  # R8 : mitigation Spectre v4
    "mce=0"                              # R8 : machine check exceptions strictes
    "page_alloc.shuffle=1"               # R8 : randomiser les allocations mémoire
    "l1tf=full,force"                    # R8 : mitigation L1 Terminal Fault
    "mds=full,nosmt"                     # R8 : mitigation Microarchitectural Data Sampling
  ];

  # ── R9 — Restrictions kernel ─────────────────────────────────────
  boot.kernel.sysctl = {
    # Seul root peut lire dmesg (masque les infos kernel aux utilisateurs)
    "kernel.dmesg_restrict" = 1;
    # Masquer les pointeurs kernel dans /proc (anti-info leak)
    "kernel.kptr_restrict" = 2;
    # PID max élevé (anti-PID prediction)
    "kernel.pid_max" = 1048576;
    # Restreindre perf_event (anti-side channel)
    "kernel.perf_event_paranoid" = 3;
    # ASLR complet (randomisation des adresses mémoire)
    "kernel.randomize_va_space" = 2;
    # Désactiver SysRq (pas de magic keys en production)
    "kernel.sysrq" = 0;
    # Restreindre BPF aux utilisateurs privilégiés
    "kernel.unprivileged_bpf_disabled" = 1;
    # Hardening BPF JIT
    "net.core.bpf_jit_harden" = 2;
    # Panic immédiat sur oops kernel (plutôt que continuer en état instable)
    "kernel.panic_on_oops" = 1;

    # ── R11 — Yama LSM (restriction ptrace) ────────────────────────
    # Un processus ne peut tracer que ses propres enfants
    "kernel.yama.ptrace_scope" = 1;

    # ── R12 — Durcissement IPv4 ────────────────────────────────────
    # Pas de forwarding (ce n'est pas un routeur)
    "net.ipv4.ip_forward" = 0;
    # Ignorer les ICMP redirects (anti-MITM)
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.secure_redirects" = 0;
    "net.ipv4.conf.default.secure_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
    # Pas de source routing (anti-spoofing)
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;
    # Reverse path filtering strict (anti-spoofing)
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    # Journaliser les paquets martiens (IPs impossibles)
    "net.ipv4.conf.all.log_martians" = 1;
    "net.ipv4.conf.default.log_martians" = 1;
    # Protection SYN flood
    "net.ipv4.tcp_syncookies" = 1;
    # RFC 1337 — protection TIME-WAIT assassination
    "net.ipv4.tcp_rfc1337" = 1;
    # Ne pas répondre aux broadcasts ICMP (anti-Smurf)
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    # Ignorer les faux messages ICMP error
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
    # Pas de timestamps TCP (anti-fingerprinting)
    "net.ipv4.tcp_timestamps" = 0;
    # ARP : répondre uniquement sur l'interface correcte
    "net.ipv4.conf.all.arp_ignore" = 1;
    "net.ipv4.conf.all.arp_announce" = 2;

    # ── R13 — IPv6 (optionnel : décommenter pour désactiver) ──────
    # "net.ipv6.conf.all.disable_ipv6" = 1;
    # "net.ipv6.conf.default.disable_ipv6" = 1;
    # Si IPv6 activé, hardening minimal :
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_source_route" = 0;
    "net.ipv6.conf.default.accept_source_route" = 0;

    # ── R14 — Protection filesystem ────────────────────────────────
    # Protéger les FIFOs dans les répertoires sticky (anti-symlink attack)
    "fs.protected_fifos" = 2;
    "fs.protected_regular" = 2;
    # Empêcher de suivre les symlinks/hardlinks dans les dirs sticky
    "fs.protected_symlinks" = 1;
    "fs.protected_hardlinks" = 1;
    # Pas de core dump pour les binaires SUID
    "fs.suid_dumpable" = 0;
  };

  # ══════════════════════════════════════════════════════════════════
  # 8. YUBIKEY — Support clé de sécurité matérielle
  # ══════════════════════════════════════════════════════════════════
  # Smart card daemon (nécessaire pour la communication avec la YubiKey)
  services.pcscd.enable = true;

  # Support USB pour les clés de sécurité FIDO2/U2F
  hardware.gpgSmartcards.enable = true;

  # ── PAM FIDO2 — Login par clé de sécurité (optionnel) ───────────
  # Décommenter pour activer le login par YubiKey :
  # security.pam.u2f = {
  #   enable = true;
  #   cue = true;  # Affiche "Touchez votre clé de sécurité..."
  #   control = "sufficient";  # La clé suffit (pas besoin de mot de passe)
  # };

  # ══════════════════════════════════════════════════════════════════
  # 9. APPARMOR — Confinement kernel des applications
  # ══════════════════════════════════════════════════════════════════
  # Plus robuste que Firejail (niveau kernel, pas userspace).
  # Les profils restreignent l'accès fichier/réseau par application.
  # Statut : sudo aa-status
  # Logs : sudo journalctl -t audit | grep apparmor
  security.apparmor = {
    enable = true;
    # Paquets de profils pré-configurés pour les apps courantes
    packages = with pkgs; [ apparmor-profiles ];
    # Mode par défaut : enforce (bloque les accès non autorisés)
    # Changer en "complain" pour logger sans bloquer (debug) :
    # killUnconfinedConfinables = false;
  };

  # ══════════════════════════════════════════════════════════════════
  # 10. SSH HARDENING AVANCÉ — Algorithmes modernes uniquement
  # ══════════════════════════════════════════════════════════════════
  # Restreindre aux algorithmes cryptographiques modernes et sûrs.
  # Élimine les algos legacy (RSA-SHA1, diffie-hellman-group1, etc.)
  services.openssh.settings = {
    # Seuls les algorithmes d'échange de clés modernes
    KexAlgorithms = [
      "sshd-ed25519"
      "curve25519-sha256"
      "curve25519-sha256@libssh.org"
    ];
    # Seuls les chiffrements modernes
    Ciphers = [
      "chacha20-poly1305@openssh.com"
      "aes256-gcm@openssh.com"
      "aes128-gcm@openssh.com"
    ];
    # Seuls les MAC modernes
    Macs = [
      "hmac-sha2-512-etm@openssh.com"
      "hmac-sha2-256-etm@openssh.com"
    ];
    # Clés hôtes : Ed25519 uniquement (le plus sûr et le plus rapide)
    HostKeyAlgorithms = "ssh-ed25519";
    # Désactiver l'agent forwarding (risque de vol de clé)
    AllowAgentForwarding = false;
    # Désactiver le X11 forwarding (pas de serveur X)
    X11Forwarding = false;
    # Timeout d'inactivité (déconnecte après 10min d'inactivité)
    ClientAliveInterval = 600;
    ClientAliveCountMax = 0;
    # Nombre max de tentatives d'auth par connexion
    MaxAuthTries = 3;
  };

  # ══════════════════════════════════════════════════════════════════
  # 11. MAC RANDOMIZATION WiFi — Anti-tracking physique
  # ══════════════════════════════════════════════════════════════════
  # Randomise l'adresse MAC à chaque connexion WiFi.
  # Empêche le tracking par les hotspots WiFi (aéroports, cafés, etc.)
  networking.networkmanager.wifi.macAddress = "random";
  networking.networkmanager.ethernet.macAddress = "preserve"; # Pas de random sur filaire

  # ══════════════════════════════════════════════════════════════════
  # Paquets de sécurité
  # ══════════════════════════════════════════════════════════════════
  environment.systemPackages = with pkgs; [
    usbguard              # CLI pour gérer les périphériques USB
    lynis                  # Outil d'audit de sécurité (lynis audit system)
    yubikey-personalization # Configuration de la YubiKey
    yubikey-manager        # GUI/CLI pour gérer la YubiKey (ykman)
    yubico-pam             # Module PAM pour auth YubiKey
    age-plugin-yubikey     # Chiffrer les secrets age/sops avec la YubiKey
  ];
}
