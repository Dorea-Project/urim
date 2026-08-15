import 'package:flutter/foundation.dart';
import 'package:urim/core/config/mock_credentials.dart';
import 'package:urim/core/error/exceptions.dart';
import 'package:urim/core/security/auth_tokens.dart';
import 'package:urim/data/datasources/auth_data_source.dart';
import 'package:urim/domain/entities/auth/phone_number.dart';

/// Parcours d'entrée **simulé**, quand aucun serveur ne répond.
///
/// Elle ne parle à personne : elle attend toujours le même OTP — celui de
/// [MockCredentials] — et délivre des jetons factices. Cela permet de parcourir
/// l'application entière, y compris compilée, sans passerelle SMS ni backend.
///
/// ## Ce qu'elle ne prouve pas
///
/// Rien. Un code vérifié sur l'appareil n'atteste d'aucune possession de
/// numéro, et les jetons qu'elle fabrique n'ouvrent aucune porte réelle. Elle
/// est désactivée dès que le build vise le serveur
/// (`--dart-define=USE_MOCK_AUTH=false`), et interdite en production.
final class DevAuthDataSource implements AuthDataSource {
  DevAuthDataSource({String otp = MockCredentials.otp, DateTime Function()? now})
      : _otp = otp,
        _now = now ?? DateTime.now;

  final String _otp;
  final DateTime Function() _now;

  /// Numéros à qui un code a été « envoyé », en mémoire : ils ne survivent pas
  /// au redémarrage, ce qui est le comportement attendu d'un code à usage
  /// unique.
  final Set<String> _challenged = {};

  /// Codes secrets posés pendant la session de démonstration.
  final Map<String, String> _secretCodes = {};

  @override
  Future<void> requestRegistration(PhoneNumber phone) async {
    _challenged.add(phone.e164);
    debugPrint('[DEMO] Code envoyé au ${phone.e164} : $_otp');
  }

  @override
  Future<AuthTokens> confirmRegistration({
    required PhoneNumber phone,
    required String otp,
    required String secretCode,
    required String deviceId,
  }) async {
    _requireChallenge(phone);
    _requireOtp(otp);

    _secretCodes[phone.e164] = secretCode;

    return _issue();
  }

  @override
  Future<SignInOutcome> signIn({
    required PhoneNumber phone,
    required String secretCode,
    required String deviceId,
  }) async {
    final known = _secretCodes[phone.e164];

    if (known == null) {
      throw const UnauthorizedException(
        'Aucun compte pour ce numéro sur cet appareil.',
        code: 'INVALID_CREDENTIALS',
      );
    }

    if (known != secretCode) {
      throw const UnauthorizedException(
        'Code secret incorrect.',
        code: 'INVALID_CREDENTIALS',
      );
    }

    return SignInOutcome.session(_issue());
  }

  @override
  Future<AuthTokens> verifyDevice({
    required PhoneNumber phone,
    required String otp,
    required String deviceId,
  }) async {
    _requireOtp(otp);
    return _issue();
  }

  @override
  Future<void> requestSecretCodeReset(PhoneNumber phone) async {
    // Comme le serveur : aucune indication sur l'existence du numéro.
    _challenged.add(phone.e164);
    debugPrint('[DEMO] Code de réinitialisation au ${phone.e164} : $_otp');
  }

  @override
  Future<AuthTokens> confirmSecretCodeReset({
    required PhoneNumber phone,
    required String otp,
    required String newSecretCode,
    required String deviceId,
  }) async {
    _requireChallenge(phone);
    _requireOtp(otp);

    _secretCodes[phone.e164] = newSecretCode;

    return _issue();
  }

  @override
  Future<void> signOut({bool everywhere = false}) async {
    if (everywhere) _secretCodes.clear();
  }

  void _requireChallenge(PhoneNumber phone) {
    if (_challenged.contains(phone.e164)) return;

    throw const UnauthorizedException(
      'Cette demande n\'est plus valable. Recommencez.',
      code: 'OTP_UNKNOWN_CHALLENGE',
    );
  }

  void _requireOtp(String otp) {
    if (otp == _otp) return;

    throw const UnauthorizedException(
      'Code incorrect.',
      code: 'OTP_INVALID',
    );
  }

  AuthTokens _issue() {
    final now = _now();

    return AuthTokens(
      accessToken: 'demo-access-${now.microsecondsSinceEpoch}',
      refreshToken: 'demo-refresh-${now.microsecondsSinceEpoch}',
      expiresAt: now.add(const Duration(hours: 1)),
    );
  }
}
