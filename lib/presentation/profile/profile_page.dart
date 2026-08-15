import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/core/router/app_routes.dart';
import 'package:urim/domain/entities/account/known_device.dart';
import 'package:urim/domain/entities/account/user_profile.dart';
import 'package:urim/presentation/common/french_dates.dart';
import 'package:urim/presentation/common/section_card.dart';
import 'package:urim/presentation/profile/profile_view_model.dart';
import 'package:urim/presentation/profile/widgets/display_name_dialog.dart';
import 'package:urim/presentation/profile/widgets/profile_avatar.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// Profil : l'identité, les églises qui reconnaissent le numéro, les
/// appareils.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          tooltip: 'Retour',
        ),
      ),
      body: SafeArea(
        child: switch (profile) {
          AsyncData(:final value) => _ProfileList(state: value),
          AsyncError(:final error) => _ProfileError(error: error),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _ProfileList extends ConsumerWidget {
  const _ProfileList({required this.state});

  final ProfileState state;

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final name = await askDisplayName(
      context: context,
      current: state.profile.displayName,
    );

    if (name == null) return;

    final failure =
        await ref.read(profileViewModelProvider.notifier).rename(name);

    if (failure == null || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_messageFor(failure))),
    );
  }

  Future<void> _forget(
    BuildContext context,
    WidgetRef ref,
    KnownDevice device,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Retirer ${device.label} ?'),
        content: const Text(
          'Cet appareil devra se reconnecter par SMS pour ouvrir Urim.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final failure = await ref
        .read(profileViewModelProvider.notifier)
        .forgetDevice(device.id);

    if (failure == null || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_messageFor(failure))),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = state.profile;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        _Identity(profile: profile),
        const SizedBox(height: AppSpacing.xl),

        // --- Compte ----------------------------------------------------------
        const SectionLabel('Compte'),
        SectionCard(
          children: [
            SettingNavRow(
              title: 'Nom affiché',
              value: profile.hasDisplayName ? profile.displayName : 'À définir',
              onTap: () => _rename(context, ref),
            ),
            SettingNavRow(
              title: 'Numéro de téléphone',
              value: formatPhone(profile),
              subtitle: 'Changer de numéro suppose un nouveau code par SMS.',
            ),
            const SettingNavRow(
              title: 'Code à 4 chiffres',
              value: 'Modifier',
              subtitle: 'Le changement passera par l\'écran de création, '
                  'encore réservé au premier accès.',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        // --- Églises ---------------------------------------------------------
        const SectionLabel('Églises'),
        if (state.churches.isEmpty)
          const SectionCard(
            children: [
              SettingRow(
                title: 'Aucune église rattachée',
                subtitle: 'Le rattachement viendra de l\'annuaire de la '
                    'plateforme, pas d\'Urim.',
                muted: true,
              ),
            ],
          )
        else
          SectionCard(
            children: [
              for (final church in state.churches)
                SettingNavRow(
                  title: church.label,
                  subtitle: 'Ton numéro y est reconnu. Tes préparations n\'y '
                      'sont pas visibles.',
                ),
            ],
          ),
        const SectionNote(
          'Une seule identité, plusieurs églises possibles. Ce que tu écris '
          'dans Urim ne traverse jamais vers elles.',
        ),
        const SizedBox(height: AppSpacing.xl),

        // --- Appareils -------------------------------------------------------
        const SectionLabel('Appareils'),
        SectionCard(
          children: [
            for (final device in state.devices)
              SettingRow(
                title: device.label,
                subtitle: device.isCurrent
                    ? 'Cet appareil · actif maintenant'
                    : 'Dernière activité le '
                        '${frenchDayMonth(device.lastActiveAt)}',
                trailing: device.canBeForgotten
                    ? TextButton(
                        onPressed: () => _forget(context, ref, device),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                        child: const Text('Retirer'),
                      )
                    : null,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        SectionCard(
          children: [
            SettingNavRow(
              title: 'Réglages',
              onTap: () => context.pushNamed(AppRoutes.settingsName),
            ),
            SettingNavRow(
              title: 'Tes données',
              onTap: () => context.pushNamed(AppRoutes.privacyName),
            ),
          ],
        ),
      ],
    );
  }
}

/// En-tête : monogramme, nom, numéro.
class _Identity extends StatelessWidget {
  const _Identity({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        ProfileAvatar(initials: profile.initials),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.hasDisplayName ? profile.displayName : 'Sans nom',
                style: theme.textTheme.headlineSmall,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                formatPhone(profile),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileError extends ConsumerWidget {
  const _ProfileError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: scheme.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Le profil n\'a pas pu être lu.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (error is Failure) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                (error as Failure).message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.colors.textSecondary,
                    ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton(
              onPressed: () => ref.invalidate(profileViewModelProvider),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

/// « +225 07 00 00 00 00 » — les chiffres par deux, comme on les dicte.
String formatPhone(UserProfile profile) {
  final digits = profile.phone.nationalNumber;
  final groups = <String>[];

  for (var i = 0; i < digits.length; i += 2) {
    groups.add(digits.substring(i, (i + 2).clamp(0, digits.length)));
  }

  return '${profile.phone.dialCode} ${groups.join(' ')}'.trimRight();
}

String _messageFor(Failure failure) => switch (failure) {
      ValidationFailure(:final fieldErrors) when fieldErrors.isNotEmpty =>
        fieldErrors.values.first,
      ValidationFailure() => 'Cette modification a été refusée.',
      _ => 'Cette modification n\'a pas pu être enregistrée.',
    };
