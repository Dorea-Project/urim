import 'package:equatable/equatable.dart';
import 'package:urim/domain/entities/bible/scripture_reference.dart';

/// Un verset dans une traduction donnée.
///
/// Le texte n'a de sens que rapporté à sa traduction : le même [VerseRef]
/// rend un texte différent selon [translationId]. Les deux ne se séparent
/// jamais.
final class Verse extends Equatable {
  const Verse({
    required this.ref,
    required this.translationId,
    required this.text,
  });

  final VerseRef ref;
  final String translationId;
  final String text;

  @override
  List<Object?> get props => [ref, translationId, text];

  @override
  String toString() => 'Verse(${ref.canonical}, $translationId)';
}

/// Suite continue de versets, telle qu'on la lit ou qu'on la cite.
final class Passage extends Equatable {
  const Passage({
    required this.ref,
    required this.translationId,
    required this.verses,
  });

  final PassageRef ref;
  final String translationId;

  /// Versets dans l'ordre de lecture, du premier au dernier de [ref].
  final List<Verse> verses;

  bool get isEmpty => verses.isEmpty;

  /// Texte continu du passage, sans les numéros de verset. Destiné à la
  /// citation et à la recherche, pas à l'affichage en lecture — la
  /// présentation a besoin des versets séparés pour les rendre cliquables.
  String get plainText => verses.map((v) => v.text).join(' ');

  @override
  List<Object?> get props => [ref, translationId, verses];

  @override
  String toString() => 'Passage(${ref.canonical}, $translationId, ${verses.length} v.)';
}
