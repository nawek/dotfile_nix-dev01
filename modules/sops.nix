# ╔══════════════════════════════════════════════════════════════════╗
# ║  SOPS-nix — Gestion des secrets chiffrés avec age              ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Les secrets sont stockés chiffrés dans le dépôt Git (secrets/secrets.yaml)
# et déchiffrés au boot par sops-nix grâce à une clé age.
#
# ── Configuration initiale ─────────────────────────────────────────
#
# 1. Générer une clé age :
#      mkdir -p /persist/system
#      age-keygen -o /persist/system/sops-age-keys.txt
#
# 2. Copier la clé publique affichée (age1...) dans .sops.yaml
#
# 3. Créer/éditer les secrets :
#      sops secrets/secrets.yaml
#    → L'éditeur s'ouvre, modifier les valeurs, sauvegarder
#    → Le fichier est automatiquement chiffré à la sauvegarde
#
# 4. Pour le mot de passe utilisateur, générer un hash :
#      mkpasswd -m sha-512 "votre_mot_de_passe"
#    → Coller le hash comme valeur de user-password dans sops

{ config, inputs, ... }: {
  sops = {
    # Fichier de secrets par défaut (chiffré avec age)
    defaultSopsFile = ../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";

    # Clé age pour le déchiffrement — sur la partition persistante
    # ⚠️ Ce fichier doit exister AVANT le premier nixos-rebuild
    age.keyFile = "/persist/system/sops-age-keys.txt";

    # ── Secrets déclarés ───────────────────────────────────────────
    secrets = {
      # Mot de passe utilisateur (hash SHA-512)
      # neededForUsers = true : disponible au stade d'activation des utilisateurs
      # (avant que la session démarre, nécessaire pour hashedPasswordFile)
      "user-password" = {
        neededForUsers = true;
      };

      # Optionnel : ajouter vos secrets ici
      # Exemples :
      #
      # "github-token" = {
      #   owner = "kuro";  # ← ADAPTER : nom d'utilisateur
      # };
      #
      # "ssh-private-key" = {
      #   path = "/home/kuro/.ssh/id_ed25519";  # ← ADAPTER
      #   owner = "kuro";
      #   mode = "0600";
      # };
      #
      # "wifi-password" = { };
    };
  };
}
