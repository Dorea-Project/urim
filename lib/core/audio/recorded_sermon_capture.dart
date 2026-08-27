import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:urim/core/audio/sermon_capture.dart';
import 'package:urim/core/id/id_generator.dart';
import 'package:urim/core/id/id_generator_provider.dart';
import 'package:urim/core/time/clock.dart';
import 'package:urim/core/time/clock_provider.dart';

/// La capture réelle : le micro de l'appareil, des fragments sur l'appareil.
///
/// 🔴 **Rien ne part, et rien n'attend.** Pas d'envoi, pas de file, pas de
/// vérification de réseau avant d'ouvrir le micro — *« la capture n'est jamais
/// refusée »*. Le transport viendra après, et il aura le droit d'échouer : ce
/// qui est écrit ici sera toujours là.
///
/// ⚠️ **Des fragments, pas un fichier.** Un enregistrement de quarante minutes
/// dans un seul fichier n'est ni une unité de transport — F4 accumule pendant
/// les coupures — ni une unité de transcription. Et s'il se tronque, on perd le
/// culte entier au lieu d'une demi-minute.
///
/// ⚠️ **Le flux, pas le stop-and-go.** Fragmenter en arrêtant puis relançant
/// l'enregistreur coûterait un blanc à chaque frontière : sur quatre-vingts
/// fragments, plusieurs secondes de prédication perdues, invisibles et
/// irrécupérables. On lit donc le flux PCM et on le découpe soi-même : **la
/// coupe est comptable, pas acoustique**.
final class RecordedSermonCapture implements SermonCapture {
  RecordedSermonCapture({
    required Clock clock,
    required IdGenerator ids,
    AudioRecorder? recorder,
    Future<Directory> Function()? directory,
  })  : _clock = clock,
        _ids = ids,
        _recorder = recorder ?? AudioRecorder(),
        _directory = directory ?? getApplicationDocumentsDirectory;

  final Clock _clock;
  final IdGenerator _ids;
  final AudioRecorder _recorder;
  final Future<Directory> Function() _directory;

  CaptureInProgress? _current;
  StreamSubscription<Uint8List>? _flux;
  final BytesBuilder _tampon = BytesBuilder(copy: false);
  int _prochainFragment = 0;

  @override
  CaptureInProgress? get current => _current;

  @override
  Future<CaptureStart> start() async {
    if (_current case final CaptureInProgress encours) {
      // Toucher deux fois n'ouvre pas deux micros. On rend celui qui tourne
      // plutôt que d'échouer : le doigt a tremblé, la prédication continue.
      return CaptureRunning(encours);
    }

    try {
      if (!await _recorder.hasPermission()) {
        return const CaptureRefused(CaptureRefusal.micRefused);
      }
    } on Object {
      return const CaptureRefused(CaptureRefusal.noMicrophone);
    }

    final id = _ids.newId();
    final startedAt = _clock.now();

    try {
      final dossier = Directory(
        '${(await _directory()).path}/$sousDossier/${nomDeDossier(id, startedAt)}',
      )..createSync(recursive: true);

      final flux = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: CaptureFormat.sampleRate,
          numChannels: CaptureFormat.channels,
        ),
      );

      _prochainFragment = 0;
      _tampon.clear();
      _flux = flux.listen(
        (morceau) => _accumuler(dossier, morceau),
        // Une panne du micro n'efface pas ce qui est déjà écrit : les fragments
        // posés restent, et l'absence du témoin dira que ça s'est mal fini.
        onError: (Object _) {},
        cancelOnError: false,
      );

      final capture = CaptureInProgress(
        id: id,
        startedAt: startedAt,
        path: dossier.path,
      );
      _current = capture;

      return CaptureRunning(capture);
    } on FileSystemException {
      return const CaptureRefused(CaptureRefusal.storageFull);
    } on Object {
      return const CaptureRefused(CaptureRefusal.engineFailed);
    }
  }

  /// Le tampon se vide en fragments dès qu'il a de quoi en faire un.
  ///
  /// Écriture **synchrone** : quand la ligne rend la main, l'octet est sur le
  /// disque. Une écriture différée pourrait mourir avec l'application, et c'est
  /// exactement le moment où on ne veut rien perdre.
  void _accumuler(Directory dossier, Uint8List morceau) {
    _tampon.add(morceau);

    while (_tampon.length >= CaptureFormat.fragmentBytes) {
      final tout = _tampon.takeBytes();
      final plein = tout.sublist(0, CaptureFormat.fragmentBytes);
      final reste = tout.sublist(CaptureFormat.fragmentBytes);

      _ecrire(dossier, plein);
      _tampon.add(reste);
    }
  }

  /// ⚠️ **On écrit à côté, puis on renomme.** Le renommage est atomique ; une
  /// écriture ne l'est pas. Sans ce détour, la file d'envoi pourrait lire un
  /// fragment à moitié écrit et l'expédier tel quel — et l'additivité stricte
  /// (I24) interdit ensuite de le corriger. Un `.pcm` présent est donc
  /// **complet par construction**.
  void _ecrire(Directory dossier, List<int> octets) {
    if (octets.isEmpty) return;

    final nom = CaptureFormat.fragmentName(_prochainFragment);
    final brouillon = File('${dossier.path}/$nom${CaptureFormat.partSuffix}')
      ..writeAsBytesSync(octets, flush: true);

    brouillon.renameSync('${dossier.path}/$nom');
    _prochainFragment++;
  }

  @override
  Future<CapturedSermon?> stop() async {
    final encours = _current;
    if (encours == null) return null;

    _current = null;

    await _flux?.cancel();
    _flux = null;

    // ⚠️ **On rend la capture même si l'arrêt se passe mal.** Les fragments
    // sont déjà écrits ; perdre leur trace parce que la fermeture a bronché
    // serait exactement ce que la règle interdit.
    try {
      await _recorder.stop();
    } on Object {
      // Ce qui est sur le disque est sur le disque.
    }

    final dossier = Directory(encours.path);

    // Le fond du tampon devient un dernier fragment, plus court que les autres.
    _ecrire(dossier, _tampon.takeBytes());

    var octets = 0;
    try {
      // Le témoin d'arrêt propre. Son absence dira que ça s'est interrompu.
      File('${dossier.path}/${CaptureFormat.endMarker}').writeAsStringSync('');

      for (final entite in dossier.listSync()) {
        if (entite is File && entite.path.endsWith('.pcm')) {
          octets += entite.lengthSync();
        }
      }
    } on FileSystemException {
      // Le dossier a disparu sous nos pieds : on rend ce qu'on sait.
    }

    return CapturedSermon(
      id: encours.id,
      startedAt: encours.startedAt,
      duration: CaptureFormat.durationOf(octets),
      path: encours.path,
      fragments: _prochainFragment,
    );
  }

  static const String sousDossier = 'captures';

  /// `<id>_<millisecondes>` — le nom du dossier **porte la date de début**.
  ///
  /// C'est ce qui permet de savoir quand purger sans tenir de journal à côté :
  /// un index qui se désynchronise du disque ferait survivre un audio que
  /// l'application croit effacé.
  static String nomDeDossier(String id, DateTime startedAt) =>
      '${id}_${startedAt.millisecondsSinceEpoch}';
}

/// Le micro des prédications. Les tests le remplacent par une doublure.
final sermonCaptureProvider = Provider<SermonCapture>(
  (ref) => RecordedSermonCapture(
    clock: ref.watch(clockProvider),
    ids: ref.watch(idGeneratorProvider),
  ),
);
