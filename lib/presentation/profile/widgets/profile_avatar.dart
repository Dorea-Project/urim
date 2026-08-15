import 'package:flutter/material.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// Pastille d'identité : les initiales, ou une silhouette faute de nom.
///
/// Les initiales ne sont pas dessinées en Nova Cut : cette police porte la
/// marque, pas les personnes. Deux lettres de l'interface, à la place d'une
/// photo qu'Urim ne demande pas.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.initials, this.size = 64});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primary,
        shape: BoxShape.circle,
      ),
      child: initials.isEmpty
          ? Icon(
              Icons.person_outline,
              size: size / 2,
              color: scheme.onPrimary,
              semanticLabel: 'Aucun nom défini',
            )
          : Text(
              initials,
              // Deux lettres dans un cercle fixe : elles ne suivent pas
              // l'échelle système, sous peine de déborder.
              textScaler: TextScaler.noScaling,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: scheme.onPrimary,
                    fontSize: size / 2.6,
                    letterSpacing: 0.5,
                  ),
            ),
    );
  }
}

/// Bouton d'accès au profil, posé dans une barre d'application.
class ProfileAvatarButton extends StatelessWidget {
  const ProfileAvatarButton({
    super.key,
    required this.initials,
    required this.onPressed,
  });

  final String initials;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: IconButton(
        onPressed: onPressed,
        tooltip: 'Profil',
        icon: ProfileAvatar(initials: initials, size: 32),
      ),
    );
  }
}
