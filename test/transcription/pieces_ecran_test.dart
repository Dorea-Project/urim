import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urim/core/audio/file_sharer.dart';
import 'package:urim/core/audio/piece_store.dart';
import 'package:urim/core/audio/track_player.dart';
import 'package:urim/domain/entities/transcription/sermon_piece.dart';
import 'package:urim/l10n/generated/app_text.dart';
import 'package:urim/presentation/theme/app_theme.dart';
import 'package:urim/presentation/transcription/widgets/pieces_list.dart';

/// Les gestes qu'on a sur une pièce — **et celui qui ne se rattrape pas**.
///
/// 🔴 **Ce que ces tests gardent** : qu'une pièce puisse sortir du téléphone,
/// qu'un refus se lise plutôt que de laisser le pasteur devant un bouton muet,
/// et que la suppression demande avant de faire — parce qu'une pièce supprimée
/// après le septième jour ne se retaille pas, la matière ayant disparu.
void main() {
  late Directory racine;
  late _Partage partage;

  setUp(() {
    racine = Directory.systemTemp.createTempSync('urim_pieces_ecran');
    partage = _Partage();
  });

  tearDown(() {
    if (racine.existsSync()) racine.deleteSync(recursive: true);
  });

  Directory dossier() => Directory('${racine.path}/${PieceStore.sousDossier}')
    ..createSync(recursive: true);

  Future<void> poser({String titre = 'La prière'}) async {
    File('${dossier().path}/p1.wav').writeAsBytesSync(List<int>.filled(64, 3));
    await PieceStore(directory: () async => racine).save(
      SermonPiece(
        id: 'p1',
        captureId: 'culte-1',
        title: titre,
        start: const Duration(minutes: 62),
        end: const Duration(minutes: 90),
        path: '${dossier().path}/p1.wav',
        cutAt: DateTime(2026, 9, 6),
      ),
    );
  }

  Future<AppText> ouvrir(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pieceStoreProvider
              .overrideWithValue(PieceStore(directory: () async => racine)),
          fileSharerProvider.overrideWithValue(partage),
          trackPlayerProvider.overrideWithValue(_Muet()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppText.localizationsDelegates,
          supportedLocales: AppText.supportedLocales,
          home: const Scaffold(body: PiecesList(captureId: 'culte-1')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return AppText.of(tester.element(find.byType(PiecesList)));
  }

  testWidgets('une pièce se montre avec son nom et d\'où elle vient',
      (tester) async {
    await poser();
    final text = await ouvrir(tester);

    expect(find.text('La prière'), findsOneWidget);
    // La durée, puis les bornes dans le culte d'origine — c'est ce qui permet
    // de reconnaître la prière de la prédication sans les rejouer.
    expect(
      find.textContaining(text.piecesFrom('1:02:00', '1:30:00')),
      findsOneWidget,
    );
    expect(find.text(text.piecesSurvives), findsOneWidget);
  });

  testWidgets('envoyer propose le bon fichier, avec son nom', (tester) async {
    await poser();
    final text = await ouvrir(tester);

    await tester.tap(find.byTooltip(text.piecesShare));
    await tester.pumpAndSettle();

    expect(partage.chemin, endsWith('p1.wav'));
    expect(partage.titre, 'La prière');
  });

  testWidgets('un refus de partage se lit à l\'écran', (tester) async {
    await poser();
    partage.refus = ShareRefusal.fileMissing;
    final text = await ouvrir(tester);

    await tester.tap(find.byTooltip(text.piecesShare));
    await tester.pumpAndSettle();

    // 🔴 Un bouton muet ferait conclure que l'application est cassée.
    expect(find.text(text.piecesShareMissing), findsOneWidget);
  });

  testWidgets('renommer change le nom, et il tient', (tester) async {
    await poser();
    final text = await ouvrir(tester);

    // Le menu porte un type privé au fichier de l'écran : on le désigne par son
    // icône, qui est ce que le pasteur voit de toute façon.
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text(text.piecesRename));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Prière pour les malades');
    await tester.tap(find.text(text.piecesRenameSave));
    await tester.pumpAndSettle();

    expect(find.text('Prière pour les malades'), findsOneWidget);

    final relues =
        await PieceStore(directory: () async => racine).forCapture('culte-1');
    expect(relues.single.title, 'Prière pour les malades');
  });

  testWidgets('supprimer demande avant de faire, et dit ce qui se perd',
      (tester) async {
    await poser();
    final text = await ouvrir(tester);

    // Le menu porte un type privé au fichier de l'écran : on le désigne par son
    // icône, qui est ce que le pasteur voit de toute façon.
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text(text.piecesDelete));
    await tester.pumpAndSettle();

    // ⚠️ La confirmation ne demande pas « êtes-vous sûr » : elle explique que
    // la matière peut avoir déjà été purgée, donc que rien ne se retaille.
    expect(find.text(text.piecesDeleteBody), findsOneWidget);

    await tester.tap(find.text(text.piecesRenameCancel));
    await tester.pumpAndSettle();

    expect(find.text('La prière'), findsOneWidget);
  });

  testWidgets('supprimer confirmé emporte la pièce et son audio',
      (tester) async {
    await poser();
    final text = await ouvrir(tester);

    // Le menu porte un type privé au fichier de l'écran : on le désigne par son
    // icône, qui est ce que le pasteur voit de toute façon.
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text(text.piecesDelete));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, text.piecesDelete));
    await tester.pumpAndSettle();

    expect(find.text(text.piecesEmpty), findsOneWidget);
    expect(File('${dossier().path}/p1.wav').existsSync(), isFalse);
  });

  testWidgets('un culte sans pièce dit l\'enjeu du délai', (tester) async {
    final text = await ouvrir(tester);

    // La liste vide ne constate pas le vide : un pasteur qui ignore que la
    // matière expire ne découpera pas à temps.
    expect(find.text(text.piecesEmpty), findsOneWidget);
    expect(find.text(text.piecesCut), findsOneWidget);
  });
}

/// Un partage qui note ce qu'on lui a demandé, sans rien ouvrir.
final class _Partage implements FileSharer {
  String? chemin;
  String? titre;
  ShareRefusal? refus;

  @override
  Future<ShareRefusal?> partager(String chemin, {String? titre}) async {
    this.chemin = chemin;
    this.titre = titre;
    return refus;
  }
}

final class _Muet implements TrackPlayer {
  @override
  Stream<void> get onComplete => const Stream.empty();

  @override
  Stream<Duration> get onPosition => const Stream.empty();

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
