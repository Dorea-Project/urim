# Couche data

Implémente les interfaces déclarées dans `domain/repositories/`. C'est la
seule couche qui connaît le réseau, le cache et les formats de sérialisation.

## Contenu

| Dossier | Rôle |
|---|---|
| `datasources/` | Accès brut à une source : `*RemoteDataSource` (Dio), `*LocalDataSource` (cache). Lèvent des `AppException`. |
| `models/` | DTO de transport : sérialisation JSON et conversion vers/depuis les entités. |
| `repositories/` | Implémentations concrètes : orchestrent les datasources et traduisent les exceptions en `Failure`. |

## Règle de traduction des erreurs

Aucune `AppException` ne franchit la couche data. Le repository est le point
de conversion :

```dart
final class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._remote);
  final ProfileRemoteDataSource _remote;

  @override
  Future<Result<Profile>> fetchProfile(String userId) async {
    try {
      final model = await _remote.fetchProfile(userId);
      return Result.success(model.toEntity());
    } on AppException catch (e) {
      return Result.failed(e.toFailure());
    }
  }
}
```

`toFailure()` est fourni par `core/error/error_mapper.dart`.

## Modèles et entités restent distincts

Un `ProfileModel` porte la forme de l'API (champs nullables, noms
`snake_case`, dates en chaînes) ; l'entité `Profile` porte la forme du métier.
Les fusionner fait remonter chaque changement d'API jusque dans le domaine.
