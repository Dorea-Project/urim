import 'package:dio/dio.dart';
import 'package:urim/core/error/exceptions.dart';

/// Convertit une [DioException] en [AppException].
///
/// Isole Dio dans la couche réseau : au-delà des datasources, plus personne
/// ne manipule de type Dio. Changer de client HTTP ne touche que ce fichier.
AppException mapDioException(DioException error) => switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout =>
        NetworkException(
          'Le serveur n\'a pas répondu dans le délai imparti.',
          code: 'timeout',
          cause: error,
        ),
      DioExceptionType.connectionError => NetworkException(
          'Serveur injoignable.',
          code: 'connection_error',
          cause: error,
        ),
      DioExceptionType.badCertificate => NetworkException(
          'Certificat TLS refusé.',
          code: 'bad_certificate',
          cause: error,
        ),
      DioExceptionType.cancel => NetworkException(
          'Requête annulée.',
          code: 'cancelled',
          cause: error,
        ),
      DioExceptionType.badResponse => _mapBadResponse(error),
      DioExceptionType.unknown => NetworkException(
          error.message ?? 'Erreur réseau inconnue.',
          code: 'unknown',
          cause: error,
        ),
    };

AppException _mapBadResponse(DioException error) {
  final statusCode = error.response?.statusCode;

  if (statusCode == 401 || statusCode == 403) {
    return UnauthorizedException(
      'Accès refusé.',
      code: 'unauthorized',
      cause: error,
    );
  }

  return ServerException(
    'Le serveur a répondu avec le statut $statusCode.',
    statusCode: statusCode,
    code: 'bad_response',
    cause: error,
  );
}
