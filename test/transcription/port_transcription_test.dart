import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:urim/core/audio/capture_playback.dart';
import 'package:urim/core/audio/sermon_capture.dart';
import 'package:urim/core/speech/model_download.dart';
import 'package:urim/core/speech/transcriber.dart';

/// Le port de transcription — **ce qu'il promet, avant tout moteur**.
///
/// 🔴 **Ces tests ne font tourner aucun modèle**, et c'est délibéré : le
/// gabarit n'est pas choisi (D52), et le banc d'essai décidera. Ce qui se tient
/// ici est ce qui ne doit pas changer quand il le sera — le grain par fragment,
/// l'ancrage relatif, et le gabarit rangé **avec** le texte.
void main() {
  group('le grain est le fragment, jamais le culte', () {
    late Directory racine;

    setUp(() => racine = Directory.systemTemp.createTempSync('urim_port'));
    tearDown(() {
      if (racine.existsSync()) racine.deleteSync(recursive: true);
    });

    String poser(int nombre) {
      final dossier = Directory('${racine.path}/culte')
        ..createSync(recursive: true);

      for (var i = 0; i < nombre; i++) {
        File('${dossier.path}/${CaptureFormat.fragmentName(i)}')
            .writeAsBytesSync(List<int>.filled(320, i + 1));
      }
      return dossier.path;
    }

    test('un fragment se rend jouable seul', () async {
      final dossier = poser(3);

      final chemin = await const FileCapturePlayback().preparerFragment(dossier, 1);
      expect(chemin, isNotNull);

      final octets = File(chemin!).readAsBytesSync();

      // 🔴 **Celui-ci et pas un autre.** Transcrire le voisin décalerait tout le
      // transcript sans que rien ne le signale.
      expect(octets.length, 44 + 320);
      expect(octets.sublist(44).toSet(), {2});
    });

    test('l\'en-tête décrit la capture, comme pour la réécoute', () async {
      final chemin = await const FileCapturePlayback().preparerFragment(poser(1), 0);
      final vue = ByteData.sublistView(File(chemin!).readAsBytesSync());

      expect(vue.getUint32(24, Endian.little), CaptureFormat.sampleRate);
      expect(vue.getUint16(22, Endian.little), CaptureFormat.channels);
    });

    test('un fragment qui n\'existe pas ne fabrique rien', () async {
      // Le moteur recevrait un fichier vide et rendrait du texte inventé.
      expect(
        await const FileCapturePlayback().preparerFragment(poser(2), 7),
        isNull,
      );
    });

    test('le fichier de travail se réutilise, il ne s\'accumule pas', () async {
      // ⚠️ Quatre-vingts fragments feraient quatre-vingts mégaoctets de
      // fichiers de travail sur un téléphone qui en a peu.
      final dossier = poser(3);
      final lecteur = const FileCapturePlayback();

      await lecteur.preparerFragment(dossier, 0);
      await lecteur.preparerFragment(dossier, 1);
      await lecteur.preparerFragment(dossier, 2);

      final wavs = Directory(dossier)
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.wav'));

      expect(wavs, hasLength(1));
    });
  });

  group('ce que le transcript porte', () {
    const span = TranscribedSpan(
      text: 'Que l\'amour fraternel continue.',
      from: Duration(seconds: 2),
      to: Duration(seconds: 5),
    );

    test('le gabarit se range avec le texte, jamais à côté', () {
      // 🔴 Le serveur fait de même (`provider`, `model_ref`) et pour la même
      // raison : sans lui, impossible de savoir plus tard **pourquoi certains
      // dimanches sont mauvais**. La campagne compare des transcripts ; elle
      // doit savoir de quel modèle chacun vient.
      const fragment = TranscribedFragment(
        index: 3,
        spans: [span],
        model: TranscriptionModel.small,
      );

      expect(fragment.model, TranscriptionModel.small);
      expect(fragment.index, 3);
    });

    test('les bornes restent relatives au fragment', () {
      // I28 — l'horodatage de la capsule est lié à sa source, jamais recalculé.
      // Les décaler depuis le début du culte ferait dépendre chaque segment de
      // tous ceux qui le précèdent.
      expect(span.from, const Duration(seconds: 2));
      expect(span.to, const Duration(seconds: 5));
    });

    test('un fragment silencieux est vide, il n\'est pas une panne', () {
      // Une prière, une réponse de l'assemblée : le rendre vide est la vérité.
      // Le traiter comme un échec ferait retenter indéfiniment.
      const muet = TranscribedFragment(
        index: 0,
        spans: [],
        model: TranscriptionModel.small,
      );

      expect(muet.isEmpty, isTrue);
      expect(muet.text, isEmpty);
    });

    test('les segments se recollent dans l\'ordre, sans blanc', () {
      const fragment = TranscribedFragment(
        index: 0,
        spans: [
          TranscribedSpan(text: ' Le frère ', from: Duration.zero, to: Duration(seconds: 1)),
          TranscribedSpan(text: '  ', from: Duration(seconds: 1), to: Duration(seconds: 2)),
          TranscribedSpan(text: 'reste un frère.', from: Duration(seconds: 2), to: Duration(seconds: 3)),
        ],
        model: TranscriptionModel.small,
      );

      expect(fragment.text, 'Le frère reste un frère.');
    });
  });

  group('ce que le gabarit coûte', () {
    test("le poids annoncé est celui qui descend vraiment", () {
      // 🔴 **Ce chiffre a bougé deux fois, et la seconde était une solution.**
      //
      // Le 29/08 il annonçait la taille quantisée alors que le paquet
      // descendait le modèle brut : l'écran promettait moins de la moitié de ce
      // qui partait du forfait. Le 30/08, `small` s'est révélé impossible à
      // télécharger — 465 Mo que le téléchargeur du paquet chargeait
      // *entièrement en mémoire* sur un appareil qui en a quatre.
      //
      // Urim descend désormais la variante `q5_1` par son propre téléchargeur.
      // Vérifié à la source, par en-tête HTTP.
      expect(TranscriptionModel.small.megaoctets, 181);
    });

    test("l'adresse vise bien la variante quantisée", () {
      // Le jour où quelqu'un remettra le modèle brut, ce test le dira — et le
      // pasteur ne découvrira pas 465 Mo à la place de 181.
      for (final m in TranscriptionModel.values) {
        expect(ModelDownload.source(m).path, endsWith('-q5_1.bin'));
      }
    });

    test("la mémoire compte autant que le téléchargement", () {
      // ⚠️ Le A07 a 4 Go, Android en prend deux, et le micro tourne. C'est
      // cette colonne-là qui décidera si une prédication de deux heures passe
      // d'un bout à l'autre.
      expect(TranscriptionModel.small.memoireVive, greaterThan(900));
    });

    test("il n'y a plus qu'un gabarit, et c'est une décision", () {
      // 🔴 `tiny` et `base` ont été retirés le 30/08 : le terrain les a
      // départagés sur du français d'Abidjan, et les deux hallucinent trop.
      //
      // ⚠️ Les garder « au cas où » aurait été pire — un sélecteur demande au
      // pasteur de trancher une question technique déjà tranchée, et la
      // mauvaise réponse produit un transcript inutilisable qu'il n'aurait pas
      // su attribuer à son choix.
      expect(TranscriptionModel.values, hasLength(1));
      expect(TranscriptionModel.values.single, TranscriptionModel.small);
    });
  });
}
