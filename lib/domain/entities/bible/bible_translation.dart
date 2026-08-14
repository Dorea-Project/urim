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

  @override
  List<Object?> get props =>
      [id, name, abbreviation, languageCode, copyright, isPublicDomain];

  @override
  String toString() => 'BibleTranslation($abbreviation)';
}
