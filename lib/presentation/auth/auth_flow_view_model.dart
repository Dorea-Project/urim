import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/config/app_config_provider.dart';
import 'package:urim/core/config/mock_credentials.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/core/result/result.dart';
import 'package:urim/core/time/clock_provider.dart';
import 'package:urim/domain/entities/auth/auth_session.dart';
import 'package:urim/data/repositories/auth_repository_impl.dart';
import 'package:urim/data/repositories/secret_code_repository_impl.dart';
import 'package:urim/domain/entities/auth/otp_challenge.dart';
import 'package:urim/domain/entities/auth/phone_number.dart';
import 'package:urim/domain/repositories/auth_repository.dart';
import 'package:urim/domain/usecases/auth/define_secret_code.dart';
import 'package:urim/domain/usecases/auth/request_otp.dart';
import 'package:urim/domain/usecases/auth/verify_otp.dart';
import 'package:urim/presentation/auth/auth_gate.dart';

final requestOtpProvider = Provider(
  (ref) => RequestOtp(ref.watch(authRepositoryProvider)),
);

final confirmRegistrationProvider = Provider(
  (ref) => ConfirmRegistration(ref.watch(authRepositoryProvider)),
);

final verifyDeviceProvider = Provider(
  (ref) => VerifyDevice(ref.watch(authRepositoryProvider)),
);

/// Par quelle porte l'utilisateur est entré.
///
/// Le serveur en expose deux — inscription et connexion — et refuse de dire si
/// un numéro est connu : répondre ferait de la route un annuaire des inscrits.
/// C'est donc l'utilisateur qui choisit, depuis la présentation.
enum AuthDoor {
  /// Créer un compte : SMS, puis code secret posé dans le même geste.
  registration,

  /// Se connecter : code secret d'abord, SMS seulement si l'appareil est
  /// inconnu du serveur.
  signIn,

  /// Code secret oublié : SMS, puis nouveau code. Les autres appareils sont
  /// révoqués — changer la serrure laisse rarement les anciennes clés en
  /// circulation.
  secretCodeReset,

  /// Changer de numéro, depuis le profil.
  ///
  /// Le code part au **nouveau** numéro : c'est lui qu'il faut prouver.
  phoneChange,

  /// Supprimer son compte, depuis le profil.
  ///
  /// Un SMS d'abord : la suppression ne se défait pas, et c'est la seule
  /// opération où un téléphone déverrouillé oublié sur une table coûterait
  /// des années de préparations.
  accountDeletion,

  /// Changer son code depuis le profil, **en étant connecté**.
  ///
  /// Ce n'est pas un oubli : le serveur a sa propre route, authentifiée par le
  /// jeton. Elle n'ouvre pas de session — il y en a déjà une — et ne révoque
  /// personne. Passer par « code oublié » aurait déconnecté la tablette du
  /// pasteur pour un simple changement de code.
  secretCodeChange,
}

/// État partagé par les écrans du parcours d'entrée.
///
/// Un seul contrôleur plutôt qu'un par écran : le code secret a besoin du
/// numéro et du code SMS saisis deux écrans plus tôt, et les faire transiter
/// par les paramètres de route exposerait le tout dans l'URL.
final class AuthFlowState extends Equatable {
  const AuthFlowState({
    this.door = AuthDoor.registration,
    this.dialCode = PhoneNumber.defaultDialCode,
    this.nationalNumber = '',
    this.privacyAccepted = false,
    this.otp = '',
    this.secretCode = '',
    this.otpRequestedAt,
    this.isSubmitting = false,
    this.failure,
  });

  final AuthDoor door;
  final String dialCode;
  final String nationalNumber;
  final bool privacyAccepted;

  /// Code SMS saisi, gardé le temps d'atteindre l'écran du code secret :
  /// à l'inscription, le serveur veut les deux d'un seul appel.
  final String otp;

  /// Code secret saisi à la connexion, gardé **en mémoire seulement**.
  ///
  /// Il sert à poser la dérivation locale de déverrouillage une fois la session
  /// ouverte, sans redemander à l'utilisateur ce qu'il vient de taper. Il
  /// disparaît avec l'écran : rien ne l'écrit nulle part.
  final String secretCode;

  /// Moment de l'envoi, qui fait courir le compte à rebours. Le serveur ne
  /// renvoie ni identifiant de défi ni échéance — il envoie un SMS, et c'est
  /// tout.
  final DateTime? otpRequestedAt;

  final bool isSubmitting;
  final Failure? failure;

  PhoneNumber get phone => PhoneNumber(
        dialCode: dialCode,
        nationalNumber: PhoneNumber.normalize(nationalNumber),
      );

  bool get hasPendingOtp => otpRequestedAt != null;

  /// Temps restant avant qu'il faille redemander un code.
  Duration remaining(DateTime now) {
    final requestedAt = otpRequestedAt;
    if (requestedAt == null) return Duration.zero;

    final left = OtpChallenge.defaultValidity - now.difference(requestedAt);

    return left.isNegative ? Duration.zero : left;
  }

  /// Le bouton reste actif tant que la saisie est plausible ; le refus précis
  /// vient du cas d'usage, qui sait dire *pourquoi*.
  ///
  /// Le consentement ne conditionne que l'inscription : celui qui se reconnecte
  /// l'a donné le jour où il a créé son compte.
  bool get canSubmitPhone =>
      !isSubmitting &&
      phone.isValid &&
      (door != AuthDoor.registration || privacyAccepted);

  String? get fieldError => switch (failure) {
        ValidationFailure(:final fieldErrors) when fieldErrors.isNotEmpty =>
          fieldErrors.values.first,
        _ => null,
      };

  AuthFlowState copyWith({
    AuthDoor? door,
    String? dialCode,
    String? nationalNumber,
    bool? privacyAccepted,
    String? otp,
    String? secretCode,
    DateTime? otpRequestedAt,
    bool? isSubmitting,
    Failure? failure,
    bool clearFailure = false,
  }) =>
      AuthFlowState(
        door: door ?? this.door,
        dialCode: dialCode ?? this.dialCode,
        nationalNumber: nationalNumber ?? this.nationalNumber,
        privacyAccepted: privacyAccepted ?? this.privacyAccepted,
        otp: otp ?? this.otp,
        secretCode: secretCode ?? this.secretCode,
        otpRequestedAt: otpRequestedAt ?? this.otpRequestedAt,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        failure: clearFailure ? null : (failure ?? this.failure),
      );

  @override
  List<Object?> get props => [
        door,
        dialCode,
        nationalNumber,
        privacyAccepted,
        otp,
        secretCode,
        otpRequestedAt,
        isSubmitting,
        failure,
      ];
}

final class AuthFlowViewModel extends Notifier<AuthFlowState> {
  @override
  AuthFlowState build() {
    // Hors serveur, le numéro de démonstration est déjà là : sans passerelle
    // SMS, taper un numéro au hasard n'apprend rien de plus. Le consentement,
    // lui, reste à cocher — c'est un geste, pas un réglage.
    if (ref.watch(appConfigProvider).usesMockCredentials) {
      return const AuthFlowState(
        dialCode: MockCredentials.dialCode,
        nationalNumber: MockCredentials.nationalNumber,
      );
    }

    return const AuthFlowState();
  }

  void setDoor(AuthDoor door) =>
      state = state.copyWith(door: door, clearFailure: true);

  void setDialCode(String value) =>
      state = state.copyWith(dialCode: value, clearFailure: true);

  void setNationalNumber(String value) =>
      state = state.copyWith(nationalNumber: value, clearFailure: true);

  void setPrivacyAccepted(bool value) =>
      state = state.copyWith(privacyAccepted: value, clearFailure: true);

  void setOtp(String value) =>
      state = state.copyWith(otp: value, clearFailure: true);

  /// Demande l'envoi du code. Vrai si le SMS est parti.
  Future<bool> requestCode() async {
    state = state.copyWith(isSubmitting: true, clearFailure: true);

    final result = await ref.read(requestOtpProvider)(
      RequestOtpParams(
        phone: state.phone,
        privacyAccepted: state.privacyAccepted,
      ),
    );

    return result.fold(
      onSuccess: (_) {
        state = state.copyWith(
          isSubmitting: false,
          otp: '',
          otpRequestedAt: ref.read(clockProvider).now(),
        );
        return true;
      },
      onFailure: (failure) {
        state = state.copyWith(isSubmitting: false, failure: failure);
        return false;
      },
    );
  }

  /// Termine l'inscription : code SMS + code secret, en un seul appel.
  Future<bool> confirmRegistration(String secretCode) async {
    state = state.copyWith(isSubmitting: true, clearFailure: true);

    final result = await ref.read(confirmRegistrationProvider)(
      ConfirmRegistrationParams(
        phone: state.phone,
        otp: state.otp,
        secretCode: secretCode,
      ),
    );

    return _settle(result);
  }

  /// Vérifie le code reçu sur un appareil inconnu du serveur.
  Future<bool> verifyDevice() async {
    state = state.copyWith(isSubmitting: true, clearFailure: true);

    final result = await ref.read(verifyDeviceProvider)(
      VerifyDeviceParams(phone: state.phone, otp: state.otp),
    );

    return _settle(result);
  }

  /// Connexion d'un compte existant.
  ///
  /// Rend l'issue du serveur : session ouverte, ou appareil inconnu — auquel
  /// cas un SMS est déjà parti et l'écran du code prend la suite. `null`
  /// signale un refus, dont le motif est dans `state.failure`.
  Future<SignInResult?> signIn(String secretCode) async {
    state = state.copyWith(
      isSubmitting: true,
      secretCode: secretCode,
      clearFailure: true,
    );

    final result = await ref.read(authRepositoryProvider).signIn(
          phone: state.phone,
          secretCode: secretCode,
        );

    final outcome = result.valueOrNull;

    if (outcome == null) {
      state = state.copyWith(
        isSubmitting: false,
        failure: result.failureOrNull,
      );
      return null;
    }

    state = state.copyWith(
      isSubmitting: false,
      otpRequestedAt: outcome is DeviceVerificationNeeded
          ? ref.read(clockProvider).now()
          : null,
      otp: '',
    );

    if (outcome is SessionOpened) {
      await _adoptUnlockCode(secretCode);
      _openGate();
    }

    return outcome;
  }

  /// Code secret oublié — demande le SMS.
  ///
  /// Réussit toujours, même sur un numéro inconnu : c'est la règle du serveur,
  /// et l'écran ne doit pas la contredire en affichant « numéro introuvable ».
  Future<bool> requestSecretCodeReset() async {
    state = state.copyWith(
      isSubmitting: true,
      door: AuthDoor.secretCodeReset,
      clearFailure: true,
    );

    final result = await ref
        .read(authRepositoryProvider)
        .requestSecretCodeReset(state.phone);

    return result.fold(
      onSuccess: (_) {
        state = state.copyWith(
          isSubmitting: false,
          otp: '',
          otpRequestedAt: ref.read(clockProvider).now(),
        );
        return true;
      },
      onFailure: (failure) {
        state = state.copyWith(isSubmitting: false, failure: failure);
        return false;
      },
    );
  }

  /// Changer de numéro — demande le SMS au nouveau numéro.
  ///
  /// L'état porte désormais le **nouveau** numéro : c'est celui que l'écran du
  /// code doit afficher, et celui que la confirmation posera.
  Future<bool> startPhoneChange(PhoneNumber newPhone) async {
    state = state.copyWith(
      dialCode: newPhone.dialCode,
      nationalNumber: newPhone.nationalNumber,
      isSubmitting: true,
      door: AuthDoor.phoneChange,
      clearFailure: true,
    );

    final result =
        await ref.read(authRepositoryProvider).requestPhoneChange(newPhone);

    return result.fold(
      onSuccess: (_) {
        state = state.copyWith(
          isSubmitting: false,
          otp: '',
          otpRequestedAt: ref.read(clockProvider).now(),
        );
        return true;
      },
      onFailure: (failure) {
        state = state.copyWith(
          isSubmitting: false,
          door: AuthDoor.signIn,
          failure: failure,
        );
        return false;
      },
    );
  }

  /// Changer de numéro — pose le nouveau numéro sur le compte.
  Future<bool> confirmPhoneChange() async {
    state = state.copyWith(isSubmitting: true, clearFailure: true);

    final result = await ref.read(authRepositoryProvider).confirmPhoneChange(
          newPhone: state.phone,
          otp: state.otp,
        );

    return result.fold(
      onSuccess: (_) {
        state = state.copyWith(isSubmitting: false, door: AuthDoor.signIn);
        // Le profil lit la session : sans cela, il afficherait l'ancien numéro
        // jusqu'au prochain lancement.
        ref.invalidate(authSessionProvider);
        return true;
      },
      onFailure: (failure) {
        state = state.copyWith(isSubmitting: false, failure: failure);
        return false;
      },
    );
  }

  /// Supprimer son compte — demande le SMS.
  ///
  /// Rien n'est détruit ici : le code seulement part. Tant qu'il n'est pas
  /// saisi, le compte est intact.
  Future<bool> startAccountDeletion(PhoneNumber phone) async {
    state = state.copyWith(
      dialCode: phone.dialCode,
      nationalNumber: phone.nationalNumber,
      isSubmitting: true,
      door: AuthDoor.accountDeletion,
      clearFailure: true,
    );

    final result =
        await ref.read(authRepositoryProvider).requestAccountDeletion();

    return result.fold(
      onSuccess: (_) {
        state = state.copyWith(
          isSubmitting: false,
          otp: '',
          otpRequestedAt: ref.read(clockProvider).now(),
        );
        return true;
      },
      onFailure: (failure) {
        state = state.copyWith(
          isSubmitting: false,
          door: AuthDoor.signIn,
          failure: failure,
        );
        return false;
      },
    );
  }

  /// Referme la porte de suppression — l'utilisateur a renoncé, ou c'est fini.
  void closeDoor() => state = state.copyWith(door: AuthDoor.signIn);

  /// Change son code secret depuis le profil — demande le SMS.
  ///
  /// Route dédiée du serveur, authentifiée par le jeton : le numéro n'est là
  /// que pour l'écran, qui affiche où part le code. Un pasteur connecté n'a
  /// donc ni à se déconnecter, ni à emprunter le chemin de l'oubli — celui-ci
  /// révoque les autres appareils.
  Future<bool> startSecretCodeChange(PhoneNumber phone) async {
    state = state.copyWith(
      dialCode: phone.dialCode,
      nationalNumber: phone.nationalNumber,
      isSubmitting: true,
      door: AuthDoor.secretCodeChange,
      clearFailure: true,
    );

    final result =
        await ref.read(authRepositoryProvider).requestSecretCodeChange();

    return result.fold(
      onSuccess: (_) {
        state = state.copyWith(
          isSubmitting: false,
          otp: '',
          otpRequestedAt: ref.read(clockProvider).now(),
        );
        return true;
      },
      onFailure: (failure) {
        // La porte se referme : laisser `secretCodeChange` ouverte après un
        // refus autoriserait les écrans du parcours d'entrée sans qu'aucun
        // code n'ait été envoyé.
        state = state.copyWith(
          isSubmitting: false,
          door: AuthDoor.signIn,
          failure: failure,
        );
        return false;
      },
    );
  }

  /// Change son code secret — pose le nouveau code.
  ///
  /// La session ne bouge pas : elle était déjà ouverte, et le serveur ne rend
  /// pas de jetons. Seule la dérivation locale de déverrouillage suit, sinon
  /// l'application continuerait d'ouvrir sur l'ancien code hors connexion.
  Future<bool> confirmSecretCodeChange(String newSecretCode) async {
    state = state.copyWith(isSubmitting: true, clearFailure: true);

    final result = await ref.read(authRepositoryProvider).confirmSecretCodeChange(
          otp: state.otp,
          newSecretCode: newSecretCode,
        );

    switch (result) {
      case Success():
        await _adoptUnlockCode(newSecretCode);
        // La porte se referme derrière soi : la redirection cesse d'autoriser
        // les écrans du parcours d'entrée à qui vient d'y terminer son affaire.
        state = state.copyWith(isSubmitting: false, door: AuthDoor.signIn);
        return true;
      case Failed(:final failure):
        state = state.copyWith(isSubmitting: false, failure: failure);
        return false;
    }
  }

  /// Code secret oublié — pose le nouveau code et ouvre la session.
  Future<bool> confirmSecretCodeReset(String newSecretCode) async {
    state = state.copyWith(isSubmitting: true, clearFailure: true);

    final result = await ref.read(authRepositoryProvider).confirmSecretCodeReset(
          phone: state.phone,
          otp: state.otp,
          newSecretCode: newSecretCode,
        );

    final settled = _settle(result);

    // La porte se referme derrière soi. Sans cela, la redirection continuerait
    // d'autoriser les écrans du parcours d'entrée à un utilisateur qui vient
    // d'y terminer son affaire, et il resterait bloqué dessus.
    if (settled) state = state.copyWith(door: AuthDoor.signIn);

    return settled;
  }

  bool _settle(Result<AuthSession> result) => result.fold(
        onSuccess: (_) {
          state = state.copyWith(isSubmitting: false);
          _openGate();
          return true;
        },
        onFailure: (failure) {
          state = state.copyWith(isSubmitting: false, failure: failure);
          return false;
        },
      );

  /// Pose la dérivation locale du code que l'utilisateur vient de taper.
  ///
  /// Le serveur vient de le valider : le redemander pour créer la serrure
  /// locale serait le lui faire saisir deux fois de suite. L'échec est
  /// volontairement ignoré — un code que la politique locale refuse (une suite,
  /// une répétition) laisse simplement l'application demander un code de
  /// déverrouillage à l'écran suivant.
  Future<void> _adoptUnlockCode(String secretCode) async {
    await DefineSecretCode(ref.read(secretCodeRepositoryProvider))(
      DefineSecretCodeParams(code: secretCode, confirmation: secretCode),
    );

    ref.invalidate(hasSecretCodeProvider);
  }

  /// La redirection prend le relais : la session existe désormais.
  void _openGate() {
    ref.invalidate(authSessionProvider);
    ref.read(sessionUnlockedProvider.notifier).unlock();
  }
}

final authFlowViewModelProvider =
    NotifierProvider<AuthFlowViewModel, AuthFlowState>(AuthFlowViewModel.new);
