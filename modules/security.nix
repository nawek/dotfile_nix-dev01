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
      # 51820 # WireGuard — décommenter si VPN utilisé
    ];

    # Plages de ports pour les applications qui en ont besoin
    # allowedTCPPortRanges = [{ from = 3000; to = 3100; }]; # Dev servers

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

    # Durée du bannissement (en secondes) — 10 minutes par défaut
    bantime = "10m";

    # Fenêtre d'observation — période pendant laquelle les tentatives sont comptées
    findtime = "10m";

    # Nombre de tentatives avant bannissement
    maxretry = 5;

    # Configuration des jails (services surveillés)
    jails = {
      # SSH — protection contre les tentatives de connexion
      sshd = {
        settings = {
          enabled = true;
          port = "ssh";
          filter = "sshd";
          maxretry = 3;       # Plus strict pour SSH
          bantime = "1h";     # Ban d'1 heure pour SSH
        };
      };
    };

    # ← ADAPTER : ajouter des jails pour d'autres services
    # Exemple pour Nginx :
    # jails.nginx-http-auth = {
    #   settings = {
    #     enabled = true;
    #     port = "http,https";
    #     filter = "nginx-http-auth";
    #     maxretry = 5;
    #   };
    # };

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

    # DNS principaux — Quad9 (respectueux de la vie privée, bloque le malware)
    # ← ADAPTER : alternatives populaires :
    #   Cloudflare : 1.1.1.1#cloudflare-dns.com  (rapide)
    #   Mullvad :    194.242.2.2#dns.mullvad.net  (pas de logs, suédois)
    #   AdGuard :    94.140.14.14#dns.adguard.com (bloque pubs + trackers)
    dns = [
      "9.9.9.9#dns.quad9.net"         # Quad9 principal
      "149.112.112.112#dns.quad9.net"  # Quad9 secondaire
    ];

    # Forcer le DNS-over-TLS
    dnsovertls = "true"; # "true" = obligatoire, "opportunistic" = si disponible

    # Fallback DNS (non chiffré, utilisé uniquement si le DoT échoue)
    fallbackDns = [
      "1.1.1.1#cloudflare-dns.com"
      "8.8.8.8#dns.google"
    ];

    # DNSSEC — validation de l'authenticité des réponses DNS
    dnssec = "true";

    # Domaines à résoudre localement (pas via DoT)
    # ← ADAPTER : ajouter vos domaines internes
    domains = [ "~." ]; # Tous les domaines via resolved
  };

  # Désactiver le DNS de NetworkManager (resolved s'en charge)
  networking.networkmanager.dns = "systemd-resolved";

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

      # ← ADAPTER : ajouter vos propres règles d'audit
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

  # ══════════════════════════════════════════════════════════════════
  # Persistance des données de sécurité (impermanence)
  # ══════════════════════════════════════════════════════════════════
  # Les données Fail2ban, ClamAV et audit doivent survivre aux reboots
  environment.persistence."/persist/system" = {
    directories = [
      "/var/lib/fail2ban"    # Base de données des bans
      "/var/lib/clamav"      # Signatures antivirus
    ];
  };

  # ══════════════════════════════════════════════════════════════════
  # Paquets de sécurité
  # ══════════════════════════════════════════════════════════════════
  environment.systemPackages = with pkgs; [
    usbguard       # CLI pour gérer les périphériques USB
    lynis           # Outil d'audit de sécurité (lynis audit system)
  ];
}
