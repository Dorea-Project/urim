import 'package:urim/core/error/failure.dart';

/// Résultat d'une opération susceptible d'échouer.
///
/// Rend l'échec explicite dans la signature : un use case renvoie
/// `Future<Result<T>>` plutôt que de lever une exception. L'appelant est
/// obligé de traiter les deux cas, et l'exhaustivité est vérifiée à la
/// compilation grâce au `switch` sur un type scellé.
///
/// ```dart
/// final result = await getProfile(userId);
/// final label = result.fold(
///   onSuccess: (profile) => profile.name,
///   onFailure: (failure) => failure.message,
/// );
/// ```
sealed class Result<T> {
  const Result();

  const factory Result.success(T value) = Success<T>;

  const factory Result.failed(Failure failure) = Failed<T>;

  bool get isSuccess => this is Success<T>;

  bool get isFailure => this is Failed<T>;

  /// Valeur en cas de succès, `null` sinon. À réserver aux cas où l'échec
  /// est sans conséquence ; préférer [fold] partout ailleurs.
  T? get valueOrNull => switch (this) {
        Success<T>(:final value) => value,
        Failed<T>() => null,
      };

  Failure? get failureOrNull => switch (this) {
        Success<T>() => null,
        Failed<T>(:final failure) => failure,
      };

  /// Réduit les deux branches vers une valeur unique.
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Failure failure) onFailure,
  }) =>
      switch (this) {
        Success<T>(:final value) => onSuccess(value),
        Failed<T>(:final failure) => onFailure(failure),
      };

  /// Transforme la valeur d'un succès ; propage l'échec inchangé.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
        Success<T>(:final value) => Success<R>(transform(value)),
        Failed<T>(:final failure) => Failed<R>(failure),
      };

  /// Enchaîne une opération elle-même faillible, sans imbriquer les résultats.
  Result<R> flatMap<R>(Result<R> Function(T value) transform) =>
      switch (this) {
        Success<T>(:final value) => transform(value),
        Failed<T>(:final failure) => Failed<R>(failure),
      };
}

final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> && other.value == value;

  @override
  int get hashCode => Object.hash(Success, value);

  @override
  String toString() => 'Success<$T>($value)';
}

final class Failed<T> extends Result<T> {
  const Failed(this.failure);

  final Failure failure;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failed<T> && other.failure == failure;

  @override
  int get hashCode => Object.hash(Failed, failure);

  @override
  String toString() => 'Failed<$T>($failure)';
}
