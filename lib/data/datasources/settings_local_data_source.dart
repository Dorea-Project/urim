import 'package:shared_preferences/shared_preferences.dart';
import 'package:urim/core/error/exceptions.dart';
import 'package:urim/domain/entities/bible/bible_translation.dart';
import 'package:urim/domain/entities/settings/app_settings.dart';

/// Accès brut aux préférences.
abstract interface class SettingsLocalDataSource {
  Future<AppSettings> read();

  Future<void> write(AppSettings settings);
}

/// Mise en œuvre sur les préférences système (D11).
///
/// Trois scalaires lus une fois au démarrage : c'est exactement ce à quoi les
/// préférences conviennent. Ce qui les disqualifie pour les préparations — un
/// fil qui grandit, un audio de plusieurs dizaines de mégaoctets — ne s'oppose
/// pas ici.
final class SharedPreferencesSettingsDataSource
    implements SettingsLocalDataSource {
  const SharedPreferencesSettingsDataSource(this._preferences);

  static const String readingTextSizeKey = 'settings.readingTextSize.v1';
  static const String defaultTranslationKey = 'settings.defaultTranslation.v1';
  static const String alwaysShowReferenceKey =
      'settings.alwaysShowReference.v1';

  final SharedPreferences _preferences;

  @override
  Future<AppSettings> read() async {
    const defaults = AppSettings();

    return AppSettings(
      readingTextSize: ReadingTextSize.fromName(
        _preferences.getString(readingTextSizeKey),
      ),
      // Une traduction retirée du catalogue — droits perdus, identifiant
      // renommé — ne doit pas laisser l'application sur une version qu'elle ne
      // sait plus afficher.
      defaultTranslationId: BibleTranslation.byId(
        _preferences.getString(defaultTranslationKey) ??
            defaults.defaultTranslationId,
      ).id,
      alwaysShowReference: _preferences.getBool(alwaysShowReferenceKey) ??
          defaults.alwaysShowReference,
    );
  }

  @override
  Future<void> write(AppSettings settings) async {
    final written = await Future.wait([
      _preferences.setString(readingTextSizeKey, settings.readingTextSize.name),
      _preferences.setString(
        defaultTranslationKey,
        settings.defaultTranslationId,
      ),
      _preferences.setBool(
        alwaysShowReferenceKey,
        settings.alwaysShowReference,
      ),
    ]);

    if (written.any((success) => !success)) {
      throw const CacheException(
        'Impossible d\'enregistrer les réglages.',
        code: 'settings_write_failed',
      );
    }
  }
}
