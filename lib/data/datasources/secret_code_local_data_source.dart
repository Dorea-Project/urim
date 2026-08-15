import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urim/core/error/exceptions.dart';
import 'package:urim/domain/entities/auth/secret_code_policy.dart';

/// Stockage local du code secret.
///
/// Le code **n'est jamais conservé**. Seuls un sel aléatoire et une clé
/// dérivée le sont ; vérifier consiste à redériver et à comparer.
///
/// ## Limite assumée à ce stade
///
/// Ces valeurs vivent dans les préférences système, lisibles sur un appareil
/// débridé. Pour une mise en production, la clé dérivée doit passer dans le
/// trousseau matériel (`flutter_secure_storage`, adossé au Keychain iOS et au
/// Keystore Android). La dérivation ci-dessous reste alors valable — seul le
/// support de stockage change.
///
/// Quatre chiffres ne font que dix mille combinaisons : ce n'est pas la
/// dérivation qui protège, c'est le plafond d'essais.
abstract interface class SecretCodeLocalDataSource {
  Future<bool> isDefined();

  Future<void> define(String code);

  /// Lève [UnauthorizedException] avec le code `too_many_attempts` lorsque le
  /// plafond est atteint.
  Future<bool> verify(String code);

  Future<void> clear();
}

final class SharedPreferencesSecretCodeDataSource
    implements SecretCodeLocalDataSource {
  SharedPreferencesSecretCodeDataSource(this._preferences, [Random? random])
      : _random = random ?? Random.secure();

  static const String saltKey = 'secret_code.salt.v1';
  static const String hashKey = 'secret_code.hash.v1';
  static const String attemptsKey = 'secret_code.attempts.v1';

  /// Coût de la dérivation. Assez élevé pour ralentir une attaque hors ligne,
  /// assez bas pour rester imperceptible à la saisie.
  static const int iterations = 20000;

  final SharedPreferences _preferences;
  final Random _random;

  @override
  Future<bool> isDefined() async =>
      _preferences.getString(hashKey) != null &&
      _preferences.getString(saltKey) != null;

  @override
  Future<void> define(String code) async {
    final salt = List<int>.generate(16, (_) => _random.nextInt(256));
    final derived = _derive(code, salt);

    final written = await _preferences.setString(saltKey, base64Encode(salt)) &&
        await _preferences.setString(hashKey, base64Encode(derived)) &&
        await _preferences.setInt(attemptsKey, 0);

    if (!written) {
      throw const CacheException(
        'Impossible d\'enregistrer le code secret.',
        code: 'secret_code_write_failed',
      );
    }
  }

  @override
  Future<bool> verify(String code) async {
    final storedSalt = _preferences.getString(saltKey);
    final storedHash = _preferences.getString(hashKey);

    if (storedSalt == null || storedHash == null) {
      throw const CacheException(
        'Aucun code secret n\'est défini sur cet appareil.',
        code: 'secret_code_missing',
      );
    }

    final attempts = _preferences.getInt(attemptsKey) ?? 0;
    if (attempts >= SecretCodePolicy.maxAttempts) {
      throw const UnauthorizedException(
        'Trop de tentatives. Reconnectez-vous par SMS.',
        code: 'too_many_attempts',
      );
    }

    final derived = _derive(code, base64Decode(storedSalt));
    final matches = _constantTimeEquals(derived, base64Decode(storedHash));

    // Le compteur ne repart de zéro qu'en cas de succès : sinon il suffirait
    // d'alterner un bon et un mauvais code pour ne jamais l'épuiser.
    await _preferences.setInt(attemptsKey, matches ? 0 : attempts + 1);

    return matches;
  }

  @override
  Future<void> clear() async {
    await _preferences.remove(saltKey);
    await _preferences.remove(hashKey);
    await _preferences.remove(attemptsKey);
  }

  /// PBKDF2-HMAC-SHA256, une seule passe de bloc — la clé dérivée fait la
  /// taille d'une empreinte SHA-256, aucune extension n'est nécessaire.
  static List<int> _derive(String code, List<int> salt) {
    final hmac = Hmac(sha256, utf8.encode(code));

    var block = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
    final result = List<int>.from(block);

    for (var i = 1; i < iterations; i++) {
      block = hmac.convert(block).bytes;
      for (var j = 0; j < result.length; j++) {
        result[j] ^= block[j];
      }
    }

    return result;
  }

  /// Comparaison à durée constante : une comparaison qui s'arrête au premier
  /// octet différent laisse fuir, par son temps d'exécution, le nombre
  /// d'octets déjà corrects.
  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;

    var difference = 0;
    for (var i = 0; i < a.length; i++) {
      difference |= a[i] ^ b[i];
    }

    return difference == 0;
  }
}
