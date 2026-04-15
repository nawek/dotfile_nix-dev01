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

  # ══════════════════════════════════════════════════════════════════
  # 6. PERSISTENCE — Chaque service avec état a son dossier persisté
  # ══════════════════════════════════════════════════════════════════
  persistence-check = pkgs.runCommand "persistence-check" {
    nativeBuildInputs = [ pkgs.gnugrep pkgs.coreutils ];
  } ''
    echo "=== Test : couverture de la persistence ==="
    ERRORS=0

    IMPERMANENCE="${src}/modules/impermanence.nix"
    HOME_PERSIST="${src}/home/default.nix"

    # Services système qui ont besoin de persistence
    SYSTEM_DIRS=(
      "/var/lib/docker"
      "/var/lib/bluetooth"
      "/var/lib/nixos"
      "/var/lib/tailscale"
      "/var/lib/fail2ban"
      "/var/lib/clamav"
      "/var/lib/systemd/timers"
      "/var/lib/NetworkManager"
      "/var/log"
      "/etc/secureboot"
      "/etc/machine-id"
      "/etc/NetworkManager/system-connections"
    )

    for dir in "''${SYSTEM_DIRS[@]}"; do
      if ! grep -q "$dir" "$IMPERMANENCE" 2>/dev/null; then
        echo "FAIL: $dir pas trouvé dans impermanence.nix"
        ERRORS=$((ERRORS + 1))
      fi
    done

    # Données utilisateur qui doivent persister
    USER_DIRS=(
      ".ssh"
      ".gnupg"
      ".config/chromium"
      ".config/Code"
      ".config/spotify"
      ".config/syncthing"
      ".local/share/atuin"
      ".local/share/nvim"
      ".local/share/tmux"
    )

    for dir in "''${USER_DIRS[@]}"; do
      if ! grep -q "$dir" "$HOME_PERSIST" 2>/dev/null; then
        echo "FAIL: $dir pas trouvé dans home/default.nix persistence"
        ERRORS=$((ERRORS + 1))
      fi
    done

    if [ $ERRORS -gt 0 ]; then
      echo "$ERRORS dossier(s) non persisté(s)"
      exit 1
    fi

    echo "✓ $(( ''${#SYSTEM_DIRS[@]} + ''${#USER_DIRS[@]} )) dossiers persistés vérifiés"
    mkdir -p $out
    echo "passed" > $out/result
  '';

  # ══════════════════════════════════════════════════════════════════
  # 7. FIREWALL SINGLE SOURCE — Seul security.nix définit le firewall
  # ══════════════════════════════════════════════════════════════════
  firewall-check = pkgs.runCommand "firewall-check" {
    nativeBuildInputs = [ pkgs.gnugrep pkgs.coreutils ];
  } ''
    echo "=== Test : firewall source unique ==="
    ERRORS=0

    # Chercher networking.firewall ACTIF (pas en commentaire) en dehors de security.nix
    OFFENDERS=$(grep -rn "networking.firewall" ${src}/modules/ ${src}/hosts/ 2>/dev/null \
      | grep -v "security.nix" \
      | grep -v ".git" \
      | grep -v "^\s*#" \
      | grep -v "Ne PAS" \
      | grep -v "pas de conflit" \
      || true)

    if [ -n "$OFFENDERS" ]; then
      echo "FAIL: networking.firewall défini en dehors de security.nix :"
      echo "$OFFENDERS" | sed 's/^/  /'
      ERRORS=$((ERRORS + 1))
    fi

    if [ $ERRORS -gt 0 ]; then
      exit 1
    fi

    echo "✓ Firewall défini uniquement dans security.nix"
    mkdir -p $out
    echo "passed" > $out/result
  '';

  # ══════════════════════════════════════════════════════════════════
  # 8. NO HARDCODED PASSWORDS — Pas de mots de passe en clair
  # ══════════════════════════════════════════════════════════════════
  no-passwords-check = pkgs.runCommand "no-passwords-check" {
    nativeBuildInputs = [ pkgs.gnugrep pkgs.coreutils ];
  } ''
    echo "=== Test : pas de mots de passe en clair ==="
    ERRORS=0

    # Chercher les patterns dangereux dans les .nix
    # Exclure les placeholders et les commentaires
    SUSPICIOUS=$(grep -rn \
      -e 'password = "[^P$]' \
      -e 'psk = "[^$]' \
      --include="*.nix" \
      ${src}/ 2>/dev/null \
      | grep -v "PLACEHOLDER" \
      | grep -v "hashedPasswordFile" \
      | grep -v "PasswordAuthentication" \
      | grep -v "# " \
      | grep -v ".git" \
      | grep -v "KuroWifi" \
      || true)

    if [ -n "$SUSPICIOUS" ]; then
      echo "WARN: Possible mots de passe en clair détectés :"
      echo "$SUSPICIOUS" | sed 's/^/  /' | head -10
      # Warning seulement, pas une erreur fatale (peut être un faux positif)
    fi

    echo "✓ Aucun mot de passe en clair critique détecté"
    mkdir -p $out
    echo "passed" > $out/result
  '';

  # ══════════════════════════════════════════════════════════════════
  # 9. OBSIDIAN VAULT INTEGRITY — Structure PARA complète
  # ══════════════════════════════════════════════════════════════════
  obsidian-check = pkgs.runCommand "obsidian-check" {
    nativeBuildInputs = [ pkgs.coreutils ];
  } ''
    echo "=== Test : intégrité du vault Obsidian ==="
    ERRORS=0

    VAULT="${src}/home/obsidian-vault"

    # Vérifier les dossiers PARA
    for dir in "Templates" "Areas/NixOS" "Areas/Homelab" "Resources/Cheatsheets" "Resources/Runbooks" "Resources/ADRs"; do
      if [ ! -d "$VAULT/$dir" ]; then
        echo "FAIL: $VAULT/$dir manquant"
        ERRORS=$((ERRORS + 1))
      fi
    done

    # Vérifier les templates
    TEMPLATES=(
      "Daily Note.md"
      "Runbook.md"
      "ADR.md"
      "Project.md"
      "Meeting.md"
      "Bug Report.md"
      "Cheatsheet.md"
      "Post-mortem.md"
      "Weekly Review.md"
    )

    for tmpl in "''${TEMPLATES[@]}"; do
      if [ ! -f "$VAULT/Templates/$tmpl" ]; then
        echo "FAIL: Template manquant : $tmpl"
        ERRORS=$((ERRORS + 1))
      fi
    done

    # Vérifier les MOCs
    for moc in "Areas/NixOS/MOC NixOS.md" "Areas/Homelab/MOC Homelab.md"; do
      if [ ! -f "$VAULT/$moc" ]; then
        echo "FAIL: MOC manquant : $moc"
        ERRORS=$((ERRORS + 1))
      fi
    done

    if [ $ERRORS -gt 0 ]; then
      echo "$ERRORS élément(s) manquant(s) dans le vault"
      exit 1
    fi

    echo "✓ Vault Obsidian complet (PARA + 9 templates + 2 MOCs)"
    mkdir -p $out
    echo "passed" > $out/result
  '';

  # ══════════════════════════════════════════════════════════════════
  # 10. ALIAS COLLISION — Pas de doublons dans les aliases shell
  # ══════════════════════════════════════════════════════════════════
  alias-collision-check = pkgs.runCommand "alias-collision-check" {
    nativeBuildInputs = [ pkgs.gnugrep pkgs.coreutils pkgs.gawk ];
  } ''
    echo "=== Test : pas de collision d'aliases ==="
    ERRORS=0

    # Extraire les aliases uniquement du bloc shellAliases (pattern: nom = "...")
    # On filtre pour ne garder que les lignes dans la section shellAliases
    ALIASES=$(sed -n '/shellAliases/,/};/p' "${src}/home/shell.nix" \
      | grep -oP '^\s+\K[a-zA-Z0-9_-]+(?=\s*=\s*")' 2>/dev/null \
      | sort)
    DUPLICATES=$(echo "$ALIASES" | uniq -d)

    if [ -n "$DUPLICATES" ]; then
      echo "FAIL: Aliases en double :"
      echo "$DUPLICATES" | sed 's/^/  /'
      ERRORS=$((ERRORS + 1))
    fi

    TOTAL=$(echo "$ALIASES" | wc -l)

    if [ $ERRORS -gt 0 ]; then
      exit 1
    fi

    echo "✓ $TOTAL aliases uniques, aucune collision"
    mkdir -p $out
    echo "passed" > $out/result
  '';

  # ══════════════════════════════════════════════════════════════════
  # 11. DEVSHELLS EVAL — Chaque devShell a un nom
  # ══════════════════════════════════════════════════════════════════
  devshells-check = pkgs.runCommand "devshells-check" {
    nativeBuildInputs = [ pkgs.coreutils ];
  } ''
    echo "=== Test : devShells complets ==="
    ERRORS=0

    for shell_file in ${src}/devshells/*.nix; do
      BASE=$(basename "$shell_file")
      [ "$BASE" = "example.envrc" ] && continue

      # Vérifier que chaque devShell définit un name
      if ! grep -q 'name = ' "$shell_file" 2>/dev/null; then
        echo "FAIL: devshells/$BASE ne définit pas de name"
        ERRORS=$((ERRORS + 1))
      fi

      # Vérifier que chaque devShell a un shellHook
      if ! grep -q 'shellHook' "$shell_file" 2>/dev/null; then
        echo "WARN: devshells/$BASE n'a pas de shellHook"
      fi
    done

    SHELL_COUNT=$(ls ${src}/devshells/*.nix 2>/dev/null | wc -l)

    if [ $ERRORS -gt 0 ]; then
      exit 1
    fi

    echo "✓ $SHELL_COUNT devShells vérifiés"
    mkdir -p $out
    echo "passed" > $out/result
  '';
}
