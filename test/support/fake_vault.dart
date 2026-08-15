import 'package:urim/core/security/secure_store.dart';

/// Coffre en mémoire, pour les tests.
///
/// Le coffre matériel ne répond que sur un vrai appareil : sans cette
/// substitution, le moindre test touchant à l'authentification échouerait sur
/// un canal de plateforme absent.
final class FakeVault implements SecretVault {
  final Map<String, String> entries = {};

  @override
  Future<String?> read(String key) async => entries[key];

  @override
  Future<void> write(String key, String value) async => entries[key] = value;

  @override
  Future<void> delete(String key) async => entries.remove(key);
}
