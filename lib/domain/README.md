# Couche domaine

Le cœur métier. **Ne dépend de rien** : ni Flutter, ni Dio, ni base de données.
Un fichier de cette couche ne doit importer que `dart:*`, `package:equatable`
et d'autres fichiers de `domain/` ou `core/`.

C'est la règle qui rend le métier testable sans émulateur et remplaçable sans
réécriture.

## Contenu

| Dossier | Rôle |
|---|---|
| `entities/` | Objets métier immuables, identifiés par leur sens, pas par leur sérialisation. |
| `repositories/` | **Interfaces** décrivant ce dont le métier a besoin. Aucune implémentation. |
| `usecases/` | Une intention métier par classe, implémentant `UseCase<T, P>`. |

## Sens de la dépendance

`data` → `domain` ← `presentation`

Les deux couches externes dépendent du domaine ; le domaine n'en connaît
aucune. L'inversion se fait par les interfaces de `repositories/`, que `data`
implémente.

## Exemple

```dart
// domain/entities/profile.dart
final class Profile extends Equatable {
  const Profile({required this.id, required this.name});
  final String id;
  final String name;
  @override
  List<Object?> get props => [id, name];
}

// domain/repositories/profile_repository.dart
abstract interface class ProfileRepository {
  Future<Result<Profile>> fetchProfile(String userId);
}

// domain/usecases/get_profile.dart
final class GetProfile implements UseCase<Profile, String> {
  const GetProfile(this._repository);
  final ProfileRepository _repository;

  @override
  Future<Result<Profile>> call(String userId) =>
      _repository.fetchProfile(userId);
}
```
