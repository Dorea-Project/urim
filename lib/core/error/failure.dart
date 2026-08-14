import 'package:equatable/equatable.dart';

/// Erreur métier, exposée par la couche domaine vers la présentation.
///
/// Les couches basses lèvent des [AppException] ; les repositories les
/// traduisent en [Failure] pour qu'aucune exception ne traverse le domaine.
sealed class Failure extends Equatable {
  const Failure({required this.message, this.code});

  /// Message technique, destiné aux logs. La présentation reste responsable
  /// de produire un texte affichable et localisé.
  final String message;

  /// Code stable permettant à la présentation de discriminer un cas précis
  /// (`invalid_credentials`, `quota_exceeded`, ...).
  final String? code;

  @override
  List<Object?> get props => [message, code];

  @override
  String toString() => '$runtimeType(code: $code, message: $message)';
}

/// Le serveur a répondu avec un statut d'erreur.
final class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code, this.statusCode});

  final int? statusCode;

  @override
  List<Object?> get props => [...super.props, statusCode];
}

/// Aucune réponse du serveur : hors ligne, DNS, timeout.
final class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Aucune connexion disponible.',
    super.code,
  });
}

/// Lecture ou écriture du cache local impossible.
final class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code});
}

/// Authentification absente, expirée ou insuffisante.
final class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code});
}

/// Données d'entrée invalides, avec le détail par champ.
final class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    this.fieldErrors = const {},
    super.code,
  });

  /// Clé = nom du champ, valeur = motif du rejet.
  final Map<String, String> fieldErrors;

  @override
  List<Object?> get props => [...super.props, fieldErrors];
}

/// Filet de sécurité : tout ce qui n'a pas été anticipé.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    super.message = 'Une erreur inattendue est survenue.',
    super.code,
  });
}
