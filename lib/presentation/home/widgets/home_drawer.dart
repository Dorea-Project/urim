import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:urim/core/audio/sermon_capture.dart';
import 'package:urim/core/router/app_routes.dart';
import 'package:urim/core/text/french_dates.dart';
import 'package:urim/domain/entities/preparation/study_summary.dart';
import 'package:urim/l10n/generated/app_text.dart';
import 'package:urim/presentation/bible/search_page.dart';
import 'package:urim/presentation/common/domain_labels.dart';
import 'package:urim/presentation/home/opening_rule.dart';
import 'package:urim/presentation/home/widgets/capture_bar.dart';
import 'package:urim/presentation/theme/app_colors.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// Le tiroir : l'historique **du travail en cours**, et le reste de
/// l'application.
///
/// ⚠️ **Il suit l'écran.** Sur la préparation il porte les préparations et
/// ouvre un travail neuf ; sur les prédications il porte les prédications et
/// lance un enregistrement. Un tiroir qui montrerait les deux mêlés annulerait
/// la séparation qu'on vient de faire — et un tiroir figé sur un seul des deux
/// obligerait à basculer pour retrouver ce qu'on cherche.
///
/// Ce qui ne change pas d'un côté à l'autre est en bas : chercher, les projets,
/// les réglages, le profil. **Ce qu'on consulte de temps en temps se range ; ce
/// qu'on fait tous les jours reste sous les doigts.**
class HomeDrawer extends StatelessWidget {
  const HomeDrawer({
    super.key,
    required this.tab,
    required this.preparations,
    required this.preached,
    required this.captures,
    required this.currentId,
    required this.onNewPreparation,
    required this.onOpenPreparation,
    required this.onRecord,
    required this.onOpenPreached,
    required this.recording,
  });

  final HomeTab tab;

  /// Les préparations, déjà triées par l'accueil.
  final List<StudySummary> preparations;

  /// Les prédications déjà transcrites, servies par le fil.
  final List<StudySummary> preached;

  /// Les captures posées sur l'appareil, pas encore transcrites.
  final List<CapturedSermon> captures;

  /// La conversation qu'on est en train de lire, s'il y en a une.
  final String? currentId;

  final VoidCallback onNewPreparation;
  final void Function(String id) onOpenPreparation;
  final VoidCallback onRecord;
  final void Function(String id) onOpenPreached;

  /// Un enregistrement tourne : la première entrée devient l'arrêt.
  final bool recording;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final text = AppText.of(context);

    final prepare = tab == HomeTab.prepare;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Text('Urim', style: theme.textTheme.headlineSmall),
            ),

            // Le geste neuf du travail en cours, et lui seul : ouvrir une
            // préparation d'un côté, ouvrir le micro de l'autre.
            if (prepare)
              ListTile(
                leading: const Icon(Icons.add),
                title: Text(text.drawerNewPreparation),
                onTap: () {
                  Navigator.of(context).pop();
                  onNewPreparation();
                },
              )
            else
              ListTile(
                leading: Icon(
                  recording ? Icons.stop : Icons.fiber_manual_record,
                  color: theme.colorScheme.error,
                ),
                title: Text(
                  recording ? text.homeRecordStop : text.homeRecordSermon,
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  onRecord();
                },
              ),

            // ⚠️ **La loupe a quitté la barre du haut.** L'accueil est devenu la
            // conversation : sa barre porte ce qui agit dessus, et chercher dans
            // le corpus n'agit sur rien — c'est une consultation.
            ListTile(
              leading: const Icon(Icons.search),
              title: Text(text.searchTitle),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SearchPage()),
                );
              },
            ),
            const Divider(height: AppSpacing.lg),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Text(
                prepare ? text.drawerPreparations : text.drawerPreached,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            Expanded(
              child: prepare
                  ? _Historique(
                      vide: text.drawerEmpty,
                      lignes: [
                        for (final summary in preparations)
                          _Ligne(
                            titre: summary.rawInput,
                            // Ce qui attend une réponse le dit ici aussi : le
                            // tiroir sert à retrouver ce qu'on a laissé en plan.
                            note: summary.lastOutcome?.waitsForUser ?? false
                                ? turnOutcomeLabel(text, summary.lastOutcome!)
                                : null,
                            courante: summary.id == currentId,
                            onTap: () => onOpenPreparation(summary.id),
                          ),
                      ],
                    )
                  : _Historique(
                      vide: text.drawerEmptyPreached,
                      lignes: [
                        // Les captures d'abord : c'est le culte de ce matin, et
                        // rien ne l'a encore transcrit.
                        for (final capture in captures)
                          _Ligne(
                            titre: frenchShortDate(capture.startedAt),
                            note:
                                '${formatElapsed(capture.duration)} · ${text.homeCaptureNotSent}',
                            // Aucun écran ne la lit encore : la rendre touchable
                            // promettrait une relecture qui n'existe pas.
                            onTap: null,
                          ),
                        for (final summary in preached)
                          _Ligne(
                            titre: summary.rawInput,
                            onTap: () => onOpenPreached(summary.id),
                          ),
                      ],
                    ),
            ),

            const Divider(height: 1),
            // Inactive, et qui dit ce qu'elle attend plutôt que de manquer
            // (D13) : une entrée absente ne se distingue pas d'un oubli.
            ListTile(
              enabled: false,
              leading: const Icon(Icons.workspaces_outlined),
              title: Text(text.drawerProjects),
              trailing: Text(
                text.drawerProjectsPending,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
            // Ce qui a été prêché vit à part du fil : c'est un registre, pas un
            // travail en cours. Il se consulte, il ne se reprend pas.
            ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: Text(text.archiveTitle),
              onTap: () {
                Navigator.of(context).pop();
                context.pushNamed(AppRoutes.archiveName);
              },
            ),
            ListTile(
              leading: const Icon(Icons.tune),
              title: Text(text.settingsTitle),
              onTap: () {
                Navigator.of(context).pop();
                context.pushNamed(AppRoutes.settingsName);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(text.profileTitle),
              onTap: () {
                Navigator.of(context).pop();
                context.pushNamed(AppRoutes.profileName);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

/// Une ligne d'historique, quel que soit le travail.
final class _Ligne {
  const _Ligne({
    required this.titre,
    this.note,
    this.courante = false,
    this.onTap,
  });

  final String titre;
  final String? note;
  final bool courante;
  final VoidCallback? onTap;
}

class _Historique extends StatelessWidget {
  const _Historique({required this.lignes, required this.vide});

  final List<_Ligne> lignes;
  final String vide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    if (lignes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Text(
          vide,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.textSecondary,
            height: 1.5,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: lignes.length,
      itemBuilder: (_, index) {
        final ligne = lignes[index];

        return ListTile(
          // Une conversation est une ligne, pas une carte : la hauteur par
          // défaut faisait tenir cinq travaux là où il en passe neuf.
          dense: true,
          visualDensity: VisualDensity.compact,
          selected: ligne.courante,
          enabled: ligne.onTap != null,
          title: Text(
            ligne.titre,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: ligne.note == null
              ? null
              : Text(
                  ligne.note!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ligne.courante || ligne.onTap == null
                        ? colors.textSecondary
                        : theme.colorScheme.primary,
                    fontWeight: ligne.onTap == null
                        ? FontWeight.w400
                        : FontWeight.w600,
                  ),
                ),
          onTap: ligne.onTap == null
              ? null
              : () {
                  Navigator.of(context).pop();
                  ligne.onTap!();
                },
        );
      },
    );
  }
}
