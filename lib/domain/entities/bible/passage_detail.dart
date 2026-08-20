import 'package:equatable/equatable.dart';
import 'package:urim/domain/entities/preparation/study.dart';

/// Ce que le corpus sait d'un passage — **sans ouvrir de préparation**.
///
/// Lecture pure : aucune écriture, aucune réservation, aucun appel de modèle.
/// Le pasteur à qui l'on propose six textes veut les ouvrir avant de choisir ;
/// jusqu'ici il fallait s'engager sur l'un d'eux pour le regarder.
final class PassageDetail extends Equatable {
  const PassageDetail({
    required this.reference,
    this.units = const [],
    this.pericopeLabel,
    this.pericopeRationale,
    this.reviewedBy,
    this.verses = const [],
    this.bearings = const [],
    this.caveats = const [],
    this.context = const [],
    this.variants = const [],
  });

  final String reference;

  /// Les unités qui couvrent la demande. **Plus d'une** signifie que le passage
  /// chevauche plusieurs unités littéraires : la curation reste alors vide, et
  /// c'est au pasteur d'ouvrir celle qu'il veut lire.
  final List<UnitRef> units;

  final String? pericopeLabel;

  /// Pourquoi ces bornes-là. La phrase que le pasteur lit pour contredire.
  final String? pericopeRationale;

  /// Qui a signé l'unité. C'est la seule chose qui distingue un énoncé relu
  /// d'un énoncé produit et jamais lu.
  final String? reviewedBy;

  final List<ServedVerse> verses;

  /// **Les dix pesées, `absent` compris** — contrairement à l'écran du fil, qui
  /// n'affiche que ce qui porte. Un locus `absent` dit *quelqu'un a regardé et
  /// le texte n'en dit rien* ; un locus manquant dit *personne n'a regardé*.
  final List<AxisBearing> bearings;

  /// Ce que le texte **ne dit pas**.
  final List<String> caveats;

  final List<ContextNote> context;

  /// Ce que les manuscrits portent là où ils divergent.
  final List<TextualVariant> variants;

  @override
  List<Object?> get props => [
        reference,
        units,
        pericopeLabel,
        pericopeRationale,
        reviewedBy,
        verses,
        bearings,
        caveats,
        context,
        variants,
      ];
}

final class UnitRef extends Equatable {
  const UnitRef({
    required this.id,
    required this.label,
    required this.reference,
    required this.rationale,
  });

  final String id;
  final String label;
  final String reference;
  final String rationale;

  @override
  List<Object?> get props => [id, label, reference, rationale];
}

final class AxisBearing extends Equatable {
  const AxisBearing({
    required this.axisCode,
    required this.label,
    required this.strength,
    required this.rationale,
  });

  final String axisCode;
  final String label;

  /// `dominant`, `porte`, `resiste`, `absent`.
  final String strength;
  final String rationale;

  @override
  List<Object?> get props => [axisCode, label, strength, rationale];
}

final class TextualVariant extends Equatable {
  const TextualVariant({required this.reference, required this.body});

  final String reference;
  final String body;

  @override
  List<Object?> get props => [reference, body];
}

/// Toutes les occurrences d'un mot de l'original.
///
/// **La seule pierre du module de recherche qui ne peut rien inventer** : elle
/// montre le texte, elle ne dit rien du monde. La culture matérielle s'y
/// enseigne par la récurrence, pas par une note qui pourrait se tromper sans
/// que personne dans l'assemblée puisse la vérifier.
final class Concordance extends Equatable {
  const Concordance({
    required this.lemma,
    required this.language,
    required this.total,
    this.occurrences = const [],
  });

  final String lemma;

  /// `grc` ou `hbo`.
  final String language;

  /// Le compte **réel**, indépendant de ce qui est rendu : en montrer cinquante
  /// sans le dire ferait passer un extrait pour l'ensemble.
  final int total;

  final List<Occurrence> occurrences;

  bool get isTruncated => total > occurrences.length;

  @override
  List<Object?> get props => [lemma, language, total, occurrences];
}

final class Occurrence extends Equatable {
  const Occurrence({
    required this.reference,
    required this.text,
    required this.surface,
    required this.morphology,
  });

  final String reference;
  final String text;

  /// La forme telle qu'elle paraît dans ce verset.
  final String surface;
  final String morphology;

  @override
  List<Object?> get props => [reference, text, surface, morphology];
}
