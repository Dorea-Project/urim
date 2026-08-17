import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/storage/local_documents.dart';
import 'package:urim/core/time/clock.dart';
import 'package:urim/core/time/clock_provider.dart';

/// Ce que le pasteur est en train d'écrire, retenu sur l'appareil.
///
/// **La seule faute que cet outil n'a pas le droit de commettre est de perdre
/// les phrases d'un homme.** Un appel entrant, une batterie vide, un système
/// qui referme l'application : aujourd'hui ce qui est tapé ne vit que dans un
/// contrôleur de saisie et disparaît avec lui.
///
/// Ce n'est pas un cache — un cache accélère une chose qu'on peut refaire.
/// C'est une **avance d'écriture** : le texte est posé ici *avant* de partir au
/// serveur, et n'est effacé qu'une fois que le serveur l'a accusé. Entre les
/// deux, l'appareil est la seule copie qui existe.
final class DraftLocalDataSource {
  DraftLocalDataSource({required LocalDocuments documents, required Clock clock})
      : _documents = documents,
        _clock = clock;

  final LocalDocuments _documents;
  final Clock _clock;

  static const String _prefixe = 'brouillon/';

  /// Le brouillon de la barre de saisie d'une préparation.
  static String composerKey(String studyId) => '${_prefixe}saisie/$studyId';

  /// Celui du formulaire d'ouverture, qui n'a pas encore d'identifiant.
  static const String ouvertureKey = '${_prefixe}ouverture';

  /// ⚠️ **Aucune de ces trois méthodes ne lève.**
  ///
  /// Perdre un brouillon est grave ; empêcher un pasteur d'ouvrir sa
  /// préparation parce que le magasin local ne répond pas serait plus grave
  /// encore. Un disque plein, un répertoire refusé, un greffon absent : l'outil
  /// continue, dégradé, et c'est le bon arbitrage. La contrepartie est que
  /// l'appelant ne doit **jamais** faire dépendre un geste de leur succès.
  Future<Draft?> read(String key) async {
    final String? brut;
    try {
      brut = await _documents.read(key);
    } catch (_) {
      return null;
    }
    if (brut == null) return null;

    try {
      final json = jsonDecode(brut) as Map<String, dynamic>;
      return Draft(
        text: json['text'] as String? ?? '',
        at: DateTime.tryParse(json['at'] as String? ?? '') ?? _clock.now(),
      );
    } on FormatException {
      // Un brouillon illisible vaut un brouillon absent : l'écran s'ouvre, et
      // l'ancien contenu est perdu plutôt que de faire échouer l'ouverture.
      return null;
    }
  }

  Future<void> write(String key, String text) async {
    if (text.trim().isEmpty) return delete(key);

    try {
      await _documents.write(
        key,
        jsonEncode({'text': text, 'at': _clock.now().toIso8601String()}),
      );
    } catch (_) {
      // Rien à faire de plus : la phrase est encore sous les yeux du pasteur.
    }
  }

  Future<void> delete(String key) async {
    try {
      await _documents.delete(key);
    } catch (_) {
      // Un brouillon qui ne s'efface pas reparaîtra une fois. C'est tout.
    }
  }

  /// Les brouillons oubliés — une préparation supprimée ailleurs, une saisie
  /// abandonnée il y a des mois.
  ///
  /// Balayer n'est pas une politique de rétention : c'est éviter qu'un dossier
  /// grandisse sans fin. Le seuil est large **exprès** — un pasteur qui reprend
  /// une préparation trois semaines plus tard doit retrouver sa phrase.
  Future<void> sweep({Duration keepFor = const Duration(days: 90)}) async {
    final limite = _clock.now().subtract(keepFor);

    final List<String> presentes;
    try {
      presentes = await _documents.keys();
    } catch (_) {
      return;
    }

    for (final key in presentes) {
      if (!key.startsWith(_prefixe)) continue;

      final brouillon = await read(key);
      if (brouillon != null && brouillon.at.isBefore(limite)) {
        await delete(key);
      }
    }
  }
}

/// Un brouillon, et **quand** il a été écrit.
///
/// L'heure n'est pas décorative : elle permet de dire au pasteur « voici ce que
/// vous étiez en train d'écrire » plutôt que de faire réapparaître un texte
/// sans explication.
final class Draft {
  const Draft({required this.text, required this.at});

  final String text;
  final DateTime at;
}

final draftLocalDataSourceProvider = Provider<DraftLocalDataSource>(
  (ref) => DraftLocalDataSource(
    documents: ref.watch(localDocumentsProvider),
    clock: ref.watch(clockProvider),
  ),
);
