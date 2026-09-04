import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/audio/sermon_capture.dart';

/// L'onde d'un culte — **ce qui rend le découpage possible à l'œil**.
///
/// Un pasteur qui cherche la frontière entre sa prédication et sa prière ne la
/// trouvera pas à l'oreille : il faudrait écouter une heure. Il la trouve **en
/// la voyant** — le creux des applaudissements, la reprise du chant, le silence
/// avant la prière. L'onde n'est pas un ornement de l'éditeur, c'est
/// l'instrument qui remplace une heure d'écoute par un coup d'œil.
///
/// ## Pourquoi un condensé, et pas l'audio
///
/// 🔴 **Une heure et demie pèse 173 Mo.** Les relire à chaque image, à chaque
/// glissement de doigt, ferait ramer l'application sur un A07 — et l'éditeur
/// serait inutilisable précisément sur l'appareil pour lequel il est fait.
///
/// On calcule donc **dix crêtes par seconde, une fois**, et on les garde. Une
/// crête tient sur un octet : quatre-vingt-dix minutes font 54 000 octets, soit
/// **trois mille fois plus léger** que la matière. Et dix par seconde suffisent
/// largement — placer une coupe au dixième de seconde est déjà plus fin que ce
/// qu'un doigt peut viser.
///
/// ## Où le condensé vit, et pourquoi là
///
/// ⚠️ **Dans le dossier de la capture, comme la réécoute.** Il décrit la matière
/// brute ; il doit donc **disparaître avec elle** au septième jour. Le ranger
/// ailleurs laisserait la silhouette d'un culte survivre à l'audio qu'on a
/// promis d'effacer — une trace plus maigre, mais une trace quand même.
///
/// Les deux lecteurs du dossier ne s'en émeuvent pas : `CaptureStore` ne compte
/// que les `.pcm`, la file d'envoi aussi.
@immutable
final class Waveform {
  const Waveform(this.cretes);

  /// Une crête par pas, de 0 à 255 — l'amplitude la plus forte de la tranche.
  ///
  /// **La crête, pas la moyenne.** Une moyenne écraserait les attaques : un
  /// « Amen » lancé sur un fond calme disparaîtrait dans la ligne, et c'est
  /// exactement le repère qu'on cherche.
  final Uint8List cretes;

  /// L'onde d'avant le calcul — ce que l'éditeur dessine pendant qu'il attend.
  ///
  /// Un écran vide et un écran qui n'a rien à montrer se ressemblent trop ; le
  /// premier se distingue par une onde plate assumée, pas par une exception.
  static final Waveform vide = Waveform(Uint8List(0));

  static const int pasParSeconde = 10;

  /// Le nom du condensé, dans le dossier de la capture.
  static const String fichier = 'onde.bin';

  static const int _octetsParPas =
      CaptureFormat.bytesPerSecond ~/ pasParSeconde;

  bool get estVide => cretes.isEmpty;

  Duration get duree =>
      Duration(milliseconds: cretes.length * 1000 ~/ pasParSeconde);

  /// La crête à un instant donné, ou 0 hors des bornes.
  int a(Duration position) {
    final index = position.inMilliseconds * pasParSeconde ~/ 1000;
    if (index < 0 || index >= cretes.length) return 0;
    return cretes[index];
  }

  /// Réduit l'onde à [combien] colonnes, entre deux instants.
  ///
  /// C'est ce que l'affichage consomme : une fenêtre de temps et une largeur en
  /// pixels. ⚠️ **On garde le maximum de chaque colonne, jamais la première
  /// valeur** — dézoomer sur une heure et demie en échantillonnant ferait
  /// clignoter l'onde à chaque glissement, parce qu'un pixel prendrait tantôt
  /// une crête, tantôt un creux. Le maximum est stable : la silhouette ne bouge
  /// plus quand on la traverse.
  Uint8List fenetre(Duration debut, Duration fin, int combien) {
    final sortie = Uint8List(combien.clamp(0, 1 << 16));
    if (sortie.isEmpty || cretes.isEmpty) return sortie;

    final premier = (debut.inMilliseconds * pasParSeconde / 1000).floor();
    final dernier = (fin.inMilliseconds * pasParSeconde / 1000).ceil();
    final etendue = dernier - premier;
    if (etendue <= 0) return sortie;

    for (var colonne = 0; colonne < sortie.length; colonne++) {
      final de = premier + etendue * colonne ~/ sortie.length;
      var a = premier + etendue * (colonne + 1) ~/ sortie.length;
      if (a <= de) a = de + 1;

      var crete = 0;
      for (var i = de; i < a; i++) {
        if (i < 0 || i >= cretes.length) continue;
        if (cretes[i] > crete) crete = cretes[i];
      }
      sortie[colonne] = crete;
    }

    return sortie;
  }

  /// Calcule les crêtes d'un flux de PCM 16 bits signé, petit-boutiste.
  ///
  /// Pure et sans disque : c'est elle qu'on éprouve, et c'est elle qui tourne
  /// dans l'isolat. Les fragments sont traversés **comme un seul flux** — une
  /// tranche de cent millisecondes qui chevauche deux fichiers doit rendre la
  /// crête des deux, sinon l'onde porterait un faux creux toutes les trente
  /// secondes, quatre-vingts fois par culte.
  static Uint8List calculer(Iterable<Uint8List> fragments) {
    final cretes = <int>[];

    var creteCourante = 0;
    var octetsDansLePas = 0;
    var reste = -1; // l'octet de poids faible resté du fragment précédent

    for (final fragment in fragments) {
      var i = 0;

      if (reste >= 0 && fragment.isNotEmpty) {
        final valeur = _amplitude(reste, fragment[0]);
        if (valeur > creteCourante) creteCourante = valeur;
        octetsDansLePas += 2;
        reste = -1;
        i = 1;
      }

      for (; i + 1 < fragment.length; i += 2) {
        final valeur = _amplitude(fragment[i], fragment[i + 1]);
        if (valeur > creteCourante) creteCourante = valeur;

        octetsDansLePas += 2;
        if (octetsDansLePas >= _octetsParPas) {
          cretes.add(creteCourante);
          creteCourante = 0;
          octetsDansLePas = 0;
        }
      }

      // Un fragment de longueur impaire : son dernier octet appartient à un
      // échantillon dont la seconde moitié est au début du fragment suivant.
      if (i < fragment.length) reste = fragment[i];
    }

    // La dernière tranche est incomplète presque toujours — on la garde plutôt
    // que de la jeter : c'est la fin du culte, et une onde qui s'arrête avant
    // l'audio ferait croire à une capture tronquée.
    if (octetsDansLePas > 0) cretes.add(creteCourante);

    return Uint8List.fromList(cretes);
  }

  /// L'amplitude d'un échantillon, ramenée à un octet.
  ///
  /// PCM 16 bits signé : on prend la valeur absolue et on la comprime sur huit
  /// bits. `-32768` n'a pas d'opposé représentable — d'où la borne, qui évite
  /// un débordement silencieux sur l'échantillon le plus fort du culte.
  static int _amplitude(int bas, int haut) {
    var valeur = bas | (haut << 8);
    if (valeur >= 0x8000) valeur -= 0x10000;
    if (valeur < 0) valeur = -valeur;
    if (valeur > 0x7FFF) valeur = 0x7FFF;
    return valeur >> 7;
  }
}

/// Prépare l'onde d'une capture, et la garde.
///
/// ⚠️ **Interface, pour la même raison que `TrackPlayer` en est une** : le
/// calcul part dans un isolat, et un isolat ne répond pas sous `flutter_test` —
/// l'horloge y est factice et ne pompe jamais sa réponse. Brancher le calcul en
/// dur rendrait l'éditeur intestable, exactement comme un greffon le ferait.
abstract interface class WaveformDigest {
  /// Rend l'onde de la capture, ou `null` s'il n'y a rien à dessiner.
  Future<Waveform?> preparer(String cheminCapture);
}

/// L'onde réelle, lue sur le disque et calculée hors du fil de l'interface.
final class FileWaveformDigest implements WaveformDigest {
  const FileWaveformDigest();

  /// Rend l'onde de la capture, en la calculant si le condensé manque.
  ///
  /// ⚠️ **Recalculée si le compte d'octets a changé.** Un culte dont la
  /// dernière minute est arrivée après une première ouverture doit montrer sa
  /// vraie longueur — même raison que la reconstruction de la réécoute.
  ///
  /// Rend `null` s'il n'y a rien à dessiner.
  @override
  Future<Waveform?> preparer(String cheminCapture) async {
    final dossier = Directory(cheminCapture);
    if (!dossier.existsSync()) return null;

    final fragments = _fragments(dossier);
    if (fragments.isEmpty) return null;

    final octets = fragments.fold<int>(0, (s, f) => s + f.lengthSync());
    final attendu = octets ~/ Waveform._octetsParPas +
        (octets % Waveform._octetsParPas == 0 ? 0 : 1);

    final cache = File('$cheminCapture/${Waveform.fichier}');
    if (cache.existsSync() && cache.lengthSync() == attendu) {
      return Waveform(cache.readAsBytesSync());
    }

    // Le calcul lit toute la matière — 173 Mo pour une heure et demie. Sur le
    // fil de l'interface, l'application se figerait pendant plusieurs secondes
    // à l'ouverture de l'éditeur ; l'isolat garde l'écran vivant, et l'attente
    // devient une barre de progression au lieu d'un gel.
    final cretes = await compute(_calculerDepuisLeDisque, cheminCapture);
    if (cretes.isEmpty) return null;

    // À côté puis renommer, comme partout ailleurs : un condensé tronqué que sa
    // taille dirait complet ferait dessiner une onde fausse.
    final provisoire = File('${cache.path}.part')..writeAsBytesSync(cretes);
    provisoire.renameSync(cache.path);

    return Waveform(cretes);
  }

  static List<File> _fragments(Directory dossier) => dossier
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.pcm'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

/// Le corps de l'isolat — hors classe, comme `compute` l'exige.
Uint8List _calculerDepuisLeDisque(String cheminCapture) {
  final fragments = FileWaveformDigest._fragments(Directory(cheminCapture));
  return Waveform.calculer(fragments.map((f) => f.readAsBytesSync()));
}

final waveformDigestProvider =
    Provider<WaveformDigest>((ref) => const FileWaveformDigest());
