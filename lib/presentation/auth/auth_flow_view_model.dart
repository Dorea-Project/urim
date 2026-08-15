import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/core/time/clock_provider.dart';
import 'package:urim/data/repositories/auth_repository_impl.dart';
import 'package:urim/domain/entities/auth/otp_challenge.dart';
import 'package:urim/domain/entities/auth/phone_number.dart';
import 'package:urim/domain/usecases/auth/request_otp.dart';
import 'package:urim/domain/usecases/auth/verify_otp.dart';
import 'package:urim/presentation/auth/auth_gate.dart';

final requestOtpProvider = Provider(
  (ref) => RequestOtp(ref.watch(authRepositoryProvider)),
);

final verifyOtpProvider = Provider(
  (ref) => VerifyOtp(
    ref.watch(authRepositoryProvider),
    ref.watch(clockProvider).now,
  ),
);

/// État partagé par les deux écrans de connexion.
///
/// Un seul contrôleur plutôt qu'un par écran : l'écran du code a besoin du
/// défi produit par l'écran du numéro, et le faire transiter par les
/// paramètres de route exposerait un identifiant de session dans l'URL.
final class AuthFlowState extends Equatable {
  const AuthFlowState({
    this.dialCode = PhoneNumber.defaultDialCode,
    this.nationalNumber = '',
    this.privacyAccepted = false,
    this.challenge,
    this.isSubmitting = false,
    this.failure,
  });

  final String dialCode;
  final String nationalNumber;
  final bool privacyAccepted;
  final OtpChallenge? challenge;
  final bool isSubmitting;
  final Failure? failure;

  PhoneNumber get phone => PhoneNumber(
        dialCode: dialCode,
        nationalNumber: PhoneNumber.normalize(nationalNumber),
      );

  /// Le bouton reste actif tant que la saisie est plausible ; le refus précis
  /// vient du cas d'usage, qui sait dire *pourquoi*.
  bool get canSubmitPhone =>
      !isSubmitting && privacyAccepted && phone.isValid;

  String? get fieldError => switch (failure) {
        ValidationFailure(:final fieldErrors) when fieldErrors.isNotEmpty =>
          fieldErrors.values.first,
        _ => null,
      };

  AuthFlowState copyWith({
    String? dialCode,
    String? nationalNumber,
    bool? privacyAccepted,
    OtpChallenge? challenge,
    bool? isSubmitting,
    Failure? failure,
    bool clearFailure = false,
  }) =>
      AuthFlowState(
        dialCode: dialCode ?? this.dialCode,
        nationalNumber: nationalNumber ?? this.nationalNumber,
        privacyAccepted: privacyAccepted ?? this.privacyAccepted,
        challenge: challenge ?? this.challenge,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        failure: clearFailure ? null : (failure ?? this.failure),
      );

  @override
  List<Object?> get props => [
        dialCode,
        nationalNumber,
        privacyAccepted,
        challenge,
        isSubmitting,
        failure,
      ];
}

final class AuthFlowViewModel extends Notifier<AuthFlowState> {
  @override
  AuthFlowState build() => const AuthFlowState();

  void setDialCode(String value) =>
      state = state.copyWith(dialCode: value, clearFailure: true);

  void setNationalNumber(String value) =>
      state = state.copyWith(nationalNumber: value, clearFailure: true);

  void setPrivacyAccepted(bool value) =>
      state = state.copyWith(privacyAccepted: value, clearFailure: true);

  /// Demande l'envoi du code. Vrai si un défi a été obtenu.
  Future<bool> requestCode() async {
    state = state.copyWith(isSubmitting: true, clearFailure: true);

    final result = await ref.read(requestOtpProvider)(
      RequestOtpParams(
        phone: state.phone,
        privacyAccepted: state.privacyAccepted,
      ),
    );

    return result.fold(
      onSuccess: (challenge) {
        state = state.copyWith(challenge: challenge, isSubmitting: false);
        return true;
      },
      onFailure: (failure) {
        state = state.copyWith(isSubmitting: false, failure: failure);
        return false;
      },
    );
  }

  /// Vérifie le code saisi. Vrai si la session est ouverte.
  Future<bool> verifyCode(String code) async {
    final challenge = state.challenge;
    if (challenge == null) return false;

    state = state.copyWith(isSubmitting: true, clearFailure: true);

    final result = await ref.read(verifyOtpProvider)(
      VerifyOtpParams(challenge: challenge, code: code),
    );

    return result.fold(
      onSuccess: (_) {
        state = state.copyWith(isSubmitting: false);
        // La redirection prend le relais : la session existe désormais.
        ref.invalidate(authSessionProvider);
        return true;
      },
      onFailure: (failure) {
        state = state.copyWith(isSubmitting: false, failure: failure);
        return false;
      },
    );
  }
}

final authFlowViewModelProvider =
    NotifierProvider<AuthFlowViewModel, AuthFlowState>(AuthFlowViewModel.new);
