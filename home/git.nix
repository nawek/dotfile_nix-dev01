# ╔══════════════════════════════════════════════════════════════════╗
# ║  Git — Configuration avec Delta et SSH                         ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Configuration Git déclarative avec :
# - Delta pour des diffs lisibles (side-by-side, line numbers)
# - Bonnes pratiques : rebase par défaut, auto-setup remote
# - Agent SSH intégré pour l'authentification GitHub

{ config, pkgs, ... }: {

  # ── Git ──────────────────────────────────────────────────────────
  programs.git = {
    enable = true;
    userName = "Kuro";                      # ← ADAPTER
    userEmail = "votre@email.com";          # ← ADAPTER

    # Branche par défaut
    extraConfig = {
      init.defaultBranch = "main";

      # Rebase par défaut au lieu de merge lors d'un pull
      pull.rebase = true;

      # Configurer automatiquement le tracking upstream au premier push
      push.autoSetupRemote = true;

      # Éditeur par défaut pour les commits
      core.editor = "code --wait"; # ← ADAPTER : "nvim" si vous préférez

      # Style de conflit amélioré (montre l'ancêtre commun)
      merge.conflictstyle = "zdiff3";

      # Mémoriser les résolutions de conflits précédentes
      rerere.enabled = true;
    };

    # ── Delta — Diffs améliorés ────────────────────────────────────
    # Le thème de coloration est géré par Stylix via BAT_THEME
    # ⚠️ Ne PAS définir syntax-theme ici (conflit avec Stylix)
    delta = {
      enable = true;
      options = {
        navigate = true;      # Navigation entre les hunks avec n/N
        line-numbers = true;  # Numéros de lignes dans le diff
        side-by-side = true;  # Affichage côte-à-côte
      };
    };
  };

  # ── GitHub CLI ───────────────────────────────────────────────────
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh"; # Utiliser SSH pour les opérations Git
    };
  };

  # ── SSH — Agent et configuration ─────────────────────────────────
  programs.ssh = {
    enable = true;
    addKeysToAgent = "yes"; # Ajouter les clés à l'agent automatiquement

    # ← ADAPTER : configurer vos hôtes SSH
    matchBlocks = {
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519"; # ← ADAPTER : chemin de votre clé
      };

      # ← ADAPTER : ajouter vos serveurs ici
      # "mon-serveur" = {
      #   hostname = "192.168.1.100";
      #   user = "admin";
      #   identityFile = "~/.ssh/id_ed25519";
      # };
    };
  };

  # Agent SSH (gère les clés en mémoire)
  services.ssh-agent.enable = true;
}
