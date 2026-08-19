import 'package:equatable/equatable.dart';

/// Ce qu'Urim vient de dire, et ce qu'il attend.
///
/// **Un tour, pas un historique.** Le moteur rejoue son pipeline à chaque
/// lecture : il n'y a pas de journal de conversation côté serveur, et il n'y en
/// aura pas. Ce que porte une préparation, ce sont les décisions du pasteur ;
/// les phrases se refabriquent à partir d'elles. Ouvrir une préparation vieille
/// d'une semaine ne rend donc pas ce qui a été dit alors — cela rend ce que le
/// moteur en dit **aujourd'hui**.
///
/// Les trois phrases ne viennent pas du même endroit, et c'est le contrat :
///
/// - [say] — ce qu'Urim vient de faire, écrit une fois côté serveur ;
/// - [why] — **le motif du moteur, tel quel**. Jamais réécrit, jamais nul :
///   une réponse sans son motif serait une conclusion sans provenance ;
/// - [ask] — la question, et seulement quand le pasteur a quelque chose à
///   faire.
///
/// Aucune de ces phrases n'est traduite ni reformulée ici. L'application n'a
/// pas le droit d'écrire une phrase de sa propre autorité : ce que le pasteur
/// lit vient du serveur, donc se relit en un seul endroit.
final class Turn extends Equatable {
  const Turn({
    required this.say,
    required this.why,
    required this.expects,
    required this.stageCode,
    this.ask = '',
    this.signature,
    this.blocks = const [],
    this.speaks = '',
  });

  final String say;

  /// Le filet doré. Vide serait une anomalie de contrat, pas un cas à traiter.
  final String why;

  final String ask;
  final TurnExpects expects;

  /// L'étage où poster une décision. Sauf pour les pesées, qui portent le leur.
  final String stageCode;

  /// Qui a signé l'unité — `ia-mistral`, ou le nom d'un relecteur.
  final String? signature;

  /// Dans l'ordre de l'écran, de haut en bas. Le serveur le fixe ; l'écran rend
  /// ce qu'on lui donne dans l'ordre où on le lui donne.
  final List<TurnBlock> blocks;

  /// ⚠️ **Le bloc dont ce tour parle**, et la seule chose qui permette de ne pas
  /// tout redéplier.
  ///
  /// Les pesées et les couples accompagnent **tous** les tours qui suivent
  /// l'étage qui les a produits : c'est du décor ambiant, voulu, et il se
  /// réaffichait à l'identique à chaque fois. Mesuré sur un téléphone, un tour
  /// de `shape_homiletic` faisait onze écrans, dont neuf de matière déjà lue.
  ///
  /// Porte un `kind` de bloc, ou `rien` / `epuise` / `correction` quand ce qui
  /// parle n'est pas un bloc.
  final String speaks;

  /// Ce bloc est-il le sujet du tour ?
  ///
  /// Sert à déplier l'un et replier les autres — **jamais à en cacher un** : le
  /// décor reste là, sous son intitulé et son nombre. Les refusés voyagent
  /// toujours avec les faisables.
  bool isSpoken(TurnBlock block) => switch (block) {
        ChipsBlock() => speaks == 'chips' || speaks == 'correction',
        UnitsBlock() => speaks == 'units',
        BoundsBlock() => speaks == 'bounds',
        BearingsBlock() => speaks == 'bearings',
        FeasibilityBlock() => speaks == 'feasibility',
        ThemeBlock() => speaks == 'theme',
        // Les sorties accompagnent le thème, elles ne le remplacent pas — mais
        // un bouton ouvert est un geste, et un geste ne se replie pas.
        ActionsBlock() => true,
        UnknownBlock() => false,
      };

  /// Vrai quand le tour offre quelque chose à toucher.
  bool get offersChoice => blocks.any((block) => block.isTouchable);

  @override
  List<Object?> get props => [say, why, ask, expects, stageCode, signature, blocks];
}

/// Ce que le tour attend.
///
/// `choice` **n'exclut pas** la saisie : les pastilles sont des raccourcis,
/// jamais des barreaux. Le pasteur peut toujours écrire — c'est la règle du
/// compagnon, et la barre ne se ferme jamais.
enum TurnExpects {
  choice,
  text,
  nothing;

  static TurnExpects fromWire(String? value) => switch (value) {
        'choice' => TurnExpects.choice,
        'nothing' => TurnExpects.nothing,
        _ => TurnExpects.text,
      };
}

/// Un bloc du tour.
///
/// Scellé : le compilateur impose de traiter toute nature nouvelle — sauf
/// [UnknownBlock], qui existe précisément pour qu'un `kind` ajouté côté serveur
/// ne fasse pas tomber l'écran d'un client plus ancien.
sealed class TurnBlock extends Equatable {
  const TurnBlock();

  /// Le bloc porte-t-il un geste ? Sert à savoir si le tour finit sur un mur.
  bool get isTouchable => false;
}

/// Une pastille : un raccourci vers une décision.
final class ChipItem extends Equatable {
  const ChipItem({
    required this.code,
    required this.label,
    this.reference = '',
    this.hint = '',
    this.origin = 'moteur',
    this.selected = false,
    this.signature,
  });

  final String code;
  final String label;

  /// La référence du passage désigné — « Colossiens 3:18-25 ». Vide pour ce
  /// qui n'en désigne aucun : un locus, un couple plan × matière.
  final String reference;

  final String hint;

  /// D'où vient la **proposition** — `locus`, `sens`, `correction`…
  final String origin;
  final bool selected;

  /// Qui a **habillé** la proposition, quand ce n'est pas le corpus. Les dix
  /// loci viennent tous de la dogmatique ; certains portent une phrase écrite
  /// par un modèle. Les confondre reviendrait à dire que l'axe est généré.
  final String? signature;

  @override
  List<Object?> get props =>
      [code, label, reference, hint, origin, selected, signature];
}

final class ChipsBlock extends TurnBlock {
  const ChipsBlock(this.items);

  final List<ChipItem> items;

  @override
  bool get isTouchable => items.isNotEmpty;

  @override
  List<Object?> get props => [items];
}

/// Une unité relue, dans le groupe qui dit ce qu'elle fait du sujet.
final class UnitItem extends Equatable {
  const UnitItem({
    required this.code,
    required this.label,
    this.reference = '',
    this.rationale = '',
  });

  final String code;
  final String label;
  final String reference;
  final String rationale;

  @override
  List<Object?> get props => [code, label, reference, rationale];
}

/// « En fait son sujet », « Le soutient », « Lui résiste ».
///
/// Le troisième groupe s'affiche **au même rang** que les deux autres : c'est
/// la seule mécanique anti-proof-texting du produit. Le reléguer en note de bas
/// de page reviendrait à fabriquer la preuve de ce qu'on avait déjà décidé de
/// trouver.
final class UnitGroup extends Equatable {
  const UnitGroup({
    required this.role,
    required this.heading,
    required this.items,
  });

  final String role;

  /// Écrit par le serveur. L'application ne le traduit pas.
  final String heading;
  final List<UnitItem> items;

  @override
  List<Object?> get props => [role, heading, items];
}

final class UnitsBlock extends TurnBlock {
  const UnitsBlock(this.groups);

  final List<UnitGroup> groups;

  @override
  bool get isTouchable => groups.any((group) => group.items.isNotEmpty);

  @override
  List<Object?> get props => [groups];
}

/// L'unité relue contre les bornes du pasteur.
///
/// Un bloc distinct des pastilles parce que la [consequence] n'est pas
/// optionnelle à l'affichage : garder ses bornes coupe l'alerte sur le risque
/// de proof-texting, et cela doit se lire avant de choisir.
final class BoundsBlock extends TurnBlock {
  const BoundsBlock({required this.items, this.consequence = ''});

  final List<ChipItem> items;
  final String consequence;

  @override
  bool get isTouchable => items.isNotEmpty;

  @override
  List<Object?> get props => [items, consequence];
}

/// Ce qu'un axe pèse dans ce texte.
final class BearingItem extends Equatable {
  const BearingItem({
    required this.axisCode,
    required this.label,
    required this.strength,
    required this.rationale,
    this.selected = false,
    this.selectable = false,
  });

  final String axisCode;
  final String label;

  /// `dominant`, `porte`, `resiste`, `absent`. Le vocabulaire du moteur.
  final String strength;
  final String rationale;

  /// L'axe sur lequel la préparation travaille — celui dont tout l'aval dépend.
  final bool selected;

  /// Cet axe peut être pris **à la place** de celui-là.
  ///
  /// Le geste existait de bout en bout côté serveur ; rien ne le disait. Une
  /// porte ouverte que personne ne voit est pire qu'une porte fermée : elle a
  /// l'air d'une fonctionnalité manquante.
  final bool selectable;

  @override
  List<Object?> get props =>
      [axisCode, label, strength, rationale, selected, selectable];
}

final class BearingsBlock extends TurnBlock {
  const BearingsBlock({
    required this.items,
    this.caveats = const [],
    this.decideStage = 'bear_axes',
  });

  final List<BearingItem> items;
  final List<String> caveats;

  /// ⚠️ **Où poster**, et ce n'est pas l'étage du tour. Les pesées
  /// accompagnent les tours qui suivent l'étage qui les a produites : envoyer
  /// une décision à l'étage courant serait refusé par le serveur.
  final String decideStage;

  @override
  bool get isTouchable => items.any((item) => item.selectable);

  @override
  List<Object?> get props => [items, caveats, decideStage];
}

/// Un couple plan × matière : ce que le texte peut tenir, ou refuse.
final class FeasibilityItem extends Equatable {
  const FeasibilityItem({
    required this.planSource,
    required this.subjectMatter,
    required this.feasible,
    this.risk = '',
    this.rationale = '',
  });

  final String planSource;
  final String subjectMatter;
  final bool feasible;
  final String risk;
  final String rationale;

  @override
  List<Object?> get props =>
      [planSource, subjectMatter, feasible, risk, rationale];
}

/// Les refusés voyagent avec les faisables : les cacher laisserait croire qu'on
/// n'y a pas pensé.
final class FeasibilityBlock extends TurnBlock {
  const FeasibilityBlock(this.items);

  final List<FeasibilityItem> items;

  @override
  List<Object?> get props => [items];
}

/// Un thème, jamais un titre — le titre, c'est la voix du pasteur.
final class ThemeBlock extends TurnBlock {
  const ThemeBlock(this.body);

  final String body;

  @override
  List<Object?> get props => [body];
}

/// Une sortie.
final class ActionItem extends Equatable {
  const ActionItem({
    required this.code,
    required this.label,
    required this.enabled,
    this.unavailableReason = '',
  });

  final String code;
  final String label;
  final bool enabled;

  /// Un bouton fermé **porte toujours son motif**. Un bouton grisé muet est un
  /// mensonge poli.
  final String unavailableReason;

  @override
  List<Object?> get props => [code, label, enabled, unavailableReason];
}

final class ActionsBlock extends TurnBlock {
  const ActionsBlock(this.items);

  final List<ActionItem> items;

  @override
  bool get isTouchable => items.any((item) => item.enabled);

  @override
  List<Object?> get props => [items];
}

/// Un `kind` que cette version ne connaît pas encore.
///
/// Le moteur gagne des étages ; une application installée ne les gagne pas en
/// même temps. Le bloc inconnu est **tu** plutôt que rendu de travers : le
/// reste du tour, lui, reste lisible et utilisable.
final class UnknownBlock extends TurnBlock {
  const UnknownBlock(this.kind);

  final String kind;

  @override
  List<Object?> get props => [kind];
}
