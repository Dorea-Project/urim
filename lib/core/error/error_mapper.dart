import 'package:urim/core/error/exceptions.dart';
import 'package:urim/core/error/failure.dart';

/// Traduction des exceptions techniques en erreurs métier.
///
/// À appeler dans les repositories, seul endroit autorisé à faire la
/// conversion — voir `lib/data/README.md`.
extension AppExceptionMapper on AppException {
  Failure toFailure() => switch (this) {
        ServerException(:final message, :final code, :final statusCode) =>
          ServerFailure(message: message, code: code, statusCode: statusCode),
        UnauthorizedException(:final message, :final code) =>
          AuthFailure(message: message, code: code),
        NetworkException(:final message, :final code) =>
          NetworkFailure(message: message, code: code),
        CacheException(:final message, :final code) =>
          CacheFailure(message: message, code: code),
      };
}
