import 'package:flutter/material.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// Intitulé d'une section : « LECTURE », « COMPTE », « APPAREILS ».
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xs,
        bottom: AppSpacing.md,
      ),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: context.colors.textSecondary,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

/// Carte qui groupe des lignes, séparées d'un filet.
///
/// Le filet ne court pas jusqu'aux bords : il commence à l'aplomb du texte,
/// ce qui rattache visuellement chaque séparation aux libellés plutôt qu'à la
/// carte.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.only(left: AppSpacing.lg),
                child: Divider(),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Commentaire sous une carte, en retrait — jamais porteur d'une information
/// que l'utilisateur devrait chercher : il explique, il ne prescrit pas.
class SectionNote extends StatelessWidget {
  const SectionNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.md,
        left: AppSpacing.xs,
        right: AppSpacing.xs,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
              height: 1.45,
            ),
      ),
    );
  }
}

/// Une ligne d'une [SectionCard] : un libellé, une explication, une commande.
class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.muted = false,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Réglage affiché mais sans effet : le titre s'efface, l'explication dit ce
  /// qu'il attend (D13).
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: muted ? colors.textSecondary : colors.textPrimary,
                  ),
                ),
                if (subtitle case final String subtitle) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing case final Widget trailing) ...[
            const SizedBox(width: AppSpacing.md),
            trailing,
          ],
        ],
      ),
    );

    if (onTap == null) return content;

    return InkWell(onTap: onTap, child: content);
  }
}

/// Ligne qui mène ailleurs : la valeur courante, puis un chevron.
class SettingNavRow extends StatelessWidget {
  const SettingNavRow({
    super.key,
    required this.title,
    this.subtitle,
    this.value,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SettingRow(
      title: title,
      subtitle: subtitle,
      muted: onTap == null,
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value case final String value)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                value,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
            ),
          const SizedBox(width: AppSpacing.sm),
          Icon(Icons.chevron_right, size: 20, color: colors.textSecondary),
        ],
      ),
    );
  }
}

/// Ligne portant un interrupteur. `onChanged` nul = réglage inactif (D13).
class SettingSwitchRow extends StatelessWidget {
  const SettingSwitchRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    // Le libellé de la ligne et l'interrupteur sont annoncés ensemble : seuls,
    // ni « Transcrire sur l'appareil » ni « activé » ne veulent dire
    // grand-chose.
    return MergeSemantics(
      child: SettingRow(
        title: title,
        subtitle: subtitle,
        muted: onChanged == null,
        onTap: onChanged == null ? null : () => onChanged!(!value),
        trailing: Switch(value: value, onChanged: onChanged),
      ),
    );
  }
}
