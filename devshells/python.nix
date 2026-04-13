# ╔══════════════════════════════════════════════════════════════════╗
# ║  Dev Shell Python — Python 3.12 + outils de dev                ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Usage : nix develop .#python
# Ou via direnv : echo "use flake .#python" > .envrc && direnv allow
#
# Crée automatiquement un virtualenv .venv si absent
# (utile pour pip install de dépendances projet)

{ pkgs }: pkgs.mkShell {
  name = "python-dev";

  packages = with pkgs; [
    # Runtime Python
    python312         # ← ADAPTER : version Python
    python312Packages.pip
    python312Packages.virtualenv
    python312Packages.ipython   # REPL amélioré

    # Linting et formatage
    ruff              # Linter + formateur ultra-rapide (remplace flake8, black, isort)

    # Typage statique
    pyright           # LSP et vérificateur de types
  ];

  # Script exécuté à l'entrée dans le shell
  shellHook = ''
    # Créer un virtualenv si absent (pour les dépendances pip du projet)
    if [ ! -d ".venv" ]; then
      echo "Création du virtualenv .venv..."
      python -m venv .venv
    fi
    source .venv/bin/activate
    echo "Environnement Python $(python --version) activé"
  '';
}
