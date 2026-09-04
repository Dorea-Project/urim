import 'package:equatable/equatable.dart';

/// Une **pièce** — ce qu'un pasteur taille dans son culte et publie (D70).
///
/// 🔴 **C'est l'objet que le produit livre, pas le culte.** Un dimanche donne
/// une heure et demie d'un seul tenant : une prédication enchaînée par une
/// prière, avec du bruit et des chants au démarrage. On ne publie pas ça. On en
/// tire deux pièces, qui sortent à trois jours d'intervalle.
///
/// ## Ce qui la distingue d'une capture
///
/// | | La capture | La pièce |
/// |---|---|---|
/// | Ce que c'est | ce que le micro a pris **sans intention** | ce que le pasteur a **décidé de garder** |
/// | Durée de vie | sept jours, puis purge | **elle vit avec sa publication** |
/// | Combien par dimanche | une | autant qu'il en taille |
///
/// ⚠️ **Le découpage est le consentement** (D70) : le pasteur a écouté avant de
/// couper, donc ce qu'il garde est ce qu'il a choisi. C'est cet acte, et non une
/// durée de rétention, qui transforme une matière captée en objet assumé — et
/// c'est pourquoi une pièce survit là où la matière disparaît.
final class SermonPiece extends Equatable {
  const SermonPiece({
    required this.id,
    required this.captureId,
    required this.title,
    required this.start,
    required this.end,
    required this.path,
    required this.cutAt,
  });

  final String id;

  /// La capture dont elle est tirée — **gardée même quand la matière est
  /// purgée**. Savoir de quel culte vient une pièce reste vrai après le
  /// septième jour ; pouvoir y retourner, non.
  final String captureId;

  /// Le nom que le pasteur lui a donné.
  ///
  /// Jamais vide : une pièce sans nom dans une liste de pièces ne se distingue
  /// pas de sa voisine, et c'est celle qu'il publiera par erreur.
  final String title;

  /// Les bornes **dans la capture d'origine**, pas dans la pièce.
  ///
  /// Elles ne servent plus à retailler — la matière aura disparu — mais elles
  /// disent *d'où* vient ce qu'on écoute, et c'est ce qui permet de reconnaître
  /// « la prière » de « la prédication » sans les rejouer.
  final Duration start;
  final Duration end;

  /// Le fichier, hors du dossier que la purge balaie.
  final String path;

  final DateTime cutAt;

  Duration get duration => end > start ? end - start : Duration.zero;

  SermonPiece renommee(String nouveau) => SermonPiece(
        id: id,
        captureId: captureId,
        title: nouveau,
        start: start,
        end: end,
        path: path,
        cutAt: cutAt,
      );

  @override
  List<Object?> get props => [id, captureId, title, start, end, path, cutAt];
}
