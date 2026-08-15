import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urim/core/error/exceptions.dart';
import 'package:urim/domain/entities/auth/auth_session.dart';
import 'package:urim/domain/entities/auth/otp_challenge.dart';
import 'package:urim/domain/entities/auth/phone_number.dart';

/// Envoi et vérification du code SMS.
abstract interface class AuthDataSource {
  Future<OtpChallenge> requestOtp(PhoneNumber phone);

  Future<AuthSession> verifyOtp({
    required String challengeId,
    required String code,
  });

  Future<AuthSession?> currentSession();

  Future<void> signOut();
}

/// Implémentation **de développement**, en attendant le serveur.
///
/// Elle ne parle à personne : elle tire un code au hasard, le journalise en
/// mode débogage, et l'accepte s'il correspond. Cela permet de parcourir tout
/// le flux sans passerelle SMS.
///
/// ## À remplacer avant toute mise en ligne
///
/// Un code vérifié sur l'appareil ne prouve rien : n'importe qui peut modifier
/// l'application et se déclarer connecté. La vérification doit revenir au
/// serveur, qui seul émet le jeton de session. Ce fichier disparaîtra au
/// profit d'un `AuthRemoteDataSource` bâti sur le client Dio déjà en place ;
/// rien d'autre dans l'application n'aura à changer.
final class DevAuthDataSource implements AuthDataSource {
  DevAuthDataSource(this._preferences, {Random? random, DateTime Function()? now})
      : _random = random ?? Random(),
        _now = now ?? DateTime.now;

  static const String sessionKey = 'auth.session.v1';

  final SharedPreferences _preferences;
  final Random _random;
  final DateTime Function() _now;

  /// Codes émis, en mémoire : ils ne survivent pas au redémarrage, ce qui est
  /// exactement le comportement attendu d'un code à usage unique.
  final Map<String, _PendingChallenge> _pending = {};

  @override
  Future<OtpChallenge> requestOtp(PhoneNumber phone) async {
    final id = 'dev-${_now().microsecondsSinceEpoch.toRadixString(36)}';
    final code = List.generate(
      OtpChallenge.defaultCodeLength,
      (_) => _random.nextInt(10),
    ).join();

    final challenge = OtpChallenge(
      id: id,
      phone: phone,
      expiresAt: _now().add(OtpChallenge.defaultValidity),
    );

    _pending[id] = _PendingChallenge(code: code, challenge: challenge);

    // Seul moyen de récupérer le code sans passerelle SMS. `debugPrint` est
    // retiré des compilations de production par le compilateur.
    debugPrint('[DEV] Code envoyé au ${phone.e164} : $code');

    return challenge;
  }

  @override
  Future<AuthSession> verifyOtp({
    required String challengeId,
    required String code,
  }) async {
    final pending = _pending[challengeId];

    if (pending == null) {
      throw const UnauthorizedException(
        'Cette demande n\'est plus valable. Recommencez.',
        code: 'unknown_challenge',
      );
    }

    if (pending.challenge.isExpired(_now())) {
      _pending.remove(challengeId);
      throw const UnauthorizedException(
        'Ce code a expiré.',
        code: 'otp_expired',
      );
    }

    if (pending.code != code) {
      throw const UnauthorizedException(
        'Code incorrect.',
        code: 'invalid_otp',
      );
    }

    _pending.remove(challengeId);

    final session = AuthSession(
      userId: 'dev-${pending.challenge.phone.nationalNumber}',
      phone: pending.challenge.phone,
      openedAt: _now(),
    );

    await _preferences.setString(sessionKey, jsonEncode(_encode(session)));

    return session;
  }

  @override
  Future<AuthSession?> currentSession() async {
    final raw = _preferences.getString(sessionKey);
    if (raw == null) return null;

    try {
      return _decode(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException catch (e) {
      // Session illisible : on la traite comme absente plutôt que de bloquer
      // le démarrage. L'utilisateur se reconnecte.
      throw CacheException(
        'Session locale illisible.',
        code: 'corrupt_session',
        cause: e,
      );
    }
  }

  @override
  Future<void> signOut() async {
    await _preferences.remove(sessionKey);
    _pending.clear();
  }

  static Map<String, dynamic> _encode(AuthSession session) => {
        'userId': session.userId,
        'dialCode': session.phone.dialCode,
        'nationalNumber': session.phone.nationalNumber,
        'openedAt': session.openedAt.toIso8601String(),
      };

  static AuthSession _decode(Map<String, dynamic> json) => AuthSession(
        userId: json['userId'] as String,
        phone: PhoneNumber(
          dialCode: json['dialCode'] as String,
          nationalNumber: json['nationalNumber'] as String,
        ),
        openedAt: DateTime.parse(json['openedAt'] as String),
      );
}

final class _PendingChallenge {
  const _PendingChallenge({required this.code, required this.challenge});

  final String code;
  final OtpChallenge challenge;
}
