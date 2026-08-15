import 'package:shared_preferences/shared_preferences.dart';
import 'package:urim/core/error/exceptions.dart';

/// Accès brut au nom affiché.
///
/// Seul le nom est ici : les églises et les appareils viennent d'un serveur
/// qui n'existe pas encore (Q9, Q11).
abstract interface class AccountLocalDataSource {
  Future<String> readDisplayName();

  Future<void> writeDisplayName(String name);
}

final class SharedPreferencesAccountDataSource
    implements AccountLocalDataSource {
  const SharedPreferencesAccountDataSource(this._preferences);

  static const String displayNameKey = 'account.displayName.v1';

  final SharedPreferences _preferences;

  @override
  Future<String> readDisplayName() async =>
      _preferences.getString(displayNameKey) ?? '';

  @override
  Future<void> writeDisplayName(String name) async {
    final written = await _preferences.setString(displayNameKey, name);
    if (!written) {
      throw const CacheException(
        'Impossible d\'enregistrer le nom affiché.',
        code: 'display_name_write_failed',
      );
    }
  }
}
