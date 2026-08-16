import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'package:urim/presentation/transcription/synthesis_page.dart';
import 'package:urim/presentation/transcription/transcription_page.dart';

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

void main() {
  final fixedNow = DateTime(2026, 8, 15, 10);

  ProviderContainer makeContainer() => ProviderContainer.test(
        overrides: [
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
      expect(draft.voices, hasLength(5));

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
          GoRoute(
            path: AppRoutes.transcriptionPath,
            name: AppRoutes.transcriptionName,
            builder: (context, state) =>
                TranscriptionPage(preparationId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: AppRoutes.synthesisPath,
            name: AppRoutes.synthesisName,
            builder: (context, state) =>
                SynthesisPage(preparationId: state.pathParameters['id']!),
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
          ],
          child: wrapRouter(router),
        ),
      );
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

    testWidgets('la synthèse annonce que rien n\'est parti', (tester) async {
      await pumpTranscription(tester);

      await tester.tap(find.text(texte.transcriptionSeeSynthesis));
      await tester.pumpAndSettle();

      expect(find.text(texte.synthesisTitleDraft), findsOneWidget);
      expect(find.text(texte.synthesisSealTitleDraft), findsOneWidget);
      expect(
        find.textContaining('Aucun membre ne la voit'),
        findsOneWidget,
      );
      expect(find.text(texte.synthesisReadAloudLocked),
          findsOneWidget);
      expect(find.textContaining('CAPSULE 1'), findsOneWidget);
      expect(find.text(texte.synthesisSectionVerse.toUpperCase()), findsOneWidget);
      expect(find.text('Dioula'), findsOneWidget);
      expect(find.text('Ta propre voix'), findsOneWidget);
    });

    testWidgets('valider change ce que l\'écran promet', (tester) async {
      await pumpTranscription(tester);

      await tester.tap(find.text(texte.transcriptionSeeSynthesis));
      await tester.pumpAndSettle();

      await tester.tap(find.text(texte.synthesisValidate));
      await tester.pumpAndSettle();

      expect(find.text(texte.synthesisTitleValidated), findsOneWidget);
      expect(find.text(texte.synthesisSealTitleValidated), findsOneWidget);
      expect(find.text(texte.synthesisSealTitleDraft), findsNothing);
      expect(
        find.text(texte.synthesisReadAloudLocked),
        findsNothing,
      );

      // Même validée, aucune voix ne lit encore : ni la synthèse vocale ni les
      // traductions n'existent (Q3).
      final play = tester.widget<Tooltip>(
        find.ancestor(
          of: find.byIcon(Icons.play_arrow).first,
          matching: find.byType(Tooltip),
        ),
      );
      expect(play.message, texte.synthesisVoiceComing);
    });
  });
}
