import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:urim/core/router/app_routes.dart';
import 'package:urim/presentation/auth/auth_flow_view_model.dart';
import 'package:urim/presentation/common/brand_mark.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// Saisie du numéro de téléphone : inscription et connexion confondues.
///
/// Il n'y a pas deux parcours. Un numéro déjà connu ouvre une session, un
/// numéro inconnu crée un compte — l'utilisateur n'a pas à savoir dans quel
/// cas il se trouve.
class PhonePage extends ConsumerWidget {
  const PhonePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authFlowViewModelProvider);
    final viewModel = ref.read(authFlowViewModelProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    Future<void> submit() async {
      if (await viewModel.requestCode() && context.mounted) {
        context.goNamed(AppRoutes.otpName);
      }
    }

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
                'Votre numéro valide',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  SizedBox(
                    width: 84,
                    child: TextFormField(
                      initialValue: state.dialCode,
                      keyboardType: TextInputType.phone,
                      textAlign: TextAlign.center,
                      onChanged: viewModel.setDialCode,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\+0-9]')),
                        LengthLimitingTextInputFormatter(5),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      keyboardType: TextInputType.phone,
                      autofocus: true,
                      onChanged: viewModel.setNationalNumber,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(14),
                      ],
                      decoration: InputDecoration(
                        hintText: '07 47 76 9069',
                        errorText: state.fieldError,
                      ),
                      onFieldSubmitted: (_) {
                        if (state.canSubmitPhone) submit();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _PrivacyConsent(
                accepted: state.privacyAccepted,
                onChanged: viewModel.setPrivacyAccepted,
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: state.canSubmitPhone ? submit : null,
                child: state.isSubmitting
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Soumettre'),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacyConsent extends StatelessWidget {
  const _PrivacyConsent({required this.accepted, required this.onChanged});

  final bool accepted;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: context.colors.textSecondary,
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Checkbox(
          value: accepted,
          onChanged: (value) => onChanged(value ?? false),
          visualDensity: VisualDensity.compact,
        ),
        Expanded(
          // Toute la phrase est cliquable, pas seulement la case : viser une
          // case de 18 pixels au pouce est une épreuve inutile.
          child: GestureDetector(
            onTap: () => onChanged(!accepted),
            child: Text.rich(
              TextSpan(
                text: 'J\'ai lu et j\'accepte la ',
                style: textStyle,
                children: [
                  TextSpan(
                    text: 'politique de confidentialité',
                    style: textStyle?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
