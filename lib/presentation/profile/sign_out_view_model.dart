import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/data/repositories/auth_repository_impl.dart';
import 'package:urim/presentation/auth/auth_gate.dart';

/// Fermer la session.
///
/// Le dépôt savait le faire depuis le début ; aucun écran ne l'offrait. Un
/// pasteur qui prête son téléphone, ou qui en change, n'avait aucun moyen de
/// sortir d'Urim.
final class SignOutViewModel extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// [everywhere] ferme aussi les sessions des autres appareils.
  ///
  /// Renvoie la `Failure` si le serveur a refusé — mais **la session locale
  /// est fermée dans tous les cas** : le dépôt efface jetons et trace même
  /// quand l'appel échoue, et refuser de déconnecter parce que le réseau
  /// manque serait absurde.
  Future<Failure?> signOut({bool everywhere = false}) async {
    state = const AsyncLoading();

    final result =
        await ref.read(authRepositoryProvider).signOut(everywhere: everywhere);

    // Les drapeaux de session en premier : ce sont eux qui décident de
    // l'écran. Sans cela, l'application resterait déverrouillée sur une
    // session qui n'existe plus.
    ref.read(sessionUnlockedProvider.notifier).lock();
    ref.invalidate(authSessionProvider);
    ref.invalidate(hasSecretCodeProvider);

    return result.fold(
      onSuccess: (_) {
        state = const AsyncData(null);
        return null;
      },
      onFailure: (failure) {
        state = AsyncError(failure, StackTrace.current);
        return failure;
      },
    );
  }
}

final signOutViewModelProvider =
    NotifierProvider<SignOutViewModel, AsyncValue<void>>(SignOutViewModel.new);
