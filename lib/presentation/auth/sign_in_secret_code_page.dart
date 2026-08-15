import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:urim/core/config/mock_credentials.dart';
import 'package:urim/core/router/app_routes.dart';
import 'package:urim/domain/entities/auth/secret_code_policy.dart';
import 'package:urim/domain/repositories/auth_repository.dart';
import 'package:urim/presentation/auth/auth_flow_view_model.dart';
import 'package:urim/presentation/common/brand_mark.dart';
import 'package:urim/presentation/common/code_input.dart';
import 'package:urim/presentation/common/demo_banner.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// Connexion d'un compte existant : le code secret.
///
/// L'inverse de l'inscription — ici le code secret vient **avant** le SMS, et
/// le SMS ne vient que si le serveur ne reconnaît pas l'appareil. C'est ce qui
/// évite un SMS à chaque ouverture sur le téléphone habituel.
class SignInSecretCodePage extends ConsumerStatefulWidget {
  const SignInSecretCodePage({super.key});

  @override
  ConsumerState<SignInSecretCodePage> createState() =>
      _SignInSecretCodePageState();
}

class _SignInSecretCodePageState extends ConsumerState<SignInSecretCodePage> {
  final GlobalKey<CodeInputState> _inputKey = GlobalKey<CodeInputState>();

  Future<void> _submit(String code) async {
    final outcome =
        await ref.read(authFlowViewModelProvider.notifier).signIn(code);

    if (!mounted) return;

    switch (outcome) {
      // Session ouverte : la redirection conduit à la suite. Le code local de
      // déverrouillage se pose à l'écran suivant, si l'appareil n'en a pas.
      case SessionOpened():
        return;

      // Appareil inconnu du serveur : un SMS est parti.
      case DeviceVerificationNeeded():
        context.goNamed(AppRoutes.otpName);

      // Refus : le motif est affiché, la saisie repart à zéro.
      case null:
        _inputKey.currentState?.reset();
    }
  }

  Future<void> _forgotten() async {
    final sent =
        await ref.read(authFlowViewModelProvider.notifier).requestSecretCodeReset();

    if (sent && mounted) context.goNamed(AppRoutes.otpName);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authFlowViewModelProvider);
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.goNamed(AppRoutes.signInName),
          tooltip: 'Retour',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xl),
              BrandMonogram(color: scheme.primary, size: 96),
              const SizedBox(height: AppSpacing.xxxl),
              Text(
                'Ton code secret',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                state.phone.e164,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const DemoBanner(
                text: 'Serveur simulé : le code est celui que tu as posé à '
                    'l\'inscription — ${MockCredentials.secretCode} si tu as '
                    'suivi la suggestion.',
              ),
              const SizedBox(height: AppSpacing.lg),
              CodeInput(
                key: _inputKey,
                length: SecretCodePolicy.length,
                obscure: true,
                hasError: state.failure != null,
                onCompleted: state.isSubmitting ? (_) {} : _submit,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (state.failure != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 16, color: scheme.error),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        'Code secret incorrect.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.error,
                            ),
                      ),
                    ),
                  ],
                ),
              if (state.isSubmitting)
                const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.lg),
                  child: SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),
              TextButton(
                onPressed: state.isSubmitting ? null : _forgotten,
                child: const Text('Code oublié ?'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
