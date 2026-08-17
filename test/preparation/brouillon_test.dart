import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/core/result/result.dart';
import 'package:urim/core/storage/local_documents.dart';
import 'package:urim/core/storage/shared_preferences_provider.dart';
import 'package:urim/core/time/clock.dart';
import 'package:urim/core/time/clock_provider.dart';
import 'package:urim/data/datasources/draft_local_data_source.dart';
import 'package:urim/data/repositories/study_repository_impl.dart';
import 'package:urim/domain/entities/preparation/study.dart';
import 'package:urim/domain/repositories/study_repository.dart';
import 'package:urim/presentation/common/draft_keeper.dart';
import 'package:urim/presentation/preparation/preparation_page.dart';
import '../support/fake_documents.dart';
import '../support/pump_app.dart';
import '../support/tours_reels.dart';

/// La seule faute que cet outil n'a pas le droit de commettre est de perdre
/// les phrases d'un homme. Ces tests gardent cette regle-la.
///
/// Ils sont ecrits autour de l'**echec**, pas du succes : quand tout marche,
/// un brouillon ne sert a rien. Il sert quand le reseau tombe, quand un appel
/// arrive, quand le systeme referme l'application.

final class _FixedClock implements Clock {
  const _FixedClock(this._now);
  final DateTime _now;

  @override
  DateTime now() => _now;
}

/// Refuse tout : c'est le seul etat ou un brouillon a un role.
base class _DepotQuiRefuse extends DepotFige {
  _DepotQuiRefuse(super.etude);

  @override
  Future<Result<Study>> say({
    required String studyId,
    required String rawInput,
  }) async {
    paroles.add(rawInput);
    return const Result.failed(
      NetworkFailure(message: 'Pas de reseau.', code: 'offline'),
    );
  }
}

void main() {
  final maintenant = DateTime(2026, 8, 17, 21, 14);

  group('le magasin de brouillons', () {
    late FakeDocuments documents;
    late DraftLocalDataSource source;

    setUp(() {
      documents = FakeDocuments();
      source = DraftLocalDataSource(
        documents: documents,
        clock: _FixedClock(maintenant),
      );
    });

    test('ce qui est ecrit se relit, avec son heure', () async {
      await source.write('brouillon/saisie/x', 'Je garde la pericope entiere.');

      final garde = await source.read('brouillon/saisie/x');

      expect(garde!.text, 'Je garde la pericope entiere.');
      expect(garde.at, maintenant);
    });

    test('un texte vide efface plutot que d\'enregistrer du vide', () async {
      await source.write('brouillon/saisie/x', 'quelque chose');
      await source.write('brouillon/saisie/x', '   ');

      expect(await source.read('brouillon/saisie/x'), isNull);
    });

    test('un brouillon illisible vaut un brouillon absent', () async {
      // Une coupure en pleine ecriture, un fichier tronque : l'ecran doit
      // s'ouvrir quand meme. On perd ce brouillon, pas l'outil.
      documents.contenu['brouillon/saisie/x'] = '{ceci n\'est pas du json';

      expect(await source.read('brouillon/saisie/x'), isNull);
    });

    test('le balayage epargne ce qui est recent et large', () async {
      final vieux = DraftLocalDataSource(
        documents: documents,
        clock: _FixedClock(maintenant.subtract(const Duration(days: 100))),
      );
      await vieux.write('brouillon/saisie/oublie', 'il y a trois mois');
      await source.write('brouillon/saisie/frais', 'la semaine derniere');

      await source.sweep();

      expect(await source.read('brouillon/saisie/oublie'), isNull);
      expect(await source.read('brouillon/saisie/frais'), isNotNull);
    });

    test('le balayage ne touche pas ce qui n\'est pas un brouillon', () async {
      documents.contenu['session/jeton'] = 'pas a moi';

      await source.sweep();

      expect(documents.contenu, contains('session/jeton'));
    });
  });

  group('la garde du brouillon', () {
    test('un champ detruit ecrit avant de disparaitre', () async {
      // C'est **la** regle. Un minuteur en attente ne survit pas a la
      // destruction de son ecran : sans cette ligne, les 350 dernieres
      // millisecondes de frappe sont perdues a chaque fois.
      final documents = FakeDocuments();
      final garde = DraftKeeper(
        source: DraftLocalDataSource(
          documents: documents,
          clock: _FixedClock(maintenant),
        ),
        key: 'brouillon/saisie/x',
        delay: const Duration(seconds: 30),
      );

      garde.remember('une phrase jamais envoyee');
      garde.dispose();
      await Future<void>.delayed(Duration.zero);

      expect(documents.contenu['brouillon/saisie/x'], contains('jamais'));
    });

    test('oublier annule ce qui etait en attente', () async {
      final documents = FakeDocuments();
      final garde = DraftKeeper(
        source: DraftLocalDataSource(
          documents: documents,
          clock: _FixedClock(maintenant),
        ),
        key: 'brouillon/saisie/x',
        delay: const Duration(seconds: 30),
      );

      garde.remember('deja parti au serveur');
      garde.forget();
      await Future<void>.delayed(Duration.zero);
      garde.dispose();
      await Future<void>.delayed(Duration.zero);

      expect(documents.contenu, isEmpty,
          reason: 'un brouillon accuse ne doit pas se reecrire apres coup');
    });
  });

  group('l\'ecran', () {
    Future<FakeDocuments> pumpFil(
      WidgetTester tester, {
      required StudyRepository Function() depot,
      Map<String, String> deja = const {},
    }) async {
      final documents = FakeDocuments()..contenu.addAll(deja);

      SharedPreferences.setMockInitialValues(<String, Object>{});
      final preferences = await SharedPreferences.getInstance();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
            demoConfigOverride,
            clockProvider.overrideWithValue(_FixedClock(maintenant)),
            localDocumentsProvider.overrideWithValue(documents),
            studyRepositoryProvider.overrideWithValue(depot()),
          ],
          child: wrapScreen(const PreparationPage(preparationId: 'etude-1')),
        ),
      );
      await tester.pumpAndSettle();

      return documents;
    }

    testWidgets('la frappe est posee sur l\'appareil sans qu\'on l\'envoie',
        (tester) async {
      final documents = await pumpFil(
        tester,
        depot: () => DepotFige(ToursReels.etude(ToursReels.ouverture)),
      );

      await tester.enterText(find.byType(TextField), 'Je pense a Actes 2.');
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        documents.contenu[DraftLocalDataSource.composerKey('etude-1')],
        contains('Actes 2'),
      );
    });

    testWidgets('un envoi qui echoue garde la phrase', (tester) async {
      // Le cas qui justifie tout le reste. Le pasteur voit son texte, le
      // serveur ne l'a pas, et l'appareil est la seule copie qui existe.
      final documents = await pumpFil(
        tester,
        depot: () => _DepotQuiRefuse(ToursReels.etude(ToursReels.ouverture)),
      );

      await tester.enterText(find.byType(TextField), 'Ma phrase a moi.');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byIcon(Icons.arrow_upward));
      await tester.pumpAndSettle();

      expect(
        documents.contenu[DraftLocalDataSource.composerKey('etude-1')],
        contains('Ma phrase a moi.'),
      );
      // Et elle est encore dans le champ : rien n'a ete efface par optimisme.
      expect(find.text('Ma phrase a moi.'), findsOneWidget);
    });

    testWidgets('un envoi accepte efface la copie locale', (tester) async {
      final documents = await pumpFil(
        tester,
        depot: () => DepotFige(ToursReels.etude(ToursReels.ouverture)),
      );

      await tester.enterText(find.byType(TextField), 'Envoyee, celle-la.');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byIcon(Icons.arrow_upward));
      await tester.pumpAndSettle();

      expect(
        documents.contenu,
        isNot(contains(DraftLocalDataSource.composerKey('etude-1'))),
        reason: 'garder une copie accusee ferait reapparaitre un doublon',
      );
    });

    testWidgets('en revenant, la phrase jamais envoyee est dans le champ',
        (tester) async {
      await pumpFil(
        tester,
        depot: () => DepotFige(ToursReels.etude(ToursReels.ouverture)),
        deja: {
          DraftLocalDataSource.composerKey('etude-1'):
              '{"text":"Ce que j\'ecrivais hier soir.",'
                  '"at":"2026-08-16T21:14:00.000"}',
        },
      );

      expect(find.text('Ce que j\'ecrivais hier soir.'), findsOneWidget);
    });
  });
}
