import 'package:equatable/equatable.dart';
import 'package:urim/domain/entities/preparation/preparation.dart';

/// Comment le moteur a fini son dernier tour.
///
/// **Le vocabulaire est celui du serveur**, mot pour mot. Il aurait été facile
/// d'inventer ici des états plus parlants — « en attente », « à toi » — et
/// c'est exactement ce qu'on a fait tant que l'accueil était une maquette. Le
/// prix se paie au premier étage nouveau du moteur : deux vocabulaires à tenir
/// d'accord, et une traduction qui se décale d'un mot sans que rien n'échoue.
///
/// `await_decision` **est** « rend la main ». Le moteur ne connaît pas d'autre
/// manière de le dire, et l'application non plus désormais.
enum TurnOutcome {
  /// `continue` — le moteur est allé au bout sans rien demander.
  kept,

  /// `await_decision` — il s'est arrêté sur une question. La main est au
  /// pasteur : c'est le seul état qui met une préparation en tête de l'accueil.
  handsBack,

  /// `refuse` — il n'a pas voulu travailler, et il dit pourquoi.
  refused,

  /// `degrade` — il a servi moins qu'il ne voulait, et l'annonce.
  degraded;

  /// Traduit ce que le serveur envoie. Inconnu — un étage ajouté côté serveur
  /// avant que l'application ne suive — vaut « rien à dire » plutôt qu'une
  /// erreur : une préparation ne doit pas disparaître du fil parce que le
  /// moteur a appris un mot de plus.
  static TurnOutcome? fromWire(String? value) => switch (value) {
        'continue' => TurnOutcome.kept,
        'await_decision' => TurnOutcome.handsBack,
        'refuse' => TurnOutcome.refused,
        'degrade' => TurnOutcome.degraded,
        _ => null,
      };

  /// Vrai quand la préparation attend une réponse.
  bool get waitsForUser => this == TurnOutcome.handsBack;
}

/// Une ligne du fil d'accueil.
///
/// Ce n'est **pas** une préparation allégée : c'est tout ce que le serveur peut
/// dire d'une préparation sans rejouer son moteur. La phrase d'Urim — ce qu'il
/// a dit, et pourquoi — n'en fait pas partie, et n'en fera jamais partie : elle
/// naît du rejeu, et vingt lignes de fil feraient vingt rejeux. Elle arrive en
/// ouvrant la préparation.
///
/// Le fil dit **où l'on en est**, l'écran de la préparation dit **ce qu'Urim a
/// dit**.
final class StudySummary extends Equatable {
  const StudySummary({
    required this.id,
    required this.rawInput,
    required this.lastActivity,
    this.pericopeLabel,
    this.theme,
    this.serviceDate,
    this.lastOutcome,
    this.isClosed = false,
    this.origin = PreparationOrigin.written,
  });

  final String id;

  /// Ce que le pasteur a écrit en ouvrant, tel quel. C'est le titre tant que
  /// rien n'est résolu — « l'amour fraternel n'existe plus dans l'église ».
  final String rawInput;

  /// L'unité une fois bornée : « Hébreux 13:1-6 ». Nulle avant.
  final String? pericopeLabel;

  /// Le thème, quand le moteur en a arrêté un.
  final String? theme;

  /// Le dimanche visé. Nul quand la préparation n'est pas datée : on prépare
  /// aussi sans savoir quand on prêchera.
  final DateTime? serviceDate;

  /// Le dernier tour rendu, ou nul si le moteur n'a encore rien dit.
  final TurnOutcome? lastOutcome;

  /// Dernier tour, à défaut l'ouverture. Sert au tri et au regroupement.
  final DateTime lastActivity;

  /// « J'ai prêché celle-ci. » Une préparation close reste au fil — c'est
  /// justement ce qu'on revient revoir.
  final bool isClosed;

  /// Par quelle porte le travail est entré.
  ///
  /// Le serveur ne sert pas cette information : son moteur ne connaît que les
  /// préparations écrites — la capture est verrouillée à l'étape 1 côté
  /// serveur. Elle existe pour la branche transcription, qui reste une
  /// maquette, et pour l'aiguillage de la carte : une prédication transcrite
  /// s'ouvre sur sa relecture, pas sur le fil.
  final PreparationOrigin origin;

  /// La deuxième ligne de la carte.
  ///
  /// Le thème s'il est arrêté, sinon l'unité bornée. Jamais une phrase d'Urim :
  /// il n'y en a pas ici, et il n'y en aura pas.
  String? get subtitle => theme ?? pericopeLabel;

  bool get waitsForUser => lastOutcome?.waitsForUser ?? false;

  @override
  List<Object?> get props => [
        id,
        rawInput,
        pericopeLabel,
        theme,
        serviceDate,
        lastOutcome,
        lastActivity,
        isClosed,
        origin,
      ];

  @override
  String toString() => 'StudySummary($id, ${lastOutcome?.name ?? "aucun tour"})';
}
