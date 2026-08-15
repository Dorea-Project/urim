import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/security/secure_store.dart';

/// Identifiant stable de cet appareil, exigé par toutes les routes d'entrée.
///
/// Le serveur s'en sert pour reconnaître un appareil de confiance : un
/// identifiant qui changerait à chaque lancement provoquerait un SMS de
/// vérification à chaque connexion. Il est donc **généré une seule fois**, puis
/// conservé dans le coffre matériel.
///
/// Tiré au hasard plutôt que lu dans le matériel : les identifiants matériels
/// (IMEI, Android ID) sont des données personnelles, pistables d'une
/// application à l'autre, et Urim n'a besoin que de savoir « c'est le même
/// appareil qu'hier ».
final class DeviceIdentity {
  DeviceIdentity(this._vault, {Random? random})
      : _random = random ?? Random.secure();

  static const String storageKey = 'device.id.v1';

  final SecretVault _vault;
  final Random _random;

  Future<String>? _pending;

  /// Lit l'identifiant, ou en crée un à la première demande.
  ///
  /// Les appels concurrents partagent la même résolution : deux écritures
  /// simultanées produiraient deux identifiants, dont un perdu — et un SMS de
  /// trop pour l'utilisateur.
  Future<String> resolve() => _pending ??= _resolve();

  Future<String> _resolve() async {
    final existing = await _vault.read(storageKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final created = _generate();
    await _vault.write(storageKey, created);

    return created;
  }

  /// 128 bits, en hexadécimal, préfixés pour être reconnaissables dans un
  /// journal serveur.
  String _generate() {
    final bytes = List.generate(16, (_) => _random.nextInt(256));
    final hex =
        bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

    return 'urim-$hex';
  }
}

final deviceIdentityProvider = Provider<DeviceIdentity>(
  (ref) => DeviceIdentity(ref.watch(secretVaultProvider)),
);
