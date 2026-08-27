import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:urim/core/audio/sermon_capture.dart';

/// Ce qui emporte un fragment ailleurs.
///
/// Interface, parce que le transport n'existe pas encore : le serveur porte le
/// domaine de la capture mais **aucune route**. La file, elle, peut être écrite,
/// éprouvée et remplie dès aujourd'hui — c'est le sens de F4, où les fragments
/// s'accumulent pendant les coupures.
abstract interface class FragmentSender {
  /// Emporte un fragment. Rend vrai si le serveur l'a **accusé**.
  ///
  /// Ne lève jamais : une panne de réseau est l'ordinaire de ce métier, pas une
  /// exception. Rendre `false` suffit — le fragment reste sur le disque et
  /// repartira.
  Future<bool> send({
    required String captureId,
    required int index,
    required List<int> bytes,
  });
}

/// Combien reste-t-il à emporter, pour une capture.
final class OutboxStatus {
  const OutboxStatus({
    required this.captureId,
    required this.startedAt,
    required this.path,
    required this.sent,
    required this.total,
  });

  final String captureId;

  /// Le début de la capture — c'est **lui** qui ordonne la file.
  ///
  /// 🔴 Trier sur le chemin triait sur l'identifiant, et l'identifiant ne dit
  /// rien de l'échéance : une capture nommée « a… » passait devant une capture
  /// de la semaine dernière nommée « z… », à un jour de sa purge.
  final DateTime startedAt;

  final String path;

  /// Le nombre de fragments déjà accusés par le serveur.
  final int sent;

  /// Le nombre de fragments posés sur le disque.
  final int total;

  int get pending => total - sent;
  bool get complete => pending == 0;
}

/// La file d'envoi — **le disque, encore une fois**.
///
/// 🔴 **Rien ici ne touche le chemin de la capture.** C5 l'interdit : aucun
/// étage local ne doit dépendre du réseau pour s'exécuter une première fois. Le
/// micro écrit ; la file lit ce qui est écrit, quand elle peut. Les deux ne se
/// croisent jamais, et c'est ce qui rend la promesse tenable — *« la capture
/// n'est jamais refusée »*.
///
/// **Une marque haute suffit.** Les fragments sont numérotés et partent dans
/// l'ordre : un seul entier — combien ont été accusés — dit tout ce qu'il y a à
/// savoir. Un journal par fragment finirait par diverger du disque, et la
/// divergence irait dans le pire sens : croire envoyé ce qui ne l'est pas.
///
/// **Un échec ne perd rien.** Le fragment reste, la marque n'avance pas, et le
/// prochain passage reprend exactement là.
final class FragmentOutbox {
  FragmentOutbox({
    required FragmentSender sender,
    Future<Directory> Function()? directory,
  })  : _sender = sender,
        _directory = directory ?? getApplicationDocumentsDirectory;

  final FragmentSender _sender;
  final Future<Directory> Function() _directory;

  static const String sousDossier = 'captures';

  /// Le fichier qui porte la marque haute, dans le dossier de la capture.
  static const String marque = 'envoi';

  /// Ce qui reste à emporter, capture par capture, la plus ancienne d'abord.
  ///
  /// ⚠️ **La plus ancienne d'abord, et non la plus récente.** Un culte capté il
  /// y a six jours est à un jour de sa purge : s'il ne part pas maintenant, il ne
  /// partira jamais. Celui de ce matin a une semaine devant lui.
  Future<List<OutboxStatus>> pending() async {
    final racine = await _racine();
    if (!racine.existsSync()) return const [];

    final etats = <OutboxStatus>[];

    for (final entite in racine.listSync()) {
      if (entite is! Directory) continue;

      final etat = _lire(entite);
      if (etat != null && !etat.complete) etats.add(etat);
    }

    etats.sort((a, b) => a.startedAt.compareTo(b.startedAt));
    return etats;
  }

  /// Emporte ce qui peut l'être, et rend le nombre de fragments accusés.
  ///
  /// S'arrête à la première capture qui refuse d'avancer : les fragments d'une
  /// même capture partent **dans l'ordre**, et insister sur une file bloquée
  /// pendant qu'une autre attend ferait mentir la marque haute.
  Future<int> flush() async {
    var accuses = 0;

    for (final etat in await pending()) {
      accuses += await _vider(etat);
    }

    return accuses;
  }

  Future<int> _vider(OutboxStatus etat) async {
    var envoyes = etat.sent;

    for (var index = etat.sent; index < etat.total; index++) {
      final fragment = File(
        '${etat.path}/${CaptureFormat.fragmentName(index)}',
      );
      if (!fragment.existsSync()) break;

      final accuse = await _sender.send(
        captureId: etat.captureId,
        index: index,
        bytes: fragment.readAsBytesSync(),
      );

      // Le réseau a lâché, ou le serveur a refusé : on s'arrête **ici**, sans
      // sauter le fragment. Le prochain passage reprendra à celui-ci.
      if (!accuse) break;

      envoyes = index + 1;
      _poserMarque(etat.path, envoyes);
    }

    return envoyes - etat.sent;
  }

  /// La marque s'écrit **après** l'accusé, jamais avant.
  ///
  /// Dans l'autre ordre, une application tuée entre les deux laisserait un
  /// fragment marqué envoyé qui ne l'est pas — et il ne repartirait jamais.
  /// Ainsi, le pire qui puisse arriver est un fragment envoyé deux fois, ce que
  /// le serveur sait absorber : l'additivité stricte (I24) est faite pour ça.
  void _poserMarque(String dossier, int compte) {
    File('$dossier/$marque').writeAsStringSync('$compte', flush: true);
  }

  Future<Directory> _racine() async =>
      Directory('${(await _directory()).path}/$sousDossier');

  OutboxStatus? _lire(Directory dossier) {
    final nom =
        dossier.uri.pathSegments.where((segment) => segment.isNotEmpty).last;

    final parties = nom.split('_');
    if (parties.length != 2) return null;

    final debut = int.tryParse(parties[1]);
    if (debut == null) return null;

    var total = 0;
    var sent = 0;

    for (final entite in dossier.listSync()) {
      if (entite is! File) continue;

      if (entite.path.endsWith('.pcm')) {
        total++;
      } else if (entite.path.endsWith(marque)) {
        sent = int.tryParse(entite.readAsStringSync().trim()) ?? 0;
      }
    }

    if (total == 0) return null;

    return OutboxStatus(
      captureId: parties[0],
      startedAt: DateTime.fromMillisecondsSinceEpoch(debut),
      path: dossier.path,
      // Une marque plus haute que ce que le disque porte est une marque
      // corrompue : on la ramène au réel plutôt que de sauter des fragments.
      sent: sent.clamp(0, total),
      total: total,
    );
  }
}

/// La file d'envoi. **Sans destination pour l'instant** : le serveur porte le
/// domaine de la capture et aucune route. Elle se remplit, elle ne se vide pas
/// encore — et ce qu'elle garde ne se perd pas.
final fragmentOutboxProvider = Provider<FragmentOutbox>(
  (ref) => FragmentOutbox(sender: const _SansDestination()),
);

final class _SansDestination implements FragmentSender {
  const _SansDestination();

  @override
  Future<bool> send({
    required String captureId,
    required int index,
    required List<int> bytes,
  }) async =>
      false;
}
