# Piste 3 — Debug & Code Generation

**Branche :** `feat/debug-tests`
**Outil principal :** Claude Code / Cline

## Périmètre
- Résolution des bugs complexes (analyse de stack traces, bisect, instrumentation).
- Exécution de la génération de code : `build_runner`, freezed, json_serializable, mocks.
- Écriture des tests unitaires, de widgets et d'intégration ; mise en place de la couverture.

## Zones de fichiers
- `test/**`, `integration_test/**`
- Fichiers générés `*.g.dart`, `*.freezed.dart`, `*.mocks.dart`
- Correctifs ciblés partout ailleurs, à condition de rester minimaux.

## Commandes de référence
```bash
flutter analyze
dart run build_runner build --delete-conflicting-outputs
flutter test --coverage
```

## Hors périmètre
- Refonte d'architecture ou d'UI : signaler à la piste concernée plutôt que réécrire.

## Contrat d'intégration
Tout bug corrigé arrive avec un test qui échouait avant le correctif.
