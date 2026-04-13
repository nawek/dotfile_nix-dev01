# Template Python — généré par : nix flake init -t /home/kuro/nixos-config#python
{
  description = "Projet Python avec Nix devShell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { nixpkgs, ... }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    devShells.${system}.default = pkgs.mkShell {
      name = "python-project";
      packages = with pkgs; [
        python312
        python312Packages.pip
        python312Packages.virtualenv
        python312Packages.ipython
        ruff
        pyright
      ];
      shellHook = ''
        if [ ! -d ".venv" ]; then
          echo "Création du virtualenv .venv..."
          python -m venv .venv
        fi
        source .venv/bin/activate
        echo "Python $(python --version) prêt"
      '';
    };
  };
}
