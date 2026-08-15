import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/error/exceptions.dart';
import 'package:urim/core/security/auth_tokens.dart';
import 'package:urim/core/security/secure_store.dart';

/// Conservation des jetons de session.
abstract interface class TokenStore {
  Future<AuthTokens?> read();

  Future<void> save(AuthTokens tokens);

  Future<void> clear();
}

/// Mise en œuvre sur le coffre matériel.
///
/// Une seule entrée plutôt que trois : les trois valeurs n'ont de sens
/// qu'ensemble, et une écriture partielle laisserait un accès sans son
/// rafraîchissement — donc une session qui meurt en silence dans l'heure.
final class SecureTokenStore implements TokenStore {
  const SecureTokenStore(this._vault);

  static const String storageKey = 'auth.tokens.v1';

  final SecretVault _vault;

  @override
  Future<AuthTokens?> read() async {
    final raw = await _vault.read(storageKey);
    if (raw == null) return null;

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;

      return AuthTokens(
        accessToken: json['access'] as String,
        refreshToken: json['refresh'] as String,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        tokenType: json['tokenType'] as String? ?? 'bearer',
      );
    } catch (e) {
      // Entrée illisible : on la traite comme absente et on nettoie. Bloquer le
      // démarrage sur un coffre abîmé serait pire qu'une reconnexion.
      await clear();
      return null;
    }
  }

  @override
  Future<void> save(AuthTokens tokens) async {
    try {
      await _vault.write(
        storageKey,
        jsonEncode({
          'access': tokens.accessToken,
          'refresh': tokens.refreshToken,
          'expiresAt': tokens.expiresAt.toIso8601String(),
          'tokenType': tokens.tokenType,
        }),
      );
    } catch (e) {
      throw CacheException(
        'Impossible de conserver la session.',
        code: 'token_write_failed',
        cause: e,
      );
    }
  }

  @override
  Future<void> clear() => _vault.delete(storageKey);
}

final tokenStoreProvider = Provider<TokenStore>(
  (ref) => SecureTokenStore(ref.watch(secretVaultProvider)),
);
