import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urim/core/config/app_config.dart';
import 'package:urim/core/config/app_config_provider.dart';
import 'package:urim/core/id/id_generator.dart';
import 'package:urim/core/id/id_generator_provider.dart';
import 'package:urim/core/router/app_routes.dart';
import 'package:urim/core/storage/shared_preferences_provider.dart';
import 'package:urim/core/time/clock.dart';
import 'package:urim/core/time/clock_provider.dart';
import 'package:urim/data/repositories/in_memory_preparation_repository.dart';
import 'package:urim/data/repositories/in_memory_transcription_repository.dart';
import 'package:urim/domain/entities/preparation/preparation.dart';
import 'package:urim/domain/entities/transcription/synthesis_draft.dart';
import 'package:urim/l10n/generated/app_text_fr.dart';
import 'package:urim/presentation/home/home_page.dart';

import '../support/pump_app.dart';
import 'package:urim/presentation/transcription/sermon_shell.dart';

final class _FixedClock implements Clock {
  const _FixedClock(this._now);
  final DateTime _now;

  @override
  DateTime now() => _now;
}

final class _SequentialIds implements IdGenerator {
  int _next = 0;

  @override
  String newId() => 'id-${_next++}';
}

/// Les libelles viennent de la meme source que l'ecran.
final texte = AppTextFr();

/// Un build qui vise le serveur : aucun jeu d'exemple ne doit lui repondre.
const serveurConfig = AppConfig(
  flavor: Flavor.dev,
  apiBaseUrl: 'http://serveur.test',
);

void main() {
  final fixedNow = DateTime(2026, 8, 15, 10);

  ProviderContainer makeContainer({bool demo = true}) =>
      ProviderContainer.test(
        overrides: [
          // Le jeu d'exemple ne repond que sous la demonstration : hors d'elle,
          // personne ne transcrit encore, et servir cette relecture ferait
          // porter « Hebreux 13 » a n'importe quelle predication reelle.
          demo
              ? demoConfigOverride
              : appConfigProvider.overrideWithValue(serveurConfig),
          clockProvider.overrideWithValue(_FixedClock(fixedNow)),
          idGeneratorProvider.overrideWithValue(_SequentialIds()),
        ],
      );

  /// Identifiant de la prédication transcrite du jeu d'exemple.
  Future<String> transcribedId(ProviderContainer container) async {
    final preparations = (await container
            .read(preparationRepositoryProvider)
            .watchPreparations()
            .first)
        .valueOrNull!;

    return preparations
        .firstWhere((p) => p.origin == PreparationOrigin.transcribed)
        .id;
  }

  group('relecture', () {
    test('hors demonstration, aucune relecture n\'est inventee', () async {
      // 🔴 **Le jeu d'exemple est fixe, et il portait le nom d'autrui.** La
      // meme relecture, les memes capsules, « Hebreux 13 — 9 aout », quelle que
      // soit la preparation ouverte. Tant que la demonstration etait le defaut,
      // la coincidence tenait : une seule preparation du jeu d'essai est
      // transcrite. Elle ne tient plus depuis que le build vise le serveur.
      //
      // Personne ne transcrit encore (D52, sprint 8). La reponse honnete est
      // l'absence — l'ecran dit « cette preparation n'a pas d'enregistrement
      // transcrit », ce qui est vrai — pas la predication d'un autre.
      final container = makeContainer(demo: false);
      final depot = container.read(transcriptionRepositoryProvider('nimporte'));

      expect((await depot.review()).valueOrNull, isNull);
      expect((await depot.synthesis()).valueOrNull, isNull);
      expect(
        (await depot.validate()).valueOrNull,
        isNull,
        reason: 'on ne valide pas une synthese qui n\'existe pas',
      );
    });

    test('les fragments non acquittés sont comptés, pas cachés', () async {
      final container = makeContainer();
      final id = await transcribedId(container);

      final review = (await container
              .read(transcriptionRepositoryProvider(id))
              .review())
          .valueOrNull!;

      expect(review.recording.fragmentCount, 57);
      expect(review.recording.fragmentsAcknowledged, 55);
      expect(review.recording.fragmentsPending, 2);
      expect(review.recording.isFullyAcknowledged, isFalse);
    });

    test('ce qui n\'était pas prévu est identifié comme tel', () async {
      final container = makeContainer();
      final id = await transcribedId(container);

      final review = (await container
              .read(transcriptionRepositoryProvider(id))
              .review())
          .valueOrNull!;

      expect(review.convoked, hasLength(2));
      expect(review.unplanned, hasLength(1));
      expect(review.unplanned.single.passage.referenceLabel, 'Hébreux 13:3');
    });
  });

  group('synthèse', () {
    test('rien n\'est lisible avant validation', () async {
      final container = makeContainer();
      final id = await transcribedId(container);
      final repository = container.read(transcriptionRepositoryProvider(id));

      final draft = (await repository.synthesis()).valueOrNull!;

      expect(draft.isValidated, isFalse);
      expect(draft.canBeReadAloud, isFalse);
      expect(draft.voices, hasLength(6));

      // ⚠️ **Le branchement se fait sur le code, jamais sur le libelle.**
      // « Français » est du texte d'ecran : il se reecrit, il se met en
      // minuscule. Le jour ou quelqu'un le retouche, le bouton doit continuer
      // de parler.
      expect(
        draft.voices.map((v) => v.code),
        containsAll(<String>['fr', 'en', 'own']),
      );

      // Ces langues sont des voix, jamais des ecrans : la seule qui ne demande
      // aucun modele est celle du predicateur lui-meme.
      expect(
        draft.voices.where((v) => v.kind == ReadAloudKind.translated).length,
        3,
      );
      expect(
        draft.voices.where((v) => v.kind == ReadAloudKind.ownVoice).length,
        1,
      );
    });

    test('valider ouvre la lecture, et ne se fait qu\'une fois', () async {
      final container = makeContainer();
      final id = await transcribedId(container);
      final repository = container.read(transcriptionRepositoryProvider(id));

      final validated = (await repository.validate()).valueOrNull!;

      expect(validated.isValidated, isTrue);
      expect(validated.canBeReadAloud, isTrue);
      expect((await repository.validate()).failureOrNull, isNotNull);
    });

    test('le verset validé reste celui de la Bible, capsules à part', () async {
      final container = makeContainer();
      final id = await transcribedId(container);

      final draft = (await container
              .read(transcriptionRepositoryProvider(id))
              .synthesis())
          .valueOrNull!;

      expect(draft.verse.text, 'Que l\'amour fraternel continue.');
      expect(draft.verse.translationLabel, 'LSG 1910');
      expect(draft.capsules, hasLength(2));
    });
  });

  group('écrans', () {
    Future<GoRouter> pumpTranscription(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final preferences = await SharedPreferences.getInstance();

      tester.view.physicalSize = const Size(1000, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final router = GoRouter(
        initialLocation: AppRoutes.homePath,
        routes: [
          GoRoute(
            path: AppRoutes.homePath,
            name: AppRoutes.homeName,
            builder: (context, state) => const HomePage(),
          ),
          // 🔴 **Le routeur du test suit la production, sinon il éprouve un
          // écran que personne n'atteint.** Depuis A3, les deux chemins mènent
          // à la même coque sur deux onglets différents — c'est ce que
          // `app_router.dart` fait, et c'est donc ce qu'on doit piloter ici.
          GoRoute(
            path: AppRoutes.transcriptionPath,
            name: AppRoutes.transcriptionName,
            builder: (context, state) => SermonShell(
              preparationId: state.pathParameters['id']!,
              initialTab: 0,
            ),
          ),
          GoRoute(
            path: AppRoutes.synthesisPath,
            name: AppRoutes.synthesisName,
            builder: (context, state) =>
                SermonShell(preparationId: state.pathParameters['id']!),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clockProvider.overrideWithValue(_FixedClock(fixedNow)),
            idGeneratorProvider.overrideWithValue(_SequentialIds()),
            sharedPreferencesProvider.overrideWithValue(preferences),
            demoConfigOverride,
          ],
          child: wrapRouter(router),
        ),
      );
      await tester.pumpAndSettle();

      // Les prédications ne sont plus dans le fil des préparations : elles ont
      // leur page, et l'icône du haut y mène — en demandant d'abord.
      await tester.tap(
        find.ancestor(
          of: find.byIcon(Icons.record_voice_over_outlined),
          matching: find.byType(IconButton),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(texte.homeSwitchPreach));
      await tester.pumpAndSettle();

      // Une prédication transcrite s'ouvre sur sa relecture.
      await tester.tap(find.text('Hébreux 13:1-6 — prêché le 9 août'));
      await tester.pumpAndSettle();

      return router;
    }

    testWidgets('la relecture rend ce qui a été mesuré', (tester) async {
      await pumpTranscription(tester);

      expect(find.text('Hébreux 13 — 9 août'), findsOneWidget);
      expect(find.text('41:07'), findsOneWidget);
      expect(
        find.textContaining(texte.transcriptionFragmentsAcknowledged(55)),
        findsOneWidget,
      );
      expect(
        find.textContaining(texte.transcriptionFragmentsPending(2)),
        findsOneWidget,
      );
      expect(find.textContaining(texte.transcriptionAudioDeletedOn('16 août')), findsOneWidget);
      expect(find.text('CONSTAT'), findsOneWidget);
      expect(find.text('ALIGNEMENT AU SQUELETTE'), findsOneWidget);
      expect(
        find.textContaining('je sais seulement que je ne l\'ai pas entendu'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Aucune séparation de locuteurs'),
        findsOneWidget,
      );
    });

    testWidgets('un texte non prévu est signalé comme tel', (tester) async {
      await pumpTranscription(tester);

      expect(
        find.text(texte.transcriptionPlanned('Hébreux 13:1')),
        findsOneWidget,
      );
      expect(find.text(texte.transcriptionUnplanned('Hébreux 13:3')), findsOneWidget);
    });

    testWidgets('la reprise d\'enregistrement est visible mais fermée',
        (tester) async {
      await pumpTranscription(tester);

      final button = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, texte.transcriptionResume),
      );

      expect(button.onPressed, isNull);
    });

    testWidgets('la synthèse du plan est éteinte, et l\'onglet dit pourquoi',
        (tester) async {
      // ⛔ **Deux tests vivaient ici, et ils gardaient l'inverse.** L'un
      // vérifiait que la synthèse s'affiche avec ses capsules et sa bannière
      // « rien n'est encore parti » ; l'autre que la signature ouvre les voix
      // de l'onglet d'à côté. Les deux décrivaient la synthèse **née de la
      // préparation** (D59).
      //
      // 🔴 **D72 l'a éteinte le 06/09.** Elle résumait une intention, pas un
      // sermon : lue à une assemblée ou interprétée en malinké, elle aurait
      // présenté un projet comme la parole prononcée. Celle qui la remplacera
      // naîtra du transcript d'une pièce, et attend la mesure.
      //
      // ⚠️ **L'onglet ne disparaît pas** (D13). Le pasteur l'a vu fonctionner
      // hier ; un onglet qui s'efface sans un mot ressemble à une panne, et la
      // vérité est une décision. C'est cette phrase que ce test garde.
      await pumpTranscription(tester);

      await tester.tap(find.text(texte.transcriptionSeeSynthesis));
      await tester.pumpAndSettle();

      expect(find.text(texte.synthesisFromPlanGone), findsOneWidget);
      expect(find.text(texte.synthesisSealTitleDraft), findsNothing);
      expect(find.textContaining('CAPSULE 1'), findsNothing);

      // La sortie pendait à cette synthèse ; elle pend maintenant à celle qui
      // n'existe pas encore, et elle le dit plutôt que d'offrir des voix qui
      // n'ont rien à lire.
      await tester.tap(find.text(texte.sermonTabOutput));
      await tester.pumpAndSettle();

      expect(find.text(texte.outputWaitsSynthesis), findsOneWidget);
      expect(find.text('Malinké'), findsNothing);
    });
  });
}
