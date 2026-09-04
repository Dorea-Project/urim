import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urim/core/audio/capture_store.dart';
import 'package:urim/core/audio/piece_store.dart';
import 'package:urim/core/audio/fragment_outbox.dart';
import 'package:urim/core/audio/sermon_capture.dart';
import 'package:urim/core/time/clock.dart';
import 'package:urim/core/time/clock_provider.dart';
import 'package:urim/core/audio/track_player.dart';
import 'package:urim/core/speech/transcriber.dart';
import 'package:urim/core/speech/whisper_transcriber.dart';
import 'package:urim/data/datasources/fragment_remote_data_source.dart';
import 'package:urim/l10n/generated/app_text.dart';
import 'package:urim/presentation/transcription/capture_shell.dart';

import '../support/pump_app.dart';

/// Une capture s'ouvre — **et le cul-de-sac qu'elle n'est plus**.
///
/// 🔴 **Jusqu'au 29/08, sa carte était un `Container`.** Trois faits, aucun
/// geste : le seul objet du produit sur lequel on ne pouvait rien faire. La
/// retenue se défendait — *annoncer un transcript qui n'existe pas serait
/// mentir* — mais elle laissait le pasteur devant un objet mort.
///
/// Ces tests tiennent ce que l'écran dit **et surtout ce qu'il refuse de
/// promettre** : deux onglets sur trois sont fermés, et ils nomment leur motif.
void main() {
  final maintenant = DateTime(2026, 8, 29, 15, 0);

  late Directory racine;

  setUp(() => racine = Directory.systemTemp.createTempSync('urim_capture'));
  tearDown(() {
    if (racine.existsSync()) racine.deleteSync(recursive: true);
  });

  /// Pose une capture sur le disque, comme le micro l'aurait fait.
  String poser({
    required int fragments,
    required DateTime debut,
    String? eglise,
    bool propre = true,
    int accuses = 0,
  }) {
    const id = 'culte-1';
    final dossier = Directory(
      '${racine.path}/${CaptureStore.sousDossier}/'
      '${id}_${debut.millisecondsSinceEpoch}',
    )..createSync(recursive: true);

    for (var index = 0; index < fragments; index++) {
      File('${dossier.path}/${CaptureFormat.fragmentName(index)}')
          .writeAsBytesSync(List<int>.filled(CaptureFormat.fragmentBytes, 0));
    }
    if (propre) {
      File('${dossier.path}/${CaptureFormat.endMarker}').writeAsStringSync('');
    }
    if (eglise != null) {
      File('${dossier.path}/${CaptureFormat.churchMarker}')
          .writeAsStringSync(eglise);
    }
    if (accuses > 0) {
      File('${dossier.path}/${FragmentOutbox.marque}')
          .writeAsStringSync('$accuses');
    }
    return id;
  }

  Future<void> ouvrir(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          demoConfigOverride,
          clockProvider.overrideWithValue(_Fixe(maintenant)),
          captureStoreProvider
              .overrideWithValue(CaptureStore(directory: () async => racine)),
          trackPlayerProvider.overrideWithValue(_Muet()),
          // Le magasin des pièces passe par le dossier de l'application, un
          // greffon qui ne répond pas ici. Sans lui, l'onglet « sortie » reste
          // muet et le test lirait un écran vide sans savoir pourquoi.
          pieceStoreProvider
              .overrideWithValue(PieceStore(directory: () async => racine)),
          transcriberProvider.overrideWithValue(const _SansMoteur()),
          fragmentOutboxProvider.overrideWithValue(
            FragmentOutbox(
              sender: const _SansDestination(),
              directory: () async => racine,
            ),
          ),
        ],
        child: wrapScreen(const CaptureShell(captureId: 'culte-1')),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('elle montre ce qu\'on sait, faute de transcript', (tester) async {
    poser(fragments: 3, debut: maintenant.subtract(const Duration(hours: 2)),
        eglise: 'eglise-1', accuses: 3);

    await ouvrir(tester);
    final text = AppText.of(tester.element(find.byType(CaptureShell)));

    // Ce qui est réel se montre : la durée et les fragments.
    expect(find.text(text.captureFragments(3)), findsOneWidget);
    // Et l'audio dit quand il disparaît — sept jours moins les deux heures.
    expect(find.text(text.capturePurgeIn(6)), findsOneWidget);
  });

  testWidgets('la synthèse reste fermée, et dit pourquoi', (tester) async {
    poser(fragments: 2, debut: maintenant, eglise: 'eglise-1', accuses: 2);

    await ouvrir(tester);
    final text = AppText.of(tester.element(find.byType(CaptureShell)));

    // 🔴 D13 — un onglet absent ne se distingue pas d'un oubli. Et celui-ci
    // reste fermé pour de bon : la synthèse naît du transcript, qui attend la
    // mesure des quinze avis dans trois églises.
    await tester.tap(find.text(text.sermonTabSynthesis));
    await tester.pumpAndSettle();
    expect(find.text(text.captureSynthesisPending), findsOneWidget);
  });

  testWidgets('la sortie n\'attend plus rien : elle offre de tailler',
      (tester) async {
    // 🔴 **Ce test gardait l'inverse jusqu'au 06/09.** L'onglet disait « la
    // lecture à voix haute et l'interprétation partent d'une synthèse validée ;
    // elles attendent celle-ci ». D70 a renversé le tronc : la sortie d'un
    // culte, ce sont les pièces qu'on en taille, et elles ne demandent aucun
    // modèle ni aucune mesure.
    poser(fragments: 2, debut: maintenant, eglise: 'eglise-1', accuses: 2);

    await ouvrir(tester);
    final text = AppText.of(tester.element(find.byType(CaptureShell)));

    await tester.tap(find.text(text.sermonTabOutput));
    await tester.pumpAndSettle();

    expect(find.text(text.piecesCut), findsOneWidget);
    // ⚠️ La liste vide ne constate pas le vide : elle dit l'enjeu du délai.
    // Un pasteur qui ignore que la matière expire ne découpera pas à temps.
    expect(find.text(text.piecesEmpty), findsOneWidget);
  });

  testWidgets('l\'écran ne promet plus aucun départ', (tester) async {
    // ⛔ **Deux tests vivaient ici, et ils gardaient l'inverse.** L'un vérifiait
    // que le compteur « 3 fragments attendent de partir » s'affiche, l'autre
    // qu'une capture sans assemblée annonce qu'elle ne partira jamais.
    //
    // 🔴 **D71 a coupé la montée automatique** : le port `FragmentStore` n'a
    // que `put` et `purge`, rien ne lit jamais les fragments montés, et on ne
    // transcrit plus la matière brute. Ces trois phrases sont donc devenues
    // fausses — et une phrase fausse sur le sort d'un culte est pire qu'une
    // phrase absente. C'est cette absence que ce test garde.
    poser(fragments: 5, debut: maintenant, eglise: 'eglise-1', accuses: 2);

    await ouvrir(tester);
    final text = AppText.of(tester.element(find.byType(CaptureShell)));

    expect(find.text(text.captureUploadPending(3)), findsNothing);
    expect(find.text(text.captureUploadAllSent), findsNothing);
    expect(find.text(text.captureUploadNoChurch), findsNothing);

    // Ce qui reste dit est vrai, et suffit : l'audio est ici, et il expire.
    expect(find.text(text.captureLocalOnly), findsOneWidget);
    expect(find.text(text.capturePurgeIn(7)), findsOneWidget);
  });

  testWidgets('une capture sans assemblée n\'annonce plus rien de faux',
      (tester) async {
    // ⚠️ **Le témoin d'église reste écrit** (D68) : dix pasteurs desservent
    // sept assemblées, et un culte rangé sous la mauvaise fausserait la mesure.
    // Ce qu'il débloquait a changé ; ce qu'il atteste, non. Mais l'écran ne dit
    // plus « sans elle, elle ne peut pas partir » — plus rien ne part.
    poser(fragments: 4, debut: maintenant, eglise: null);

    await ouvrir(tester);
    final text = AppText.of(tester.element(find.byType(CaptureShell)));

    expect(find.text(text.captureUploadNoChurch), findsNothing);
    expect(find.text(text.captureFragments(4)), findsOneWidget);
  });

  testWidgets('un enregistrement interrompu se signale sans alarmer',
      (tester) async {
    // L'absence du témoin d'arrêt dit que l'application est morte en route. La
    // capture **apparaît quand même** : la faire disparaître serait le pire des
    // silences, le pasteur croyait avoir enregistré.
    poser(fragments: 2, debut: maintenant, eglise: 'eglise-1', propre: false);

    await ouvrir(tester);
    final text = AppText.of(tester.element(find.byType(CaptureShell)));

    expect(find.text(text.captureInterrupted), findsOneWidget);
  });

  testWidgets('elle dit qu\'elle ne suit pas l\'appareil', (tester) async {
    // La promesse à formuler **avant** le premier pilote : c'est le premier
    // objet d'Urim qui ne se synchronise pas.
    poser(fragments: 1, debut: maintenant, eglise: 'eglise-1', accuses: 1);

    await ouvrir(tester);
    final text = AppText.of(tester.element(find.byType(CaptureShell)));

    expect(find.text(text.captureLocalOnly), findsOneWidget);
  });

  group('nommer son culte', () {
    test("une date n'est pas un nom — on peut en poser un", () async {
      // 🔴 Au bout de quatre dimanches, « dim. 6 septembre » ne dit plus rien
      // de ce qui a été prêché.
      poser(fragments: 1, debut: maintenant, eglise: 'e1');
      final magasin = CaptureStore(directory: () async => racine);

      expect(await magasin.nommer('culte-1', 'Nouvelle naissance'), isTrue);
      expect((await magasin.list()).single.title, 'Nouvelle naissance');
    });

    test("il se renomme autant qu'on veut", () async {
      // Contrairement à l'assemblée : un titre ne décide de rien, et le figer
      // coûterait la faute de frappe qu'on ne peut plus corriger.
      poser(fragments: 1, debut: maintenant, eglise: 'e1');
      final magasin = CaptureStore(directory: () async => racine);

      await magasin.nommer('culte-1', 'Premier');
      await magasin.nommer('culte-1', 'Second');

      expect((await magasin.list()).single.title, 'Second');
    });

    test("vider le champ retire le nom, il n'en pose pas un vide", () async {
      // Une chaîne vide ferait un titre invisible qu'on croirait écrit.
      poser(fragments: 1, debut: maintenant, eglise: 'e1');
      final magasin = CaptureStore(directory: () async => racine);

      await magasin.nommer('culte-1', 'Un nom');
      await magasin.nommer('culte-1', '   ');

      expect((await magasin.list()).single.title, isNull);
    });

    test('le nom ne se compte pas comme un fragment', () async {
      // `CaptureStore` déduit la durée des octets des `.pcm`. Compter le titre
      // rallongerait le culte d'une durée inventée.
      poser(fragments: 2, debut: maintenant, eglise: 'e1');
      final magasin = CaptureStore(directory: () async => racine);

      final avant = (await magasin.list()).single.duration;
      await magasin.nommer('culte-1', 'Actes 2, matin');

      expect((await magasin.list()).single.duration, avant);
      expect((await magasin.list()).single.fragments, 2);
    });

    test("nommer une capture qui n'existe pas ne fabrique rien", () async {
      final magasin = CaptureStore(directory: () async => racine);

      expect(await magasin.nommer('fantome', 'Un nom'), isFalse);
    });
  });
}

/// Aucun moteur : le modèle n'est pas là, et l'écran doit le dire.
final class _SansMoteur implements Transcriber {
  const _SansMoteur();
  @override
  Future<bool> estPret(TranscriptionModel model) async => false;
  @override
  Future<TranscriptionRefusal?> preparer(TranscriptionModel model,
          {void Function(ModelProgress)? avancement}) async =>
      TranscriptionRefusal.modelDownloadFailed;
  @override
  Future<TranscriptionOutcome> transcrire({
    required String cheminWav,
    required int index,
    required TranscriptionModel model,
  }) async =>
      const TranscriptionRefused(TranscriptionRefusal.modelMissing);
  @override
  Future<void> liberer() async {}
}

final class _Muet implements TrackPlayer {
  /// Les positions demandées — un saut se vérifie, il ne se suppose pas.
  final List<Duration> vues = [];

  _Muet();
  @override
  Future<PlaybackRefusal?> play(String path) async => null;
  @override
  Future<void> stop() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> resume() async {}
  @override
  Stream<void> get onComplete => const Stream<void>.empty();
  @override
  Stream<Duration> get onPosition => const Stream<Duration>.empty();
  @override
  Stream<Duration> get onDuration => const Stream<Duration>.empty();

  @override
  Future<void> seek(Duration position) async => vues.add(position);
}

final class _Fixe implements Clock {
  const _Fixe(this._instant);
  final DateTime _instant;
  @override
  DateTime now() => _instant;
}

final class _SansDestination implements FragmentSender {
  const _SansDestination();

  @override
  Future<SendOutcome> send({
    required String captureId,
    required int index,
    required List<int> bytes,
    required DateTime startedAt,
    required String churchId,
  }) async =>
      SendOutcome.retryLater;
}
