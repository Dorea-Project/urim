import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urim/core/error/auth_error_codes.dart';
import 'package:urim/core/error/error_mapper.dart';
import 'package:urim/core/error/exceptions.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/core/network/dio_error_mapper.dart';

/// Ce que le serveur refuse, et ce que l'ecran doit en dire.
///
/// Ecrit apres un essai reel : un code SMS expire revenait en 410, tombait dans
/// les erreurs serveur, et l'utilisateur lisait une panne la ou il devait lire
/// « demande un nouveau code ».
DioException _refus(int status, String code, String message) {
  final request = RequestOptions(path: '/auth/verify-registration');

  return DioException(
    requestOptions: request,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: request,
      statusCode: status,
      data: {
        'error': {'code': code, 'message': message, 'details': {}},
      },
    ),
  );
}

void main() {
  group('enveloppe du serveur', () {
    test('le code du serveur traverse intact jusqu\'a la Failure', () {
      final failure = mapDioException(
        _refus(410, AuthErrorCodes.otpExpired, 'Ce code a expiré.'),
      ).toFailure();

      expect(failure.code, AuthErrorCodes.otpExpired);
    });

    test('un code expire est une erreur d\'acces, pas une panne serveur', () {
      final exception = mapDioException(
        _refus(410, AuthErrorCodes.otpExpired, 'Ce code a expiré.'),
      );

      expect(exception, isA<UnauthorizedException>());
      expect(exception.toFailure(), isA<AuthFailure>());
    });

    test('un compte verrouille se distingue d\'un code faux', () {
      final locked = mapDioException(
        _refus(429, AuthErrorCodes.tooManyAttempts, 'Trop d\'essais.'),
      ).toFailure();
      final wrong = mapDioException(
        _refus(401, AuthErrorCodes.invalidCredentials, 'Refuse.'),
      ).toFailure();

      expect(locked.code, isNot(wrong.code));
      expect(AuthErrorCodes.isThrottled(locked.code), isTrue);
      expect(AuthErrorCodes.isThrottled(wrong.code), isFalse);
    });

    test('les erreurs par champ d\'un 422 sont conservees', () {
      final request = RequestOptions(path: '/auth/register');
      final failure = mapDioException(
        DioException(
          requestOptions: request,
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            requestOptions: request,
            statusCode: 422,
            data: {
              'error': {
                'code': 'VALIDATION_ERROR',
                'message': 'La requête est invalide.',
                'details': {
                  'errors': [
                    {
                      'loc': ['body', 'phone_number'],
                      'msg': 'field required',
                    }
                  ]
                },
              },
            },
          ),
        ),
      ).toFailure();

      expect(failure, isA<ValidationFailure>());
      expect(
        (failure as ValidationFailure).fieldErrors['phone_number'],
        'field required',
      );
    });

    test('une reponse hors format ne casse rien', () {
      final request = RequestOptions(path: '/auth/login');
      final failure = mapDioException(
        DioException(
          requestOptions: request,
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            requestOptions: request,
            statusCode: 502,
            data: '<html>Bad Gateway</html>',
          ),
        ),
      ).toFailure();

      expect(failure, isA<ServerFailure>());
      expect(failure.code, 'http_502');
    });
  });

  group('ce que l\'ecran doit proposer', () {
    test('un code expire appelle un nouveau code', () {
      expect(AuthErrorCodes.needsNewCode(AuthErrorCodes.otpExpired), isTrue);
      expect(AuthErrorCodes.needsNewCode(AuthErrorCodes.otpNotFound), isTrue);
      expect(AuthErrorCodes.needsNewCode(AuthErrorCodes.otpInvalid), isFalse);
    });

    test('un verrou appelle a attendre, pas a reessayer', () {
      expect(AuthErrorCodes.isThrottled(AuthErrorCodes.otpTooManyRequests),
          isTrue);
      expect(AuthErrorCodes.isThrottled(AuthErrorCodes.invalidCredentials),
          isFalse);
    });
  });
}
