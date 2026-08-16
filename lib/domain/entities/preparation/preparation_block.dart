import 'package:equatable/equatable.dart';
import 'package:urim/domain/entities/bible/scripture_reference.dart';

/// Où se situe un bloc dans le fil.
///
/// Deux repères irréductibles : une préparation écrite se déroule dans le
/// temps réel, une transcription dans la durée de l'enregistrement. Les
/// confondre obligerait à inventer une date pour « 03:10 », ou un décalage
/// pour « hier 20:58 ».
sealed class BlockAnchor extends Equatable {
  const BlockAnchor();
}

/// Horodatage réel — préparations écrites ou dictées.
final class ClockAnchor extends BlockAnchor {
  const ClockAnchor(this.at);

  final DateTime at;

  @override
  List<Object?> get props => [at];
}

/// Décalage depuis le début de l'enregistrement — transcriptions.
final class MediaAnchor extends BlockAnchor {
  const MediaAnchor(this.offset);

  final Duration offset;

  @override
  List<Object?> get props => [offset];
}

/// D'où vient un passage biblique apparu dans le fil.
enum ScriptureProvenance {
  /// L'utilisateur l'a cité, ou Urim l'a proposé en réponse.
  cited,

  /// Repéré automatiquement dans l'enregistrement.
  recognizedInRecording,
}

/// Un passage cité, tel qu'il s'affiche.
///
/// [referenceLabel] accompagne [ref] parce que le nom du livre dépend de la
/// traduction qui a servi le texte : `act.2.42` est la forme de stockage,
/// « Actes 2:42 » est ce qui se lit. Les déduire l'un de l'autre supposerait
/// une table de noms globale, que le domaine se refuse à tenir.
final class QuotedPassage extends Equatable {
  const QuotedPassage({
    required this.ref,
    required this.referenceLabel,
    required this.text,
    required this.translationLabel,
    this.pericopeLabel,
  });

  final PassageRef ref;

  /// « Actes 2:42 ».
  final String referenceLabel;

  final String text;

  /// Nom lisible de la traduction : « Louis Segond 1910 ». Distinct de
  /// l'identifiant technique — c'est ce qui s'affiche sous le passage, et une
  /// mention de traduction est souvent une obligation contractuelle.
  final String translationLabel;

  /// Unité littéraire dont le passage fait partie : « péricope 42-47 ».
  /// Absente tant qu'Urim n'a pas borné le texte.
  final String? pericopeLabel;

  @override
  List<Object?> get props =>
      [ref, referenceLabel, text, translationLabel, pericopeLabel];
}

/// Un élément du fil d'une préparation.
///
/// Scellé : le fil n'accepte que ces natures, et ajouter la suivante obligera
/// à traiter le cas partout où il est affiché.
sealed class PreparationBlock extends Equatable {
  const PreparationBlock({required this.id, required this.anchor});

  final String id;
  final BlockAnchor anchor;
}

/// Ce que l'utilisateur a écrit ou dit.
final class UserBlock extends PreparationBlock {
  const UserBlock({
    required super.id,
    required super.anchor,
    required this.text,
  });

  final String text;

  @override
  List<Object?> get props => [id, anchor, text];
}

/// Un passage biblique posé seul dans le fil.
final class ScriptureBlock extends PreparationBlock {
  const ScriptureBlock({
    required super.id,
    required super.anchor,
    required this.passage,
    this.provenance = ScriptureProvenance.cited,
  });

  final QuotedPassage passage;
  final ScriptureProvenance provenance;

  @override
  List<Object?> get props => [id, anchor, passage, provenance];
}

/// Ce qu'un texte fait à la lecture en cours.
///
/// Les trois valeurs sont au même rang, et c'est tout l'enjeu : un moteur qui
/// ne servirait que [supports] fabriquerait la preuve de ce qu'on avait déjà
/// décidé de trouver.
enum TextStance {
  /// Le texte traite le sujet lui-même.
  subject,

  /// Il va dans le sens de la lecture.
  supports,

  /// Il lui résiste.
  complicates;

  /// Vrai pour ce qui contrarie la lecture — signalé, jamais masqué.
  bool get resists => this == TextStance.complicates;
}

/// Un texte pesé : sa référence, et ce qu'il fait à l'axe retenu.
final class WeighedText extends Equatable {
  const WeighedText({
    required this.stance,
    required this.ref,
    required this.referenceLabel,
    required this.note,
  });

  final TextStance stance;
  final PassageRef ref;

  /// « 1 Corinthiens 11:17-22 ».
  final String referenceLabel;

  /// Une phrase, qui dit pourquoi ce texte est là.
  final String note;

  @override
  List<Object?> get props => [stance, ref, referenceLabel, note];
}

/// Une réponse proposée à la question d'Urim.
///
/// Proposée, pas imposée : la barre de saisie reste ouverte, et l'utilisateur
/// peut répondre autre chose.
final class TurnChoice extends Equatable {
  const TurnChoice({required this.label, this.detail});

  /// « L'Église ».
  final String label;

  /// Ce que ce choix engage : « Ce qu'est l'assemblée, ce qui la tient. »
  final String? detail;

  @override
  List<Object?> get props => [label, detail];
}

/// Un tour d'Urim : ce qu'il a compris, ce qu'il sert, et la main qu'il rend.
///
/// Toutes les parties sont facultatives sauf une — un tour dit forcément
/// quelque chose. L'ordre d'affichage est celui des champs : le raisonnement,
/// la déclaration, les textes pesés, le passage, puis la question.
///
/// [trace] n'est pas un ornement : « Comment j'en suis arrivé là » est ce qui
/// distingue une proposition d'un oracle. Sans elle, l'utilisateur ne peut ni
/// vérifier ni contredire.
final class UrimTurn extends PreparationBlock {
  const UrimTurn({
    required super.id,
    required super.anchor,
    this.reasoning,
    this.statement,
    this.texts = const [],
    this.passage,
    this.question,
    this.choices = const [],
    this.moreLabel,
    this.trace,
  }) : assert(
          reasoning != null ||
              statement != null ||
              question != null ||
              passage != null,
          'Un tour dit toujours quelque chose : raisonnement, déclaration, '
          'passage ou question.',
        );

  /// Ce qu'Urim a compris, en gris : « Six de tes mots sont dans l'Écriture,
  /// mais ils ne s'y suivent pas. »
  final String? reasoning;

  /// Ce qu'il annonce, en encre pleine.
  final String? statement;

  final List<WeighedText> texts;
  final QuotedPassage? passage;

  /// La question rendue : « Sur quel axe veux-tu prêcher ? »
  final String? question;

  final List<TurnChoice> choices;

  /// Ouverture vers l'ensemble dont les choix sont extraits : « Voir les dix
  /// loci ».
  final String? moreLabel;

  /// Le chemin suivi, replié par défaut.
  final String? trace;

  bool get asksSomething => question != null;

  @override
  List<Object?> get props => [
        id,
        anchor,
        reasoning,
        statement,
        texts,
        passage,
        question,
        choices,
        moreLabel,
        trace,
      ];
}

/// Un point du plan proposé par Urim.
final class SynthesisPoint extends Equatable {
  const SynthesisPoint({
    required this.heading,
    required this.body,
    this.from,
    this.to,
  });

  /// Formule courte et mémorisable : « Persévérer, c'est revenir. »
  final String heading;

  final String body;

  /// Segment de l'enregistrement dont le point est tiré. Nul pour une
  /// préparation écrite.
  final Duration? from;
  final Duration? to;

  bool get isAnchoredInMedia => from != null && to != null;

  @override
  List<Object?> get props => [heading, body, from, to];
}

/// La synthèse produite par Urim.
///
/// [caution] n'est pas facultative, et c'est délibéré : le type interdit
/// d'afficher une synthèse sans son avertissement. Urim propose une lecture,
/// il ne se substitue pas au travail de celui qui prêche — cette réserve
/// disparaîtrait au premier écran pressé si elle était optionnelle.
final class SynthesisBlock extends PreparationBlock {
  const SynthesisBlock({
    required super.id,
    required super.anchor,
    required this.lead,
    required this.points,
    required this.caution,
  });

  /// Phrase d'introduction : « Le verset tient sur quatre appuis. »
  final String lead;

  final List<SynthesisPoint> points;

  /// « Relis les sources avant de prêcher. »
  final String caution;

  @override
  List<Object?> get props => [id, anchor, lead, points, caution];
}
