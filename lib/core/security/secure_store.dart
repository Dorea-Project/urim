import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Coffre à secrets de l'appareil.
///
/// Interface volontairement minuscule : trois gestes, aucune notion de format.
/// Elle isole le greffon natif — un `FlutterSecureStorage` ne répond que sur un
/// vrai appareil, et le brancher directement rendrait toute la couche
/// d'authentification intestable.
abstract interface class SecretVault {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

/// Mise en œuvre matérielle : Keystore sur Android, Keychain sur iOS.
///
/// Tout ce qui prouve une identité vit ici, et **rien d'autre ne doit y aller** :
/// les jetons de session et l'identifiant d'appareil. Les préférences système
/// restent réservées à ce qui n'a pas de valeur volée — les réglages, le nom
/// affiché, l'état de la présentation.
///
/// Les options par défaut de la version 11 suffisent : valeurs chiffrées en
/// AES-GCM, clé enveloppée par RSA-OAEP dans le Keystore, à partir d'Android 6.
final class KeystoreVault implements SecretVault {
  const KeystoreVault([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

final secretVaultProvider = Provider<SecretVault>(
  (ref) => const KeystoreVault(),
);
