# ╔══════════════════════════════════════════════════════════════════╗
# ║  treefmt — Formatage automatique multi-langages                 ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Formate automatiquement les fichiers du projet :
# - Nix → alejandra (style standard communauté)
# - Shell → shfmt
# - YAML/JSON → prettier
#
# Usage :
#   nix fmt           → formate tout le projet
#   treefmt           → idem (si treefmt est installé)
#   treefmt --fail-on-change  → vérification CI (ne modifie rien)

{ pkgs, ... }: {
  projectRootFile = "flake.nix";

  programs = {
    # Nix — alejandra (formateur Nix opinionated)
    alejandra.enable = true;

    # Shell — shfmt (formateur de scripts shell)
    shfmt = {
      enable = true;
      indent_size = 2;
    };

    # YAML/JSON/Markdown — prettier
    prettier.enable = true;
  };
}
