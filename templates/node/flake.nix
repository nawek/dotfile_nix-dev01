# Template Node.js — généré par : nix flake init -t /home/kuro/nixos-config#node
{
  description = "Projet Node.js avec Nix devShell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { nixpkgs, ... }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    devShells.${system}.default = pkgs.mkShell {
      name = "node-project";
      packages = with pkgs; [
        nodejs_22
        nodePackages.pnpm
        nodePackages.typescript
        nodePackages.typescript-language-server
        nodePackages.prettier
      ];
      shellHook = ''
        echo "Node $(node --version) + pnpm $(pnpm --version) prêt"
      '';
    };
  };
}
