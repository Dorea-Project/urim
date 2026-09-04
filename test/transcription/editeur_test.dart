import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urim/core/audio/capture_playback.dart';
import 'package:urim/core/audio/piece_cutter.dart';
import 'package:urim/core/audio/sermon_capture.dart';
import 'package:urim/core/audio/track_player.dart';
import 'package:urim/core/audio/waveform.dart';
import 'package:urim/l10n/generated/app_text.dart';
import 'package:urim/presentation/theme/app_theme.dart';
import 'package:urim/presentation/transcription/piece_editor_page.dart';
import 'package:urim/presentation/transcription/piece_editor_view_model.dart';
import 'package:urim/presentation/home/capture_view_model.dart';

/// L'éditeur, éprouvé sur une vraie capture posée sur le disque.
///
/// 🔴 **Ce que ces tests gardent n'est pas l'apparence, c'est le geste.** Un
/// éditeur audio se juge sur trois choses : qu'on ne puisse pas tailler une
/// pièce vide, que poser une borne la pose là où l'oreille est, et que rien de
/// tout cela ne détruise la matière. Le reste est du dessin.
void main() {
  late Directory racine;
  late Directory culte;

  setUp(() {
    racine = Directory.systemTemp.createTempSync('urim_editeur');
    culte = Directory('${racine.path}/captures/c_0')
      ..createSync(recursive: true);

    // Six secondes de son, en fragments d'une seconde.
    for (var i = 0; i < 6; i++) {
      File('${culte.path}/${CaptureFormat.fragmentName(i)}').writeAsBytesSync(
        Uint8List(CaptureFormat.bytesPerSecond)
          ..fillRange(0, CaptureFormat.bytesPerSecond, 40),
      );
    }
  });

  tearDown(() {
    // L'isolat qui calcule l'onde peut tenir un fragment une poignée de
    // millisecondes après la fin du test. Un dossier temporaire qui résiste
    // n'est pas un échec — le système le balaiera.
    try {
      if (racine.existsSync()) racine.deleteSync(recursive: true);
    } on FileSystemException {
      // rien à faire, et rien à dire
    }
  });

  Future<ProviderContainer> poser(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Le lecteur est un greffon : il ne répond pas hors d'un appareil.
          trackPlayerProvider.overrideWithValue(_LecteurMuet()),
          // L'onde se calcule dans un isolat, et un isolat ne répond pas sous
          // `flutter_test`. On donne l'onde déjà faite : ce qu'on éprouve ici
          // est le geste de l'éditeur, pas le calcul — celui-ci a ses propres
          // tests, dans `onde_test.dart`.
          waveformDigestProvider.overrideWithValue(
            _OndeToutePrete(const Duration(seconds: 6)),
          ),
          // Assembler le culte écrit des mégaoctets ; l'horloge factice d'un
          // test de widget ne pompe jamais la fin d'une écriture disque.
          capturePlaybackProvider
              .overrideWithValue(const _JouableToutPret()),
          // Le tailleur écrit dans le dossier de l'application, qui n'existe
          // pas non plus ici.
          pieceCutterProvider.overrideWithValue(
            PieceCutter(directory: () async => racine),
          ),
          localCapturesProvider.overrideWith(
            (ref) async => [
              CapturedSermon(
                id: 'c',
                startedAt: DateTime(2026, 9, 6),
                duration: const Duration(seconds: 6),
                path: culte.path,
                fragments: 6,
              ),
            ],
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppText.localizationsDelegates,
          supportedLocales: AppText.supportedLocales,
          home: const PieceEditorPage(captureId: 'c'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 🔴 **`pumpAndSettle` n'attend ni un isolat ni le disque.** L'onde se
    // calcule hors du fil de l'interface — c'est tout l'intérêt — et un test de
    // widget vit dans une horloge factice qui ne pompe jamais l'un ni l'autre.
    // `runAsync` rend la main au temps réel le temps que le modèle se monte ;
    // sans lui, chaque test lirait l'écran d'attente, indéfiniment.
    final conteneur = ProviderScope.containerOf(
      tester.element(find.byType(PieceEditorPage)),
    );
    await tester.runAsync(
      () => conteneur.read(pieceEditorProvider(culte.path).future),
    );
    await tester.pumpAndSettle();

    return conteneur;
  }

  testWidgets('l\'écran s\'ouvre sur le culte entier sélectionné',
      (tester) async {
    await poser(tester);

    final texte =
        await AppText.delegate.load(AppText.supportedLocales.first);

    expect(find.text(texte.editorTitle), findsOneWidget);
    // Tout est pris par défaut : la pièce la plus probable est le culte, et
    // demander deux bornes avant de montrer quoi que ce soit serait un mur.
    expect(find.text(texte.editorRange('00:00', '00:06')), findsOneWidget);
  });

  testWidgets('tailler est fermé tant que la pièce ne dure rien',
      (tester) async {
    await poser(tester);

    final texte =
        await AppText.delegate.load(AppText.supportedLocales.first);
    final modele = ProviderScope.containerOf(
      tester.element(find.byType(PieceEditorPage)),
    );

    // Les deux bornes au même endroit : il n'y a plus de pièce.
    final vm = modele.read(pieceEditorProvider(culte.path).notifier)
      ..poserDebut()
      ..poserFin();
    await tester.pumpAndSettle();

    expect(vm, isNotNull);

    // ⚠️ Une `ListView` ne bâtit pas ce qui est hors écran : le bouton de coupe
    // et sa phrase vivent en bas de la liste, il faut y descendre pour les lire.
    await tester.scrollUntilVisible(
      find.text(texte.editorTooShort),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text(texte.editorTooShort), findsOneWidget);

    final bouton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, texte.editorCut),
    );
    expect(bouton.onPressed, isNull, reason: 'le bouton doit être fermé');
  });

  testWidgets('poser une borne la pose là où l\'oreille est', (tester) async {
    await poser(tester);

    final texte =
        await AppText.delegate.load(AppText.supportedLocales.first);
    final conteneur = ProviderScope.containerOf(
      tester.element(find.byType(PieceEditorPage)),
    );
    final vm = conteneur.read(pieceEditorProvider(culte.path).notifier);

    await vm.allerA(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    await tester.tap(find.text(texte.editorSetStart));
    await tester.pumpAndSettle();

    expect(find.text(texte.editorRange('00:02', '00:06')), findsOneWidget);
    expect(find.text(texte.editorLength('00:04')), findsOneWidget);
  });

  testWidgets('tailler écrit une pièce et ne touche pas à la matière',
      (tester) async {
    await poser(tester);

    final conteneur = ProviderScope.containerOf(
      tester.element(find.byType(PieceEditorPage)),
    );
    final vm = conteneur.read(pieceEditorProvider(culte.path).notifier);

    await vm.allerA(const Duration(seconds: 1));
    vm.poserDebut();
    await vm.allerA(const Duration(seconds: 4));
    vm.poserFin();
    await tester.pumpAndSettle();

    // Tailler écrit vraiment sur le disque : la future est créée dans le temps
    // réel, sinon l'horloge factice du test ne pomperait jamais sa fin.
    final chemin = await tester.runAsync(vm.tailler);
    await tester.pumpAndSettle();

    expect(chemin, isNotNull);
    expect(File(chemin!).existsSync(), isTrue);
    expect(
      File(chemin).lengthSync(),
      CaptureFormat.wavHeaderBytes + 3 * CaptureFormat.bytesPerSecond,
    );

    // 🔴 La matière est intacte : on peut recommencer autant qu'il faut.
    expect(
      culte.listSync().whereType<File>().where((f) => f.path.endsWith('.pcm')),
      hasLength(6),
    );
  });

  testWidgets('enchaîner repart de la fin de la pièce précédente',
      (tester) async {
    await poser(tester);

    final texte =
        await AppText.delegate.load(AppText.supportedLocales.first);
    final conteneur = ProviderScope.containerOf(
      tester.element(find.byType(PieceEditorPage)),
    );
    final vm = conteneur.read(pieceEditorProvider(culte.path).notifier);

    // La prédication : du début à la troisième seconde.
    await vm.allerA(const Duration(seconds: 3));
    vm.poserFin();
    await tester.pumpAndSettle();
    expect(find.text(texte.editorRange('00:00', '00:03')), findsOneWidget);

    // 🔴 **Le geste de son dimanche** : la prière commence exactement là où la
    // prédication s'arrête. Lui faire replacer la borne à la main serait lui
    // demander de retrouver un endroit qu'il vient de désigner.
    vm.enchainer();
    await tester.pumpAndSettle();

    expect(find.text(texte.editorRange('00:03', '00:06')), findsOneWidget);
    expect(find.text(texte.editorLength('00:03')), findsOneWidget);
  });
}

/// Une onde déjà calculée, d'une durée donnée et d'amplitude constante.
final class _OndeToutePrete implements WaveformDigest {
  const _OndeToutePrete(this.duree);

  final Duration duree;

  @override
  Future<Waveform?> preparer(String cheminCapture) async => Waveform(
        Uint8List.fromList(
          List<int>.filled(
            duree.inMilliseconds * Waveform.pasParSeconde ~/ 1000,
            120,
          ),
        ),
      );
}

/// Un assemblage qui n'écrit rien : le lecteur est muet de toute façon.
final class _JouableToutPret implements CapturePlayback {
  const _JouableToutPret();

  @override
  Future<String?> preparer(String cheminCapture) async =>
      '$cheminCapture/lecture.wav';

  @override
  Future<String?> preparerFragment(String cheminCapture, int index) async =>
      '$cheminCapture/fragment.wav';
}

/// Un lecteur qui ne joue rien — le greffon n'existe pas hors d'un appareil.
final class _LecteurMuet implements TrackPlayer {
  final _positions = StreamController<Duration>.broadcast();
  final _fins = StreamController<void>.broadcast();

  @override
  Stream<void> get onComplete => _fins.stream;

  @override
  Stream<Duration> get onPosition => _positions.stream;

  @override
  Stream<Duration> get onDuration => const Stream.empty();

  @override
  Future<PlaybackRefusal?> play(String path) async => null;

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> stop() async {}
}
