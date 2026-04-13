# ╔══════════════════════════════════════════════════════════════════╗
# ║  Dev Shell C/C++ — GCC, Clang, CMake, GDB, Valgrind            ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Usage : nix develop .#cc
# Ou via direnv : echo "use flake .#cc" > .envrc && direnv allow
#
# Fournit les deux compilateurs (GCC et Clang) pour flexibilité.
# Par défaut, GCC est le compilateur CC. Pour utiliser Clang :
#   CC=clang CXX=clang++ cmake ..

{ pkgs }: pkgs.mkShell {
  name = "cc-dev";

  packages = with pkgs; [
    # Compilateurs
    gcc           # GCC (C/C++)
    clang         # Clang/LLVM (C/C++)

    # Build system
    cmake
    gnumake
    ninja         # Backend rapide pour CMake

    # Debug et profiling
    gdb           # Débugueur GNU
    valgrind      # Détection de fuites mémoire
    lldb          # Débugueur LLVM (alternative à GDB)

    # LSP
    clang-tools   # clangd (LSP), clang-format, clang-tidy

    # Dépendances système fréquentes
    pkg-config
    openssl
    zlib
  ];

  shellHook = ''
    echo "Environnement C/C++ activé"
    echo "  GCC $(gcc --version | head -1 | cut -d' ' -f4)"
    echo "  Clang $(clang --version | head -1 | cut -d' ' -f4)"
    echo "  CMake $(cmake --version | head -1 | cut -d' ' -f3)"
    echo "  gdb, valgrind, clangd disponibles"
  '';
}
