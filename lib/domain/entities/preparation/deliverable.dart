import 'package:equatable/equatable.dart';

/// Le dossier de validation d'un document — **et aucun fichier n'existe
/// encore**.
///
/// Le contrôle est en amont, parce qu'un fichier produit est un fichier qui
/// circule. Ce que le pasteur lit ici, c'est ce que le corpus dit de ce qu'il
/// compte projeter, diapositive par diapositive.
final class Deliverable extends Equatable {
  const Deliverable({
    required this.id,
    required this.kind,
    required this.format,
    required this.validation,
    this.controls = const [],
  });

  final String id;

  /// `deck` — ce que l'assemblée voit — ou `note`, la fiche de chaire.
  final String kind;

  /// `pptx`, `docx`, `pdf`.
  final String format;

  /// `conforme` ou `rejete`.
  final String validation;

  final List<CitationCheck> controls;

  bool get isConform => validation == 'conforme';

  /// Ce qui a été altéré — le seul verdict qui ferme la porte du fichier.
  List<CitationCheck> get altered =>
      controls.where((c) => c.verdict == 'altere').toList();

  @override
  List<Object?> get props => [id, kind, format, validation, controls];
}

/// Le verdict d'une diapositive.
///
/// `version` nomme celle qui reconnaît le texte, et ce n'est pas cosmétique :
/// sur Romains 8:1, reconnaître Ostervald plutôt que la LSG change la doctrine
/// du verset projeté.
final class CitationCheck extends Equatable {
  const CitationCheck({
    required this.slideNo,
    required this.reference,
    required this.projectedText,
    required this.verdict,
    required this.rationale,
  });

  final int slideNo;
  final String reference;
  final String projectedText;

  /// `conforme`, `tronque`, `altere`.
  final String verdict;
  final String rationale;

  @override
  List<Object?> get props =>
      [slideNo, reference, projectedText, verdict, rationale];
}

/// Un document rendu : ses octets, et le nom sous lequel il doit être posé.
final class DeliverableFile extends Equatable {
  const DeliverableFile({required this.bytes, required this.filename});

  final List<int> bytes;
  final String filename;

  @override
  List<Object?> get props => [filename, bytes.length];
}
