# Vault Obsidian — CITADEL

Structure organisée en méthode **PARA** (Projects, Areas, Resources, Archive) adaptée pour un sysadmin/dev.

## Structure

```
Inbox/          → Capture rapide (notes brutes, idées, liens)
Journal/        → Daily notes (une par jour, auto-générée)
Projects/       → Projets actifs (limité dans le temps)
Areas/          → Domaines permanents (NixOS, Docker, Homelab...)
  ├── NixOS/
  ├── Docker/
  ├── Homelab/
  ├── Sécurité/
  └── Réseau/
Resources/      → Référence (cheatsheets, runbooks, ADRs)
  ├── Cheatsheets/
  ├── Runbooks/
  └── ADRs/
Archive/        → Projets terminés
Templates/      → Templates de notes
```

## Workflow quotidien

1. **Inbox** → tout ce qui arrive (idées, liens, bugs) va ici
2. **Journal** → daily note auto-générée au login (revue du jour)
3. **Traitement** → déplacer les notes de l'Inbox vers Projects/Areas/Resources
4. **Weekly review** → archiver les projets terminés, nettoyer l'Inbox

## Extensions Obsidian recommandées

Installer au premier lancement via les Community Plugins :
- **Templater** — templates avancés avec variables dynamiques
- **Calendar** — vue calendrier des daily notes
- **Dataview** — requêtes SQL-like sur les notes (lister les TODOs, projets actifs, etc.)
- **Kanban** — tableaux Kanban dans les notes
- **Excalidraw** — dessins/diagrammes dans les notes
- **Git** — backup Git intégré (en plus de notre auto-commit systemd)
- **Periodic Notes** — daily/weekly/monthly notes automatiques
- **Outliner** — meilleure gestion des listes imbriquées
