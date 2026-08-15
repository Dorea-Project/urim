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

/// Un élément du fil d'une préparation.
///
/// Scellé : le fil n'accepte que ces trois natures, et ajouter la quatrième
/// obligera à traiter le cas partout où il est affiché.
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

/// Un passage biblique, avec sa référence et sa traduction.
final class ScriptureBlock extends PreparationBlock {
  const ScriptureBlock({
    required super.id,
    required super.anchor,
    required this.ref,
    required this.text,
    required this.translationLabel,
    this.provenance = ScriptureProvenance.cited,
  });

  final PassageRef ref;
  final String text;

  /// Nom lisible de la traduction : « Louis Segond 1910 ». Distinct de
  /// l'identifiant technique — c'est ce qui s'affiche sous le passage, et une
  /// mention de traduction est souvent une obligation contractuelle.
  final String translationLabel;

  final ScriptureProvenance provenance;

  @override
  List<Object?> get props => [id, anchor, ref, text, translationLabel, provenance];
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
