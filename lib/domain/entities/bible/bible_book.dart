import 'package:equatable/equatable.dart';

/// Partition du canon.
///
/// Nommé `oldTestament` / `newTestament` plutôt que `old` / `new` : `new` est
/// un mot réservé du langage.
enum Testament { oldTestament, newTestament }

/// Livre du canon biblique.
///
/// [id] est stable et indépendant de la langue (`gen`, `psa`, `rom`) ; [name]
/// et [abbreviation] varient selon la traduction et sont donc portés par le
/// livre tel que fourni par une traduction donnée, pas par une table globale.
final class BibleBook extends Equatable {
  const BibleBook({
    required this.id,
    required this.name,
    required this.abbreviation,
    required this.testament,
    required this.order,
    required this.chapterCount,
  });

  final String id;
  final String name;
  final String abbreviation;
  final Testament testament;

  /// Rang dans le canon, à partir de 1. Seule source d'ordre fiable entre
  /// livres : les identifiants ne se trient pas alphabétiquement.
  final int order;

  final int chapterCount;

  @override
  List<Object?> get props => [id, name, abbreviation, testament, order, chapterCount];

  @override
  String toString() => 'BibleBook($id, $name)';
}
