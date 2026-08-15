import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/data/repositories/settings_repository_impl.dart';
import 'package:urim/domain/entities/settings/app_settings.dart';

/// Réglages de l'utilisateur, chargés une fois puis tenus en mémoire.
final class SettingsViewModel extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final result = await ref.watch(settingsRepositoryProvider).load();

    return result.fold(
      onSuccess: (settings) => settings,
      onFailure: (failure) => throw failure,
    );
  }

  Future<Failure?> setReadingTextSize(ReadingTextSize size) =>
      _update((settings) => settings.copyWith(readingTextSize: size));

  Future<Failure?> setAlwaysShowReference(bool value) =>
      _update((settings) => settings.copyWith(alwaysShowReference: value));

  Future<Failure?> setDefaultTranslation(String translationId) =>
      _update((settings) => settings.copyWith(
            defaultTranslationId: translationId,
          ));

  /// Applique le changement à l'écran d'abord, l'écrit ensuite, et revient en
  /// arrière si l'écriture échoue.
  ///
  /// Un interrupteur qui attend le disque avant de bouger paraît cassé ; un
  /// interrupteur qui bouge sans que rien ne soit écrit ment. Il reste à
  /// remettre l'ancienne valeur et à laisser l'écran le dire.
  Future<Failure?> _update(AppSettings Function(AppSettings) change) async {
    final current = state.value;
    if (current == null) return null;

    final updated = change(current);
    if (updated == current) return null;

    state = AsyncData(updated);

    final result = await ref.read(settingsRepositoryProvider).save(updated);

    return result.fold(
      onSuccess: (saved) {
        state = AsyncData(saved);
        return null;
      },
      onFailure: (failure) {
        state = AsyncData(current);
        return failure;
      },
    );
  }
}

final settingsViewModelProvider =
    AsyncNotifierProvider<SettingsViewModel, AppSettings>(
  SettingsViewModel.new,
);

/// Réglages tels que l'affichage doit les appliquer, sans attendre.
///
/// Un verset ne reste pas blanc le temps de lire une préférence : tant que la
/// lecture n'a pas abouti — ou si elle a échoué — ce sont les valeurs par
/// défaut qui s'appliquent.
final effectiveSettingsProvider = Provider<AppSettings>(
  (ref) => ref.watch(settingsViewModelProvider).value ?? const AppSettings(),
);
