import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:urim/core/audio/capture_playback.dart';
import 'package:urim/core/audio/sermon_capture.dart';

/// Réécouter son propre culte — **le seul geste que « prêcher » offre
/// aujourd'hui**.
///
/// 🔴 **L'audio existait sans qu'aucun écran ne sache le jouer.** Il montait au
/// serveur, il se purgeait au septième jour, et son auteur ne l'entendait
/// jamais. La cause est un choix de format assumé : la capture écrit du PCM
/// brut parce que c'est ce que Whisper mange (D53), et **aucun lecteur du
/// téléphone n'ouvre du PCM brut** — rien dedans ne dit la fréquence ni le
/// nombre de canaux.
///
/// Quarante-quatre octets d'en-tête suffisent, sans toucher un échantillon.
void main() {
  late Directory racine;

  setUp(() => racine = Directory.systemTemp.createTempSync('urim_reecoute'));
  tearDown(() {
    if (racine.existsSync()) racine.deleteSync(recursive: true);
  });

  /// Pose des fragments comme le micro l'aurait fait, et rend le dossier.
  String poser(List<int> taillesParFragment) {
    final dossier = Directory('${racine.path}/culte')..createSync(recursive: true);

    for (var index = 0; index < taillesParFragment.length; index++) {
      File('${dossier.path}/${CaptureFormat.fragmentName(index)}')
          .writeAsBytesSync(
        List<int>.filled(taillesParFragment[index], index + 1),
      );
    }
    return dossier.path;
  }

  group('le fichier jouable', () {
    test('il porte un en-tête WAV, et tout l\'audio derrière', () async {
      final dossier = poser([320, 160]);

      final chemin = await const FileCapturePlayback().preparer(dossier);
      expect(chemin, isNotNull);

      final octets = File(chemin!).readAsBytesSync();

      // 44 octets d'en-tête, puis les 480 octets de PCM, intacts.
      expect(octets.length, 44 + 480);
      expect(String.fromCharCodes(octets.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(octets.sublist(8, 12)), 'WAVE');
      expect(String.fromCharCodes(octets.sublist(36, 40)), 'data');
    });

    test('l\'en-tête décrit la capture, pas autre chose', () async {
      // 🔴 Se tromper ici ne casse rien : ça **joue de travers**. Un mauvais
      // taux d'échantillonnage rendrait la voix du pasteur méconnaissable, et
      // aucun test d'écran ne l'aurait vu.
      final chemin = await const FileCapturePlayback().preparer(poser([160]));
      final vue = ByteData.sublistView(File(chemin!).readAsBytesSync());

      expect(vue.getUint16(20, Endian.little), 1, reason: 'PCM non compressé');
      expect(vue.getUint16(22, Endian.little), CaptureFormat.channels);
      expect(vue.getUint32(24, Endian.little), CaptureFormat.sampleRate);
      expect(vue.getUint32(28, Endian.little), CaptureFormat.bytesPerSecond);
      expect(vue.getUint16(34, Endian.little), 16, reason: '16 bits par échantillon');
    });

    test('les tailles annoncées sont celles du fichier', () async {
      // Un lecteur qui croit le fichier plus long joue du silence à la fin ;
      // plus court, il coupe la dernière phrase du pasteur.
      final chemin = await const FileCapturePlayback().preparer(poser([320, 320]));
      final octets = File(chemin!).readAsBytesSync();
      final vue = ByteData.sublistView(octets);

      expect(vue.getUint32(4, Endian.little), octets.length - 8);
      expect(vue.getUint32(40, Endian.little), 640);
    });

    test('les fragments se suivent dans l\'ordre du culte', () async {
      // L'ordre est dans le nom. Trier sur autre chose mélangerait la
      // prédication sans que rien ne le signale.
      final chemin = await const FileCapturePlayback().preparer(poser([4, 4, 4]));
      final audio = File(chemin!).readAsBytesSync().sublist(44);

      expect(audio, [1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3]);
    });
  });

  group('ce qui ne se réécoute pas', () {
    test('une capture sans fragment ne rend rien', () async {
      // Offrir un bouton qui ne joue rien serait pire que ne rien offrir.
      final vide = Directory('${racine.path}/vide')..createSync();

      expect(await const FileCapturePlayback().preparer(vide.path), isNull);
    });

    test('un dossier absent ne fait pas tomber l\'écran', () async {
      expect(
        await const FileCapturePlayback().preparer('${racine.path}/nulle-part'),
        isNull,
      );
    });
  });

  group('ce qui se reconstruit, et ce qui ne se refait pas', () {
    test('une seconde écoute réutilise le fichier', () async {
      final dossier = poser([320]);

      final premier = await const FileCapturePlayback().preparer(dossier);
      final quand = File(premier!).lastModifiedSync();

      final second = await const FileCapturePlayback().preparer(dossier);

      expect(second, premier);
      expect(File(second!).lastModifiedSync(), quand);
    });

    test('un fragment arrivé depuis force la reconstruction', () async {
      // ⚠️ Un culte dont la dernière minute est arrivée après une première
      // écoute doit se rejouer **entier**.
      final dossier = poser([320]);
      await const FileCapturePlayback().preparer(dossier);

      File('$dossier/${CaptureFormat.fragmentName(1)}')
          .writeAsBytesSync(List<int>.filled(160, 9));

      final chemin = await const FileCapturePlayback().preparer(dossier);

      expect(File(chemin!).lengthSync(), 44 + 480);
    });

    test('le fichier vit dans la capture, donc il se purge avec elle',
        () async {
      // 🔴 Posé ailleurs, il survivrait à la promesse des sept jours —
      // exactement ce que la purge existe pour empêcher.
      final dossier = poser([160]);
      final chemin = await const FileCapturePlayback().preparer(dossier);

      expect(chemin, startsWith(dossier));
      expect(chemin, endsWith(FileCapturePlayback.nom));
    });

    test('il reste invisible pour les deux lecteurs du dossier', () async {
      // `CaptureStore` compte les octets des `.pcm` pour en déduire la durée ;
      // la file d'envoi compte les `.pcm` pour savoir ce qui reste à monter. Un
      // `.wav` compté par l'un ou l'autre fausserait la durée affichée ou
      // ferait attendre un fragment qui n'existe pas.
      final dossier = poser([320]);
      await const FileCapturePlayback().preparer(dossier);

      final pcm = Directory(dossier)
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.pcm'));

      expect(pcm, hasLength(1));
    });
  });
}
