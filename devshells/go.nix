# ╔══════════════════════════════════════════════════════════════════╗
# ║  Dev Shell Go — Go + gopls + delve + golangci-lint              ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Usage : nix develop .#go
# Ou via direnv : echo "use flake .#go" > .envrc && direnv allow

{ pkgs }: pkgs.mkShell {
  name = "go-dev";

  packages = with pkgs; [
    # Runtime Go
    go            # ← ADAPTER : go_1_21 pour une version spécifique

    # LSP et outils
    gopls         # Serveur de langage Go
    delve         # Débugueur Go
    golangci-lint # Linter multi-rules

    # Outils Go courants
    gotools       # goimports, gorename, etc.
    go-tools      # staticcheck
  ];

  # Variables d'environnement Go
  GOPATH = "$HOME/go";

  shellHook = ''
    echo "Environnement Go $(go version | cut -d' ' -f3) activé"
    echo "gopls, delve, golangci-lint disponibles"
  '';
}
