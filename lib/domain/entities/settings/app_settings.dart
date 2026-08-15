import 'package:equatable/equatable.dart';
import 'package:urim/domain/entities/bible/bible_translation.dart';

/// Taille du texte biblique en lecture suivie.
///
/// Le réglage porte sur la **lecture**, pas sur l'interface : la maquette le
/// range sous « Lecture » et l'illustre d'un verset (D12). L'échelle de police
/// du système reste maîtresse du reste de l'écran, et les deux se composent —
/// un utilisateur qui a déjà grossi tout son téléphone n'a pas à recommencer
/// ici.
enum ReadingTextSize {
  small('Petit', 0.875),
  normal('Normal', 1),
  large('Grand', 1.15),
  extraLarge('Très grand', 1.35);

  const ReadingTextSize(this.label, this.scale);

  /// Libellé du sélecteur.
  final String label;

  /// Facteur appliqué à la taille du texte de lecture.
  final double scale;

  /// Retombe sur [normal] pour une valeur inconnue : une préférence illisible
  /// ne doit pas empêcher l'application de démarrer.
  static ReadingTextSize fromName(String? name) => values.firstWhere(
        (size) => size.name == name,
        orElse: () => normal,
      );
}

/// Préférences de l'utilisateur.
///
/// Ne contient que les réglages qui ont un effet aujourd'hui. Ceux que la
/// maquette montre mais qui dépendent d'une question ouverte — texte biblique
/// téléchargé, transcription sur l'appareil, synchronisation, rappels — ne
/// sont pas stockés : les afficher inactifs suffit, et une préférence
/// enregistrée pour rien devient une préférence oubliée le jour où la
/// fonction arrive (D13).
final class AppSettings extends Equatable {
  const AppSettings({
    this.readingTextSize = ReadingTextSize.normal,
    this.defaultTranslationId = BibleTranslation.louisSegond1910Id,
    this.alwaysShowReference = true,
  });

  final ReadingTextSize readingTextSize;

  /// Traduction proposée par défaut à la citation.
  final String defaultTranslationId;

  /// Livre, chapitre, verset et version sous chaque citation.
  ///
  /// Vrai par défaut, conformément à la maquette : une citation sans
  /// référence n'est pas vérifiable.
  final bool alwaysShowReference;

  AppSettings copyWith({
    ReadingTextSize? readingTextSize,
    String? defaultTranslationId,
    bool? alwaysShowReference,
  }) =>
      AppSettings(
        readingTextSize: readingTextSize ?? this.readingTextSize,
        defaultTranslationId: defaultTranslationId ?? this.defaultTranslationId,
        alwaysShowReference: alwaysShowReference ?? this.alwaysShowReference,
      );

  @override
  List<Object?> get props =>
      [readingTextSize, defaultTranslationId, alwaysShowReference];
}
