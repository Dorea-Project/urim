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
    this.stageCode = '',
    this.optionCode = '',
    this.text = '',
    this.key = '',
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
        text: json['text'] as String? ?? '',
        key: json['key'] as String? ?? '',
        label: json['label'] as String? ?? '',
        madeAt: DateTime.tryParse(json['made_at'] as String? ?? ''),
      );

  final PendingGestureKind kind;

  /// L'étage où poster. Recopié du bloc, pas du tour : les pesées portent le
  /// leur, et le refabriquer plus tard serait le refabriquer faux.
  final String stageCode;
  final String optionCode;

  /// La phrase, pour une parole.
  final String text;

  /// ⚠️ **La clé d'idempotence, tirée une fois et gardée avec le geste.**
  ///
  /// C'est ce qui rend une parole rejouable. Décider et écarter posent un
  /// état : les renvoyer donne le même résultat. Une parole, non — le serveur y
  /// répond, et la renvoyer coûterait un second passage du répondeur, donc un
  /// appel de modèle. La tirer au moment de l'**envoi** au lieu de la mise en
  /// file la rendrait différente à chaque tentative, c'est-à-dire inutile.
  final String key;

  /// Ce que le pasteur a vu écrit sur ce qu'il a touché. Sert à le lui
  /// remontrer, pas à l'envoyer.
  final String label;

  final DateTime? madeAt;

  PendingGesture at(DateTime moment) => PendingGesture(
        kind: kind,
        stageCode: stageCode,
        optionCode: optionCode,
        text: text,
        key: key,
        label: label,
        madeAt: madeAt ?? moment,
      );

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        if (stageCode.isNotEmpty) 'stage_code': stageCode,
        if (optionCode.isNotEmpty) 'option_code': optionCode,
        if (text.isNotEmpty) 'text': text,
        if (key.isNotEmpty) 'key': key,
        if (label.isNotEmpty) 'label': label,
        if (madeAt case final DateTime moment)
          'made_at': moment.toIso8601String(),
      };
}

/// Décider fait avancer le pipeline ; écarter ne fait avancer aucun étage ;
/// parler n'est ni l'un ni l'autre. Trois routes distinctes côté serveur, donc
/// trois natures ici.
enum PendingGestureKind { decide, dismiss, say }
