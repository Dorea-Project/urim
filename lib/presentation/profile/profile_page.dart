import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/core/router/app_routes.dart';
import 'package:urim/domain/entities/account/device_roster.dart';
import 'package:urim/domain/entities/account/known_device.dart';
import 'package:urim/domain/entities/account/user_profile.dart';
import 'package:urim/domain/entities/auth/phone_number.dart';
import 'package:urim/l10n/generated/app_text.dart';
import 'package:urim/presentation/auth/auth_flow_view_model.dart';
import 'package:urim/core/text/french_dates.dart';
import 'package:urim/presentation/common/section_card.dart';
import 'package:urim/presentation/profile/profile_view_model.dart';
import 'package:urim/presentation/profile/sign_out_view_model.dart';
import 'package:urim/presentation/profile/widgets/display_name_dialog.dart';
import 'package:urim/presentation/profile/widgets/phone_change_dialog.dart';
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
        title: Text(AppText.of(context).profileTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          tooltip: AppText.of(context).back,
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
      SnackBar(content: Text(_messageFor(AppText.of(context), failure))),
    );
  }

  Future<void> _forget(
    BuildContext context,
    WidgetRef ref,
    KnownDevice device,
  ) async {
    final text = AppText.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(text.profileDeviceRemoveTitle(device.label)),
        content: Text(text.profileDeviceRemoveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(text.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(text.profileDeviceRemove),
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
      SnackBar(content: Text(_messageFor(text, failure))),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = state.profile;
    final text = AppText.of(context);
    final roster = DeviceRoster(state.devices);

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
        SectionLabel(text.profileSectionAccount),
        SectionCard(
          children: [
            SettingNavRow(
              title: text.profileDisplayName,
              value: profile.hasDisplayName
                  ? profile.displayName
                  : text.profileDisplayNameEmpty,
              onTap: () => _rename(context, ref),
            ),
            SettingNavRow(
              title: text.profilePhone,
              value: formatPhone(profile),
              onTap: () => _changePhone(context, ref, profile.phone),
            ),
            SettingNavRow(
              title: text.profileSecretCode,
              value: text.profileSecretCodeAction,
              onTap: () => _changeSecretCode(context, ref, profile.phone),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        // --- Églises ---------------------------------------------------------
        SectionLabel(text.profileSectionChurches),
        if (state.churches.isEmpty)
          SectionCard(
            children: [
              SettingRow(
                title: text.profileNoChurch,
                subtitle: text.profileNoChurchHint,
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
                  subtitle: text.profileChurchRecognised,
                ),
            ],
          ),
        SectionNote(text.profileChurchesNote),
        const SizedBox(height: AppSpacing.xl),

        // --- Appareils -------------------------------------------------------
        SectionLabel(
          '${text.profileSectionDevices} · '
          '${text.profileDevicesCount(roster.count, DeviceRoster.maxDevices)}',
        ),
        SectionCard(
          children: [
            for (final device in state.devices)
              SettingRow(
                title: device.label,
                subtitle: device.isCurrent
                    ? text.profileDeviceCurrent
                    : text.profileDeviceLastSeen(
                        frenchDayMonth(device.lastActiveAt),
                      ),
                trailing: device.canBeForgotten
                    ? TextButton(
                        onPressed: () => _forget(context, ref, device),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                        child: Text(text.profileDeviceRemove),
                      )
                    : null,
              ),
          ],
        ),
        // Dire ce qu'il reste, ou ce qu'il faut libérer. Découvrir la limite
        // en pleine connexion sur un téléphone neuf serait la découvrir au
        // pire moment.
        SectionNote(
          roster.isFull
              ? text.profileDevicesFull
              : text.profileDevicesRoom(roster.freeSlots),
        ),
        const SizedBox(height: AppSpacing.xl),

        SectionCard(
          children: [
            SettingNavRow(
              title: text.settingsTitle,
              onTap: () => context.pushNamed(AppRoutes.settingsName),
            ),
            SettingNavRow(
              title: text.privacyTitle,
              onTap: () => context.pushNamed(AppRoutes.privacyName),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        SectionCard(
          children: [
            _SignOutRow(onTap: () => _confirmSignOut(context, ref)),
            _DestructiveRow(
              icon: Icons.delete_outline,
              label: text.profileDeleteAccount,
              onTap: () => _confirmErasure(context, ref, profile.phone),
            ),
          ],
        ),
      ],
    );
  }
}

/// Changer de numéro, depuis le profil.
///
/// Le code part sur le **nouveau** numéro : l'ancien a été prouvé le jour de
/// l'inscription, et le jeton atteste déjà du compte. Ce qu'il reste à
/// vérifier, c'est que celui qui demande tient bien la nouvelle ligne.
Future<void> _changePhone(
  BuildContext context,
  WidgetRef ref,
  PhoneNumber current,
) async {
  final text = AppText.of(context);

  final wanted = await askNewPhone(context: context, current: current);

  if (wanted == null || !context.mounted) return;

  final sent =
      await ref.read(authFlowViewModelProvider.notifier).startPhoneChange(wanted);

  if (!context.mounted) return;

  if (!sent) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text.profilePhoneChangeFailed)),
    );
    return;
  }

  context.pushNamed(AppRoutes.otpName);
}

/// Changer son code secret, depuis le profil.
///
/// Le serveur ne connaît qu'un chemin pour reposer une serrure, et il passe
/// par un SMS — le même que « code oublié ». Un pasteur connecté n'a donc pas
/// à se déconnecter pour changer son code, mais il doit toujours prouver
/// qu'il tient le numéro.
Future<void> _changeSecretCode(
  BuildContext context,
  WidgetRef ref,
  PhoneNumber phone,
) async {
  final text = AppText.of(context);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(text.profileSecretCodeChangeTitle),
      content: Text(text.profileSecretCodeChangeBody(phone.e164)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(text.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(text.profileSecretCodeChangeConfirm),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  final sent = await ref
      .read(authFlowViewModelProvider.notifier)
      .startSecretCodeChange(phone);

  if (!context.mounted) return;

  if (!sent) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text.profileSecretCodeChangeFailed)),
    );
    return;
  }

  // La porte est ouverte : la redirection laisse désormais passer les deux
  // écrans du parcours, et les refermera dès que le nouveau code sera posé.
  context.pushNamed(AppRoutes.otpName);
}

/// Rangée de déconnexion : couleur d'erreur, libellé sans ambiguïté.
class _SignOutRow extends StatelessWidget {
  const _SignOutRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _DestructiveRow(
        icon: Icons.logout,
        label: AppText.of(context).profileSignOut,
        onTap: onTap,
      );
}

/// Une action qui défait quelque chose : icône, couleur d'erreur, et rien
/// d'autre. Les deux du bas du profil se ressemblent parce qu'elles sont de
/// même nature — les distinguer par le chrome laisserait croire que l'une est
/// plus anodine.
class _DestructiveRow extends StatelessWidget {
  const _DestructiveRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: scheme.error),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: scheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Confirmation de suppression : elle dit ce qui part **et ce qui reste**.
///
/// Taire que le numéro demeure connu du service serait une seconde promesse
/// non tenue, juste après celle qu'on vient d'honorer.
Future<void> _confirmErasure(
  BuildContext context,
  WidgetRef ref,
  PhoneNumber phone,
) async {
  final text = AppText.of(context);
  final scheme = Theme.of(context).colorScheme;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(text.profileDeleteAccountTitle),
      content: Text(text.profileDeleteAccountBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(text.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: TextButton.styleFrom(foregroundColor: scheme.error),
          child: Text(text.profileDeleteAccountConfirm),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  // Ce bouton n'efface rien : il fait partir un SMS. Rien n'est détruit tant
  // que le code n'est pas saisi — c'est la seule opération irréversible du
  // profil, et la seule qui mérite deux gestes.
  final sent = await ref
      .read(authFlowViewModelProvider.notifier)
      .startAccountDeletion(phone);

  if (!context.mounted) return;

  if (!sent) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text.profileDeleteAccountFailed)),
    );
    return;
  }

  context.pushNamed(AppRoutes.otpName);
}

/// Confirmation : elle dit ce que la déconnexion **ne détruit pas**.
///
/// C'est la seule inquiétude réelle au moment de toucher ce bouton — perdre
/// son travail. Le dialogue y répond avant de la laisser naître.
Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
  final text = AppText.of(context);
  final scheme = Theme.of(context).colorScheme;
  var everywhere = false;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: Text(text.profileSignOutTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text.profileSignOutBody),
            const SizedBox(height: AppSpacing.sm),
            CheckboxListTile(
              value: everywhere,
              onChanged: (value) =>
                  setDialogState(() => everywhere = value ?? false),
              title: Text(text.profileSignOutEverywhere),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(text.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: scheme.error),
            child: Text(text.profileSignOutConfirm),
          ),
        ],
      ),
    ),
  );

  if (confirmed != true || !context.mounted) return;

  final failure = await ref
      .read(signOutViewModelProvider.notifier)
      .signOut(everywhere: everywhere);

  // La session locale est fermée quoi qu'il arrive : la redirection reprend la
  // main d'elle-même. Un échec serveur se dit, il ne retient personne.
  if (failure != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text.profileSignOutFailed)),
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
                profile.hasDisplayName
                    ? profile.displayName
                    : AppText.of(context).profileNoName,
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
              AppText.of(context).profileReadFailed,
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
              child: Text(AppText.of(context).retry),
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

String _messageFor(AppText text, Failure failure) => switch (failure) {
      // Le motif par champ vient du serveur ou du cas d'usage : il est déjà
      // rédigé pour être lu, et il en dit plus que la règle générale.
      ValidationFailure(:final fieldErrors) when fieldErrors.isNotEmpty =>
        fieldErrors.values.first,
      ValidationFailure() => text.profileChangeRefused,
      _ => text.profileChangeFailed,
    };
