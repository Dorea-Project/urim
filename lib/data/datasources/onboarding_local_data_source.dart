import 'package:shared_preferences/shared_preferences.dart';
import 'package:urim/core/error/exceptions.dart';

/// Accès brut à l'état de la présentation.
abstract interface class OnboardingLocalDataSource {
  Future<bool> hasCompleted();

  Future<void> markCompleted();
}

/// Mise en œuvre sur les préférences système.
final class SharedPreferencesOnboardingDataSource
    implements OnboardingLocalDataSource {
  const SharedPreferencesOnboardingDataSource(this._preferences);

  /// Suffixée par une version : si la présentation est refondue et doit être
  /// remontrée à tout le monde, il suffira de passer à `v2`.
  static const String storageKey = 'onboarding.completed.v1';

  final SharedPreferences _preferences;

  @override
  Future<bool> hasCompleted() async =>
      _preferences.getBool(storageKey) ?? false;

  @override
  Future<void> markCompleted() async {
    final written = await _preferences.setBool(storageKey, true);
    if (!written) {
      throw const CacheException(
        'Impossible d\'enregistrer la fin de la présentation.',
        code: 'onboarding_write_failed',
      );
    }
  }
}
