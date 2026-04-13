# Template Go — généré par : nix flake init -t /home/kuro/nixos-config#go
{
  description = "Projet Go avec Nix devShell";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = with pkgs; [ go gopls delve golangci-lint gotools ];
      shellHook = ''echo "Go $(go version | cut -d' ' -f3) prêt"'';
    };
  };
}
