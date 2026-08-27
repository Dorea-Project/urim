import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:urim/core/router/app_routes.dart';
import 'package:urim/data/repositories/study_repository_impl.dart';
import 'package:urim/domain/entities/preparation/preached.dart';
import 'package:urim/l10n/generated/app_text_fr.dart';
import 'package:urim/presentation/archive/archive_page.dart';

import '../support/pump_app.dart';
import '../support/tours_reels.dart';

/// L'archive du prédicateur — **des faits, aucune consigne**.
///
/// Ces tests tiennent les trois règles que le serveur pose dans son propre
/// contrat et qui se perdraient à l'écran : les deux nombres qui ne
/// s'additionnent pas, l'axe nul qui se nomme au lieu de disparaître, et la
/// phrase qui empêche « aucun sermon rangé ici » de devenir un reproche.
void main() {
  final texte = AppTextFr();

  Future<DepotFige> pumpArchive(
    WidgetTester tester, {
    List<PreachedSermon> archive = const [],
    PreachingCoverage couverture = const PreachingCoverage(
      books: [],
      axes: [],
      booksUntouched: 0,
    ),
  }) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final depot = DepotFige(ToursReels.etude(ToursReels.ouverture))
      ..archive = archive
      ..couverture = couverture;

    final router = GoRouter(
      initialLocation: AppRoutes.archivePath,
      routes: [
        GoRoute(
          path: AppRoutes.archivePath,
          name: AppRoutes.archiveName,
          builder: (context, state) => const ArchivePage(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          demoConfigOverride,
          studyRepositoryProvider.overrideWithValue(depot),
        ],
        child: wrapRouter(router),
      ),
    );
    await tester.pumpAndSettle();

    return depot;
  }

  testWidgets('rien de consigne dit quoi faire, pas juste « vide »',
      (tester) async {
    await pumpArchive(tester);

    expect(find.text(texte.archiveEmpty), findsOneWidget);
  });

  testWidgets('une predication porte son texte et sa date', (tester) async {
    await pumpArchive(
      tester,
      archive: [
        PreachedSermon(
          id: 'a',
          preachedOn: DateTime(2026, 8, 23),
          reference: 'Actes 1:1-14',
          pericopeLabel: 'Actes 1 — l\'ascension',
          axisCode: 'christologie',
        ),
      ],
    );

    expect(find.text('Actes 1 — l\'ascension'), findsOneWidget);
    expect(find.text('dim. 23 août'), findsOneWidget);
  });

  testWidgets('un axe nul se nomme, il ne disparait pas', (tester) async {
    // 🔴 Hors unite curee, il n'y a **aucun axe a retenir** — ce n'est pas un
    // trou. Masquer la ligne ferait croire a une archive incomplete.
    await pumpArchive(
      tester,
      archive: [
        PreachedSermon(
          id: 'a',
          preachedOn: DateTime(2026, 8, 23),
          reference: 'Psaume 125',
          axisCode: null,
        ),
      ],
    );

    expect(find.text('Psaume 125'), findsOneWidget);
    expect(find.text(texte.archiveUnfiled), findsOneWidget);
  });

  testWidgets('les deux nombres de la couverture ne se fondent pas',
      (tester) async {
    // ⚠️ **Jamais additionnes.** Trois lieux distincts, cinq assemblees qui ont
    // entendu : les fondre en « huit » perdrait les deux informations.
    await pumpArchive(
      tester,
      archive: [
        PreachedSermon(
          id: 'a',
          preachedOn: DateTime(2026, 8, 23),
          reference: 'Actes 1:1-14',
        ),
      ],
      couverture: PreachingCoverage(
        books: [
          BookCoverage(
            book: 'Actes',
            passages: 3,
            preachings: 5,
            lastPreachedOn: DateTime(2026, 8, 23),
          ),
        ],
        axes: const [],
        booksUntouched: 61,
      ),
    );

    expect(find.text(texte.coverageTitle), findsOneWidget);
    expect(find.textContaining(texte.coveragePassages(3)), findsOneWidget);
    expect(find.textContaining(texte.coveragePreachings(5)), findsOneWidget);
    expect(find.text(texte.coverageUntouched(61)), findsOneWidget);
  });

  testWidgets('l\'ecran dit ce que « non range » ne veut pas dire',
      (tester) async {
    // C'est la phrase qui empeche l'ecran de reprocher : un texte peut avoir
    // ete preche sous une autre unite, ou sans axe retenu.
    await pumpArchive(
      tester,
      archive: [
        PreachedSermon(
          id: 'a',
          preachedOn: DateTime(2026, 8, 23),
          reference: 'Actes 1:1-14',
        ),
      ],
    );

    expect(find.text(texte.coverageNotice), findsOneWidget);
  });
}
