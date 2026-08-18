import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/config/app_config_provider.dart';
import 'package:urim/core/error/error_mapper.dart';
import 'package:urim/core/error/exceptions.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/core/network/dio_client.dart';
import 'package:urim/core/result/result.dart';
import 'package:urim/core/security/auth_tokens.dart';
import 'package:urim/core/security/device_identity.dart';
import 'package:urim/core/security/token_store.dart';
import 'package:urim/core/storage/shared_preferences_provider.dart';
import 'package:urim/core/time/clock_provider.dart';
import 'package:urim/data/datasources/auth_data_source.dart';
import 'package:urim/data/datasources/auth_local_data_source.dart';
import 'package:urim/data/datasources/auth_remote_data_source.dart';
import 'package:urim/data/datasources/session_local_data_source.dart';
import 'package:urim/domain/entities/auth/auth_session.dart';
import 'package:urim/domain/entities/auth/phone_number.dart';
import 'package:urim/domain/repositories/auth_repository.dart';

/// Recolle les trois pièces du parcours d'entrée : ce que dit le serveur, les
/// jetons qu'on garde au coffre, et la trace lisible de la session.
///
/// L'ordre d'écriture n'est pas indifférent : les jetons d'abord, la trace
/// ensuite. Une trace sans jetons ferait croire à une session ouverte que le
/// premier appel démentirait ; des jetons sans trace se rattrapent, eux, en
/// affichant un profil incomplet.
final class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthDataSource source,
    required SessionLocalDataSource sessions,
    required TokenStore tokens,
    required DeviceIdentity device,
    required DateTime Function() now,
  })  : _source = source,
        _sessions = sessions,
        _tokens = tokens,
        _device = device,
        _now = now;

  final AuthDataSource _source;
  final SessionLocalDataSource _sessions;
  final TokenStore _tokens;
  final DeviceIdentity _device;
  final DateTime Function() _now;

  @override
  Future<Result<void>> requestRegistration(PhoneNumber phone) =>
      _guard(() => _source.requestRegistration(phone));

  @override
  Future<Result<AuthSession>> confirmRegistration({
    required PhoneNumber phone,
    required String otp,
    required String secretCode,
  }) =>
      _guard(() async {
        final tokens = await _source.confirmRegistration(
          phone: phone,
          otp: otp,
          secretCode: secretCode,
          deviceId: await _device.resolve(),
        );

        return _openSession(phone, tokens);
      });

  @override
  Future<Result<SignInResult>> signIn({
    required PhoneNumber phone,
    required String secretCode,
  }) =>
      _guard(() async {
        final outcome = await _source.signIn(
          phone: phone,
          secretCode: secretCode,
          deviceId: await _device.resolve(),
        );

        return switch (outcome) {
          SignedIn(:final tokens) =>
            SignInResult.opened(await _openSession(phone, tokens)),
          DeviceVerificationRequired() => const SignInResult.deviceUnknown(),
        };
      });

  @override
  Future<Result<AuthSession>> verifyDevice({
    required PhoneNumber phone,
    required String otp,
  }) =>
      _guard(() async {
        final tokens = await _source.verifyDevice(
          phone: phone,
          otp: otp,
          deviceId: await _device.resolve(),
        );

        return _openSession(phone, tokens);
      });

  @override
  Future<Result<void>> requestSecretCodeReset(PhoneNumber phone) =>
      _guard(() => _source.requestSecretCodeReset(phone));

  @override
  Future<Result<AuthSession>> confirmSecretCodeReset({
    required PhoneNumber phone,
    required String otp,
    required String newSecretCode,
  }) =>
      _guard(() async {
        final tokens = await _source.confirmSecretCodeReset(
          phone: phone,
          otp: otp,
          newSecretCode: newSecretCode,
          deviceId: await _device.resolve(),
        );

        return _openSession(phone, tokens);
      });

  @override
  Future<Result<void>> requestSecretCodeChange() =>
      _guard(() => _source.requestSecretCodeChange());

  @override
  Future<Result<void>> confirmSecretCodeChange({
    required String otp,
    required String newSecretCode,
  }) =>
      _guard(() => _source.confirmSecretCodeChange(
            otp: otp,
            newSecretCode: newSecretCode,
          ));

  @override
  Future<Result<AuthSession?>> currentSession() async {
    try {
      final session = await _sessions.read();
      if (session == null) return const Result.success(null);

      // Une trace sans jetons ne vaut rien : le coffre a pu être vidé par une
      // révocation, ou par l'échec d'un rafraîchissement.
      if (await _tokens.read() == null) {
        await _sessions.clear();
        return const Result.success(null);
      }

      return Result.success(session);
    } on CacheException {
      // Trace corrompue : équivalente à pas de session. Bloquer le démarrage
      // sur une donnée locale abîmée serait pire que demander une reconnexion.
      await _sessions.clear();
      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failed(e.toFailure());
    }
  }

  @override
  Future<Result<void>> signOut({bool everywhere = false}) async {
    // L'appel serveur peut échouer — hors ligne, jeton déjà mort. L'effacement
    // local, lui, doit avoir lieu dans tous les cas : refuser de déconnecter
    // parce que le réseau manque serait absurde.
    Failure? remoteFailure;

    try {
      await _source.signOut(everywhere: everywhere);
    } on AppException catch (e) {
      remoteFailure = e.toFailure();
    }

    await _tokens.clear();
    await _sessions.clear();

    return remoteFailure == null
        ? const Result.success(null)
        : Result.failed(remoteFailure);
  }

  Future<AuthSession> _openSession(PhoneNumber phone, AuthTokens tokens) async {
    await _tokens.save(tokens);

    final session = AuthSession(
      userId: phone.e164,
      phone: phone,
      openedAt: _now(),
    );

    await _sessions.write(session);

    return session;
  }

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

/// Qui répond : le serveur, ou la source simulée.
///
/// Un seul point de bascule, commandé par la configuration — aucun écran, aucun
/// cas d'usage n'a à savoir lequel des deux est branché.
final authDataSourceProvider = Provider<AuthDataSource>((ref) {
  final config = ref.watch(appConfigProvider);

  if (config.useMockAuth) {
    return DevAuthDataSource(now: ref.watch(clockProvider).now);
  }

  return AuthRemoteDataSource(ref.watch(dioProvider));
});

final sessionLocalDataSourceProvider = Provider<SessionLocalDataSource>(
  (ref) => SharedPreferencesSessionDataSource(
    ref.watch(sharedPreferencesProvider),
  ),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    source: ref.watch(authDataSourceProvider),
    sessions: ref.watch(sessionLocalDataSourceProvider),
    tokens: ref.watch(tokenStoreProvider),
    device: ref.watch(deviceIdentityProvider),
    now: ref.watch(clockProvider).now,
  ),
);
