import 'package:equatable/equatable.dart';
import 'package:urim/domain/entities/preparation/plan_element.dart';
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
    this.elements = const [],
    this.supports = const [],
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

  /// La chaîne de textes d'appui, dans **l'ordre du pasteur** — pas celui du
  /// canon. Il écrit sa progression : l'annonce avant l'accomplissement.
  final List<SupportText> supports;

  /// Le squelette homilétique, tel que le pasteur l'a écrit.
  ///
  /// Vide tant qu'il n'a rien posé — et c'est l'état normal d'une préparation
  /// qui vient de s'ouvrir. Le livrable, lui, en exige au moins un point.
  final List<PlanElement> elements;

  /// Le plan porte-t-il au moins un point ? C'est le seuil du document : « les
  /// diapositives mettent en page ce que vous avez écrit ; le moteur ne l'écrit
  /// pas à votre place ».
  bool get hasPlan => elements.any(
        (e) => e.code == PlanSkeleton.pointCentral && !e.isEmpty,
      );

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

/// Un texte d'appui, **avec ce que la saisie a donné — ou pourquoi elle n'a
/// rien donné**.
///
/// C'est ici que le contrôle de référence atteint le pasteur. Ses notes
/// portaient `Hb 2v29` et `Ph 28v9` ; Urim savait dire « Hébreux 2 compte 18
/// versets » depuis le premier jour, faute d'une surface où ces textes soient
/// soumis.
final class SupportText extends Equatable {
  const SupportText({
    required this.raw,
    this.reference = '',
    this.text = '',
    this.verdict = '',
  });

  /// Ce que le pasteur a écrit, dans sa notation. **Il survit toujours** : le
  /// perdre l'obligerait à se souvenir de ce qu'il voulait citer.
  final String raw;

  final String reference;
  final String text;

  /// Ce qui manque **au corpus**, jamais au pasteur.
  final String verdict;

  bool get isResolved => reference.isNotEmpty;

  @override
  List<Object?> get props => [raw, reference, text, verdict];
}
