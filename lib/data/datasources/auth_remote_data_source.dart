import 'package:dio/dio.dart';
import 'package:urim/core/network/dio_error_mapper.dart';
import 'package:urim/core/network/token_refresher.dart';
import 'package:urim/core/security/auth_tokens.dart';
import 'package:urim/data/datasources/auth_data_source.dart';
import 'package:urim/domain/entities/auth/phone_number.dart';

/// Parcours d'entrée contre le backend Dorea, canal mobile.
///
/// Les noms de champs sont ceux du serveur (`phone_number`, `secret_code`,
/// `device_id`) : la conversion vers le vocabulaire du domaine se fait ici, et
/// nulle part ailleurs.
///
/// Le serveur distingue **inscription** et **connexion** — deux portes, deux
/// jeux de routes. C'est lui qui tranche : l'application ne peut pas deviner
/// si un numéro est connu, et le lui demander ferait de la route un annuaire.
final class AuthRemoteDataSource implements AuthDataSource {
  const AuthRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<void> requestRegistration(PhoneNumber phone) async {
    await _post('/auth/register', {'phone_number': phone.e164});
  }

  @override
  Future<AuthTokens> confirmRegistration({
    required PhoneNumber phone,
    required String otp,
    required String secretCode,
    required String deviceId,
  }) async {
    final json = await _post('/auth/verify-registration', {
      'phone_number': phone.e164,
      'otp': otp,
      'secret_code': secretCode,
      'device_id': deviceId,
    });

    return tokensFromJson(json!, now: DateTime.now());
  }

  @override
  Future<SignInOutcome> signIn({
    required PhoneNumber phone,
    required String secretCode,
    required String deviceId,
  }) async {
    final response = await _send('/auth/login', {
      'phone_number': phone.e164,
      'secret_code': secretCode,
      'device_id': deviceId,
    });

    // 202 : appareil inconnu. Le serveur a envoyé un SMS et n'a émis aucun
    // jeton — la suite passe par `verifyDevice`.
    if (response.statusCode == 202) return const SignInOutcome.otpRequired();

    return SignInOutcome.session(
      tokensFromJson(response.data!, now: DateTime.now()),
    );
  }

  @override
  Future<AuthTokens> verifyDevice({
    required PhoneNumber phone,
    required String otp,
    required String deviceId,
  }) async {
    final json = await _post('/auth/verify-device', {
      'phone_number': phone.e164,
      'otp': otp,
      'device_id': deviceId,
    });

    return tokensFromJson(json!, now: DateTime.now());
  }

  @override
  Future<void> requestSecretCodeReset(PhoneNumber phone) async {
    await _post('/auth/reset-secret-code/request', {
      'phone_number': phone.e164,
    });
  }

  @override
  Future<AuthTokens> confirmSecretCodeReset({
    required PhoneNumber phone,
    required String otp,
    required String newSecretCode,
    required String deviceId,
  }) async {
    final json = await _post('/auth/reset-secret-code/confirm', {
      'phone_number': phone.e164,
      'otp': otp,
      'new_secret_code': newSecretCode,
      'device_id': deviceId,
    });

    return tokensFromJson(json!, now: DateTime.now());
  }

  @override
  Future<void> requestSecretCodeChange() async {
    // Aucun corps : le serveur lit le compte dans le jeton. Lui passer un
    // numéro laisserait croire qu'on peut changer le code d'un autre.
    await _post('/account/change-password/request', const {});
  }

  @override
  Future<void> confirmSecretCodeChange({
    required String otp,
    required String newSecretCode,
  }) async {
    await _post('/account/change-password/confirm', {
      'otp': otp,
      'new_secret_code': newSecretCode,
    });
  }

  @override
  Future<void> signOut({bool everywhere = false}) async {
    await _post('/auth/logout', {'everywhere': everywhere});
  }

  Future<Map<String, dynamic>?> _post(
    String path,
    Map<String, dynamic> body,
  ) async =>
      (await _send(path, body)).data;

  Future<Response<Map<String, dynamic>>> _send(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      return await _dio.post<Map<String, dynamic>>(path, data: body);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
