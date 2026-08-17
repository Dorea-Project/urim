/// Un geste que le pasteur a fait, et qui n'est pas encore parti.
///
/// Dans le domaine et non dans la couche data : c'est un fait metier — un
/// pasteur a decide quelque chose — et le depot en depend dans son contrat.
/// La forme JSON reste ici parce qu'elle est l'ecriture de ce fait, pas un
/// detail de transport : c'est la meme raison qui met `toJson` sur une entite
/// et pas dans un mappeur.
library;

final class PendingGesture {
  const PendingGesture({
    required this.kind,
    required this.stageCode,
    required this.optionCode,
    this.label = '',
    this.madeAt,
  });

  factory PendingGesture.fromJson(Map<String, dynamic> json) => PendingGesture(
        kind: PendingGestureKind.values.firstWhere(
          (k) => k.name == json['kind'],
          orElse: () => PendingGestureKind.decide,
        ),
        stageCode: json['stage_code'] as String? ?? '',
        optionCode: json['option_code'] as String? ?? '',
        label: json['label'] as String? ?? '',
        madeAt: DateTime.tryParse(json['made_at'] as String? ?? ''),
      );

  final PendingGestureKind kind;

  /// L'étage où poster. Recopié du bloc, pas du tour : les pesées portent le
  /// leur, et le refabriquer plus tard serait le refabriquer faux.
  final String stageCode;
  final String optionCode;

  /// Ce que le pasteur a vu écrit sur ce qu'il a touché. Sert à le lui
  /// remontrer, pas à l'envoyer.
  final String label;

  final DateTime? madeAt;

  PendingGesture at(DateTime moment) => PendingGesture(
        kind: kind,
        stageCode: stageCode,
        optionCode: optionCode,
        label: label,
        madeAt: madeAt ?? moment,
      );

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'stage_code': stageCode,
        'option_code': optionCode,
        'label': label,
        if (madeAt case final DateTime moment)
          'made_at': moment.toIso8601String(),
      };
}

/// Décider fait avancer le pipeline ; écarter ne fait avancer aucun étage.
/// Deux routes distinctes côté serveur, donc deux natures ici.
enum PendingGestureKind { decide, dismiss }
