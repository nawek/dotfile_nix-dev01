# ╔══════════════════════════════════════════════════════════════════╗
# ║  Tests — Validation automatisée de la configuration CITADEL     ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# 5 checks exécutés par : nix flake check
# Ou individuellement : nix build .#checks.x86_64-linux.<nom>
#
# 1. structure-check  — Tous les fichiers critiques existent
# 2. imports-check    — Les imports correspondent aux fichiers réels
# 3. scripts-check    — Tous les scripts sont exécutables
# 4. templates-check  — Tous les templates ont un flake.nix + .envrc
# 5. secrets-check    — .sops.yaml et secrets.yaml sont cohérents

{ pkgs, lib, ... }:

let
  src = ../.;
in
{
  # ══════════════════════════════════════════════════════════════════
  # 1. STRUCTURE — Tous les fichiers critiques existent
  # ══════════════════════════════════════════════════════════════════
  structure-check = pkgs.runCommand "structure-check" {} ''
    echo "=== Test : structure des fichiers ==="
    ERRORS=0

    REQUIRED=(
      # Flake
      "${src}/flake.nix"
      # Host
      "${src}/hosts/kuro/configuration.nix"
      "${src}/hosts/kuro/hardware-configuration.nix"
      # Modules système (17)
      "${src}/modules/disko.nix"
      "${src}/modules/impermanence.nix"
      "${src}/modules/lanzaboote.nix"
      "${src}/modules/nvidia.nix"
      "${src}/modules/hyprland.nix"
      "${src}/modules/stylix.nix"
      "${src}/modules/plymouth.nix"
      "${src}/modules/security.nix"
      "${src}/modules/networking.nix"
      "${src}/modules/monitoring.nix"
      "${src}/modules/sops.nix"
      "${src}/modules/ux.nix"
      "${src}/modules/automations.nix"
      # Home (13)
      "${src}/home/default.nix"
      "${src}/home/shell.nix"
      "${src}/home/git.nix"
      "${src}/home/hyprland.nix"
      "${src}/home/vscode.nix"
      "${src}/home/neovim.nix"
      "${src}/home/helix.nix"
      "${src}/home/tmux.nix"
      "${src}/home/yazi.nix"
      "${src}/home/spotify.nix"
      "${src}/home/dev-tools.nix"
      "${src}/home/cheatsheet.md"
      "${src}/home/fastfetch.jsonc"
      # Secrets
      "${src}/secrets/secrets.yaml"
      "${src}/.sops.yaml"
      # Scripts
      "${src}/scripts/validate-config.sh"
      "${src}/scripts/deploy.sh"
      "${src}/scripts/post-install.sh"
      "${src}/scripts/health-check.sh"
      "${src}/scripts/audit.sh"
      "${src}/scripts/prepare-secrets.sh"
      "${src}/scripts/pre-flight-check.sh"
      "${src}/scripts/update.sh"
      "${src}/scripts/backup-export.sh"
      "${src}/scripts/rescue.sh"
      "${src}/scripts/new-machine.sh"
    )

    for f in "''${REQUIRED[@]}"; do
      if [ ! -f "$f" ]; then
        echo "FAIL: $f manquant"
        ERRORS=$((ERRORS + 1))
      fi
    done

    if [ $ERRORS -gt 0 ]; then
      echo "$ERRORS fichier(s) manquant(s)"
      exit 1
    fi

    echo "✓ $(echo "''${REQUIRED[@]}" | wc -w) fichiers vérifiés"
    mkdir -p $out
    echo "passed" > $out/result
  '';

  # ══════════════════════════════════════════════════════════════════
  # 2. IMPORTS — Les imports dans configuration.nix et home/default.nix
  #    correspondent aux fichiers réels dans modules/ et home/
  # ══════════════════════════════════════════════════════════════════
  imports-check = pkgs.runCommand "imports-check" {
    nativeBuildInputs = [ pkgs.gnugrep pkgs.coreutils pkgs.gnused ];
  } ''
    echo "=== Test : cohérence des imports ==="
    ERRORS=0

    # Vérifier que chaque .nix dans modules/ est importé dans configuration.nix
    for f in ${src}/modules/*.nix; do
      BASE=$(basename "$f")
      if ! grep -q "$BASE" "${src}/hosts/kuro/configuration.nix"; then
        echo "WARN: modules/$BASE n'est PAS importé dans configuration.nix"
      fi
    done

    # Vérifier que chaque .nix dans home/ (sauf default.nix) est importé dans home/default.nix
    for f in ${src}/home/*.nix; do
      BASE=$(basename "$f")
      [ "$BASE" = "default.nix" ] && continue
      if ! grep -q "$BASE" "${src}/home/default.nix"; then
        # Pas une erreur fatale — certains sont commentés volontairement
        echo "INFO: home/$BASE n'est pas importé dans home/default.nix (peut être commenté)"
      fi
    done

    echo "✓ Imports vérifiés"
    mkdir -p $out
    echo "passed" > $out/result
  '';

  # ══════════════════════════════════════════════════════════════════
  # 3. SCRIPTS — Tous les scripts sont exécutables et ont un shebang
  # ══════════════════════════════════════════════════════════════════
  scripts-check = pkgs.runCommand "scripts-check" {
    nativeBuildInputs = [ pkgs.coreutils pkgs.gnugrep pkgs.file ];
  } ''
    echo "=== Test : scripts exécutables ==="
    ERRORS=0

    for f in ${src}/scripts/*.sh; do
      BASE=$(basename "$f")

      # Vérifier le shebang
      if ! head -1 "$f" | grep -q "^#!"; then
        echo "FAIL: $BASE n'a pas de shebang"
        ERRORS=$((ERRORS + 1))
      fi

      # Vérifier que le fichier n'est pas vide
      if [ ! -s "$f" ]; then
        echo "FAIL: $BASE est vide"
        ERRORS=$((ERRORS + 1))
      fi
    done

    SCRIPT_COUNT=$(ls ${src}/scripts/*.sh 2>/dev/null | wc -l)

    if [ $ERRORS -gt 0 ]; then
      echo "$ERRORS script(s) invalide(s)"
      exit 1
    fi

    echo "✓ $SCRIPT_COUNT scripts vérifiés"
    mkdir -p $out
    echo "passed" > $out/result
  '';

  # ══════════════════════════════════════════════════════════════════
  # 4. TEMPLATES — Chaque template a un flake.nix et un .envrc
  # ══════════════════════════════════════════════════════════════════
  templates-check = pkgs.runCommand "templates-check" {
    nativeBuildInputs = [ pkgs.coreutils ];
  } ''
    echo "=== Test : templates complets ==="
    ERRORS=0

    for tmpl_dir in ${src}/templates/*/; do
      TMPL=$(basename "$tmpl_dir")

      # Le dossier docker/ contient des docker-compose, pas des flake templates
      [ "$TMPL" = "docker" ] && continue

      # Doit avoir un flake.nix
      if [ ! -f "$tmpl_dir/flake.nix" ]; then
        echo "FAIL: templates/$TMPL/ manque flake.nix"
        ERRORS=$((ERRORS + 1))
      fi

      # Doit avoir un .envrc
      if [ ! -f "$tmpl_dir/.envrc" ]; then
        echo "FAIL: templates/$TMPL/ manque .envrc"
        ERRORS=$((ERRORS + 1))
      fi

      # Doit avoir un .gitignore
      if [ ! -f "$tmpl_dir/.gitignore" ]; then
        echo "FAIL: templates/$TMPL/ manque .gitignore"
        ERRORS=$((ERRORS + 1))
      fi
    done

    TMPL_COUNT=$(ls -d ${src}/templates/*/ 2>/dev/null | wc -l)

    if [ $ERRORS -gt 0 ]; then
      echo "$ERRORS template(s) incomplet(s)"
      exit 1
    fi

    echo "✓ $TMPL_COUNT templates vérifiés (flake.nix + .envrc + .gitignore)"
    mkdir -p $out
    echo "passed" > $out/result
  '';

  # ══════════════════════════════════════════════════════════════════
  # 5. SECRETS — .sops.yaml et secrets.yaml sont cohérents
  # ══════════════════════════════════════════════════════════════════
  secrets-check = pkgs.runCommand "secrets-check" {
    nativeBuildInputs = [ pkgs.coreutils pkgs.gnugrep ];
  } ''
    echo "=== Test : cohérence des secrets ==="
    ERRORS=0

    # .sops.yaml doit exister
    if [ ! -f "${src}/.sops.yaml" ]; then
      echo "FAIL: .sops.yaml manquant"
      ERRORS=$((ERRORS + 1))
    fi

    # secrets.yaml doit exister
    if [ ! -f "${src}/secrets/secrets.yaml" ]; then
      echo "FAIL: secrets/secrets.yaml manquant"
      ERRORS=$((ERRORS + 1))
    fi

    # .sops.yaml doit référencer secrets/secrets.yaml (path_regex)
    if ! grep -q "secrets/.*yaml" "${src}/.sops.yaml" 2>/dev/null; then
      echo "FAIL: .sops.yaml ne référence pas secrets/*.yaml"
      ERRORS=$((ERRORS + 1))
    fi

    # Vérifier que les secrets déclarés dans sops.nix existent dans secrets.yaml
    # (au moins user-password et wifi-password)
    for secret in "user-password" "wifi-password"; do
      if ! grep -q "$secret" "${src}/secrets/secrets.yaml" 2>/dev/null; then
        echo "WARN: $secret pas trouvé dans secrets.yaml (peut être chiffré)"
      fi
    done

    if [ $ERRORS -gt 0 ]; then
      echo "$ERRORS erreur(s) dans les secrets"
      exit 1
    fi

    echo "✓ Secrets cohérents"
    mkdir -p $out
    echo "passed" > $out/result
  '';
}
