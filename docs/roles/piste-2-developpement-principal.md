# Piste 2 — Développement principal

**Branche :** `feat/core-architecture`
**Outil principal :** Cursor (ou VS Code + Copilot)

## Périmètre
- Mise en place de l'architecture (Clean Architecture / MVVM).
- Gestion d'état, injection de dépendances, routage.
- Règles métier, entités, use cases, repositories, sources de données.

## Zones de fichiers
- `lib/domain/**` (entités, use cases, interfaces de repository)
- `lib/data/**` (implémentations, DTO, datasources)
- `lib/core/**` (DI, config, erreurs, routage)
- `lib/presentation/**/*_view_model.dart` (ViewModels uniquement)
- `ARCHITECTURE.md` et les `README.md` de couche sous `lib/`

## Hors périmètre
- Design visuel et composants purement UI → piste 1 (`feat/ui-prototype`).
- Écriture des suites de tests → piste 3 (`feat/debug-tests`).

## Contrat d'intégration
Le domaine ne dépend d'aucun framework. Les ViewModels exposent un état immuable
et des méthodes d'intention ; ils ne connaissent aucun widget.
