import 'package:urim/domain/entities/preparation/study.dart';
import 'package:urim/domain/entities/preparation/study_summary.dart';
import 'package:urim/domain/entities/preparation/turn.dart';

/// Un moteur de **démonstration** — il rejoue, il ne raisonne pas.
///
/// Il existe pour que l'application compilée reste parcourable sans serveur,
/// même raison que les identifiants de démonstration. Ce qu'il imite n'est pas
/// le raisonnement d'Urim — personne ne peut l'imiter — mais la **forme du
/// contrat** : un tour à la fois, trois phrases qui ne viennent pas du même
/// endroit, des blocs typés, et un pipeline qui repart du début à chaque
/// décision.
///
/// Les phrases sont celles du serveur, recopiées. C'est assumé : dans un build
/// de démonstration, ce moteur **tient la place** du serveur, et la règle « le
/// client n'écrit jamais une phrase de sa propre autorité » vaut pour l'écran,
/// pas pour le mannequin qui joue le serveur.
final class DemoUrimEngine {
  DemoUrimEngine();

  final Map<String, _DemoState> _states = {};

  /// Inscrit une préparation d'exemple à l'étage où elle doit apparaître.
  ///
  /// Sans effet si elle a déjà été touchée : ce que le pasteur a décidé dans
  /// cette session prime sur l'étage d'origine.
  void ensure(String studyId, {required TurnOutcome? outcome}) {
    if (_states.containsKey(studyId)) return;

    _states[studyId] = _DemoState(
      // Ce que le fil annonce doit se retrouver derrière la carte : une
      // préparation qui « rend la main » ouvre sur une question, une qui a
      // servi de la matière ouvre sur son thème.
      step: switch (outcome) {
        TurnOutcome.handsBack => _Step.axis,
        TurnOutcome.kept => _Step.bearings,
        TurnOutcome.refused => _Step.refused,
        _ => _Step.axis,
      },
    );
  }

  Study open(String studyId, String rawInput) {
    _states[studyId] = _DemoState(step: _Step.axis);
    return _study(studyId, rawInput);
  }

  Study read(String studyId, String rawInput) => _study(studyId, rawInput);

  Study decide(String studyId, String rawInput, String optionCode) {
    final state = _states.putIfAbsent(studyId, () => _DemoState(step: _Step.axis));

    // Le pipeline repart du début : ce qui a été décidé plus haut n'est pas
    // rejoué, mais rien n'est reconstruit à partir de l'étage courant.
    if (_axes.any((chip) => chip.code == optionCode)) {
      state.axisCode = optionCode;
    } else if (optionCode.startsWith('unit:')) {
      state.unitCode = optionCode;
    } else if (optionCode.startsWith('bounds:')) {
      state.boundsKept = optionCode == 'bounds:pericope';
    }

    return _study(studyId, rawInput);
  }

  Study dismiss(String studyId, String rawInput, String optionCode) {
    final state = _states.putIfAbsent(studyId, () => _DemoState(step: _Step.axis));
    state.dismissed.add(optionCode);
    return _study(studyId, rawInput);
  }

  /// Une phrase libre.
  ///
  /// **La liaison passe avant tout le reste** : « L'Église », « la péricope
  /// entière » désignent ce qui est à l'écran et se résolvent par comparaison
  /// de chaînes. Le mannequin ne sait rien faire d'autre — et c'est justement
  /// ce que le vrai moteur fait en premier, avant de payer un appel.
  Study say(String studyId, String rawInput, String said) {
    final study = _study(studyId, rawInput);
    final cherche = _plain(said);

    for (final block in study.turn?.blocks ?? const <TurnBlock>[]) {
      final trouve = switch (block) {
        ChipsBlock(:final items) || BoundsBlock(items: final items) =>
          items.where((item) => _plain(item.label) == cherche).firstOrNull?.code,
        UnitsBlock(:final groups) => groups
            .expand((group) => group.items)
            .where((item) => _plain(item.label) == cherche)
            .firstOrNull
            ?.code,
        _ => null,
      };

      if (trouve != null) return decide(studyId, rawInput, trouve);
    }

    // Rien de désigné : le tour ne bouge pas, et le mannequin le dit plutôt que
    // d'inventer un raisonnement.
    return _study(
      studyId,
      rawInput,
      say: 'Ce que je peux dire de votre travail est déjà sous vos yeux.',
    );
  }

  Study _study(String studyId, String rawInput, {String? say}) {
    final state = _states.putIfAbsent(studyId, () => _DemoState(step: _Step.axis));
    final etape = state.current;

    return Study(
      id: studyId,
      status: 'ouverte',
      rawInput: rawInput,
      theme: etape == _Step.bearings ? _theme : null,
      pericopeLabel: state.unitCode != null ? 'Actes 2:42-47' : null,
      axisCode: state.axisCode,
      boundsOverridden: state.boundsKept == false,
      outcome: switch (etape) {
        _Step.refused => TurnOutcome.refused,
        _Step.bearings => TurnOutcome.kept,
        _ => TurnOutcome.handsBack,
      },
      turn: _turn(state, say: say),
    );
  }

  Turn _turn(_DemoState state, {String? say}) => switch (state.current) {
        _Step.axis => Turn(
            say: say ?? 'Voici ce que je peux vous proposer ici.',
            why: 'Six de vos mots sont dans l\'Écriture, mais ils ne s\'y '
                'suivent pas. Ce n\'est pas une citation : c\'est ce que vous '
                'voulez dire. Je pars donc de votre intention vers un texte.',
            ask: 'Lequel retenez-vous ?',
            expects: TurnExpects.choice,
            stageCode: 'weigh_conviction',
            speaks: 'chips',
            blocks: [ChipsBlock(state.keep(_axes))],
          ),
        _Step.units => Turn(
            say: say ??
                'Voici les textes relus qui disent quelque chose de cet axe.',
            why: 'Votre formulation est chargée — j\'affiche davantage de '
                'textes qui résistent, et le risque de proof-texting sera '
                'relevé plus loin.',
            ask: 'Lequel ouvrons-nous ?',
            expects: TurnExpects.choice,
            stageCode: 'find_units',
            speaks: 'units',
            blocks: const [UnitsBlock(_unites)],
          ),
        _Step.bounds => Turn(
            say: say ?? 'Vos bornes ne coïncident pas avec l\'unité relue.',
            why: 'Vous aviez le verset 42 ; l\'unité littéraire va jusqu\'au '
                '47. S\'arrêter au 42 coupe la conséquence de ce qui est '
                'décrit.',
            ask: 'Lesquelles gardons-nous ?',
            expects: TurnExpects.choice,
            stageCode: 'bound_pericope',
            speaks: 'bounds',
            blocks: [
              BoundsBlock(
                items: state.keep(_bornes),
                consequence: 'Si vous gardez vos bornes, je ne pourrai plus '
                    'vous alerter sur un risque de proof-texting.',
              ),
            ],
          ),
        _Step.bearings => Turn(
            say: say ??
                'Voici ce que ce texte porte — et ce à quoi il résiste.',
            why: 'Les quatre appuis d\'Actes 2:42 sont énumérés au même '
                'niveau ; l\'ecclésiologie y domine, et la christologie n\'y '
                'est pas thématisée.',
            ask: 'Prêchez-le sur un autre de ses axes si le vôtre est '
                'ailleurs, ou ouvrez un autre passage.',
            expects: TurnExpects.text,
            stageCode: 'bear_axes',
            // Le bloc le plus avance parle : les pesees accompagnent, le theme
            // est ce que ce tour vient d'apporter. Meme regle que `_forme`
            // cote serveur.
            speaks: 'theme',
            signature: 'ia-mistral',
            blocks: const [
              BearingsBlock(items: _pesees, caveats: _reserves),
              ThemeBlock(_theme),
              ActionsBlock(_sorties),
            ],
          ),
        _Step.refused => Turn(
            say: say ?? 'Je n\'ai rien de plus à vous montrer sur ce point.',
            why: 'Aucun mot de cette phrase ne suit un ordre biblique, et '
                'aucune intention de prédication ne s\'en dégage. Je préfère '
                'vous le dire plutôt que de vous servir un passage au hasard.',
            ask: 'Donnez-moi un passage, ou reprenez votre sujet en clair.',
            expects: TurnExpects.text,
            stageCode: 'route_entry',
            speaks: 'rien',
          ),
      };
}

String _plain(String value) => value.trim().toLowerCase();

enum _Step { axis, units, bounds, bearings, refused }

final class _DemoState {
  _DemoState({required this.step});

  final _Step step;
  final Set<String> dismissed = {};

  String? axisCode;
  String? unitCode;
  bool? boundsKept;

  /// L'étage courant se déduit de ce qui a été décidé, pas d'un compteur : le
  /// pipeline repart du début à chaque tour, comme celui du serveur.
  _Step get current {
    if (step == _Step.refused) return _Step.refused;
    if (step == _Step.bearings) return _Step.bearings;
    if (axisCode == null) return _Step.axis;
    if (unitCode == null) return _Step.units;
    if (boundsKept == null) return _Step.bounds;
    return _Step.bearings;
  }

  /// Une option écartée reste dans la liste côté serveur, marquée et reléguée.
  /// Le mannequin, lui, la retire : il n'a pas de quoi la reléguer honnêtement.
  List<ChipItem> keep(List<ChipItem> items) =>
      items.where((item) => !dismissed.contains(item.code)).toList();
}

const _axes = [
  ChipItem(
    code: 'axe:ecclesiologie',
    label: 'L\'Église',
    hint: 'Ce qu\'est l\'assemblée, ce qui la tient, ce qu\'elle se doit à '
        'elle-même.',
    origin: 'locus',
  ),
  ChipItem(
    code: 'axe:anthropologie',
    label: 'L\'homme',
    hint: 'Si votre plainte porte sur ce que les gens sont devenus.',
    origin: 'locus',
  ),
  ChipItem(
    code: 'axe:hamartiologie',
    label: 'Le péché',
    hint: 'Ce qui s\'est rompu, et comment ça se manifeste.',
    origin: 'locus',
  ),
];

const _unites = [
  UnitGroup(
    role: 'dominant',
    heading: 'En fait son sujet',
    items: [
      UnitItem(
        code: 'unit:act-2-42',
        label: 'Actes 2:42-47',
        reference: 'Actes 2:42-47',
        rationale: 'Quatre appuis énumérés au même niveau.',
      ),
    ],
  ),
  UnitGroup(
    role: 'porte',
    heading: 'Le soutient',
    items: [
      UnitItem(
        code: 'unit:eph-4-1',
        label: 'Éphésiens 4:1-6',
        reference: 'Éphésiens 4:1-6',
        rationale: 'L\'unité y est un donné à garder, pas un résultat à '
            'produire.',
      ),
    ],
  ),
  UnitGroup(
    role: 'resiste',
    heading: 'Lui résiste',
    items: [
      UnitItem(
        code: 'unit:1co-11-17',
        label: '1 Corinthiens 11:17-22',
        reference: '1 Corinthiens 11:17-22',
        rationale: 'La même assemblée qui rompt le pain s\'y divise en le '
            'faisant.',
      ),
      UnitItem(
        code: 'unit:mat-7-1',
        label: 'Matthieu 7:1-5',
        reference: 'Matthieu 7:1-5',
        rationale: 'Se retourne vers celui qui constate le manque chez les '
            'autres.',
      ),
    ],
  ),
];

const _bornes = [
  ChipItem(
    code: 'bounds:pericope',
    label: 'La péricope entière',
    hint: 'Actes 2:42-47, l\'unité relue.',
  ),
  ChipItem(
    code: 'bounds:verse',
    label: 'Mon verset seul',
    hint: 'Vous forcez les bornes — les pesées relues ne s\'appliqueront plus.',
  ),
];

const _pesees = [
  BearingItem(
    axisCode: 'axe:ecclesiologie',
    label: 'L\'Église',
    strength: 'dominant',
    rationale: 'Les quatre appuis décrivent ce qui tient l\'assemblée.',
    selected: true,
  ),
  BearingItem(
    axisCode: 'axe:pneumatologie',
    label: 'L\'Esprit',
    strength: 'porte',
    rationale: 'Le contexte immédiat est celui de la Pentecôte.',
    selectable: true,
  ),
  BearingItem(
    axisCode: 'axe:eschatologie',
    label: 'Les fins dernières',
    strength: 'resiste',
    rationale: 'Rien dans l\'unité ne porte l\'attente du retour.',
  ),
];

const _reserves = [
  'Votre formulation est chargée : le risque de proof-texting est relevé.',
];

const _theme = 'La communion comme pratique, non comme sentiment.';

const _sorties = [
  ActionItem(code: 'elements', label: 'Écrire mes points', enabled: true),
  ActionItem(
    code: 'deck',
    label: 'PowerPoint',
    enabled: false,
    unavailableReason: 'Le livrable n\'est pas ouvert : une citation projetée '
        'doit d\'abord être contrôlée.',
  ),
  ActionItem(
    code: 'sheet',
    label: 'Fiche de chaire',
    enabled: false,
    unavailableReason: 'Le livrable n\'est pas ouvert : une citation projetée '
        'doit d\'abord être contrôlée.',
  ),
];
