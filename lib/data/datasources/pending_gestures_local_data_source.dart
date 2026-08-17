import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/storage/local_documents.dart';
import 'package:urim/core/time/clock.dart';
import 'package:urim/core/time/clock_provider.dart';
import 'package:urim/domain/entities/preparation/pending_gesture.dart';

/// Les gestes faits sans réseau, en attente d'être envoyés.
///
/// **Ce que cette file ne fait pas, et ne fera jamais : simuler le moteur.**
/// Décider hors réseau ne peut pas afficher le tour suivant — seul le pipeline
/// sait ce qu'il répondra, et fabriquer une phrase côté client est précisément
/// ce que D29 interdit. La file garde donc le **geste**, pour qu'il ne soit pas
/// perdu, et le tour arrive quand le réseau revient.
///
/// **Pourquoi rejouer dans l'ordre suffit.** Les décisions se périment en
/// cascade côté serveur : décider un étage amont invalide mécaniquement ce qui
/// en dépendait. Rejouer la file dans l'ordre d'émission donne donc le même
/// état que si les gestes avaient été faits en ligne — aucun code de fusion à
/// écrire. C'est le modèle de D28 qui rend ça possible : s'il y avait un
/// historique de phrases à réconcilier, il faudrait l'inverse.
///
/// **Une file courte, et bornée par la nature des choses.** Tous les gestes en
/// attente portent sur le **même tour**, puisqu'on ne peut pas agir sur un tour
/// qu'on n'a pas reçu : plusieurs rejets, et au plus une décision.
final class PendingGesturesLocalDataSource {
  const PendingGesturesLocalDataSource({
    required LocalDocuments documents,
    required Clock clock,
  })  : _documents = documents,
        _clock = clock;

  final LocalDocuments _documents;
  final Clock _clock;

  static const String _prefixe = 'gestes/';

  /// Les gestes en attente pour cette préparation, dans l'ordre d'émission.
  Future<List<PendingGesture>> read(String studyId) async {
    final String? brut;
    try {
      brut = await _documents.read('$_prefixe$studyId');
    } catch (_) {
      return const [];
    }
    if (brut == null) return const [];

    try {
      return [
        for (final item in jsonDecode(brut) as List<dynamic>)
          PendingGesture.fromJson(item as Map<String, dynamic>),
      ];
    } catch (_) {
      // Une file illisible ne doit pas bloquer la préparation. On la perd —
      // c'est un geste, pas une phrase écrite par le pasteur.
      return const [];
    }
  }

  Future<void> append(String studyId, PendingGesture geste) async {
    final file = [...await read(studyId), geste.at(_clock.now())];

    try {
      await _documents.write(
        '$_prefixe$studyId',
        jsonEncode([for (final g in file) g.toJson()]),
      );
    } catch (_) {
      // Le geste est perdu, mais il était de toute façon impossible à envoyer.
    }
  }

  Future<void> clear(String studyId) async {
    try {
      await _documents.delete('$_prefixe$studyId');
    } catch (_) {
      // Une file qui ne s'efface pas serait rejouée deux fois. Décider et
      // écarter posent un état : les rejouer donne le même résultat.
    }
  }

  /// Les préparations qui ont des gestes en attente.
  Future<List<String>> studies() async {
    try {
      return [
        for (final key in await _documents.keys())
          if (key.startsWith(_prefixe)) key.substring(_prefixe.length),
      ];
    } catch (_) {
      return const [];
    }
  }
}

final pendingGesturesProvider = Provider<PendingGesturesLocalDataSource>(
  (ref) => PendingGesturesLocalDataSource(
    documents: ref.watch(localDocumentsProvider),
    clock: ref.watch(clockProvider),
  ),
);
