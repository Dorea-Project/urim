import 'package:equatable/equatable.dart';

/// Étape du discernement.
///
/// L'ordre des valeurs suit le déroulé normal, mais toutes les transitions ne
/// sont pas permises — voir [PastoralQuestion.canTransitionTo].
enum DiscernmentStatus {
  /// Question posée, discernement pas encore engagé.
  open,

  /// Discernement en cours : recherche de passages, consultation, prière.
  discerning,

  /// Une décision est consignée.
  decided,

  /// Mise en attente délibérée, sans abandon.
  suspended,

  /// Question close sans décision.
  abandoned;

  bool get isClosed => this == decided || this == abandoned;
}

/// Question pastorale soumise au discernement.
///
/// Entité racine du module décisionnel : les passages qui l'éclairent
/// ([ScriptureAnchor]) et la décision qui la clôt ([Decision]) s'y rattachent
/// par [id].
final class PastoralQuestion extends Equatable {
  const PastoralQuestion({
    required this.id,
    required this.title,
    required this.askedAt,
    this.context = '',
    this.status = DiscernmentStatus.open,
    this.tags = const {},
  });

  final String id;

  /// Formulation courte de la question, telle qu'elle sera listée.
  final String title;

  /// Circonstances : ce qui a amené la question, les éléments à peser.
  final String context;

  final DateTime askedAt;
  final DiscernmentStatus status;

  /// Étiquettes libres, pour retrouver les questions par thème.
  final Set<String> tags;

  /// Une question rouverte redevient discernable ; une question abandonnée
  /// ne se décide pas sans être rouverte au préalable.
  bool canTransitionTo(DiscernmentStatus target) => switch ((status, target)) {
        (final a, final b) when a == b => false,
        (DiscernmentStatus.open, DiscernmentStatus.discerning) => true,
        (DiscernmentStatus.open, DiscernmentStatus.abandoned) => true,
        (DiscernmentStatus.discerning, _) => true,
        (DiscernmentStatus.suspended, DiscernmentStatus.discerning) => true,
        (DiscernmentStatus.suspended, DiscernmentStatus.abandoned) => true,
        (DiscernmentStatus.decided, DiscernmentStatus.discerning) => true,
        (DiscernmentStatus.abandoned, DiscernmentStatus.discerning) => true,
        _ => false,
      };

  PastoralQuestion copyWith({
    String? title,
    String? context,
    DiscernmentStatus? status,
    Set<String>? tags,
  }) =>
      PastoralQuestion(
        id: id,
        title: title ?? this.title,
        context: context ?? this.context,
        askedAt: askedAt,
        status: status ?? this.status,
        tags: tags ?? this.tags,
      );

  @override
  List<Object?> get props => [id, title, context, askedAt, status, tags];

  @override
  String toString() => 'PastoralQuestion($id, ${status.name})';
}
