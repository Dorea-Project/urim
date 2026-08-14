/// Exceptions levées par la couche data (datasources, clients HTTP, cache).
///
/// Elles ne remontent jamais au-delà des repositories : ceux-ci les
/// convertissent en `Failure`. Voir `core/error/failure.dart`.
sealed class AppException implements Exception {
  const AppException(this.message, {this.code, this.cause});

  final String message;
  final String? code;

  /// Exception d'origine, conservée pour les logs et le débogage.
  final Object? cause;

  @override
  String toString() => '$runtimeType(code: $code, message: $message)';
}

/// Réponse HTTP avec un statut d'erreur (4xx, 5xx).
final class ServerException extends AppException {
  const ServerException(super.message, {this.statusCode, super.code, super.cause});

  final int? statusCode;
}

/// Requête impossible à émettre ou sans réponse : hors ligne, DNS, timeout.
final class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.cause});
}

/// Échec de lecture ou d'écriture sur le stockage local.
final class CacheException extends AppException {
  const CacheException(super.message, {super.code, super.cause});
}

/// Jeton absent, expiré ou droits insuffisants (401, 403).
final class UnauthorizedException extends AppException {
  const UnauthorizedException(super.message, {super.code, super.cause});
}
