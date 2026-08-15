import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/data/repositories/auth_repository_impl.dart';
import 'package:urim/data/repositories/secret_code_repository_impl.dart';
import 'package:urim/domain/entities/auth/auth_session.dart';

/// Où en est l'utilisateur dans l'accès à l'application.
enum AuthGate {
  /// Aucune session : passage par le numéro de téléphone.
  signedOut,

  /// Session ouverte, mais aucun code secret sur cet appareil.
  needsSecretCode,

  /// Session ouverte, code secret défini, application encore verrouillée.
  locked,

  /// Accès ouvert.
  ready,
}

final authSessionProvider = FutureProvider<AuthSession?>((ref) async {
  final result = await ref.watch(authRepositoryProvider).currentSession();
  return result.fold(onSuccess: (session) => session, onFailure: (_) => null);
});

final hasSecretCodeProvider = FutureProvider<bool>((ref) async {
  final result = await ref.watch(secretCodeRepositoryProvider).hasSecretCode();
  return result.fold(onSuccess: (defined) => defined, onFailure: (_) => false);
});

/// Déverrouillage de la session en cours.
///
/// Volontairement non persisté : fermer l'application la reverrouille. C'est
/// tout l'intérêt d'un code secret — sans cela, il ne serait demandé qu'une
/// fois dans la vie de l'installation.
final class SessionLock extends Notifier<bool> {
  @override
  bool build() => false;

  void unlock() => state = true;

  void lock() => state = false;
}

final sessionUnlockedProvider =
    NotifierProvider<SessionLock, bool>(SessionLock.new);

/// État consolidé, lu par la redirection du routeur.
final authGateProvider = FutureProvider<AuthGate>((ref) async {
  final session = await ref.watch(authSessionProvider.future);
  if (session == null) return AuthGate.signedOut;

  final hasCode = await ref.watch(hasSecretCodeProvider.future);
  if (!hasCode) return AuthGate.needsSecretCode;

  return ref.watch(sessionUnlockedProvider)
      ? AuthGate.ready
      : AuthGate.locked;
});
