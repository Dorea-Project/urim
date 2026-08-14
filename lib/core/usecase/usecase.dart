import 'package:urim/core/result/result.dart';

/// Contrat d'un cas d'usage : une intention métier, une seule opération
/// publique. L'implémentation vit dans `domain/usecases/`.
///
/// ```dart
/// final class GetProfile implements UseCase<Profile, String> {
///   const GetProfile(this._repository);
///   final ProfileRepository _repository;
///
///   @override
///   Future<Result<Profile>> call(String userId) =>
///       _repository.fetchProfile(userId);
/// }
/// ```
abstract interface class UseCase<T, P> {
  Future<Result<T>> call(P params);
}

/// Variante synchrone, pour les règles purement calculatoires (validation,
/// dérivation) qui n'ont aucune raison d'être asynchrones.
abstract interface class SyncUseCase<T, P> {
  Result<T> call(P params);
}

/// Variante réactive, pour les sources qui émettent dans la durée
/// (websocket, écoute d'une base locale).
abstract interface class StreamUseCase<T, P> {
  Stream<Result<T>> call(P params);
}

/// Paramètre vide, pour les cas d'usage sans entrée.
final class NoParams {
  const NoParams();

  @override
  bool operator ==(Object other) => other is NoParams;

  @override
  int get hashCode => 0;
}
