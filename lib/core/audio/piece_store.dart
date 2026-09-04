import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:urim/core/audio/piece_cutter.dart';
import 'package:urim/domain/entities/transcription/sermon_piece.dart';

/// Où vivent les pièces — **et pourquoi elles ne vivent pas comme les captures**.
///
/// 🔴 **`CaptureStore` refuse un index tenu à côté du disque, et il a raison
/// pour lui.** Sa règle — *le disque fait foi, pas un journal* — protège une
/// promesse de suppression : une application qui croit avoir effacé un audio
/// encore présent ment sur quelque chose de grave. **Cette promesse n'existe pas
/// ici** : une pièce ne s'efface pas au septième jour, elle vit avec sa
/// publication. Le risque que la règle écarte n'est pas au rendez-vous.
///
/// Et une chose interdit le chemin de `CaptureStore` : **le titre est du texte
/// libre**, écrit par le pasteur. « La prière pour les malades » ne rentre pas
/// dans un nom de fichier sans qu'on le mutile, et un titre mutilé est un nom
/// mal écrit rendu à celui qui l'a choisi.
///
/// D'où un compagnon JSON à côté de l'audio, comme pour les pistes :
///
/// ```
/// pieces/<id>.wav     les octets, écrits par PieceCutter
/// pieces/<id>.json    le titre, la capture d'origine, les bornes
/// ```
///
/// ⚠️ **L'audio reste le juge.** Un compagnon dont le `.wav` a disparu ne rend
/// pas de pièce : mieux vaut n'en montrer aucune que d'en offrir une qui ne se
/// jouera pas.
final class PieceStore {
  PieceStore({Future<Directory> Function()? directory})
      : _directory = directory ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _directory;

  /// Le même dossier que le tailleur écrit — **jamais `captures`**, que la purge
  /// des sept jours balaie.
  static String get sousDossier => PieceCutter.sousDossier;

  /// Les pièces tirées d'un culte, la plus récemment taillée en tête.
  Future<List<SermonPiece>> forCapture(String captureId) async {
    final pieces = await all();
    return pieces.where((p) => p.captureId == captureId).toList();
  }

  /// Toutes les pièces, la plus récente en tête.
  ///
  /// ⚠️ **Elles survivent à leur capture.** Une pièce taillée d'un culte purgé
  /// reste listée — c'est tout l'intérêt — et son `captureId` désigne alors un
  /// dossier qui n'existe plus. Aucun appelant ne doit supposer le contraire.
  Future<List<SermonPiece>> all() async {
    final racine = await _racine();
    if (!racine.existsSync()) return const [];

    final pieces = <SermonPiece>[];

    for (final entite in racine.listSync()) {
      if (entite is! File || !entite.path.endsWith('.json')) continue;

      final piece = _lire(entite, racine);
      if (piece != null) pieces.add(piece);
    }

    pieces.sort((a, b) => b.cutAt.compareTo(a.cutAt));
    return pieces;
  }

  /// Range une pièce. **Ne touche pas à l'audio** — le tailleur l'a déjà écrit.
  Future<void> save(SermonPiece piece) async {
    final dossier = await _racine();
    dossier.createSync(recursive: true);

    File('${dossier.path}/${piece.id}.json').writeAsStringSync(
      jsonEncode({
        'capture': piece.captureId,
        'titre': piece.title,
        'debut_ms': piece.start.inMilliseconds,
        'fin_ms': piece.end.inMilliseconds,
        'taillee_a': piece.cutAt.toIso8601String(),
      }),
    );
  }

  /// Change le titre, et rien d'autre.
  ///
  /// Rend `false` si la pièce n'existe plus — un écran qui renomme un fantôme
  /// doit l'apprendre plutôt que de croire à un succès muet.
  Future<bool> renommer(String id, String titre) async {
    final pieces = await all();
    final piece = pieces.where((p) => p.id == id).cast<SermonPiece?>().firstOrNull;
    if (piece == null || titre.trim().isEmpty) return false;

    await save(piece.renommee(titre.trim()));
    return true;
  }

  /// Retire une pièce — l'audio **et** son compagnon.
  ///
  /// 🔴 **C'est le seul effacement de ce magasin, et il est explicite.** Rien
  /// ici n'expire : une pièce ne part que si le pasteur le demande.
  Future<void> remove(String id) async {
    final dossier = await _racine();

    for (final nom in ['$id.json', '$id.wav']) {
      final fichier = File('${dossier.path}/$nom');
      if (fichier.existsSync()) fichier.deleteSync();
    }
  }

  Future<Directory> _racine() async =>
      Directory('${(await _directory()).path}/$sousDossier');

  SermonPiece? _lire(File compagnon, Directory racine) {
    final id = compagnon.uri.pathSegments.last.replaceAll('.json', '');
    final audio = File('${racine.path}/$id.wav');

    // ⚠️ Un compagnon orphelin n'est pas une pièce. L'offrir à l'écoute
    // promettrait un son qui n'existe plus.
    if (!audio.existsSync() || audio.lengthSync() == 0) return null;

    try {
      final json = jsonDecode(compagnon.readAsStringSync());
      if (json is! Map<String, dynamic>) return null;

      final capture = json['capture'];
      final titre = json['titre'];
      final debut = json['debut_ms'];
      final fin = json['fin_ms'];
      final quand = DateTime.tryParse(json['taillee_a']?.toString() ?? '');

      if (capture is! String || titre is! String || titre.isEmpty) return null;
      if (debut is! int || fin is! int || quand == null) return null;

      return SermonPiece(
        id: id,
        captureId: capture,
        title: titre,
        start: Duration(milliseconds: debut),
        end: Duration(milliseconds: fin),
        path: audio.path,
        cutAt: quand,
      );
    } on FormatException {
      // Un compagnon illisible ne fait pas tomber l'écran : la pièce n'existe
      // simplement pas pour lui.
      return null;
    }
  }
}

final pieceStoreProvider = Provider<PieceStore>((ref) => PieceStore());

/// Les pièces d'un culte, pour l'écran qui les liste.
final piecesDeLaCaptureProvider =
    FutureProvider.family<List<SermonPiece>, String>(
  (ref, captureId) => ref.watch(pieceStoreProvider).forCapture(captureId),
);
