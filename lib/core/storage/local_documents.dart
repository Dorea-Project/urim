import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Un magasin de documents locaux : une clé, un texte.
///
/// Interface volontairement minuscule, pour la même raison que [SecretVault] :
/// elle isole un greffon natif qui ne répond que sur un vrai appareil, et le
/// brancher directement rendrait tout ce qui l'utilise intestable.
///
/// **Pourquoi pas SQLite ici.** Les décisions le recommandaient pour Q4, et ce
/// sera vrai le jour où quelque chose aura besoin d'être *interrogé* — une file
/// à ordonner, une recherche. Rien de tout cela n'est vrai d'un brouillon :
/// c'est une clé, une valeur, et l'écriture doit être la plus courte possible
/// puisqu'elle a lieu à la frappe. Ajouter maintenant un moteur SQL et sa
/// génération de code serait payer d'avance une facture qu'on ne doit pas
/// encore. Le jour où on la doit, c'est cette interface qui change de dos.
abstract interface class LocalDocuments {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);

  /// Les clés présentes, pour balayer ce qui traîne.
  Future<List<String>> keys();
}

/// Un fichier par clé, dans le répertoire de l'application.
///
/// Un fichier par clé et non un seul index : un brouillon écrit à la frappe ne
/// doit pas réécrire l'ensemble à chaque caractère, et une écriture
/// interrompue ne doit abîmer que son propre brouillon.
final class FileDocuments implements LocalDocuments {
  FileDocuments({Future<Directory> Function()? directory})
      : _directory = directory ?? _appDirectory;

  final Future<Directory> Function() _directory;
  Directory? _resolu;

  static Future<Directory> _appDirectory() =>
      getApplicationSupportDirectory();

  Future<Directory> _dossier() async {
    final base = _resolu ??= await _directory();
    final dossier = Directory('${base.path}/documents');
    if (!dossier.existsSync()) await dossier.create(recursive: true);
    return dossier;
  }

  Future<File> _fichier(String key) async =>
      File('${(await _dossier()).path}/${_nomDeFichier(key)}');

  @override
  Future<String?> read(String key) async {
    final fichier = await _fichier(key);
    if (!fichier.existsSync()) return null;

    try {
      return await fichier.readAsString();
    } on FileSystemException {
      // Un fichier abîmé — coupure d'alimentation en pleine écriture — ne doit
      // pas empêcher l'écran de s'ouvrir. On perd ce brouillon, pas l'outil.
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    final fichier = await _fichier(key);
    // Écriture par un fichier temporaire puis renommage : le renommage est
    // atomique, donc une coupure ne laisse jamais un brouillon a moitie ecrit
    // à la place du précédent.
    final tampon = File('${fichier.path}.tmp');
    await tampon.writeAsString(value, flush: true);
    await tampon.rename(fichier.path);
  }

  @override
  Future<void> delete(String key) async {
    final fichier = await _fichier(key);
    if (fichier.existsSync()) await fichier.delete();
  }

  @override
  Future<List<String>> keys() async {
    final dossier = await _dossier();

    return [
      for (final entite in dossier.listSync())
        if (entite is File && !entite.path.endsWith('.tmp'))
          _cleDepuisNom(entite.uri.pathSegments.last),
    ];
  }
}

/// Une clé peut contenir n'importe quoi — un identifiant, un chemin. Encodée en
/// base64 URL, elle devient un nom de fichier valide sur les trois systèmes, et
/// reste réversible.
String _nomDeFichier(String key) =>
    base64Url.encode(utf8.encode(key)).replaceAll('=', '_');

String _cleDepuisNom(String nom) {
  final brut = nom.replaceAll('_', '=');
  try {
    return utf8.decode(base64Url.decode(brut));
  } on FormatException {
    return nom;
  }
}

final localDocumentsProvider = Provider<LocalDocuments>((ref) {
  // Le magasin résout son répertoire une fois : le libérer parce que plus
  // personne ne l'écoute referait un appel natif à chaque frappe.
  ref.keepAlive();
  return FileDocuments();
});
