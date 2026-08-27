import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:urim/core/audio/capture_store.dart';
import 'package:urim/core/audio/sermon_capture.dart';

/// Ce qui est capté, et ce qui disparaît au septième jour.
///
/// 🔴 **La règle qui gouverne tout ce fichier** vient du domaine du serveur :
/// *« la capture n'est jamais refusée — ce qui n'est pas capté dimanche est
/// perdu pour toujours »*. Les tests tiennent les deux bords de cette promesse :
/// rien ne disparaît avant l'heure, et rien ne survit après.
void main() {
  late Directory racine;

  setUp(() {
    racine = Directory.systemTemp.createTempSync('urim_captures');
  });

  tearDown(() {
    if (racine.existsSync()) racine.deleteSync(recursive: true);
  });

  CaptureStore magasin() => CaptureStore(directory: () async => racine);

  /// Pose une capture comme le ferait le micro : un dossier, des fragments, et
  /// le témoin d'arrêt si elle s'est bien terminée.
  Directory poser(
    String id,
    DateTime debut, {
    required int fragments,
    int? dernierOctets,
    bool propre = true,
  }) {
    final dossier = Directory(
      '${racine.path}/${CaptureStore.sousDossier}/${id}_${debut.millisecondsSinceEpoch}',
    )..createSync(recursive: true);

    for (var index = 0; index < fragments; index++) {
      final dernier = index == fragments - 1;
      final octets = dernier && dernierOctets != null
          ? dernierOctets
          : CaptureFormat.fragmentBytes;

      File('${dossier.path}/${CaptureFormat.fragmentName(index)}')
          .writeAsBytesSync(List<int>.filled(octets, 0));
    }

    if (propre) {
      File('${dossier.path}/${CaptureFormat.endMarker}').writeAsStringSync('');
    }

    return dossier;
  }

  group('le format', () {
    test('16 kHz mono 16 bits : les octets disent le temps', () {
      // 🔴 C'est ce que Whisper mange, sans reechantillonnage ni decodage.
      expect(CaptureFormat.bytesPerSecond, 32000);
      expect(CaptureFormat.durationOf(32000), const Duration(seconds: 1));
      expect(
        CaptureFormat.durationOf(CaptureFormat.fragmentBytes),
        CaptureFormat.fragment,
      );
    });

    test('les fragments se trient par leur nom', () {
      final noms = [for (var i = 0; i < 12; i++) CaptureFormat.fragmentName(i)];

      expect(noms.first, '0000.pcm');
      expect(noms.last, '0011.pcm');
      expect(List.of(noms)..sort(), noms, reason: 'l\'ordre est dans le nom');
    });
  });

  group('lire le disque', () {
    test('un dossier absent n\'est pas une erreur', () async {
      expect(await magasin().list(), isEmpty);
    });

    test('la duree se calcule sur les octets, pas sur un journal', () async {
      final debut = DateTime(2026, 8, 23, 10, 30);
      // Deux fragments pleins, plus dix secondes.
      poser(
        'culte-1',
        debut,
        fragments: 3,
        dernierOctets: CaptureFormat.bytesPerSecond * 10,
      );

      final captures = await magasin().list();

      expect(captures, hasLength(1));
      expect(captures.single.id, 'culte-1');
      expect(captures.single.startedAt, debut);
      expect(captures.single.fragments, 3);
      expect(captures.single.duration, const Duration(seconds: 70));
      expect(captures.single.interrupted, isFalse);
    });

    test('la plus recente en tete', () async {
      poser('vieux', DateTime(2026, 8, 9, 10), fragments: 1);
      poser('recent', DateTime(2026, 8, 23, 10), fragments: 1);

      expect(
        (await magasin().list()).map((c) => c.id),
        ['recent', 'vieux'],
      );
    });

    test('sans temoin d\'arret, la capture apparait quand meme', () async {
      // Application tuee, batterie vide : le temoin n'a jamais ete ecrit.
      // 🔴 La faire disparaitre serait le pire des silences — le pasteur
      // croyait avoir enregistre.
      poser(
        'coupee',
        DateTime(2026, 8, 23, 10, 30),
        fragments: 4,
        propre: false,
      );

      final captures = await magasin().list();

      expect(captures.single.interrupted, isTrue);
      expect(
        captures.single.duration,
        const Duration(minutes: 2),
        reason: 'les fragments ecrits comptent, meme sans arret propre',
      );
    });

    test('un dossier sans fragment n\'est pas une capture', () async {
      // Le micro n'a jamais rendu un octet : montrer une ligne ferait croire a
      // un enregistrement qui n'existe pas.
      Directory('${racine.path}/${CaptureStore.sousDossier}/vide_1755000000000')
          .createSync(recursive: true);

      expect(await magasin().list(), isEmpty);
    });

    test('ce qui n\'est pas une capture est ignore, sans bruit', () async {
      Directory('${racine.path}/${CaptureStore.sousDossier}/notes')
          .createSync(recursive: true);
      poser('bonne', DateTime(2026, 8, 23, 10), fragments: 1);

      expect((await magasin().list()).map((c) => c.id), ['bonne']);
    });
  });

  group('les sept jours', () {
    test('l\'echeance tombe sept jours apres le debut', () {
      final capture = CapturedSermon(
        id: 'c',
        startedAt: DateTime(2026, 8, 23, 10, 30),
        duration: const Duration(minutes: 41),
        path: '/x',
        fragments: 82,
      );

      expect(capture.purgeAt, DateTime(2026, 8, 30, 10, 30));
      expect(capture.expired(DateTime(2026, 8, 30, 10, 29)), isFalse);
      expect(capture.expired(DateTime(2026, 8, 30, 10, 30)), isTrue);
    });

    test('la purge efface ce qui a passe l\'heure, et rien d\'autre', () async {
      final vieux = poser('vieux', DateTime(2026, 8, 16, 10), fragments: 2);
      final recent = poser('recent', DateTime(2026, 8, 22, 10), fragments: 2);

      final partis = await magasin().purge(now: DateTime(2026, 8, 24, 9));

      expect(partis.map((c) => c.id), ['vieux']);
      expect(vieux.existsSync(), isFalse);
      expect(
        recent.existsSync(),
        isTrue,
        reason: 'il lui reste cinq jours : l\'effacer serait voler du temps',
      );
    });

    test('une capture coupee se purge comme les autres', () async {
      // Elle n'a pas de temoin d'arret, elle a quand meme une echeance : la
      // promesse des sept jours ne depend pas de la facon dont ca s'est fini.
      final coupee = poser(
        'coupee',
        DateTime(2026, 8, 10, 10),
        fragments: 3,
        propre: false,
      );

      await magasin().purge(now: DateTime(2026, 8, 24, 9));

      expect(coupee.existsSync(), isFalse);
    });

    test('purger deux fois de suite ne rend rien la seconde fois', () async {
      poser('vieux', DateTime(2026, 8, 10, 10), fragments: 1);

      final magasinDuJour = magasin();
      await magasinDuJour.purge(now: DateTime(2026, 8, 24, 9));

      expect(await magasinDuJour.purge(now: DateTime(2026, 8, 24, 9)), isEmpty);
    });

    test('la purge emporte le dossier entier, fragments compris', () async {
      final vieux = poser('vieux', DateTime(2026, 8, 10, 10), fragments: 5);
      final fragment = File(
        '${vieux.path}/${CaptureFormat.fragmentName(0)}',
      );
      expect(fragment.existsSync(), isTrue);

      await magasin().purge(now: DateTime(2026, 8, 24, 9));

      expect(fragment.existsSync(), isFalse);
    });
  });
}
