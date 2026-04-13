# ╔══════════════════════════════════════════════════════════════════╗
# ║  Dev Shell Node.js — Node 22 + pnpm + TypeScript               ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Usage : nix develop .#node
# Ou via direnv : echo "use flake .#node" > .envrc && direnv allow

{ pkgs }: pkgs.mkShell {
  name = "node-dev";

  packages = with pkgs; [
    # Runtime Node.js
    nodejs_22         # ← ADAPTER : version Node.js (nodejs_20, nodejs_22)

    # Gestionnaire de paquets
    nodePackages.pnpm # ou yarn, npm suffit via nodejs

    # TypeScript
    nodePackages.typescript
    nodePackages.typescript-language-server # LSP TypeScript

    # Formatage
    nodePackages.prettier
  ];

  shellHook = ''
    echo "Environnement Node.js $(node --version) + pnpm $(pnpm --version) activé"
  '';
}
