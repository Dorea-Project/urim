import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:urim/core/audio/sermon_capture.dart';

/// Ce qui est capté, et ce qui doit disparaître.
///
/// 🔴 **Le disque fait foi, pas un journal.** Le nom du dossier porte
/// l'identifiant et le début ; les octets des fragments donnent la durée — le
/// PCM est à débit constant. Un index tenu à côté finirait par diverger du
/// disque, et la divergence irait dans le pire sens : une application qui croit
/// avoir effacé un audio qui est encore là.
final class CaptureStore {
  CaptureStore({Future<Directory> Function()? directory})
      : _directory = directory ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _directory;

  static const String sousDossier = 'captures';

  /// Les captures posées sur l'appareil, la plus récente en tête.
  Future<List<CapturedSermon>> list() async {
    final racine = await _racine();
    if (!racine.existsSync()) return const [];

    final captures = <CapturedSermon>[];

    for (final entite in racine.listSync()) {
      if (entite is! Directory) continue;

      final capture = _lire(entite);
      if (capture != null) captures.add(capture);
    }

    captures.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return captures;
  }

  /// Efface ce qui a dépassé ses sept jours, et rend ce qui est parti.
  ///
  /// ⚠️ **Échoue bruyamment.** Le domaine du serveur le dit pour son côté :
  /// *« une promesse de suppression qui échoue en silence est pire que pas de
  /// promesse »*. Ici, une suppression refusée remonte — elle ne se range pas
  /// sous un `catch` vide.
  Future<List<CapturedSermon>> purge({required DateTime now}) async {
    final partis = <CapturedSermon>[];

    for (final capture in await list()) {
      if (!capture.expired(now)) continue;

      Directory(capture.path).deleteSync(recursive: true);
      partis.add(capture);
    }

    return partis;
  }

  Future<Directory> _racine() async =>
      Directory('${(await _directory()).path}/$sousDossier');

  CapturedSermon? _lire(Directory dossier) {
    final nom = dossier.uri.pathSegments
        .where((segment) => segment.isNotEmpty)
        .last;

    final parties = nom.split('_');
    if (parties.length != 2) return null;

    final debut = int.tryParse(parties[1]);
    if (debut == null) return null;

    var octets = 0;
    var fragments = 0;
    var propre = false;

    for (final entite in dossier.listSync()) {
      if (entite is! File) continue;

      if (entite.path.endsWith('.pcm')) {
        octets += entite.lengthSync();
        fragments++;
      } else if (entite.path.endsWith(CaptureFormat.endMarker)) {
        propre = true;
      }
    }

    // Un dossier sans fragment n'est pas une capture : c'est un micro qui n'a
    // jamais rendu un octet. Le montrer ferait croire à un enregistrement.
    if (fragments == 0) return null;

    return CapturedSermon(
      id: parties[0],
      startedAt: DateTime.fromMillisecondsSinceEpoch(debut),
      duration: CaptureFormat.durationOf(octets),
      path: dossier.path,
      fragments: fragments,
      // Pas de témoin d'arrêt : l'application est morte en cours de route.
      // 🔴 La capture **apparaît quand même** — la faire disparaître serait le
      // pire des silences, le pasteur croyait avoir enregistré.
      interrupted: !propre,
    );
  }
}

final captureStoreProvider = Provider<CaptureStore>((ref) => CaptureStore());
