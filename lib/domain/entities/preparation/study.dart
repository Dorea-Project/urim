import 'package:equatable/equatable.dart';
import 'package:urim/domain/entities/preparation/study_summary.dart';
import 'package:urim/domain/entities/preparation/turn.dart';

/// Une préparation, telle que le moteur la voit **maintenant**.
///
/// Ce que le serveur garde d'une préparation, ce sont les **décisions** du
/// pasteur : l'axe retenu, l'unité, les bornes, le thème. Les phrases, elles,
/// se refabriquent — le pipeline rejoue à chaque lecture. D'où l'absence de fil
/// dans cet objet : il n'y a pas d'historique à charger, il y a un [turn]
/// courant, et c'est tout ce qui existe.
///
/// C'est une bonne nouvelle plutôt qu'une limite : le moteur qui s'améliore
/// améliore aussi ce qu'il dit d'un travail ouvert la semaine dernière.
final class Study extends Equatable {
  const Study({
    required this.id,
    required this.status,
    required this.rawInput,
    required this.turn,
    this.outcome,
    this.theme,
    this.pericopeLabel,
    this.axisCode,
    this.boundsOverridden = false,
    this.corpusDrifted = false,
  });

  final String id;

  /// `ouverte`, `close`.
  final String status;

  /// Ce que le pasteur a écrit en ouvrant.
  final String rawInput;

  /// Le tour courant. Nul si le serveur ne l'a pas rendu — un client plus
  /// ancien que le contrat, ou un état qui n'en produit pas.
  final Turn? turn;

  final TurnOutcome? outcome;
  final String? theme;
  final String? pericopeLabel;
  final String? axisCode;

  /// Le pasteur a forcé ses bornes. Tout ce qui est curé devient illisible pour
  /// les étages avals — la contrepartie assumée de la liberté.
  final bool boundsOverridden;

  /// Le corpus a été relu depuis l'ouverture de cette préparation.
  ///
  /// Le tour n'est pas faux : le moteur rejoue simplement contre un corpus qui a
  /// bougé — des unités ont pu être relues, des pesées ajoutées. Il n'est plus
  /// **mot pour mot** celui que le pasteur avait sous les yeux, et l'écran le
  /// dit une fois plutôt que de le laisser découvrir.
  final bool corpusDrifted;

  @override
  List<Object?> get props => [
        id,
        status,
        rawInput,
        turn,
        outcome,
        theme,
        pericopeLabel,
        axisCode,
        boundsOverridden,
        corpusDrifted,
      ];

  @override
  String toString() => 'Study($id, ${turn?.stageCode ?? "sans tour"})';
}
