# ╔══════════════════════════════════════════════════════════════════╗
# ║  Dev Shell Rust — Toolchain stable via Fenix                   ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Usage : nix develop .#rust
# Ou via direnv : echo "use flake .#rust" > .envrc && direnv allow
#
# Utilise Fenix pour fournir une toolchain Rust complète
# (cargo, clippy, rustfmt, rust-analyzer intégré)
#
# ⚠️ Ce fichier reçoit `fenix` en argument depuis flake.nix
#    (pas disponible via pkgs)

{ pkgs, fenix }:
let
  # Toolchain Rust stable avec tous les composants nécessaires
  toolchain = fenix.packages.${pkgs.system}.stable.withComponents [
    "cargo"
    "clippy"
    "rust-src"      # Sources Rust (nécessaire pour rust-analyzer)
    "rustc"
    "rustfmt"
  ];
in
pkgs.mkShell {
  name = "rust-dev";

  packages = [
    # Toolchain Rust complète
    toolchain

    # LSP Rust — version de rust-analyzer compatible avec la toolchain
    fenix.packages.${pkgs.system}.rust-analyzer

    # Outils Cargo supplémentaires
    pkgs.cargo-watch   # Recompilation automatique au changement de fichier
    pkgs.cargo-edit    # cargo add/rm/upgrade pour gérer les dépendances

    # Dépendances système fréquemment nécessaires pour les crates
    pkgs.pkg-config    # Détection des bibliothèques système
    pkgs.openssl       # TLS (reqwest, actix, etc.)

    # ← ADAPTER : ajouter d'autres dépendances système ici
    # pkgs.sqlite        # Pour rusqlite
    # pkgs.protobuf      # Pour tonic/prost (gRPC)
  ];

  # Chemin vers les sources Rust (nécessaire pour rust-analyzer)
  RUST_SRC_PATH = "${toolchain}/lib/rustlib/src/rust/library";

  shellHook = ''
    echo "Environnement Rust $(rustc --version) activé"
    echo "rust-analyzer, clippy, rustfmt, cargo-watch, cargo-edit disponibles"
  '';
}
