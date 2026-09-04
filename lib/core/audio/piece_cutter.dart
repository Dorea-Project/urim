import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:urim/core/audio/sermon_capture.dart';

/// Tailler une **pièce** dans la matière d'un culte — D70, étape 3 du plan.
///
/// Un pasteur enregistre une heure et demie d'un seul tenant : une prédication
/// enchaînée par une prière, avec du bruit et des chants au démarrage. Il ne
/// publie pas ça. Il coupe, il réduit, et il sort **deux pièces** qu'il diffuse
/// à trois jours d'intervalle.
///
/// 🔴 **Le découpage est le consentement** (D70). La matière brute est ce que le
/// micro a pris *sans intention* — un témoignage donné au micro du prédicateur
/// peut s'y trouver. Une pièce est ce que le pasteur a **écouté puis décidé de
/// garder**. C'est cet acte, et non une durée de rétention, qui transforme une
/// captation en objet assumé ; tout ce qui sort d'Urim sort d'ici.
///
/// ## Pourquoi la pièce ne vit pas dans le dossier de la capture
///
/// ⚠️ **C'est l'inverse exact de [CapturePlayback], et pour la raison inverse.**
/// La version jouable d'un culte est rangée *dans* le dossier de la capture pour
/// que la purge du septième jour l'emporte avec l'audio qu'elle rejoue. La
/// pièce, elle, doit **survivre** à cette purge : elle vit avec sa publication,
/// comme une piste vit avec sa synthèse (`voice_track_store`). Elle a donc son
/// propre dossier, que la purge ne visite jamais.
///
/// ## Ce que cette classe ne fait pas
///
/// **Elle ne ré-encode rien.** La sortie est du WAV — le même PCM avec son
/// en-tête devant, ~86 Mo pour quarante-cinq minutes. C'est gros, et c'est
/// voulu : aucun codec, aucun canal natif, aucune bibliothèque neuve. Si le
/// partage bute un jour sur la taille, on paiera l'AAC **en sachant pourquoi**,
/// après l'avoir vu échouer.
///
/// **Elle ne range rien.** Une pièce a un titre, un état, une date de
/// publication ; rien de tout ça n'est ici. Cette classe produit des octets à un
/// chemin, et c'est tout ce qu'on lui demande aujourd'hui.
final class PieceCutter {
  PieceCutter({Future<Directory> Function()? directory})
      : _directory = directory ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _directory;

  /// À côté de `captures/`, jamais dedans — voir l'en-tête.
  static const String sousDossier = 'pieces';

  /// Taille `[debut, fin[` dans la capture, et rend le chemin de la pièce.
  ///
  /// Rend `null` quand il n'y a rien à tailler : capture absente ou vide,
  /// bornes vides ou inversées, début au-delà de la matière. **Aucun de ces cas
  /// n'est une erreur** — ce sont des gestes que l'écran doit pouvoir empêcher
  /// avant d'arriver ici, et un fichier de zéro seconde serait pire qu'un refus.
  ///
  /// [fin] est ramenée à la durée réelle si elle la dépasse : le pasteur qui
  /// tire la borne jusqu'au bout veut la fin du culte, pas une erreur.
  Future<String?> decouper(
    String cheminCapture, {
    required Duration debut,
    required Duration fin,
    required String id,
  }) async {
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

    final tailles = fragments.map((f) => f.lengthSync()).toList();
    final total = tailles.fold<int>(0, (somme, taille) => somme + taille);

    // Un fragment tronqué par une application morte au mauvais moment peut
    // porter un octet de trop ; on l'ignore plutôt que de décaler la sortie.
    final matiere = total - (total % 2);

    final depart = CaptureFormat.bytesOf(debut).clamp(0, matiere);
    final arrivee = CaptureFormat.bytesOf(fin).clamp(0, matiere);
    if (arrivee <= depart) return null;

    final racine = await _racine();
    if (!racine.existsSync()) racine.createSync(recursive: true);

    final cible = File('${racine.path}/$id.wav');

    // Écrire à côté puis renommer : le renommage est atomique, l'écriture ne
    // l'est pas. Sans ce détour, une application tuée en cours de découpage
    // laisserait une pièce tronquée que sa taille dirait complète — et la
    // matière dont elle est tirée, elle, aura disparu au septième jour.
    final provisoire = File('${cible.path}.part');
    final sortie = provisoire.openWrite();

    try {
      sortie.add(CaptureFormat.wavHeader(arrivee - depart));

      // Une borne tombe presque toujours **au milieu** d'un fragment de trente
      // secondes : on saute les fragments entièrement hors des bornes, et on
      // rogne les deux qui les portent. Le PCM étant à débit constant, la
      // position d'un octet dans le culte est la somme des tailles qui le
      // précèdent — rien à indexer, rien à tenir à côté du disque.
      var curseur = 0;
      for (var index = 0; index < fragments.length; index++) {
        final finFragment = curseur + tailles[index];

        if (finFragment > depart && curseur < arrivee) {
          final octets = fragments[index].readAsBytesSync();
          final depuis = depart > curseur ? depart - curseur : 0;
          final jusqu =
              arrivee < finFragment ? arrivee - curseur : tailles[index];
          sortie.add(Uint8List.sublistView(octets, depuis, jusqu));
        }

        curseur = finFragment;
        if (curseur >= arrivee) break;
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

  Future<Directory> _racine() async =>
      Directory('${(await _directory()).path}/$sousDossier');
}

final pieceCutterProvider = Provider<PieceCutter>((ref) => PieceCutter());
