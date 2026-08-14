# Piste 4 — Superviseur CTO

**Branche :** `chore/cto-supervision`
**Rôle :** arbitrage technique et intégration

## Périmètre
- Arbitrer les décisions d'architecture et les conflits entre pistes.
- Relire et intégrer les branches dans `main` (ordre, cohérence, dette technique).
- Tenir les documents de cadrage : ADR, conventions, définition de « terminé ».
- Surveiller la qualité transverse : dépendances, CI, performances, sécurité.

## Zones de fichiers
- `docs/**` (ADR, conventions, roadmap)
- `README.md`, `analysis_options.yaml`, configuration CI
- `CLAUDE.md` (instructions partagées par toutes les pistes)

## Ordre d'intégration recommandé
1. `feat/core-architecture` — pose les contrats.
2. `feat/ui-prototype` — se branche sur les ViewModels existants.
3. `feat/debug-tests` — verrouille le comportement.

## Rituel de revue
Avant chaque merge dans `main` :
```bash
flutter analyze && flutter test
```
Aucune branche ne fusionne avec des tests rouges ou un `analyze` non vide.
