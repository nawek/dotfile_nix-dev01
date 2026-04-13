# ╔══════════════════════════════════════════════════════════════════╗
# ║  Outils de développement CLI                                   ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Outils en ligne de commande utiles pour le développement.
# Séparés des paquets système (configuration.nix) pour garder
# une distinction claire entre outils système et outils dev.

{ config, pkgs, ... }: {

  home.packages = with pkgs; [
    # HTTP — client HTTP moderne (alternative à curl pour le dev)
    httpie

    # Base de données — client SQLite pour le debug et le prototypage
    sqlite

    # Statistiques — compteur de lignes de code par langage
    tokei

    # Benchmarking — benchmark précis de commandes
    hyperfine

    # Task runner — alternative moderne à Make
    just

    # Diff — outil de diff structurel (comprend la syntaxe)
    difftastic

    # Shell structuré pour la manipulation de données (JSON, CSV, tables)
    # Usage : nushell (pas shell par défaut, juste disponible comme outil)
    nushell

    # TUI pour bases de données SQL (comme lazygit mais pour les BDD)
    # Optionnel : décommenter quand le paquet sera dans nixpkgs
    # lazysql

    # Client HTTP TUI — décommenter quand disponible dans nixpkgs
    # posting

    # ── Homelab / IaC ───────────────────────────────────────────────
    ansible           # Gestion de config serveurs non-NixOS
    ansible-lint      # Linter pour les playbooks Ansible

    # Optionnel : ajouter vos outils de développement ici
  ];

  # ── Mise (ex-rtx) — Gestionnaire de runtimes polyglotte ─────────
  # Alternative légère aux devShells Nix pour le quotidien.
  # Gère les versions de Python, Node, Go, Ruby, etc. par projet.
  #
  # Usage :
  #   mise install python@3.12      → installe Python 3.12
  #   mise use python@3.12          → active dans le dossier courant
  #   mise ls                       → liste les runtimes installés
  #   mise run test                 → exécute une tâche définie dans mise.toml
  #
  # Mise et Nix devShells sont complémentaires :
  # - devShells : environnements reproductibles (CI, projets partagés)
  # - Mise : prototypage rapide, scripts, projets personnels
  programs.mise = {
    enable = true;
    enableZshIntegration = true;
    # Paramètres globaux
    globalConfig = {
      settings = {
        experimental = true;    # Activer les fonctionnalités expérimentales
        auto_install = true;    # Installer automatiquement les runtimes manquants
      };
    };
  };
}
