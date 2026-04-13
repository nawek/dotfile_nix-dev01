# ╔══════════════════════════════════════════════════════════════════╗
# ║  Spotify — Client thémé via Spicetify (Catppuccin + extensions) ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Spicetify injecte un thème et des extensions dans le client Spotify.
# Tout est déclaratif : le thème, les extensions, le tout reproductible.
#
# Extensions incluses :
# - adblock : supprime les publicités audio et visuelles
# - hidePodcasts : masque la section podcasts
# - shuffle+ : meilleur algorithme de shuffle
# - keyboardShortcut : raccourcis clavier améliorés
# - fullAppDisplay : mode plein écran avec visualisation
# - playlistIcons : icônes pour les playlists
#
# Thème : Catppuccin Mocha (cohérent avec le reste du système)

{ config, pkgs, inputs, lib, ... }:
let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system};
in
{
  # Importer le module Home Manager de spicetify-nix
  imports = [ inputs.spicetify-nix.homeManagerModules.default ];

  programs.spicetify = {
    enable = true;

    # ── Thème Catppuccin Mocha (override Stylix qui injecte son propre thème)
    theme = lib.mkForce spicePkgs.themes.catppuccin;
    colorScheme = lib.mkForce "mocha";

    # ── Extensions ─────────────────────────────────────────────────
    enabledExtensions = with spicePkgs.extensions; [
      adblock              # Bloque les pubs audio et visuelles
      hidePodcasts         # Masque les podcasts de l'interface
      shuffle              # Meilleur algorithme de shuffle (shuffle+)
      keyboardShortcut     # Raccourcis clavier enrichis
      fullAppDisplay       # Mode plein écran avec artwork
      playlistIcons        # Icônes personnalisées pour les playlists

      # Optionnel : autres extensions disponibles
      # betterGenres       # Genres améliorés
      # lastfm             # Scrobbling Last.fm
      # songStats          # Statistiques de la chanson en cours
    ];

    # Optionnel : custom apps disponibles
    # enabledCustomApps = with spicePkgs.apps; [
    #   lyricsPlus         # Paroles synchronisées
    #   marketplace        # Marketplace d'extensions dans Spotify
    # ];
  };
}
