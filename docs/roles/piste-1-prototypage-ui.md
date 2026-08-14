# Piste 1 — Prototypage & UI

**Branche :** `feat/ui-prototype`
**Outil principal :** FlutterFlow AI / v0

## Périmètre
- Maquettage visuel rapide, itérations sur les écrans.
- Génération des composants UI de base (design system, thème, widgets réutilisables).
- Écrans « coquilles » : navigation, états visuels (loading / empty / error), responsive.

## Zones de fichiers
- `lib/presentation/**` (widgets, pages, thème)
- `assets/**`

## Hors périmètre
- Règles métier, appels réseau, persistance → piste 2 (`feat/core-architecture`).
- Aucun couplage direct à une source de données : les écrans consomment des ViewModels/mocks.

## Contrat d'intégration
Livrer des widgets **stateless et paramétrés** (données en entrée, callbacks en sortie),
afin que la piste 2 puisse les brancher sans les réécrire.
