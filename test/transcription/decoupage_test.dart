import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:urim/core/audio/capture_store.dart';
import 'package:urim/core/audio/piece_cutter.dart';
import 'package:urim/core/audio/sermon_capture.dart';

/// Tailler une pièce dans un culte — **et ne pas se tromper d'un octet**.
///
/// 🔴 **La panne qu'on redoute ici est silencieuse.** Un échantillon fait deux
/// octets ; une coupe décalée d'un seul rend un fichier de la bonne taille, de
/// la bonne durée, et qui ne contient que du bruit. Aucun test de logique
/// n'attraperait ça — d'où des fragments dont **chaque octet dit sa position**,
/// et des attentes à l'octet près.
///
/// ⚠️ **Les fragments de ces tests font une seconde, pas trente.** Le code lit
/// la taille réelle de chaque fichier et ne suppose jamais le grain de D53 ; une
/// seconde par fragment rend les bornes lisibles — la seconde `n` est le
/// fragment `n` — là où trente secondes obligeraient à calculer pour lire.
void main() {
  late Directory racine;

  setUp(() {
    racine = Directory.systemTemp.createTempSync('urim_pieces');
  });

  tearDown(() {
    if (racine.existsSync()) racine.deleteSync(recursive: true);
  });

  PieceCutter tailleur() => PieceCutter(directory: () async => racine);

  /// Une seconde par fragment, et l'octet `i` du culte vaut `i % 256`.
  ///
  /// La rampe rend chaque position reconnaissable : si la pièce commence par
  /// l'octet `d % 256`, elle commence bien à l'octet `d` du culte.
  const octetsParFragment = CaptureFormat.bytesPerSecond;

  Directory poser(String id, {required int fragments, int? dernierOctets}) {
    final dossier = Directory(
      '${racine.path}/${CaptureStore.sousDossier}/${id}_0',
    )..createSync(recursive: true);

    var position = 0;
    for (var index = 0; index < fragments; index++) {
      final dernier = index == fragments - 1;
      final taille =
          dernier && dernierOctets != null ? dernierOctets : octetsParFragment;

      File('${dossier.path}/${CaptureFormat.fragmentName(index)}').writeAsBytesSync(
        List<int>.generate(taille, (i) => (position + i) % 256),
      );
      position += taille;
    }

    return dossier;
  }

  /// Ce que la pièce contient, en-tête retiré.
  List<int> audio(String chemin) =>
      File(chemin).readAsBytesSync().sublist(CaptureFormat.wavHeaderBytes);

  group('les bornes', () {
    test('la pièce porte exactement les octets demandés', () async {
      final culte = poser('c1', fragments: 6);

      final chemin = await tailleur().decouper(
        culte.path,
        debut: const Duration(seconds: 2),
        fin: const Duration(seconds: 5),
        id: 'priere',
      );

      expect(chemin, isNotNull);

      final octets = audio(chemin!);
      final depart = 2 * octetsParFragment;

      expect(octets, hasLength(3 * octetsParFragment));
      expect(octets.first, depart % 256);
      expect(octets[1], (depart + 1) % 256);
      expect(octets.last, (depart + 3 * octetsParFragment - 1) % 256);
    });

    test('une borne au milieu d\'un fragment ne décale rien', () async {
      final culte = poser('c2', fragments: 4);

      // 1,5 s → 2,5 s : les deux bornes tombent à l'intérieur d'un fragment,
      // et la pièce traverse trois fragments en n'en gardant aucun entier.
      final chemin = await tailleur().decouper(
        culte.path,
        debut: const Duration(milliseconds: 1500),
        fin: const Duration(milliseconds: 2500),
        id: 'milieu',
      );

      final octets = audio(chemin!);
      final depart = octetsParFragment + octetsParFragment ~/ 2;

      expect(octets, hasLength(octetsParFragment));
      expect(octets.first, depart % 256);
      expect(octets.last, (depart + octetsParFragment - 1) % 256);
    });

    test('une fin au-delà du culte est ramenée à la matière', () async {
      final culte = poser('c3', fragments: 2);

      final chemin = await tailleur().decouper(
        culte.path,
        debut: Duration.zero,
        fin: const Duration(hours: 3),
        id: 'tout',
      );

      expect(audio(chemin!), hasLength(2 * octetsParFragment));
    });

    test('un dernier fragment plus court est pris tel quel', () async {
      // Le cas réel : la capture s'arrête au milieu d'une demi-minute.
      final culte = poser('c4', fragments: 3, dernierOctets: 8000);

      final chemin = await tailleur().decouper(
        culte.path,
        debut: Duration.zero,
        fin: const Duration(hours: 1),
        id: 'entier',
      );

      expect(audio(chemin!), hasLength(2 * octetsParFragment + 8000));
    });

    test('deux pièces qui se suivent ne se recouvrent pas et ne perdent rien',
        () async {
      final culte = poser('c5', fragments: 4);
      final t = tailleur();

      final avant = await t.decouper(
        culte.path,
        debut: Duration.zero,
        fin: const Duration(milliseconds: 2500),
        id: 'predication',
      );
      final apres = await t.decouper(
        culte.path,
        debut: const Duration(milliseconds: 2500),
        fin: const Duration(seconds: 4),
        id: 'priere',
      );

      expect(audio(avant!) + audio(apres!), hasLength(4 * octetsParFragment));
      expect(audio(apres).first, (2 * octetsParFragment + octetsParFragment ~/ 2) % 256);
    });
  });

  group('ce qui ne se taille pas', () {
    test('des bornes inversées ou vides ne rendent rien', () async {
      final culte = poser('v1', fragments: 3);
      final t = tailleur();

      expect(
        await t.decouper(culte.path,
            debut: const Duration(seconds: 2),
            fin: const Duration(seconds: 1),
            id: 'a'),
        isNull,
      );
      expect(
        await t.decouper(culte.path,
            debut: const Duration(seconds: 1),
            fin: const Duration(seconds: 1),
            id: 'b'),
        isNull,
      );
    });

    test('un début au-delà du culte ne rend rien', () async {
      final culte = poser('v2', fragments: 2);

      expect(
        await tailleur().decouper(
          culte.path,
          debut: const Duration(minutes: 5),
          fin: const Duration(minutes: 6),
          id: 'c',
        ),
        isNull,
      );
    });

    test('une capture sans fragment ne rend rien', () async {
      final vide = Directory('${racine.path}/vide')..createSync(recursive: true);

      expect(
        await tailleur().decouper(vide.path,
            debut: Duration.zero, fin: const Duration(seconds: 1), id: 'd'),
        isNull,
      );
    });

    test('une capture absente ne rend rien', () async {
      expect(
        await tailleur().decouper('${racine.path}/jamais',
            debut: Duration.zero, fin: const Duration(seconds: 1), id: 'e'),
        isNull,
      );
    });

    test('aucun fichier n\'est laissé derrière quand rien n\'est taillé',
        () async {
      final culte = poser('v3', fragments: 2);

      await tailleur().decouper(culte.path,
          debut: const Duration(seconds: 2),
          fin: const Duration(seconds: 1),
          id: 'refus');

      final pieces = Directory('${racine.path}/${PieceCutter.sousDossier}');
      expect(pieces.existsSync() && pieces.listSync().isNotEmpty, isFalse);
    });
  });

  group('le fichier produit', () {
    test('porte un en-tête WAV qui annonce la bonne taille', () async {
      final culte = poser('e1', fragments: 3);

      final chemin = await tailleur().decouper(
        culte.path,
        debut: Duration.zero,
        fin: const Duration(seconds: 2),
        id: 'entete',
      );

      final octets = File(chemin!).readAsBytesSync();
      final audioAttendu = 2 * octetsParFragment;

      expect(String.fromCharCodes(octets.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(octets.sublist(8, 12)), 'WAVE');
      expect(octets, hasLength(CaptureFormat.wavHeaderBytes + audioAttendu));

      int u32(int a) =>
          octets[a] | octets[a + 1] << 8 | octets[a + 2] << 16 | octets[a + 3] << 24;

      expect(u32(4), 36 + audioAttendu, reason: 'taille RIFF');
      expect(u32(40), audioAttendu, reason: 'taille du bloc data');
      expect(u32(24), CaptureFormat.sampleRate);
    });

    test('ne laisse aucun fichier provisoire', () async {
      final culte = poser('e2', fragments: 2);

      await tailleur().decouper(culte.path,
          debut: Duration.zero, fin: const Duration(seconds: 1), id: 'propre');

      final restes = Directory('${racine.path}/${PieceCutter.sousDossier}')
          .listSync()
          .where((f) => f.path.endsWith('.part'));

      expect(restes, isEmpty);
    });

    test('🔴 la pièce survit à la purge de la capture', () async {
      // Le point de D70 : la matière brute meurt au septième jour, la pièce
      // vit avec sa publication. Si elle était rangée dans le dossier de la
      // capture — comme la réécoute l'est volontairement — elle partirait avec.
      final debut = DateTime.now().subtract(const Duration(days: 8));
      final dossier = Directory(
        '${racine.path}/${CaptureStore.sousDossier}/'
        'vieux_${debut.millisecondsSinceEpoch}',
      )..createSync(recursive: true);
      File('${dossier.path}/${CaptureFormat.fragmentName(0)}')
          .writeAsBytesSync(List<int>.filled(octetsParFragment, 7));

      final chemin = await tailleur().decouper(dossier.path,
          debut: Duration.zero, fin: const Duration(seconds: 1), id: 'gardee');

      await CaptureStore(directory: () async => racine).purge(now: DateTime.now());

      expect(dossier.existsSync(), isFalse, reason: 'la matière est purgée');
      expect(File(chemin!).existsSync(), isTrue, reason: 'la pièce demeure');
    });
  });

  group('l\'alignement sur l\'échantillon', () {
    test('une position impaire est arrondie vers le bas', () {
      // 1 ms = 32 octets à 16 kHz : pair. On cherche une durée dont le produit
      // tombe impair — c'est le cas qu'un arrondi naïf casserait.
      expect(CaptureFormat.bytesOf(const Duration(milliseconds: 1)), 32);
      expect(CaptureFormat.bytesOf(Duration.zero), 0);
      expect(CaptureFormat.bytesOf(const Duration(seconds: 1)),
          CaptureFormat.bytesPerSecond);

      for (var ms = 0; ms < 200; ms++) {
        expect(CaptureFormat.bytesOf(Duration(milliseconds: ms)).isEven, isTrue,
            reason: '$ms ms doit tomber sur une frontière d\'échantillon');
      }
    });
  });
}
