import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Capter la prédication — **l'étage 1, et rien de plus**.
///
/// ⚠️ **Ceci n'est pas la dictée.** `Dictation` écrit dans un champ à la place
/// des doigts : l'audio ne devient jamais un document, aucune file ne s'ouvre.
/// Ici, l'audio **est** le document : il vit sept jours sur l'appareil, il porte
/// une durée, et c'est de lui que sortira un jour un transcript. Les deux gestes
/// partagent un micro, pas un problème.
///
/// 🔴 **La règle qui gouverne tout ce fichier**, et elle vient du domaine du
/// serveur : *« la capture n'est jamais refusée — ce qui n'est pas capté
/// dimanche est perdu pour toujours ; c'est la transcription qui est
/// différée. »* Tout ce qui suit en découle : on n'attend pas le réseau, on ne
/// demande pas à quelle préparation rattacher, on n'oppose aucun plafond. On
/// capte, on rattachera après.
///
/// Interface plutôt qu'appel direct au greffon, pour la raison habituelle : un
/// micro ne répond que sur un vrai appareil, et le brancher en dur rendrait
/// l'écran d'accueil intestable.
abstract interface class SermonCapture {
  /// Ouvre le micro et commence à écrire.
  ///
  /// Ne lève jamais : un refus est une réponse, pas une panne. C'est à
  /// l'appelant de dire au pasteur ce qui manque.
  Future<CaptureStart> start();

  /// Ferme le micro et rend ce qui a été capté.
  ///
  /// Rend `null` si rien n'était en cours — arrêter deux fois n'est pas une
  /// erreur, c'est un doigt qui a tremblé.
  Future<CapturedSermon?> stop();

  /// Ce qui est en cours, ou nul.
  ///
  /// Sert au bandeau qui traverse l'application : il doit pouvoir dire depuis
  /// combien de temps on enregistre sans que l'écran ait à le compter.
  CaptureInProgress? get current;

  /// 🔴 **La preuve que le micro entend** — A2.
  ///
  /// L'écran de capture était muet : un chronomètre qui avance, et rien
  /// d'autre. Or un chronomètre avance aussi quand le micro est coupé, quand
  /// une housse le bouche, quand une autre application l'a pris. Le pasteur ne
  /// l'apprenait qu'après le culte, sur un fichier vide — et *ce qui n'est pas
  /// capté dimanche est perdu pour toujours*.
  ///
  /// ⚠️ **Un flux, jamais un état interrogeable.** Un niveau qu'on relit à la
  /// demande serait faux entre deux lectures ; ce qui rassure est le mouvement,
  /// pas la valeur.
  Stream<CaptureSignal> get signal;
}

/// Ce que le micro entend, à l'instant.
final class CaptureSignal {
  const CaptureSignal({required this.level, required this.fragments});

  /// Le niveau, de 0 à 1 — **une crête, pas une moyenne**.
  ///
  /// Une moyenne sur trente secondes de prédication reste plate : les silences
  /// entre les phrases la tirent vers le bas, et la barre ne bougerait plus.
  /// C'est le mouvement qui dit que ça entend.
  final double level;

  /// Combien de fragments sont **posés sur le disque**.
  ///
  /// ⚠️ Pas « enregistrés » : écrits, atomiquement, et donc survivants à une
  /// application tuée. C'est le seul nombre qui compte pour le pasteur.
  final int fragments;
}

/// Le format de la capture — **choisi pour ce qui le lira**.
///
/// 🔴 **16 kHz, mono, PCM 16 bits : c'est exactement ce que Whisper mange.**
/// Ni rééchantillonnage, ni décodage entre l'étage 1 et l'étage 2. De l'AAC
/// aurait pesé quatre fois moins — et il aurait fallu le décoder pour le
/// transcrire, sur le téléphone, en plus du modèle.
///
/// Le prix est réel et il faut le dire : **32 ko par seconde**, soit environ
/// 77 Mo pour quarante minutes, contre 19 en AAC. C'est ce que coûte un audio
/// qui se transcrit sans intermédiaire, et il ne vit que sept jours.
abstract final class CaptureFormat {
  const CaptureFormat._();

  static const int sampleRate = 16000;
  static const int channels = 1;

  /// 16 000 échantillons de 2 octets par seconde.
  static const int bytesPerSecond = sampleRate * 2 * channels;

  /// La taille d'un fragment.
  ///
  /// ⚠️ **Trente secondes, et ce n'est pas un chiffre rond au hasard.** C'est
  /// la fenêtre de Whisper : un fragment se transcrit d'une passe, sans être
  /// recoupé. C'est aussi ce qu'on accepte de perdre si l'application meurt au
  /// mauvais moment — une demi-minute de prédication, jamais le culte.
  static const Duration fragment = Duration(seconds: 30);

  static int get fragmentBytes => bytesPerSecond * fragment.inSeconds;

  /// La durée se **calcule** : le PCM est à débit constant, donc les octets
  /// disent le temps. Rien à stocker à côté, rien qui puisse diverger.
  static Duration durationOf(int bytes) =>
      Duration(milliseconds: bytes * 1000 ~/ bytesPerSecond);

  /// Le chemin inverse — **et il s'aligne sur l'échantillon, toujours**.
  ///
  /// 🔴 **Un échantillon fait deux octets, et une coupe impaire les décale
  /// tous.** Chaque paire d'octets serait lue à cheval sur deux échantillons :
  /// la sortie ne serait pas décalée d'un poil, elle serait du bruit blanc à la
  /// place de la parole. C'est la seule façon de se tromper silencieusement ici
  /// — le fichier aurait la bonne taille, la bonne durée, et ne contiendrait
  /// rien d'audible. On arrondit donc **vers le bas**, jamais vers le haut :
  /// mieux vaut un millième de seconde en moins que le premier échantillon
  /// coupé en deux.
  static int bytesOf(Duration position) {
    final brut = position.inMilliseconds * bytesPerSecond ~/ 1000;
    return brut - (brut % 2);
  }

  static const int wavHeaderBytes = 44;

  /// L'en-tête WAV canonique — **quarante-quatre octets, et rien de plus**.
  ///
  /// 🔴 **Le PCM brut ne se joue pas.** Aucun lecteur du téléphone ne sait
  /// ouvrir un fragment : rien dedans ne dit la fréquence, le nombre de canaux
  /// ni la profondeur. Cet en-tête ne convertit rien et ne perd rien — il décrit
  /// ce que la capture est déjà. **Le WAV n'est pas un autre format, c'est le
  /// même PCM avec sa carte d'identité devant.**
  ///
  /// ⚠️ **Il vit ici, avec le format qu'il décrit, parce que deux écrivains s'en
  /// servent** — la réécoute d'un culte entier et le découpage d'une pièce. Deux
  /// copies de quarante lignes d'octets finiraient par diverger, et la panne
  /// serait un fichier illisible qu'aucun test de logique n'attraperait.
  static Uint8List wavHeader(int octetsAudio) {
    final entete = ByteData(wavHeaderBytes);
    var i = 0;

    void ascii(String texte) {
      for (final unite in texte.codeUnits) {
        entete.setUint8(i++, unite);
      }
    }

    void u32(int valeur) {
      entete.setUint32(i, valeur, Endian.little);
      i += 4;
    }

    void u16(int valeur) {
      entete.setUint16(i, valeur, Endian.little);
      i += 2;
    }

    const bits = 16;

    ascii('RIFF');
    u32(36 + octetsAudio); // tout ce qui suit ces quatre octets
    ascii('WAVE');
    ascii('fmt ');
    u32(16); // longueur du bloc de format, PCM
    u16(1); // 1 = PCM non compressé
    u16(channels);
    u32(sampleRate);
    u32(bytesPerSecond);
    u16(channels * bits ~/ 8); // alignement d'un échantillon
    u16(bits);
    ascii('data');
    u32(octetsAudio);

    return entete.buffer.asUint8List();
  }

  /// `0000.pcm`, `0001.pcm`… — l'ordre est dans le nom, et il se trie.
  static String fragmentName(int index) =>
      '${index.toString().padLeft(4, '0')}.pcm';

  /// Le suffixe d'un fragment en cours d'écriture.
  ///
  /// Il ne survit jamais à la ligne qui l'écrit : on écrit dessous, puis on
  /// renomme. Ce qui porte ce suffixe sur le disque est le reste d'une
  /// application morte au mauvais moment — et ce n'est **pas** un fragment.
  static const String partSuffix = '.part';

  /// Le témoin d'un arrêt propre. Son **absence** dit que la capture s'est
  /// interrompue toute seule.
  static const String endMarker = 'fin';

  /// L'assemblée devant laquelle ce culte a été prêché.
  ///
  /// 🔴 **Elle vit avec la capture, pas avec le pasteur.** Un profil porterait
  /// « son » église ; or dix pasteurs desservent sept assemblées, et celui qui
  /// en dessert deux prêche dans **l'une** d'elles ce dimanche-là. Une valeur
  /// par défaut serait fausse une fois sur deux, et fausse en silence.
  ///
  /// ⚠️ **Elle s'écrit à l'arrêt, jamais au démarrage.** *Rien ne s'interpose*
  /// entre le pasteur et son micro : on ne lui demande pas où il est pendant
  /// qu'il monte en chaire. On le lui demande une fois le culte fini, s'il y a
  /// lieu de le demander.
  ///
  /// Son absence n'est pas une erreur — c'est une capture qui n'a pas encore
  /// trouvé son assemblée, et qui attend plutôt que de partir au hasard.
  static const String churchMarker = 'eglise';

  /// Le titre que le pasteur donne à son culte.
  ///
  /// 🔴 **Une date n'est pas un nom.** Trois cultes du même mois se lisent
  /// « sam. 29 août », « dim. 30 août », « dim. 6 septembre » — et au bout de
  /// quatre dimanches, plus personne ne sait lequel portait quoi. Le pasteur
  /// doit pouvoir écrire « Nouvelle naissance » ou « Actes 2, matin ».
  ///
  /// ⚠️ **Facultatif, et il le reste.** Son absence n'est pas un défaut : la
  /// date suffit le jour même. Le réclamer à l'arrêt du micro serait un geste
  /// de plus au moment précis où *rien ne doit s'interposer*.
  static const String titleMarker = 'titre';
}

/// Ce que rend l'ouverture du micro.
sealed class CaptureStart {
  const CaptureStart();
}

/// Le micro est ouvert.
final class CaptureRunning extends CaptureStart {
  const CaptureRunning(this.capture);

  final CaptureInProgress capture;
}

/// Le micro n'a pas pu s'ouvrir, et on dit pourquoi.
final class CaptureRefused extends CaptureStart {
  const CaptureRefused(this.reason);

  final CaptureRefusal reason;
}

/// Pourquoi la capture n'a pas commencé.
///
/// Trois causes, trois phrases différentes à l'écran : « refusé » tout court
/// laisse le pasteur devant un bouton mort sans savoir quoi faire.
enum CaptureRefusal {
  /// L'autorisation du micro n'a pas été donnée — ou a été retirée.
  micRefused,

  /// L'appareil n'a pas de quoi enregistrer.
  noMicrophone,

  /// Plus de place pour écrire l'audio.
  ///
  /// ⚠️ Le seul refus qui ne vient pas d'un choix. Il doit dire **combien**
  /// libérer, pas seulement que c'est plein.
  storageFull,

  /// Le moteur d'enregistrement a rendu la main sans raison exploitable.
  engineFailed,
}

/// Une capture en cours.
final class CaptureInProgress extends Equatable {
  const CaptureInProgress({
    required this.id,
    required this.startedAt,
    required this.path,
  });

  final String id;
  final DateTime startedAt;

  /// Le nom que le pasteur lui a donné, ou nul.
  ///
  /// Nul veut dire *pas encore nommé* — jamais *sans importance*. L'écran
  /// retombe alors sur la date, qui est vraie mais muette.

  /// Le **dossier** en train de se remplir. Sur l'appareil, jamais ailleurs.
  final String path;

  /// Depuis combien de temps on enregistre, à [now].
  Duration elapsed(DateTime now) => now.difference(startedAt);

  @override
  List<Object?> get props => [id, startedAt, path];
}

/// Une prédication captée, posée sur l'appareil.
final class CapturedSermon extends Equatable {
  const CapturedSermon({
    required this.id,
    required this.startedAt,
    required this.duration,
    required this.path,
    required this.fragments,
    this.interrupted = false,
    this.title,
  });

  final String id;
  final DateTime startedAt;
  final Duration duration;

  /// Le **dossier** de la capture, pas un fichier : elle est faite de fragments.
  final String path;

  /// Combien de fragments elle porte.
  final int fragments;

  /// L'enregistrement s'est arrêté sans qu'on le lui demande — application
  /// tuée, batterie vide, appel entrant qui a tout emporté.
  ///
  /// 🔴 **Il apparaît quand même.** Le domaine du serveur tient la même règle
  /// pour les transcripts : *« un travail abandonné laisse le transcript en
  /// `partielle` — jamais un silence »*. Une capture qui disparaît parce
  /// qu'elle s'est mal terminée est exactement ce qu'un pasteur ne pardonnera
  /// pas : il croyait avoir enregistré.
  final bool interrupted;

  /// Le nom que le pasteur lui a donné, ou nul.
  ///
  /// 🔴 **Une date n'est pas un nom.** Quatre dimanches se lisent « dim. 30
  /// août », « dim. 6 septembre »… et plus personne ne sait lequel portait quoi.
  ///
  /// Nul veut dire *pas encore nommé*, jamais *sans importance* : l'écran
  /// retombe sur la date, qui est vraie mais muette.
  final String? title;

  /// Le jour où l'audio doit disparaître.
  ///
  /// ⚠️ **Sept jours, et la promesse se tient bruyamment.** Le domaine du
  /// serveur l'écrit pour son côté : *« une promesse de suppression qui échoue
  /// en silence est pire que pas de promesse. »* Côté appareil, la même règle —
  /// et l'écran affiche le compte à rebours pour que la disparition ne
  /// surprenne personne.
  static const Duration retention = Duration(days: 7);

  DateTime get purgeAt => startedAt.add(retention);

  /// L'audio a-t-il dépassé son échéance à [now] ?
  bool expired(DateTime now) => !now.isBefore(purgeAt);

  @override
  List<Object?> get props =>
      [id, startedAt, duration, path, fragments, interrupted, title];
}
