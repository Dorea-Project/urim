import 'package:urim/core/storage/local_documents.dart';

/// Un magasin de documents en memoire.
///
/// Meme role que `FakeVault` pour le coffre a secrets : `path_provider` ne
/// repond que sur un vrai appareil, et le brancher dans un test rendrait
/// intestable tout ce qui garde quelque chose.
final class FakeDocuments implements LocalDocuments {
  final Map<String, String> contenu = {};

  /// Ce qui a ete ecrit, dans l'ordre — c'est ce qui se verifie quand la
  /// question est « a-t-il ecrit avant d'appeler le serveur ? ».
  final List<String> ecritures = [];

  @override
  Future<String?> read(String key) async => contenu[key];

  @override
  Future<void> write(String key, String value) async {
    contenu[key] = value;
    ecritures.add(key);
  }

  @override
  Future<void> delete(String key) async {
    contenu.remove(key);
  }

  @override
  Future<List<String>> keys() async => contenu.keys.toList();
}
