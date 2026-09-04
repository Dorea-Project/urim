import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/audio/sermon_capture.dart';

/// Réécouter son propre culte — **et pourquoi il a fallu écrire un en-tête**.
///
/// 🔴 **Le PCM brut ne se joue pas.** La capture écrit des fragments de PCM
/// 16 kHz mono, choisis parce que c'est exactement ce que Whisper mange (D53) :
/// ni rééchantillonnage ni décodage entre le micro et le modèle. Le prix de ce
/// choix est qu'aucun lecteur audio du téléphone ne sait ouvrir ces fichiers —
/// il n'y a rien dedans qui dise la fréquence, le nombre de canaux ni la
/// profondeur.
///
/// Un en-tête WAV de quarante-quatre octets suffit à le rendre lisible, **sans
/// toucher un seul échantillon** : le WAV n'est pas un autre format, c'est le
/// même PCM avec sa carte d'identité devant. Il vit avec le format qu'il décrit,
/// dans `CaptureFormat.wavHeader` — deux écrivains s'en servent, la réécoute et
/// le découpage d'une pièce, et deux copies finiraient par diverger.
///
/// ⚠️ **Interface, pour la même raison que `TrackPlayer` en est une.** Assembler
/// un culte écrit des dizaines de mégaoctets ; sous `flutter_test` l'horloge est
/// factice et ne pompe jamais la fin d'une écriture. Brancher l'assemblage en
/// dur rendrait intestable tout écran qui l'appelle — l'éditeur le premier.
abstract interface class CapturePlayback {
  /// Assemble les fragments en un fichier jouable, et rend son chemin.
  Future<String?> preparer(String cheminCapture);

  /// Un seul fragment, rendu jouable.
  Future<String?> preparerFragment(String cheminCapture, int index);
}

/// L'assemblage réel, sur le disque de l'appareil.
///
/// ## Où le fichier vit, et pourquoi là
///
/// ⚠️ **Dans le dossier de la capture, jamais à côté.** `CaptureStore.purge`
/// efface ce dossier entier au septième jour : y ranger la version jouable la
/// fait disparaître avec l'audio qu'elle rejoue. Un fichier posé ailleurs
/// survivrait à la promesse de suppression — exactement ce que la purge existe
/// pour empêcher.
///
/// 🔴 **Une pièce taillée fait l'inverse, et c'est voulu** (voir [PieceCutter]) :
/// elle vit hors de ce dossier parce qu'elle doit survivre à la purge. Le même
/// raisonnement rend les deux règles opposées.
///
/// Les deux lecteurs du dossier ne s'en émeuvent pas : `CaptureStore` ne compte
/// que les `.pcm`, la file d'envoi aussi. Un `.wav` y est invisible.
final class FileCapturePlayback implements CapturePlayback {
  const FileCapturePlayback();

  /// Le nom de la version jouable, dans le dossier de la capture.
  static const String nom = 'lecture.wav';

  /// Le nom du fichier de travail d'un fragment — **réutilisé, jamais accumulé**.
  static const String ephemere = 'fragment.wav';

  /// Assemble les fragments en un fichier jouable, et rend son chemin.
  ///
  /// Rend `null` s'il n'y a aucun fragment — une capture vide ne se réécoute
  /// pas, et offrir un bouton qui ne joue rien serait pire que ne rien offrir.
  ///
  /// ⚠️ **Reconstruit si le compte de fragments a changé.** Un culte dont la
  /// dernière minute est arrivée après une première écoute doit se rejouer
  /// entier : comparer les tailles coûte une lecture de métadonnée, se tromper
  /// coûterait une minute de prédication.
  @override
  Future<String?> preparer(String cheminCapture) async {
    final dossier = Directory(cheminCapture);
    if (!dossier.existsSync()) return null;

    final fragments = dossier
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.pcm'))
        .toList()
      // L'ordre est dans le nom — `0000.pcm`, `0001.pcm`… — et il se trie.
      ..sort((a, b) => a.path.compareTo(b.path));

    if (fragments.isEmpty) return null;

    var octets = 0;
    for (final fragment in fragments) {
      octets += fragment.lengthSync();
    }

    final cible = File('$cheminCapture/$nom');
    final attendu = octets + CaptureFormat.wavHeaderBytes;

    if (cible.existsSync() && cible.lengthSync() == attendu) return cible.path;

    // On écrit à côté puis on renomme : le renommage est atomique, l'écriture
    // ne l'est pas. Sans ce détour, une application tuée en cours d'assemblage
    // laisserait un `.wav` tronqué que la taille dirait complet au prochain
    // passage. Même raisonnement que le `.part` de la capture (D54).
    final provisoire = File('$cheminCapture/$nom.part');
    final sortie = provisoire.openWrite();

    try {
      sortie.add(CaptureFormat.wavHeader(octets));
      for (final fragment in fragments) {
        sortie.add(fragment.readAsBytesSync());
      }
      await sortie.close();
    } on Object {
      await sortie.close();
      if (provisoire.existsSync()) provisoire.deleteSync();
      rethrow;
    }

    provisoire.renameSync(cible.path);
    return cible.path;
  }

  /// Un seul fragment, rendu jouable — **le grain de la transcription**.
  ///
  /// 🔴 **I28 impose ce grain, pas le confort.** Le transcript se range par
  /// fragment, chaque segment gardant sa position **dans le sien** : transcrire
  /// le culte d'un bloc perdrait l'ancrage, et aucune capsule ne pourrait plus
  /// dire à quel moment du message elle correspond.
  ///
  /// ⚠️ **Le fichier est éphémère, contrairement à celui de la réécoute.** Un
  /// culte de quarante minutes ferait quatre-vingts fichiers d'un mégaoctet ; on
  /// écrit celui dont on a besoin, on le lit, on le retire. D'où [ephemere],
  /// que l'appelant supprime quand il a fini.
  ///
  /// Rend `null` si ce fragment n'existe pas.
  @override
  Future<String?> preparerFragment(String cheminCapture, int index) async {
    final fragment = File(
      '$cheminCapture/${CaptureFormat.fragmentName(index)}',
    );
    if (!fragment.existsSync() || fragment.lengthSync() == 0) return null;

    final octets = fragment.readAsBytesSync();
    final cible = File('$cheminCapture/$ephemere');

    final sortie = cible.openWrite();
    try {
      sortie.add(CaptureFormat.wavHeader(octets.length));
      sortie.add(octets);
      await sortie.close();
    } on Object {
      await sortie.close();
      if (cible.existsSync()) cible.deleteSync();
      rethrow;
    }

    return cible.path;
  }
}

final capturePlaybackProvider =
    Provider<CapturePlayback>((ref) => const FileCapturePlayback());
