import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:urim/core/audio/piece_store.dart';
import 'package:urim/domain/entities/transcription/sermon_piece.dart';

/// Où vivent les pièces, et ce qui les distingue d'une capture.
///
/// 🔴 **La règle que tous ces tests gardent** : une capture meurt au septième
/// jour, une pièce vit avec sa publication. Si l'une des deux se trompait de
/// régime, le pasteur perdrait ce qu'il a décidé de garder — ou garderait ce
/// qu'on a promis d'effacer.
void main() {
  late Directory racine;

  setUp(() {
    racine = Directory.systemTemp.createTempSync('urim_pieces_store');
  });

  tearDown(() {
    if (racine.existsSync()) racine.deleteSync(recursive: true);
  });

  PieceStore magasin() => PieceStore(directory: () async => racine);

  Directory dossier() => Directory('${racine.path}/${PieceStore.sousDossier}')
    ..createSync(recursive: true);

  /// Pose l'audio comme le tailleur le ferait.
  void poserAudio(String id, {int octets = 1024}) {
    File('${dossier().path}/$id.wav')
        .writeAsBytesSync(List<int>.filled(octets, 7));
  }

  SermonPiece piece(
    String id, {
    String capture = 'culte-1',
    String titre = 'La prière',
    Duration debut = Duration.zero,
    Duration fin = const Duration(minutes: 30),
    DateTime? quand,
  }) =>
      SermonPiece(
        id: id,
        captureId: capture,
        title: titre,
        start: debut,
        end: fin,
        path: '${racine.path}/${PieceStore.sousDossier}/$id.wav',
        cutAt: quand ?? DateTime(2026, 9, 6, 12),
      );

  group('ranger et relire', () {
    test('une pièce rangée se relit entière', () async {
      poserAudio('p1');
      await magasin().save(piece('p1'));

      final relues = await magasin().forCapture('culte-1');

      expect(relues, hasLength(1));
      expect(relues.single.title, 'La prière');
      expect(relues.single.captureId, 'culte-1');
      expect(relues.single.start, Duration.zero);
      expect(relues.single.end, const Duration(minutes: 30));
      expect(relues.single.duration, const Duration(minutes: 30));
    });

    test('un dimanche peut donner plusieurs pièces', () async {
      // C'est tout l'objet de D70 : la prédication et la prière.
      poserAudio('p1');
      poserAudio('p2');
      await magasin().save(piece('p1', titre: 'Prédication'));
      await magasin().save(
        piece('p2', titre: 'Prière', debut: const Duration(minutes: 60)),
      );

      final relues = await magasin().forCapture('culte-1');

      expect(relues.map((p) => p.title), containsAll(['Prédication', 'Prière']));
    });

    test('les pièces d\'un autre culte ne s\'y mêlent pas', () async {
      poserAudio('p1');
      poserAudio('p2');
      await magasin().save(piece('p1'));
      await magasin().save(piece('p2', capture: 'culte-2'));

      expect(await magasin().forCapture('culte-1'), hasLength(1));
      expect(await magasin().forCapture('culte-2'), hasLength(1));
    });

    test('la plus récemment taillée vient en tête', () async {
      poserAudio('vieille');
      poserAudio('neuve');
      await magasin()
          .save(piece('vieille', quand: DateTime(2026, 9, 1)));
      await magasin().save(piece('neuve', quand: DateTime(2026, 9, 6)));

      final toutes = await magasin().all();

      expect(toutes.first.id, 'neuve');
    });

    test('un dossier absent n\'est pas une erreur', () async {
      expect(await magasin().all(), isEmpty);
    });
  });

  group('l\'audio fait juge', () {
    test('un compagnon sans audio ne rend pas de pièce', () async {
      // Le cas du tailleur interrompu : le `.json` existe, le `.wav` non.
      // L'offrir à l'écoute promettrait un son qui n'existe plus.
      await magasin().save(piece('orphelin'));

      expect(await magasin().all(), isEmpty);
    });

    test('un audio de zéro octet ne compte pas', () async {
      poserAudio('vide', octets: 0);
      await magasin().save(piece('vide'));

      expect(await magasin().all(), isEmpty);
    });

    test('un audio sans compagnon est ignoré, sans bruit', () async {
      // Le tailleur a écrit, le magasin n'a pas eu le temps. La pièce est
      // invisible plutôt que sans nom — mieux vaut ça qu'une ligne muette.
      poserAudio('sans_nom');

      expect(await magasin().all(), isEmpty);
    });

    test('un compagnon illisible ne fait pas tomber l\'écran', () async {
      poserAudio('casse');
      File('${dossier().path}/casse.json').writeAsStringSync('{ pas du json');

      expect(await magasin().all(), isEmpty);
    });

    test('un compagnon sans titre ne rend pas de pièce', () async {
      poserAudio('anonyme');
      File('${dossier().path}/anonyme.json').writeAsStringSync(
        '{"capture":"c","titre":"","debut_ms":0,"fin_ms":10,'
        '"taillee_a":"2026-09-06T12:00:00.000"}',
      );

      expect(await magasin().all(), isEmpty);
    });
  });

  group('renommer et retirer', () {
    test('renommer change le titre et rien d\'autre', () async {
      poserAudio('p1');
      await magasin().save(piece('p1'));

      expect(await magasin().renommer('p1', '  La prière du matin  '), isTrue);

      final relue = (await magasin().all()).single;
      expect(relue.title, 'La prière du matin');
      expect(relue.start, Duration.zero);
      expect(relue.end, const Duration(minutes: 30));
    });

    test('renommer une pièce inconnue le dit', () async {
      expect(await magasin().renommer('fantome', 'Titre'), isFalse);
    });

    test('un titre vide est refusé', () async {
      poserAudio('p1');
      await magasin().save(piece('p1'));

      expect(await magasin().renommer('p1', '   '), isFalse);
      expect((await magasin().all()).single.title, 'La prière');
    });

    test('retirer emporte l\'audio et son compagnon', () async {
      poserAudio('p1');
      await magasin().save(piece('p1'));

      await magasin().remove('p1');

      expect(await magasin().all(), isEmpty);
      expect(File('${dossier().path}/p1.wav').existsSync(), isFalse);
      expect(File('${dossier().path}/p1.json').existsSync(), isFalse);
    });
  });

  group('🔴 la pièce survit à sa matière', () {
    test('elle reste listée quand le culte a été purgé', () async {
      // Le point de D70. Le `captureId` désigne alors un dossier qui n'existe
      // plus — et c'est normal : savoir de quel culte vient une pièce reste
      // vrai après le septième jour ; pouvoir y retourner, non.
      final culte = Directory('${racine.path}/captures/culte-1')
        ..createSync(recursive: true);

      poserAudio('p1');
      await magasin().save(piece('p1'));

      culte.deleteSync(recursive: true);

      final relues = await magasin().forCapture('culte-1');
      expect(relues, hasLength(1));
      expect(relues.single.captureId, 'culte-1');
      expect(File(relues.single.path).existsSync(), isTrue);
    });

    test('rien n\'expire ici — le seul effacement est demandé', () async {
      poserAudio('p1');
      await magasin()
          .save(piece('p1', quand: DateTime(2020, 1, 1)));

      // Six ans plus tard, elle est toujours là.
      expect(await magasin().all(), hasLength(1));
    });
  });
}
