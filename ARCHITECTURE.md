# Architecture d'Urim

Clean Architecture à trois couches, présentation en MVVM.

> Ce document décrit le **socle** et le **modèle de domaine**, posés par la
> piste 2. Le détail des entités et des règles métier est dans
> [`lib/domain/README.md`](lib/domain/README.md).

Urim tient sur deux domaines reliés par la référence biblique : la **lecture
du texte** (`entities/bible/`) et le **discernement pastoral**
(`entities/pastoral/`) — consigner une question, les passages qui l'éclairent,
et la décision qui en découle.

## Règle unique

```
data  ──────►  domain  ◄──────  presentation
```

`domain` ne dépend de personne. Les deux autres couches en dépendent, jamais
l'inverse. Cette règle rend le métier testable sans émulateur, et permet de
remplacer l'API, la base locale ou toute l'interface sans y toucher.

L'inversion se fait par les interfaces : `domain/repositories/` déclare le
besoin, `data/repositories/` fournit l'implémentation.

## Arborescence

```
lib/
├── main.dart                  Point d'entrée : lit la config, monte ProviderScope
├── app.dart                   Racine MaterialApp.router
├── core/                      Socle transverse, sans métier
│   ├── config/                AppConfig + provider (valeurs par --dart-define)
│   ├── error/                 AppException (technique) → Failure (métier)
│   ├── network/               Client Dio partagé + traduction des DioException
│   ├── result/                Result<T> : Success | Failed
│   ├── router/                GoRouter et constantes de routes
│   └── usecase/               Contrats UseCase / SyncUseCase / StreamUseCase
├── domain/                    Métier pur — voir domain/README.md
├── data/                      Réseau, cache, DTO — voir data/README.md
└── presentation/              ViewModels + UI — voir presentation/README.md
```

## Choix techniques

| Besoin | Choix | Motif |
|---|---|---|
| État & injection | `flutter_riverpod` 3.x | Injection et gestion d'état par le même mécanisme : pas de conteneur DI séparé. Substitution triviale en test via `overrides`. |
| Navigation | `go_router` 17.x | Routage déclaratif, URL cohérentes sur le web, `redirect` centralisé pour les gardes d'authentification. |
| HTTP | `dio` 5.x | Intercepteurs, timeouts, annulation. Confiné à `core/network` et aux datasources. |
| Égalité de valeur | `equatable` | Comparaison structurelle des entités et des `Failure`, indispensable aux assertions de test. |
| Génération de code | `freezed`, `json_serializable` | Pour les DTO et les unions de la couche data. Le socle n'en dépend pas : il compile sans aucune génération. |

## Gestion des erreurs

Trois étages, une seule conversion :

1. **Datasource** — lève une `AppException` (`ServerException`, `NetworkException`,
   `CacheException`, `UnauthorizedException`). `mapDioException` traduit Dio.
2. **Repository** — capture l'`AppException`, la convertit avec `toFailure()`
   et renvoie un `Result.failed(...)`. **Aucune exception ne franchit cette
   frontière.**
3. **ViewModel / UI** — reçoit un `Result` ou une `Failure`, jamais une
   exception. Le message affichable est produit par l'UI, pas par le domaine.

```dart
final result = await getProfile(userId);
result.fold(
  onSuccess: (profile) => state = AsyncData(profile),
  onFailure: (failure) => state = AsyncError(failure, StackTrace.current),
);
```

## Ajouter une fonctionnalité

L'ordre compte : il garantit qu'on écrit le métier avant de l'habiller.

1. `domain/entities/` — l'entité, immuable, sans annotation de sérialisation.
2. `domain/repositories/` — l'interface, en `Future<Result<T>>`.
3. `domain/usecases/` — un cas d'usage par intention, implémentant `UseCase`.
4. `data/models/` — le DTO et sa conversion `toEntity()`.
5. `data/datasources/` — l'accès brut, qui lève des `AppException`.
6. `data/repositories/` — l'implémentation, qui convertit en `Failure`.
7. `presentation/<ecran>/` — le ViewModel, puis l'écran.

Chaque étape est testable seule : les étapes 1 à 3 sans aucun mock d'infrastructure.

## Configuration

Aucun secret dans le dépôt. Tout passe par `--dart-define` :

```bash
flutter run \
  --dart-define=FLAVOR=staging \
  --dart-define=API_BASE_URL=https://api.staging.urim.app
```

Sans surcharge, `AppConfig.fromEnvironment()` retombe sur le profil `dev`.

## Répartition entre les pistes

| Zone | Piste | Branche |
|---|---|---|
| `core/`, `domain/`, `data/`, `presentation/**/*_view_model.dart` | 2 — Développement principal | `feat/core-architecture` |
| `presentation/` (pages, widgets, thème), `assets/` | 1 — Prototypage & UI | `feat/ui-prototype` |
| `test/`, `integration_test/`, fichiers générés | 3 — Debug & Code Generation | `feat/debug-tests` |
| `docs/`, CI, conventions | 4 — Supervision CTO | `chore/cto-supervision` |

Le détail des contrats est dans le `README.md` de chaque couche.

## Ce qui n'est pas encore fait

- **Aucune implémentation de `data/`.** Les deux dépôts du domaine
  (`BibleRepository`, `PastoralQuestionRepository`) n'ont pas de mise en
  œuvre : la provenance du texte biblique — embarqué, API, ou hybride avec
  cache — n'est pas tranchée. Le domaine étant muet là-dessus, la décision
  n'obligera à rien réécrire en amont.
- **Aucune persistance locale choisie** (Drift, Isar, `shared_preferences`).
  Le module décisionnel en aura besoin : ses données sont créées et
  consultées hors ligne.
- **Aucune authentification** : l'intercepteur Dio et le `redirect` du routeur
  sont des emplacements réservés.
- **Aucune localisation** : à décider par la piste 4 avant que les écrans ne
  se multiplient. Les messages d'erreur du domaine sont techniques et ne sont
  pas destinés à l'affichage tel quel.
- **Aucun suivi de personnes.** Un module de communauté impliquerait des
  données personnelles sensibles, à cadrer avant d'écrire la première ligne.
