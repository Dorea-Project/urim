import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/domain/entities/auth/otp_challenge.dart';
import 'package:urim/presentation/auth/auth_flow_view_model.dart';
import 'package:urim/presentation/common/brand_mark.dart';
import 'package:urim/presentation/common/code_input.dart';
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
    final challenge = ref.read(authFlowViewModelProvider).challenge;
    if (challenge == null) return;

    final left = challenge.remaining(DateTime.now());
    if (mounted && left != _remaining) setState(() => _remaining = left);
  }

  Future<void> _validate() async {
    final verified =
        await ref.read(authFlowViewModelProvider.notifier).verifyCode(_code);

    // Réussite : la redirection conduit à la suite, l'écran n'a rien à faire.
    if (!verified && mounted) {
      _inputKey.currentState?.reset();
      setState(() => _code = '');
    }
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
                'Utiliser code SMS de '
                '${OtpChallenge.defaultCodeLength} chiffres',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xl),
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
                    : const Text('Validation'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: state.isSubmitting ? null : _resend,
                child: Text(
                  expired ? 'Demander un nouveau code' : 'Renvoyer le code',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Temps restant, ou message d'échec s'il y en a un.
class _Countdown extends StatelessWidget {
  const _Countdown({required this.remaining, required this.failure});

  final Duration remaining;
  final Object? failure;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.bodySmall;

    if (failure != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 16, color: scheme.error),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Code incorrect',
            style: style?.copyWith(color: scheme.error),
          ),
        ],
      );
    }

    if (remaining == Duration.zero) {
      return Text(
        'Code expiré',
        style: style?.copyWith(color: scheme.error),
      );
    }

    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;

    return Text(
      minutes > 0
          ? 'il reste $minutes min ${seconds.toString().padLeft(2, '0')}'
          : 'il reste $seconds s',
      style: style?.copyWith(color: context.colors.textSecondary),
    );
  }
}
