import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/storage/local_documents.dart';
import 'package:urim/core/time/clock.dart';
import 'package:urim/core/time/clock_provider.dart';

/// Le dernier tour reçu, et la dernière liste du fil, gardés sur l'appareil.
///
/// **Pourquoi c'est nécessaire.** Chaque lecture rejoue les huit étages du
/// pipeline côté serveur : huit secondes mesurées en local, sans réseau. Sans
/// rien de gardé, ouvrir une préparation c'est huit secondes de blanc, et sans
/// réseau c'est un écran vide — le samedi soir, à Abidjan.
///
/// **Ce que ça garde, et pourquoi c'est le JSON brut.** Pas l'objet analysé :
/// le corps exact que le serveur a envoyé. Deux raisons. Il n'y a alors aucun
/// code de sérialisation à tenir d'accord avec le contrat — `studyFromWire`
/// reste le **seul** chemin d'analyse, celui que les tests éprouvent déjà sur
/// des charges réelles (D31). Et un champ ajouté demain côté serveur est gardé
/// aujourd'hui, sans que rien ne le sache.
///
/// **Ce que ça ne garde pas :** les gestes. Un tour gardé sert à lire, pas à
/// répondre. Répondre hors réseau est l'étape 3 de Q4, et demande une file.
final class TurnCacheLocalDataSource {
  const TurnCacheLocalDataSource({
    required LocalDocuments documents,
    required Clock clock,
  })  : _documents = documents,
        _clock = clock;

  final LocalDocuments _documents;
  final Clock _clock;

  static const String _prefixe = 'tour/';
  static const String _cleDuFil = 'fil';

  Future<void> writeStudy(String studyId, Map<String, dynamic> body) =>
      _write('$_prefixe$studyId', body);

  Future<CachedBody?> readStudy(String studyId) =>
      _read('$_prefixe$studyId');

  Future<void> writeFeed(List<dynamic> body) => _write(_cleDuFil, body);

  Future<CachedBody?> readFeed() => _read(_cleDuFil);

  /// Une préparation abandonnée, un compte quitté : le tour gardé n'a plus de
  /// raison d'être.
  Future<void> forgetStudy(String studyId) async {
    try {
      await _documents.delete('$_prefixe$studyId');
    } catch (_) {
      // Un tour qui ne s'efface pas sera simplement remplacé.
    }
  }

  /// Ne garde que les préparations qui sont encore au fil.
  ///
  /// Sans quoi le dossier grandit d'un tour par préparation ouverte à vie — et
  /// un tour réel pèse jusqu'à 27 ko.
  Future<void> keepOnly(Iterable<String> studyIds) async {
    final vivantes = studyIds.map((id) => '$_prefixe$id').toSet();

    try {
      for (final key in await _documents.keys()) {
        if (key.startsWith(_prefixe) && !vivantes.contains(key)) {
          await _documents.delete(key);
        }
      }
    } catch (_) {
      // Le ménage rate : le prochain passage le refera.
    }
  }

  /// ⚠️ **Rien ne lève ici**, même règle que les brouillons (D32) : un magasin
  /// local qui ne répond pas doit dégrader l'outil, jamais l'arrêter.
  Future<void> _write(String key, Object body) async {
    try {
      await _documents.write(
        key,
        jsonEncode({'at': _clock.now().toIso8601String(), 'body': body}),
      );
    } catch (_) {
      // On perd la copie locale, pas la réponse : elle est déjà à l'écran.
    }
  }

  Future<CachedBody?> _read(String key) async {
    final String? brut;
    try {
      brut = await _documents.read(key);
    } catch (_) {
      return null;
    }
    if (brut == null) return null;

    try {
      final json = jsonDecode(brut) as Map<String, dynamic>;
      final at = DateTime.tryParse(json['at'] as String? ?? '');
      final body = json['body'];
      if (at == null || body == null) return null;

      return CachedBody(body: body, at: at);
    } on FormatException {
      // Un fichier abîmé vaut un fichier absent : on repart du serveur.
      return null;
    }
  }
}

/// Un corps de réponse gardé, et l'heure où il est arrivé.
final class CachedBody {
  const CachedBody({required this.body, required this.at});

  /// Le JSON tel que le serveur l'a envoyé — objet pour une préparation, liste
  /// pour le fil.
  final Object body;

  final DateTime at;
}

final turnCacheProvider = Provider<TurnCacheLocalDataSource>(
  (ref) => TurnCacheLocalDataSource(
    documents: ref.watch(localDocumentsProvider),
    clock: ref.watch(clockProvider),
  ),
);
