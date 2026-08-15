import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/error/error_mapper.dart';
import 'package:urim/core/error/exceptions.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/core/result/result.dart';
import 'package:urim/core/storage/shared_preferences_provider.dart';
import 'package:urim/core/time/clock.dart';
import 'package:urim/core/time/clock_provider.dart';
import 'package:urim/data/datasources/account_local_data_source.dart';
import 'package:urim/domain/entities/account/church_membership.dart';
import 'package:urim/domain/entities/account/known_device.dart';
import 'package:urim/domain/repositories/account_repository.dart';

/// Compte de l'utilisateur, à deux vitesses.
///
/// Le nom affiché est réel : il est saisi ici et conservé dans les
/// préférences. Les églises et les appareils sont un **jeu d'exemple en
/// mémoire**, repris de la maquette, le temps que Q9 et Q11 soient tranchées —
/// aucun annuaire ne reconnaît de numéro aujourd'hui, et aucun serveur ne tient
/// la liste des sessions.
///
/// Retirer un appareil fonctionne donc… jusqu'au prochain lancement. Le
/// contrat, lui, ne changera pas : seul ce fichier sera remplacé.
final class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl({
    required AccountLocalDataSource local,
    required Clock clock,
  })  : _local = local,
        _clock = clock {
    _seedDevices();
  }

  final AccountLocalDataSource _local;
  final Clock _clock;

  final List<KnownDevice> _devices = [];

  @override
  Future<Result<String>> displayName() async {
    try {
      return Result.success(await _local.readDisplayName());
    } on AppException catch (e) {
      return Result.failed(e.toFailure());
    } catch (e) {
      return Result.failed(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> setDisplayName(String name) async {
    final trimmed = name.trim();

    if (trimmed.length > _maxDisplayNameLength) {
      return const Result.failed(
        ValidationFailure(
          message: 'Nom affiché trop long.',
          fieldErrors: {'displayName': 'Pas plus de 60 caractères.'},
          code: 'display_name_too_long',
        ),
      );
    }

    try {
      await _local.writeDisplayName(trimmed);
      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failed(e.toFailure());
    } catch (e) {
      return Result.failed(UnexpectedFailure(message: e.toString()));
    }
  }

  /// Aucune église : le rattachement n'existe pas encore (Q9). L'écran sait
  /// afficher le vide, et n'a rien à inventer.
  @override
  Future<Result<List<ChurchMembership>>> churches() async =>
      const Result.success([]);

  @override
  Future<Result<List<KnownDevice>>> devices() async =>
      Result.success(List.unmodifiable(_devices));

  @override
  Future<Result<void>> forgetDevice(String deviceId) async {
    final device = _devices.where((d) => d.id == deviceId).firstOrNull;

    if (device == null) {
      return const Result.failed(
        CacheFailure(
          message: 'Cet appareil n\'est plus dans la liste.',
          code: 'device_not_found',
        ),
      );
    }

    // Se retirer soi-même serait une déconnexion, qui a son propre chemin.
    if (!device.canBeForgotten) {
      return const Result.failed(
        ValidationFailure(
          message: 'L\'appareil courant ne peut pas se retirer lui-même.',
          code: 'device_is_current',
        ),
      );
    }

    _devices.remove(device);

    return const Result.success(null);
  }

  static const int _maxDisplayNameLength = 60;

  /// Deux appareils, comme sur la maquette : celui qu'on tient, et un ancien.
  void _seedDevices() {
    final now = _clock.now();

    _devices.addAll([
      KnownDevice(
        id: 'device-courant',
        label: 'Tecno Spark 8C',
        lastActiveAt: now,
        isCurrent: true,
      ),
      KnownDevice(
        id: 'device-ancien',
        label: 'itel A60',
        lastActiveAt: now.subtract(const Duration(days: 18)),
      ),
    ]);
  }
}

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => AccountRepositoryImpl(
    local: SharedPreferencesAccountDataSource(
      ref.watch(sharedPreferencesProvider),
    ),
    clock: ref.watch(clockProvider),
  ),
);
