import 'package:equatable/equatable.dart';

/// Traduction de la Bible (Segond 21, Darby, LSG...).
///
/// Le texte biblique est rarement libre de droits : [copyright] et
/// [isPublicDomain] ne sont pas décoratifs, ils conditionnent ce que
/// l'application a le droit d'afficher, d'exporter et de mettre en cache.
final class BibleTranslation extends Equatable {
  const BibleTranslation({
    required this.id,
    required this.name,
    required this.abbreviation,
    required this.languageCode,
    this.copyright,
    this.isPublicDomain = false,
  });

  final String id;
  final String name;

  /// Sigle usuel affiché à côté des références : `S21`, `LSG`, `BDS`.
  final String abbreviation;

  /// Code BCP 47 : `fr`, `en`, `fr-CA`.
  final String languageCode;

  /// Mention légale à afficher lorsque la traduction n'est pas dans le
  /// domaine public.
  final String? copyright;

  final bool isPublicDomain;

  /// Vrai si la mention de copyright doit accompagner tout affichage ou
  /// partage d'un extrait.
  bool get requiresAttribution => !isPublicDomain && copyright != null;

  static const String louisSegond1910Id = 'lsg1910';

  /// Louis Segond 1910 — la seule traduction qu'Urim puisse afficher
  /// aujourd'hui sans négocier quoi que ce soit : elle est dans le domaine
  /// public. Toute autre attend Q1 et une licence.
  static const BibleTranslation louisSegond1910 = BibleTranslation(
    id: louisSegond1910Id,
    name: 'Louis Segond 1910',
    abbreviation: 'LSG',
    languageCode: 'fr',
    isPublicDomain: true,
  );

  /// Traductions proposables. Une seule tant que Q1 n'est pas tranchée — la
  /// liste existe pour que l'écran de choix n'ait pas à être réécrit quand
  /// elle s'allongera.
  static const List<BibleTranslation> available = [louisSegond1910];

  /// La traduction correspondant à [id], ou [louisSegond1910] à défaut.
  static BibleTranslation byId(String id) => available.firstWhere(
        (translation) => translation.id == id,
        orElse: () => louisSegond1910,
      );

  @override
  List<Object?> get props =>
      [id, name, abbreviation, languageCode, copyright, isPublicDomain];

  @override
  String toString() => 'BibleTranslation($abbreviation)';
}
