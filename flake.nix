# ╔══════════════════════════════════════════════════════════════════╗
# ║  CITADEL — Configuration NixOS (PC de développement)            ║
# ║  Flake principal : inputs, outputs, devShells, templates        ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Ce fichier est le point d'entrée de toute la configuration.
# Le nom d'utilisateur et le hostname sont passés via des variables
# pour faciliter la réutilisation sur d'autres machines.

{
  description = "CITADEL — Configuration NixOS modulaire et reproductible";

  # ──────────────────────────────────────────────────────────────────
  # INPUTS — Toutes les dépendances externes
  # ──────────────────────────────────────────────────────────────────
  inputs = {
    # Nixpkgs — branche stable pour la fiabilité
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    # Home Manager — gestion déclarative de l'environnement utilisateur
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Disko — partitionnement déclaratif des disques
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Impermanence — persistence sélective avec effacement root au boot
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
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs"; # Évite une deuxième copie de nixpkgs
    };

    # Stylix — thème global cohérent (GTK, QT, terminal, waybar, etc.)
    stylix = {
      url = "github:danth/stylix/release-25.05";
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

    # Spicetify — Spotify thémé et enrichi (extensions, adblock, Catppuccin)
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
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
    lib = nixpkgs.lib;

    # ── Variables centralisées ────────────────────────────────────
    # Modifier ici pour changer le nom d'utilisateur ou l'hostname
    # sans chercher/remplacer dans tous les fichiers.
    username = "kuro";       # ← ADAPTER : nom d'utilisateur
    hostname = "kuro";       # ← ADAPTER : hostname de la machine

    # ── Helper pour créer une nixosConfiguration ─────────────────
    # Réutilisable pour ajouter d'autres machines (vm-dev, serveur, etc.)
    mkHost = { hostName, userName ? username, extraModules ? [] }: nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = { inherit inputs; username = userName; hostname = hostName; };

      modules = [
        # Modules externes (flakes)
        disko.nixosModules.disko
        impermanence.nixosModules.default
        lanzaboote.nixosModules.lanzaboote
        sops-nix.nixosModules.sops
        stylix.nixosModules.stylix
        nix-index-database.nixosModules.nix-index

        # Home Manager comme module NixOS
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs; username = userName; };
            users.${userName} = import ./home/default.nix;
          };
        }

        # Configuration hôte (résolu dynamiquement par hostName)
        (./hosts + "/${hostName}/configuration.nix")
      ] ++ extraModules;
    };
  in
  {
    # ── Configurations NixOS ──────────────────────────────────────
    # Ajouter d'autres machines ici :
    nixosConfigurations.${hostname} = mkHost { hostName = hostname; userName = username; };

    # vm-test — config minimale sans Home Manager complet
    nixosConfigurations.vm-test = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; username = username; hostname = "vm-test"; };
      modules = [
        stylix.nixosModules.stylix
        ./hosts/vm-test/configuration.nix
      ];
    };

    # ── Checks — Tests automatisés ───────────────────────────────
    checks.${system} = import ./tests { inherit pkgs lib; };

    # ── NixOS Modules — Réutilisables depuis d'autres flakes ─────
    # Usage depuis un autre flake :
    #   inputs.citadel.url = "github:nawek/dotfile_nix-dev01";
    #   modules = [ inputs.citadel.nixosModules.security ];
    nixosModules = {
      security     = import ./modules/security;  # Dossier avec default.nix
      networking   = import ./modules/networking.nix;
      monitoring   = import ./modules/monitoring.nix;
      impermanence = import ./modules/impermanence.nix;
      automations  = import ./modules/automations.nix;
      ux           = import ./modules/ux.nix;
      hyprland     = import ./modules/hyprland.nix;
      nvidia       = import ./modules/nvidia.nix;
      stylix       = import ./modules/stylix.nix;
      plymouth     = import ./modules/plymouth.nix;
      disko        = import ./modules/disko.nix;
      lanzaboote   = import ./modules/lanzaboote.nix;
      sops         = import ./modules/sops.nix;
    };

    # ── Dev Shells — environnements de développement isolés ──────
    # Usage : nix develop (shell par défaut) | nix develop .#python | etc.
    devShells.${system} = {
      default = import ./devshells/python.nix { inherit pkgs; }; # Shell par défaut
      python  = import ./devshells/python.nix { inherit pkgs; };
      node    = import ./devshells/node.nix { inherit pkgs; };
      rust    = import ./devshells/rust.nix { inherit pkgs; fenix = inputs.fenix; };
      go      = import ./devshells/go.nix { inherit pkgs; };
      cc      = import ./devshells/cc.nix { inherit pkgs; };
      infra   = import ./devshells/infra.nix { inherit pkgs; };
    };

    # ── Templates — Bootstrapper un nouveau projet ───────────────
    templates = {
      python = { description = "Python 3.12 + ruff + pyright"; path = ./templates/python; };
      node   = { description = "Node.js 22 + pnpm + TypeScript"; path = ./templates/node; };
      rust   = { description = "Rust stable + fenix + rust-analyzer"; path = ./templates/rust; };
      go     = { description = "Go + gopls + delve"; path = ./templates/go; };
      cc     = { description = "C/C++ + GCC + Clang + CMake"; path = ./templates/cc; };
    };
  };
}
