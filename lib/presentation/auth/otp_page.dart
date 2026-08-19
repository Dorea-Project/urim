import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:urim/core/config/mock_credentials.dart';
import 'package:urim/core/error/auth_error_codes.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/core/router/app_routes.dart';
import 'package:urim/domain/entities/auth/otp_challenge.dart';
import 'package:urim/l10n/generated/app_text.dart';
import 'package:urim/presentation/auth/auth_flow_view_model.dart';
import 'package:urim/presentation/common/brand_mark.dart';
import 'package:urim/presentation/common/demo_banner.dart';
import 'package:urim/presentation/common/code_input.dart';
import 'package:urim/presentation/profile/account_erasure_view_model.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// Saisie du code reçu par SMS.
class OtpPage extends ConsumerStatefulWidget {
  const OtpPage({super.key});

  @override
  ConsumerState<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends ConsumerState<OtpPage> {
  final GlobalKey<CodeInputState> _inputKey = GlobalKey<CodeInputState>();

  Timer? _ticker;
  Duration _remaining = OtpChallenge.defaultValidity;
  String _code = '';

  @override
  void initState() {
    super.initState();
    _startTicker();
  }

  @override
  void dispose() {
    // Sans cette annulation, le minuteur survit à l'écran et continue de
    // réveiller un widget démonté.
    _ticker?.cancel();
    super.dispose();
  }

  void _startTicker() {
    _ticker?.cancel();
    _refreshRemaining();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _refreshRemaining();
      if (_remaining == Duration.zero) _ticker?.cancel();
    });
  }

  void _refreshRemaining() {
    final state = ref.read(authFlowViewModelProvider);
    if (!state.hasPendingOtp) return;

    final left = state.remaining(DateTime.now());
    if (mounted && left != _remaining) setState(() => _remaining = left);
  }

  /// Le code n'est pas vérifié ici.
  ///
  /// À l'inscription, le serveur veut le code SMS **et** le code secret dans le
  /// même appel : le vérifier seul obligerait à le rejouer ensuite, et un code
  /// à usage unique ne se rejoue pas. On le garde donc et l'on passe à la
  /// serrure. Sur un appareil inconnu, en revanche, il n'y a rien à poser :
  /// la vérification se fait ici.
  Future<void> _validate() async {
    final viewModel = ref.read(authFlowViewModelProvider.notifier);
    viewModel.setOtp(_code);

    final door = ref.read(authFlowViewModelProvider).door;

    // La suppression n'a pas de second écran : après le code, il n'y a plus
    // de compte.
    if (door == AuthDoor.accountDeletion) {
      await _erase();
      return;
    }

    // Inscription et code oublié posent une serrure : le code SMS les
    // accompagne dans le même appel, une fois le code secret choisi.
    if (door != AuthDoor.signIn) {
      if (mounted) context.goNamed(AppRoutes.secretCodeSetupName);
      return;
    }

    final verified = await viewModel.verifyDevice();

    // Réussite : la redirection conduit à la suite, l'écran n'a rien à faire.
    if (!verified && mounted) {
      _inputKey.currentState?.reset();
      setState(() => _code = '');
    }
  }

  /// Supprime le compte, puis laisse la redirection ramener au tout début.
  Future<void> _erase() async {
    final text = AppText.of(context);
    final failure =
        await ref.read(accountErasureViewModelProvider.notifier).erase(_code);

    if (!mounted) return;

    if (failure != null) {
      // Le compte est toujours là : l'écran redemande le code plutôt que de
      // laisser croire que quelque chose s'est passé.
      _inputKey.currentState?.reset();
      setState(() => _code = '');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text.profileDeleteAccountDone)),
    );
  }

  Future<void> _resend() async {
    final sent =
        await ref.read(authFlowViewModelProvider.notifier).requestCode();
    if (sent && mounted) {
      _inputKey.currentState?.reset();
      setState(() => _code = '');
      _startTicker();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authFlowViewModelProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = AppText.of(context);
    final expired = _remaining == Duration.zero;
    final complete = _code.length == OtpChallenge.defaultCodeLength;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxxl),
              Center(child: BrandMonogram(color: scheme.primary, size: 96)),
              const SizedBox(height: AppSpacing.xxxl),
              Text(
                text.authOtpTitle(OtpChallenge.defaultCodeLength),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              DemoBanner(text: text.demoOtp(MockCredentials.otp)),
              const SizedBox(height: AppSpacing.lg),
              CodeInput(
                key: _inputKey,
                length: OtpChallenge.defaultCodeLength,
                hasError: state.failure != null,
                onChanged: (value) => setState(() => _code = value),
                onCompleted: (_) => _validate(),
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: _Countdown(remaining: _remaining, failure: state.failure),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: state.isSubmitting || !complete || expired
                    ? null
                    : _validate,
                child: state.isSubmitting
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(text.authOtpValidate),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: state.isSubmitting ? null : _resend,
                child: Text(
                  expired ? text.authOtpRequestNew : text.authOtpResend,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ce que dit un refus du serveur, en français d'utilisateur.
///
/// Traduit le **code** et non le message : celui du serveur est technique et
/// change au fil des relectures, le code est stable.
String _messageFor(AppText text, Failure failure) =>
    switch (failure.code) {
      AuthErrorCodes.otpExpired ||
      AuthErrorCodes.otpNotFound =>
        text.errorOtpExpired,
      AuthErrorCodes.otpInvalid => text.errorOtpInvalid,
      AuthErrorCodes.otpTooManyAttempts => text.errorOtpTooManyAttempts,
      AuthErrorCodes.otpTooManyRequests => text.errorOtpTooManyRequests,
      AuthErrorCodes.phoneAlreadyRegistered =>
        text.errorPhoneAlreadyRegistered,
      _ => switch (failure) {
          NetworkFailure() => text.errorNoConnection,
          ValidationFailure() => text.errorOtpInvalid,
          _ => text.errorVerificationUnavailable,
        },
    };

/// Temps restant, ou message d'échec s'il y en a un.
class _Countdown extends StatelessWidget {
  const _Countdown({required this.remaining, required this.failure});

  final Duration remaining;
  final Failure? failure;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.bodySmall;
    final text = AppText.of(context);

    if (failure case final Failure failure) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 16, color: scheme.error),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              _messageFor(text, failure),
              textAlign: TextAlign.right,
              style: style?.copyWith(color: scheme.error),
            ),
          ),
        ],
      );
    }

    if (remaining == Duration.zero) {
      return Text(
        text.authOtpExpiredShort,
        style: style?.copyWith(color: scheme.error),
      );
    }

    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;

    return Text(
      minutes > 0
          ? text.authOtpRemainingMinutes(
              minutes,
              seconds.toString().padLeft(2, '0'),
            )
          : text.authOtpRemainingSeconds(seconds),
      style: style?.copyWith(color: context.colors.textSecondary),
    );
  }
}
