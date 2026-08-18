import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/data/repositories/secret_code_repository_impl.dart';
import 'package:urim/domain/usecases/auth/define_secret_code.dart';
import 'package:urim/domain/usecases/auth/verify_secret_code.dart';
import 'package:urim/presentation/auth/auth_flow_view_model.dart';
import 'package:urim/presentation/auth/auth_gate.dart';

final defineSecretCodeProvider = Provider(
  (ref) => DefineSecretCode(ref.watch(secretCodeRepositoryProvider)),
);

final verifySecretCodeProvider = Provider(
  (ref) => VerifySecretCode(ref.watch(secretCodeRepositoryProvider)),
);

/// Étape de la création du code.
enum SecretCodeStage { choose, confirm }

final class SecretCodeState extends Equatable {
  const SecretCodeState({
    this.stage = SecretCodeStage.choose,
    this.firstEntry = '',
    this.isSubmitting = false,
    this.failure,
  });

  final SecretCodeStage stage;
  final String firstEntry;
  final bool isSubmitting;
  final Failure? failure;

  @override
  List<Object?> get props => [stage, firstEntry, isSubmitting, failure];
}

/// Création du code secret, en deux saisies.
final class SecretCodeViewModel extends Notifier<SecretCodeState> {
  @override
  SecretCodeState build() => const SecretCodeState();

  /// Première saisie : mémorisée, sans rien écrire encore.
  void submitFirstEntry(String code) => state = SecretCodeState(
        stage: SecretCodeStage.confirm,
        firstEntry: code,
      );

  /// Retour à la première saisie, après une confirmation divergente.
  void restart() => state = const SecretCodeState();

  /// Seconde saisie : c'est ici que tout se joue.
  ///
  /// Le code part **deux fois**, et ce n'est pas une redondance :
  ///
  /// - au serveur, où il devient l'identifiant du compte — c'est lui qui sera
  ///   redemandé depuis un autre téléphone ;
  /// - en local, sous forme dérivée, pour déverrouiller l'application sans
  ///   réseau. Redemander au serveur à chaque ouverture rendrait Urim
  ///   inutilisable dès que la connexion manque.
  ///
  /// L'ordre importe : la règle locale — quatre chiffres, ni suite ni
  /// répétition, deux saisies identiques — filtre d'abord, pour ne pas
  /// dépenser un appel sur un code que le serveur refuserait aussi.
  Future<bool> confirm(String confirmation) async {
    state = SecretCodeState(
      stage: state.stage,
      firstEntry: state.firstEntry,
      isSubmitting: true,
    );

    final local = await ref.read(defineSecretCodeProvider)(
      DefineSecretCodeParams(
        code: state.firstEntry,
        confirmation: confirmation,
      ),
    );

    final rejected = local.failureOrNull;
    if (rejected != null) {
      // Codes trop simples ou saisies divergentes : on repart de la première
      // saisie, garder la précédente n'aurait pas de sens.
      state = SecretCodeState(failure: rejected);
      return false;
    }

    if (!await _settleWithServer()) {
      state = SecretCodeState(
        failure: ref.read(authFlowViewModelProvider).failure,
      );
      return false;
    }

    // Poser son code vaut déverrouillage : on ne le redemande pas dans la
    // foulée.
    ref.read(sessionUnlockedProvider.notifier).unlock();
    ref.invalidate(hasSecretCodeProvider);
    state = const SecretCodeState();

    return true;
  }

  /// Ce que le serveur doit faire de ce code, selon la porte empruntée.
  ///
  /// Quatre cas, et un seul n'appelle personne : quand la session est déjà
  /// ouverte — connexion depuis un appareil qui n'avait pas encore de serrure
  /// locale — le code ne sert qu'à déverrouiller, et le serveur a déjà le sien.
  Future<bool> _settleWithServer() async {
    final flow = ref.read(authFlowViewModelProvider.notifier);
    final hasSession = ref.read(authSessionProvider).value != null;

    return switch (ref.read(authFlowViewModelProvider).door) {
      // Une session ouverte ne dispense pas d'inscrire : elle rendrait
      // l'inscription impossible à terminer.
      AuthDoor.registration when !hasSession =>
        flow.confirmRegistration(state.firstEntry),
      AuthDoor.registration => true,

      // **Toujours le serveur**, session ouverte ou non : ne poser que la
      // serrure locale laisserait l'ancien code valable partout ailleurs, et
      // le pasteur croirait l'avoir change.
      AuthDoor.secretCodeReset =>
        flow.confirmSecretCodeReset(state.firstEntry),

      // Changement volontaire depuis le profil : route dediee, session
      // conservee, aucun appareil revoque.
      AuthDoor.secretCodeChange =>
        flow.confirmSecretCodeChange(state.firstEntry),

      // Connexion depuis un appareil qui n'avait pas encore de serrure
      // locale : le serveur a deja son code, celui-ci ne fait que
      // deverrouiller.
      AuthDoor.signIn => true,
    };
  }
}

final secretCodeViewModelProvider =
    NotifierProvider<SecretCodeViewModel, SecretCodeState>(
  SecretCodeViewModel.new,
);

/// Déverrouillage à l'ouverture.
final class SecretCodeUnlockViewModel extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Vrai si le code est le bon.
  Future<bool> unlock(String code) async {
    state = const AsyncLoading();

    final result = await ref.read(verifySecretCodeProvider)(code);

    return result.fold(
      onSuccess: (matches) {
        state = const AsyncData(null);
        if (matches) ref.read(sessionUnlockedProvider.notifier).unlock();
        return matches;
      },
      onFailure: (failure) {
        state = AsyncError(failure, StackTrace.current);
        return false;
      },
    );
  }
}

final secretCodeUnlockViewModelProvider =
    NotifierProvider<SecretCodeUnlockViewModel, AsyncValue<void>>(
  SecretCodeUnlockViewModel.new,
);
