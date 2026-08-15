import 'package:flutter/material.dart';
import 'package:urim/domain/entities/pastoral/pastoral_question.dart';
import 'package:urim/domain/entities/pastoral/scripture_anchor.dart';
import 'package:urim/presentation/theme/app_colors.dart';

/// Traduction visuelle des états du domaine.
///
/// Chaque état porte **une couleur et une icône**. Jamais la couleur seule :
/// les nuances de la charte se ressemblent trop pour être discriminées d'un
/// coup d'œil, et une part des lecteurs ne les distingue pas du tout.
///
/// Les libellés sont ici en français littéral, en attendant la décision sur
/// la localisation. Le jour où `flutter_localizations` entre dans le projet,
/// c'est le seul fichier de la couche thème à reprendre.
extension DiscernmentStatusVisual on DiscernmentStatus {
  Color color(AppColors colors) => switch (this) {
        DiscernmentStatus.open => colors.statusPending,
        DiscernmentStatus.discerning => colors.statusActive,
        DiscernmentStatus.decided => colors.statusSettled,
        DiscernmentStatus.suspended => colors.statusPaused,
        DiscernmentStatus.abandoned => colors.statusDropped,
      };

  IconData get icon => switch (this) {
        DiscernmentStatus.open => Icons.help_outline,
        DiscernmentStatus.discerning => Icons.explore_outlined,
        DiscernmentStatus.decided => Icons.check_circle_outline,
        DiscernmentStatus.suspended => Icons.pause_circle_outline,
        DiscernmentStatus.abandoned => Icons.remove_circle_outline,
      };

  String get label => switch (this) {
        DiscernmentStatus.open => 'Ouverte',
        DiscernmentStatus.discerning => 'En discernement',
        DiscernmentStatus.decided => 'Décidée',
        DiscernmentStatus.suspended => 'En attente',
        DiscernmentStatus.abandoned => 'Abandonnée',
      };
}

/// Manière dont un passage pèse sur une question.
///
/// La distinction se joue sur la forme autant que sur la couleur : la flèche
/// oriente, le point d'interrogation met en question, le rond informe.
extension AnchorWeightVisual on AnchorWeight {
  Color color(AppColors colors) => switch (this) {
        AnchorWeight.supports => colors.anchorSupports,
        AnchorWeight.challenges => colors.anchorChallenges,
        AnchorWeight.informs => colors.anchorInforms,
      };

  IconData get icon => switch (this) {
        AnchorWeight.supports => Icons.trending_up,
        AnchorWeight.challenges => Icons.report_problem_outlined,
        AnchorWeight.informs => Icons.info_outline,
      };

  String get label => switch (this) {
        AnchorWeight.supports => 'Oriente',
        AnchorWeight.challenges => 'Met en question',
        AnchorWeight.informs => 'Éclaire',
      };
}
