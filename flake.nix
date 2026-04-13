# ╔══════════════════════════════════════════════════════════════════╗
# ║  NixOS Configuration — Kuro (PC de développement)              ║
# ║  Flake principal : définit tous les inputs et outputs          ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Ce fichier est le point d'entrée de toute la configuration.
# Il déclare les dépendances (inputs), la configuration système
# (nixosConfigurations) et les environnements de dev (devShells).

{
  description = "Configuration NixOS de Kuro — PC de développement";

  # ──────────────────────────────────────────────────────────────────
  # INPUTS — Toutes les dépendances externes
  # ──────────────────────────────────────────────────────────────────
  inputs = {
    # Nixpkgs — branche unstable pour les paquets les plus récents
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home Manager — gestion déclarative de l'environnement utilisateur
    # Intégré comme module NixOS (pas standalone)
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs"; # Évite de dupliquer nixpkgs
    };

    # Disko — partitionnement déclaratif des disques
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Impermanence — persistence sélective avec effacement root au boot
    # Note : pas d'input nixpkgs à suivre pour ce flake
    impermanence.url = "github:nix-community/impermanence";

    # Lanzaboote — Secure Boot pour NixOS
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # SOPS-nix — gestion des secrets chiffrés avec age
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hyprland — compositeur Wayland (flake officiel)
    hyprland.url = "github:hyprwm/Hyprland";

    # Stylix — thème global cohérent (GTK, QT, terminal, waybar, etc.)
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Fenix — toolchains Rust via Mozilla (pour les dev shells)
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-index-database — base de données pré-construite pour nix-index / comma
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # ──────────────────────────────────────────────────────────────────
  # OUTPUTS — Ce que ce flake produit
  # ──────────────────────────────────────────────────────────────────
  outputs = { self, nixpkgs, home-manager, disko, impermanence,
              lanzaboote, sops-nix, hyprland, stylix, fenix,
              nix-index-database, ... } @ inputs:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in
  {
    # ── Configuration NixOS principale ──────────────────────────────
    nixosConfigurations.kuro = nixpkgs.lib.nixosSystem {
      inherit system;

      # specialArgs rend `inputs` accessible dans TOUS les modules
      specialArgs = { inherit inputs; };

      modules = [
        # Modules externes (flakes)
        disko.nixosModules.disko
        impermanence.nixosModules.default    # ⚠️ .default, PAS .impermanence
        lanzaboote.nixosModules.lanzaboote
        sops-nix.nixosModules.sops
        stylix.nixosModules.stylix
        nix-index-database.nixosModules.nix-index

        # Home Manager comme module NixOS
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;       # Utilise le nixpkgs du système
            useUserPackages = true;     # Installe les paquets dans /etc/profiles
            extraSpecialArgs = { inherit inputs; }; # inputs dispo dans les modules home
            users.kuro = import ./home/default.nix; # ← ADAPTER : nom d'utilisateur
          };
        }

        # Configuration hôte
        ./hosts/kuro/configuration.nix
      ];
    };

    # ── Dev Shells — environnements de développement isolés ────────
    # Usage : nix develop .#python | .#node | .#rust | .#go | .#cc
    devShells.${system} = {
      python = import ./devshells/python.nix { inherit pkgs; };
      node   = import ./devshells/node.nix { inherit pkgs; };
      rust   = import ./devshells/rust.nix { inherit pkgs; fenix = inputs.fenix; };
      go     = import ./devshells/go.nix { inherit pkgs; };
      cc     = import ./devshells/cc.nix { inherit pkgs; };
      infra  = import ./devshells/infra.nix { inherit pkgs; };
    };

    # ── Templates — Bootstrapper un nouveau projet ─────────────────
    # Usage : nix flake init -t /home/kuro/nixos-config#<lang>
    # Crée un flake.nix + .envrc + .gitignore prêts à l'emploi
    templates = {
      python = {
        description = "Projet Python 3.12 avec ruff, pyright et virtualenv";
        path = ./templates/python;
      };
      node = {
        description = "Projet Node.js 22 avec pnpm et TypeScript";
        path = ./templates/node;
      };
      rust = {
        description = "Projet Rust stable avec fenix, rust-analyzer et cargo-watch";
        path = ./templates/rust;
      };
      go = {
        description = "Projet Go avec gopls, delve et golangci-lint";
        path = ./templates/go;
      };
      cc = {
        description = "Projet C/C++ avec GCC, Clang, CMake, GDB et Valgrind";
        path = ./templates/cc;
      };
    };
  };
}
