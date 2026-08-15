import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/error/error_mapper.dart';
import 'package:urim/core/error/exceptions.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/core/result/result.dart';
import 'package:urim/core/storage/shared_preferences_provider.dart';
import 'package:urim/data/datasources/auth_local_data_source.dart';
import 'package:urim/domain/entities/auth/auth_session.dart';
import 'package:urim/domain/entities/auth/otp_challenge.dart';
import 'package:urim/domain/entities/auth/phone_number.dart';
import 'package:urim/domain/repositories/auth_repository.dart';

final class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._source);

  final AuthDataSource _source;

  @override
  Future<Result<OtpChallenge>> requestOtp(PhoneNumber phone) =>
      _guard(() => _source.requestOtp(phone));

  @override
  Future<Result<AuthSession>> verifyOtp({
    required String challengeId,
    required String code,
  }) =>
      _guard(() => _source.verifyOtp(challengeId: challengeId, code: code));

  @override
  Future<Result<AuthSession?>> currentSession() async {
    try {
      return Result.success(await _source.currentSession());
    } on CacheException {
      // Session corrompue : équivalente à pas de session. Bloquer le
      // démarrage sur une donnée locale abîmée serait pire que demander une
      // reconnexion.
      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failed(e.toFailure());
    }
  }

  @override
  Future<Result<void>> signOut() => _guard(_source.signOut);

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Result.success(await action());
    } on AppException catch (e) {
      return Result.failed(e.toFailure());
    } catch (e) {
      return Result.failed(UnexpectedFailure(message: e.toString()));
    }
  }
}

/// Séparé du dépôt pour que les tests puissent injecter une source
/// déterministe — un tirage aléatoire ensemencé rend le code SMS prévisible.
final authDataSourceProvider = Provider<AuthDataSource>(
  (ref) => DevAuthDataSource(ref.watch(sharedPreferencesProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(authDataSourceProvider)),
);
