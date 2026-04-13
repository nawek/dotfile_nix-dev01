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

    # ← ADAPTER : ajouter vos outils de développement ici
    # Exemples :
    # postman         # Client API graphique
    # insomnia        # Alternative à Postman
    # dbeaver-bin     # Client base de données universel
    # k9s             # Interface TUI pour Kubernetes
  ];
}
