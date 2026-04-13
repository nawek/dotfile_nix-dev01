# ╔══════════════════════════════════════════════════════════════════╗
# ║  Dev Shell Infra — OpenTofu + Ansible + outils IaC              ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Usage : nix develop .#infra
# Ou via direnv : echo "use flake .#infra" > .envrc && direnv allow
#
# Pour gérer le homelab : Proxmox, Cloudflare, Docker, etc.

{ pkgs }: pkgs.mkShell {
  name = "infra-dev";

  packages = with pkgs; [
    # IaC
    opentofu          # Fork open-source de Terraform
    terragrunt        # Wrapper DRY pour OpenTofu/Terraform
    tflint            # Linter Terraform/OpenTofu
    terraform-docs    # Génération de documentation

    # Config management
    ansible
    ansible-lint

    # Conteneurs
    docker-compose

    # Kubernetes (si applicable)
    kubectl
    k9s               # TUI Kubernetes
    helm              # Package manager Kubernetes

    # Cloud CLIs — décommenter selon vos providers
    # awscli2         # AWS
    # azure-cli       # Azure
    # (google-cloud-sdk) # GCP
  ];

  shellHook = ''
    echo "Environnement Infra activé"
    echo "  OpenTofu $(tofu version | head -1)"
    echo "  Ansible $(ansible --version | head -1)"
    echo "  kubectl, k9s, helm disponibles"
  '';
}
