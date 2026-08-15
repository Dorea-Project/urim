import 'package:equatable/equatable.dart';

/// Référence à un verset unique.
///
/// [bookId] est l'identifiant stable du livre (`gen`, `psa`, `rom`), jamais
/// son nom affiché : celui-ci dépend de la langue et de la traduction.
final class VerseRef extends Equatable implements Comparable<VerseRef> {
  const VerseRef({
    required this.bookId,
    required this.chapter,
    required this.verse,
  })  : assert(chapter > 0, 'Le chapitre est numéroté à partir de 1.'),
        assert(verse > 0, 'Le verset est numéroté à partir de 1.');

  final String bookId;
  final int chapter;
  final int verse;

  /// Forme canonique interne : `gen.1.1`. Sert de clé de stockage et d'URL.
  /// À ne pas afficher — voir la couche présentation pour le rendu localisé.
  String get canonical => '$bookId.$chapter.$verse';

  @override
  int compareTo(VerseRef other) {
    // L'ordre entre livres n'est pas déductible de l'identifiant : il dépend
    // du canon. Trier une liste couvrant plusieurs livres impose de passer
    // par BibleBook.order.
    final byBook = bookId.compareTo(other.bookId);
    if (byBook != 0) return byBook;
    final byChapter = chapter.compareTo(other.chapter);
    if (byChapter != 0) return byChapter;
    return verse.compareTo(other.verse);
  }

  @override
  List<Object?> get props => [bookId, chapter, verse];

  @override
  String toString() => canonical;
}

/// Étendue continue de versets, de [start] à [end] inclus.
///
/// Un verset seul se représente par une étendue dont les bornes sont égales,
/// via [VerseRef.asPassage] — ainsi le reste du domaine ne manipule qu'un
/// seul type de référence.
final class PassageRef extends Equatable {
  PassageRef({required this.start, required this.end})
      : assert(
          start.bookId == end.bookId,
          'Un passage ne peut pas enjamber deux livres.',
        ),
        assert(
          start.compareTo(end) <= 0,
          'La borne de début doit précéder la borne de fin.',
        );

  final VerseRef start;
  final VerseRef end;

  String get bookId => start.bookId;

  bool get isSingleVerse => start == end;

  /// Vrai si le passage tient dans un seul chapitre.
  bool get isWithinOneChapter => start.chapter == end.chapter;

  bool contains(VerseRef ref) =>
      ref.bookId == bookId &&
      ref.compareTo(start) >= 0 &&
      ref.compareTo(end) <= 0;

  String get canonical =>
      isSingleVerse ? start.canonical : '${start.canonical}-${end.canonical}';

  @override
  List<Object?> get props => [start, end];

  @override
  String toString() => canonical;
}

extension VerseRefRange on VerseRef {
  /// Promeut un verset unique en passage, pour uniformiser les signatures.
  PassageRef asPassage() => PassageRef(start: this, end: this);

  /// Étendue de ce verset jusqu'à [end], dans le même livre.
  PassageRef through(VerseRef end) => PassageRef(start: this, end: end);
}
