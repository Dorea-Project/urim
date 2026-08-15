import 'package:dio/dio.dart';
import 'package:urim/core/error/exceptions.dart';
import 'package:urim/core/network/api_error.dart';

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
  final api = ApiError.tryParse(error.response?.data);

  // Le code du serveur est repris tel quel : c'est lui qui permet à l'écran de
  // distinguer un code secret erroné d'un compte verrouillé, sans lire le
  // message — qui, lui, changera au gré des relectures.
  final code = api?.code ?? 'http_$statusCode';
  final message = api?.message ?? 'Le serveur a répondu avec le statut $statusCode.';

  if (statusCode == 401 || statusCode == 403) {
    return UnauthorizedException(message, code: code, cause: error);
  }

  if (statusCode == 422 || statusCode == 400 || statusCode == 409) {
    return ValidationException(
      message,
      fieldErrors: api?.fieldErrors ?? const {},
      code: code,
      cause: error,
    );
  }

  if (statusCode == 429) {
    return ServerException(
      message,
      statusCode: statusCode,
      code: code,
      cause: error,
    );
  }

  return ServerException(
    message,
    statusCode: statusCode,
    code: code,
    cause: error,
  );
}
