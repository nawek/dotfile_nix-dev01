# Template Rust — généré par : nix flake init -t /home/kuro/nixos-config#rust
{
  description = "Projet Rust avec Nix devShell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, fenix, ... }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    toolchain = fenix.packages.${system}.stable.withComponents [
      "cargo" "clippy" "rust-src" "rustc" "rustfmt"
    ];
  in {
    devShells.${system}.default = pkgs.mkShell {
      name = "rust-project";
      packages = [
        toolchain
        fenix.packages.${system}.rust-analyzer
        pkgs.cargo-watch
        pkgs.cargo-edit
        pkgs.pkg-config
        pkgs.openssl
      ];
      RUST_SRC_PATH = "${toolchain}/lib/rustlib/src/rust/library";
      shellHook = ''
        echo "Rust $(rustc --version) prêt"
      '';
    };
  };
}
