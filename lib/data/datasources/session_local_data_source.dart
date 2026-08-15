import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:urim/core/error/exceptions.dart';
import 'package:urim/domain/entities/auth/auth_session.dart';
import 'package:urim/domain/entities/auth/phone_number.dart';

/// Trace locale de la session : qui est connecté, depuis quand.
///
/// Séparée des jetons, et rangée ailleurs : ceci n'est pas un secret — c'est
/// le numéro que l'utilisateur vient de taper, affiché sur son propre profil.
/// Le coffre matériel est réservé à ce qui ouvre des portes.
///
/// Sans cette trace, l'application saurait qu'une session existe mais pas à
/// quel numéro elle appartient : le jeton ne porte pas le numéro, et le
/// redemander au serveur au démarrage retarderait l'affichage pour rien.
abstract interface class SessionLocalDataSource {
  Future<AuthSession?> read();

  Future<void> write(AuthSession session);

  Future<void> clear();
}

final class SharedPreferencesSessionDataSource
    implements SessionLocalDataSource {
  const SharedPreferencesSessionDataSource(this._preferences);

  static const String storageKey = 'auth.session.v2';

  final SharedPreferences _preferences;

  @override
  Future<AuthSession?> read() async {
    final raw = _preferences.getString(storageKey);
    if (raw == null) return null;

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;

      return AuthSession(
        userId: json['userId'] as String,
        phone: PhoneNumber(
          dialCode: json['dialCode'] as String,
          nationalNumber: json['nationalNumber'] as String,
        ),
        openedAt: DateTime.parse(json['openedAt'] as String),
      );
    } on FormatException catch (e) {
      throw CacheException(
        'Session locale illisible.',
        code: 'corrupt_session',
        cause: e,
      );
    }
  }

  @override
  Future<void> write(AuthSession session) async {
    final written = await _preferences.setString(
      storageKey,
      jsonEncode({
        'userId': session.userId,
        'dialCode': session.phone.dialCode,
        'nationalNumber': session.phone.nationalNumber,
        'openedAt': session.openedAt.toIso8601String(),
      }),
    );

    if (!written) {
      throw const CacheException(
        'Impossible de conserver la session.',
        code: 'session_write_failed',
      );
    }
  }

  @override
  Future<void> clear() async {
    await _preferences.remove(storageKey);
  }
}
