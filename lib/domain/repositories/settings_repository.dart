import 'package:urim/core/result/result.dart';
import 'package:urim/domain/entities/settings/app_settings.dart';

/// Lecture et écriture des préférences.
///
/// Volontairement sans granularité : les réglages tiennent en trois champs et
/// se lisent d'un bloc au démarrage. Une méthode par interrupteur multiplierait
/// les allers-retours sans rien simplifier.
abstract interface class SettingsRepository {
  Future<Result<AppSettings>> load();

  /// Enregistre et renvoie les réglages effectivement retenus.
  Future<Result<AppSettings>> save(AppSettings settings);
}
