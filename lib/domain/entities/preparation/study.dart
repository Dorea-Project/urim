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
    this.verses = const [],
    this.context = const [],
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

  /// ⚠️ **Le texte lui-même** — et le pasteur ne le voyait nulle part.
  ///
  /// Aucun bloc du tour ne porte les versets : le fil parle de l'unité, la
  /// pèse, propose des plans, et ne montre jamais ce dont il parle. Le
  /// document, lui, l'imprime sous « Le texte ». Il faut travailler sur son
  /// écran, pas sur celui d'à côté.
  final List<ServedVerse> verses;

  /// Le contexte, littéraire et historique.
  ///
  /// Calculé à l'ouverture par l'étage `load_context`, écrit dans la trace,
  /// stocké — et jamais montré. Un pasteur a demandé « le contexte du livre de
  /// Marc » alors que la réponse était **déjà dans sa préparation**.
  ///
  /// Le corpus ne l'a pas pour toutes les unités : absent, rien ne s'affiche
  /// plutôt qu'une section vide qui promettrait ce qu'elle n'a pas.
  final List<ContextNote> context;

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
        verses,
        context,
      ];

  @override
  String toString() => 'Study($id, ${turn?.stageCode ?? "sans tour"})';
}

/// Un verset servi **par le corpus** — jamais saisi, donc rien à falsifier.
final class ServedVerse extends Equatable {
  const ServedVerse({required this.reference, required this.text});

  final String reference;
  final String text;

  @override
  List<Object?> get props => [reference, text];
}

/// Une note de contexte : ce qui entoure le passage.
final class ContextNote extends Equatable {
  const ContextNote({
    required this.kind,
    required this.body,
    this.sourceRef = '',
  });

  /// `litteraire`, `historique`… Le vocabulaire du corpus.
  final String kind;
  final String body;

  /// D'où la note vient, et sous quelle version.
  final String sourceRef;

  @override
  List<Object?> get props => [kind, body, sourceRef];
}
