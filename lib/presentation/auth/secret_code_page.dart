import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/config/mock_credentials.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/domain/entities/auth/secret_code_policy.dart';
import 'package:urim/l10n/generated/app_text.dart';
import 'package:urim/presentation/auth/secret_code_view_model.dart';
import 'package:urim/presentation/common/brand_mark.dart';
import 'package:urim/presentation/common/code_input.dart';
import 'package:urim/presentation/common/demo_banner.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// Création du code secret, en deux saisies.
class SecretCodeSetupPage extends ConsumerStatefulWidget {
  const SecretCodeSetupPage({super.key});

  @override
  ConsumerState<SecretCodeSetupPage> createState() =>
      _SecretCodeSetupPageState();
}

class _SecretCodeSetupPageState extends ConsumerState<SecretCodeSetupPage> {
  final GlobalKey<CodeInputState> _inputKey = GlobalKey<CodeInputState>();

  Future<void> _submit(String code) async {
    final viewModel = ref.read(secretCodeViewModelProvider.notifier);
    final stage = ref.read(secretCodeViewModelProvider).stage;

    if (stage == SecretCodeStage.choose) {
      viewModel.submitFirstEntry(code);
      _inputKey.currentState?.reset();
      return;
    }

    // Échec : on repart de la première saisie, garder l'ancienne n'aurait pas
    // de sens puisque c'est peut-être elle qui était fautive.
    if (!await viewModel.confirm(code)) _inputKey.currentState?.reset();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(secretCodeViewModelProvider);
    final isConfirming = state.stage == SecretCodeStage.confirm;
    final text = AppText.of(context);

    return _SecretCodeScaffold(
      title: isConfirming
          ? text.secretCodeConfirmTitle
          : text.secretCodeChooseTitle,
      helper: isConfirming
          ? text.secretCodeConfirmHelper
          : text.secretCodeChooseHelper(SecretCodePolicy.length),
      demo: text.demoSecretCodeSetup(MockCredentials.secretCode),
      failure: state.failure,
      isSubmitting: state.isSubmitting,
      inputKey: _inputKey,
      onCompleted: _submit,
    );
  }
}

/// Déverrouillage à l'ouverture de l'application.
class SecretCodeUnlockPage extends ConsumerStatefulWidget {
  const SecretCodeUnlockPage({super.key});

  @override
  ConsumerState<SecretCodeUnlockPage> createState() =>
      _SecretCodeUnlockPageState();
}

class _SecretCodeUnlockPageState extends ConsumerState<SecretCodeUnlockPage> {
  final GlobalKey<CodeInputState> _inputKey = GlobalKey<CodeInputState>();
  bool _wrongCode = false;

  Future<void> _submit(String code) async {
    setState(() => _wrongCode = false);

    final unlocked =
        await ref.read(secretCodeUnlockViewModelProvider.notifier).unlock(code);

    if (!unlocked && mounted) {
      setState(() => _wrongCode = true);
      _inputKey.currentState?.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(secretCodeUnlockViewModelProvider);
    final text = AppText.of(context);

    return _SecretCodeScaffold(
      title: text.secretCodeUnlockTitle,
      helper: _wrongCode
          ? text.secretCodeWrong
          : text.secretCodeUnlockHelper,
      helperIsError: _wrongCode,
      demo: text.demoSecretCodeUnlock(MockCredentials.secretCode),
      failure: status.error is Failure ? status.error as Failure : null,
      isSubmitting: status.isLoading,
      inputKey: _inputKey,
      onCompleted: _submit,
    );
  }
}

/// Habillage commun aux deux écrans : même disposition, même marque, même
/// traitement des erreurs.
class _SecretCodeScaffold extends StatelessWidget {
  const _SecretCodeScaffold({
    required this.title,
    required this.helper,
    required this.demo,
    required this.failure,
    required this.isSubmitting,
    required this.inputKey,
    required this.onCompleted,
    this.helperIsError = false,
  });

  final String title;
  final String helper;

  /// Ce que dit le bandeau de démonstration. Ignoré en production.
  final String demo;

  final bool helperIsError;
  final Failure? failure;
  final bool isSubmitting;
  final GlobalKey<CodeInputState> inputKey;
  final ValueChanged<String> onCompleted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xxxl),
              BrandMonogram(color: scheme.primary, size: 96),
              const SizedBox(height: AppSpacing.xxxl),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                helper,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:
                          helperIsError ? scheme.error : colors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              DemoBanner(text: demo),
              const SizedBox(height: AppSpacing.lg),
              CodeInput(
                key: inputKey,
                length: SecretCodePolicy.length,
                obscure: true,
                hasError: helperIsError || failure != null,
                onCompleted: isSubmitting ? (_) {} : onCompleted,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (failure != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 16, color: scheme.error),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        failure!.message,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.error,
                            ),
                      ),
                    ),
                  ],
                ),
              if (isSubmitting)
                const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.lg),
                  child: SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
