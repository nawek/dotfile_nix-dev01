# Template C/C++ — généré par : nix flake init -t /home/kuro/nixos-config#cc
{
  description = "Projet C/C++ avec Nix devShell";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = with pkgs; [ gcc clang cmake gnumake ninja gdb valgrind clang-tools pkg-config ];
      shellHook = ''echo "C/C++ (GCC + Clang + CMake) prêt"'';
    };
  };
}
