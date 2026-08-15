import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/core/id/id_generator.dart';
import 'package:urim/core/id/id_generator_provider.dart';
import 'package:urim/core/result/result.dart';
import 'package:urim/core/time/clock.dart';
import 'package:urim/core/time/clock_provider.dart';
import 'package:urim/domain/entities/bible/scripture_reference.dart';
import 'package:urim/domain/entities/preparation/preparation.dart';
import 'package:urim/domain/entities/preparation/preparation_block.dart';
import 'package:urim/domain/repositories/preparation_repository.dart';

/// Dépôt **temporaire**, en mémoire.
///
/// Il existe pour que l'écran de préparation soit manipulable avant que la
/// question du stockage (Q4) ne soit tranchée. Rien n'est conservé d'un
/// lancement à l'autre.
///
/// Il sera remplacé par une implémentation Drift : les préférences système ne
/// conviennent pas à un fil qui grandit ni à un audio de plusieurs dizaines de
/// mégaoctets. Le contrat ne changera pas — seul ce fichier.
final class InMemoryPreparationRepository implements PreparationRepository {
  InMemoryPreparationRepository({required Clock clock, required IdGenerator ids})
      : _clock = clock,
        _ids = ids {
    _seed();
  }

  final Clock _clock;
  final IdGenerator _ids;

  final Map<String, Preparation> _store = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  @override
  Stream<Result<List<Preparation>>> watchPreparations() async* {
    yield Result.success(_sorted());
    yield* _changes.stream.map((_) => Result.success(_sorted()));
  }

  @override
  Future<Result<Preparation>> getById(String preparationId) async {
    final preparation = _store[preparationId];

    if (preparation == null) {
      return const Result.failed(
        CacheFailure(
          message: 'Cette préparation n\'existe plus.',
          code: 'preparation_not_found',
        ),
      );
    }

    return Result.success(preparation);
  }

  @override
  Future<Result<Preparation>> save(Preparation preparation) async {
    _store[preparation.id] = preparation;
    _notify();
    return Result.success(preparation);
  }

  @override
  Future<Result<void>> delete(String preparationId) async {
    _store.remove(preparationId);
    _notify();
    return const Result.success(null);
  }

  @override
  Future<Result<Preparation>> appendBlock({
    required String preparationId,
    required PreparationBlock block,
  }) async {
    final preparation = _store[preparationId];

    if (preparation == null) {
      return const Result.failed(
        CacheFailure(
          message: 'Cette préparation n\'existe plus.',
          code: 'preparation_not_found',
        ),
      );
    }

    // La date de dernière activité suit l'ajout : c'est elle qui ordonne
    // l'accueil, pas la date de création.
    final updated = preparation.copyWith(
      blocks: [...preparation.blocks, block],
      updatedAt: _clock.now(),
    );

    _store[preparation.id] = updated;
    _notify();

    return Result.success(updated);
  }

  @override
  Future<Result<List<Preparation>>> search(String query) async {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return const Result.success([]);

    return Result.success(
      _sorted().where((preparation) {
        if (preparation.title.toLowerCase().contains(needle)) return true;
        if (preparation.summary.toLowerCase().contains(needle)) return true;

        return preparation.blocks.any(
          (block) => switch (block) {
            UserBlock(:final text) => text.toLowerCase().contains(needle),
            ScriptureBlock(:final passage) =>
              passage.text.toLowerCase().contains(needle),
            UrimTurn(:final reasoning, :final statement, :final passage) =>
              (reasoning ?? '').toLowerCase().contains(needle) ||
                  (statement ?? '').toLowerCase().contains(needle) ||
                  (passage?.text ?? '').toLowerCase().contains(needle),
            SynthesisBlock(:final lead, :final points) =>
              lead.toLowerCase().contains(needle) ||
                  points.any(
                    (point) =>
                        point.heading.toLowerCase().contains(needle) ||
                        point.body.toLowerCase().contains(needle),
                  ),
          },
        );
      }).toList(),
    );
  }

  void dispose() => _changes.close();

  List<Preparation> _sorted() =>
      _store.values.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  /// Ouvre une préparation à partir de ce que l'utilisateur vient d'écrire.
  ///
  /// Le titre est tiré de la première phrase : la maquette montre « Amour
  /// fraternel » au-dessus d'un fil ouvert par « l'amour fraternel n'existe
  /// plus dans l'église ». Nommer soi-même viendra plus tard.
  Future<Result<Preparation>> open({
    required String text,
    DateTime? serviceDate,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const Result.failed(
        ValidationFailure(
          message: 'Rien à ouvrir.',
          fieldErrors: {'text': 'Écris une phrase, une référence, une idée.'},
          code: 'preparation_empty',
        ),
      );
    }

    final now = _clock.now();
    final preparation = Preparation(
      id: _ids.newId(),
      title: _titleFrom(trimmed),
      summary: 'Ouverte à l\'instant. Urim n\'a pas encore répondu.',
      origin: PreparationOrigin.written,
      createdAt: now,
      updatedAt: now,
      state: PreparationState.served,
      serviceDate: serviceDate,
      blocks: [
        UserBlock(id: _ids.newId(), anchor: ClockAnchor(now), text: trimmed),
      ],
    );

    return save(preparation);
  }

  /// Quatre mots au plus, sans ponctuation de fin.
  static String _titleFrom(String text) {
    final words = text
        .replaceAll(RegExp(r'[«»"“”]'), '')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(4)
        .join(' ');

    final title = words.replaceAll(RegExp(r'[.,;:!?]+$'), '');

    return title.isEmpty
        ? 'Préparation'
        : title[0].toUpperCase() + title.substring(1);
  }

  /// Jeu d'exemple repris des maquettes : quatre travaux dans les quatre
  /// états, et un fil guidé complet sur le premier.
  void _seed() {
    final now = _clock.now();

    _add(_brotherlyLove(now.subtract(const Duration(hours: 13))));
    _add(_actsPericope(now.subtract(const Duration(days: 4))));
    _add(_hebrewsPreached(now.subtract(const Duration(days: 6))));
    _add(_openMicrophone(now.subtract(const Duration(days: 11))));
  }

  void _add(Preparation preparation) => _store[preparation.id] = preparation;

  /// « L'amour fraternel n'existe plus dans l'église » — le fil guidé des
  /// maquettes, jusqu'à la question sur les bornes du passage.
  Preparation _brotherlyLove(DateTime at) {
    final anchor = ClockAnchor(at);

    return Preparation(
      id: _ids.newId(),
      title: 'Amour fraternel',
      summary: 'Six passages proposés. Le moteur attend que tu choisisses '
          'lequel tu lis.',
      origin: PreparationOrigin.written,
      createdAt: at,
      updatedAt: at,
      state: PreparationState.handsBack,
      blocks: [
        UserBlock(
          id: _ids.newId(),
          anchor: anchor,
          text: 'L\'amour fraternel n\'existe plus dans l\'église.',
        ),
        UrimTurn(
          id: _ids.newId(),
          anchor: anchor,
          reasoning: 'Six de tes mots sont dans l\'Écriture, mais ils ne s\'y '
              'suivent pas. Ce n\'est pas une citation : c\'est ce que tu veux '
              'dire. Je pars donc de ton intention vers un texte.',
          question: 'Sur quel axe veux-tu prêcher ?',
          choices: const [
            TurnChoice(
              label: 'L\'Église',
              detail: 'Ce qu\'est l\'assemblée, ce qui la tient, ce qu\'elle '
                  'se doit à elle-même.',
            ),
            TurnChoice(
              label: 'L\'homme',
              detail: 'Si ta plainte porte sur ce que les gens sont devenus.',
            ),
            TurnChoice(
              label: 'Le péché',
              detail: 'Ce qui s\'est rompu, et comment ça se manifeste.',
            ),
          ],
          moreLabel: 'Voir les dix loci',
          trace: 'Tes mots recoupent le vocabulaire de la charité fraternelle, '
              'mais dans un ordre qui n\'apparaît nulle part : j\'ai donc lu '
              'une intention, pas une référence. Les trois axes proposés sont '
              'ceux des loci que ta phrase touche.',
        ),
        UserBlock(id: _ids.newId(), anchor: anchor, text: 'L\'Église'),
        UrimTurn(
          id: _ids.newId(),
          anchor: anchor,
          reasoning: 'Ta formulation est chargée — j\'affiche davantage de '
              'textes qui résistent, et le risque de proof-texting sera relevé '
              'plus loin.',
          statement: 'Voici ce que l\'Écriture dit de l\'Église. Ceux qui '
              'portent ta lecture et ceux qui la compliquent sont au même '
              'rang.',
          texts: [
            WeighedText(
              stance: TextStance.subject,
              ref: const VerseRef(bookId: 'act', chapter: 2, verse: 42)
                  .through(const VerseRef(bookId: 'act', chapter: 2, verse: 47)),
              referenceLabel: 'Actes 2:42-47',
              note: 'Quatre appuis énumérés au même niveau.',
            ),
            WeighedText(
              stance: TextStance.supports,
              ref: const VerseRef(bookId: 'eph', chapter: 4, verse: 1)
                  .through(const VerseRef(bookId: 'eph', chapter: 4, verse: 6)),
              referenceLabel: 'Éphésiens 4:1-6',
              note: 'L\'unité y est un donné à garder, pas un résultat à '
                  'produire.',
            ),
            WeighedText(
              stance: TextStance.complicates,
              ref: const VerseRef(bookId: '1co', chapter: 11, verse: 17).through(
                const VerseRef(bookId: '1co', chapter: 11, verse: 22),
              ),
              referenceLabel: '1 Corinthiens 11:17-22',
              note: 'La même assemblée qui rompt le pain s\'y divise en le '
                  'faisant.',
            ),
            WeighedText(
              stance: TextStance.complicates,
              ref: const VerseRef(bookId: 'mat', chapter: 7, verse: 1)
                  .through(const VerseRef(bookId: 'mat', chapter: 7, verse: 5)),
              referenceLabel: 'Matthieu 7:1-5',
              note: 'Se retourne vers celui qui constate le manque chez les '
                  'autres.',
            ),
          ],
        ),
        UserBlock(id: _ids.newId(), anchor: anchor, text: 'Actes 2:42-47'),
        UrimTurn(
          id: _ids.newId(),
          anchor: anchor,
          reasoning: 'Tu avais le verset 42 ; l\'unité littéraire va jusqu\'au '
              '47. S\'arrêter au 42 coupe la conséquence de ce qui est décrit.',
          passage: QuotedPassage(
            ref: const VerseRef(bookId: 'act', chapter: 2, verse: 42).asPassage(),
            referenceLabel: 'Actes 2:42',
            text: 'Ils persévéraient dans l\'enseignement des apôtres, dans la '
                'communion fraternelle, dans la fraction du pain et dans les '
                'prières.',
            translationLabel: 'LSG 1910',
            pericopeLabel: 'péricope 42-47',
          ),
          question: 'Je continue sur la péricope entière, ou je m\'en tiens à '
              'ton verset ?',
          choices: const [
            TurnChoice(label: 'La péricope entière'),
            TurnChoice(
              label: 'Mon verset seul',
              detail: 'Tu forces les bornes — les pesées relues ne '
                  's\'appliqueront plus.',
            ),
          ],
        ),
      ],
    );
  }

  /// Le même travail, une fois l'axe tenu et la matière servie.
  Preparation _actsPericope(DateTime at) {
    final anchor = ClockAnchor(at);

    return Preparation(
      id: _ids.newId(),
      title: 'Actes 2:42-47',
      summary: 'Péricope bornée, axe retenu : la communion comme pratique. '
          'Squelette à trois mouvements, deux remplis.',
      origin: PreparationOrigin.written,
      createdAt: at,
      updatedAt: at,
      state: PreparationState.served,
      serviceDate: DateTime(at.year, 8, 17),
      blocks: [
        UserBlock(
          id: _ids.newId(),
          anchor: anchor,
          text: 'Je garde la péricope entière, axe : la communion comme '
              'pratique.',
        ),
        SynthesisBlock(
          id: _ids.newId(),
          anchor: anchor,
          lead: 'Trois mouvements tiennent dans la péricope. Le troisième '
              'attend encore ta matière :',
          points: const [
            SynthesisPoint(
              heading: 'Quatre appuis, pas un.',
              body: 'Enseignement, communion, table, prière — l\'isolement '
                  'casse l\'ensemble.',
            ),
            SynthesisPoint(
              heading: 'La table est un lieu, pas une image.',
              body: 'La fraction du pain se fait dans les maisons, au jour le '
                  'jour.',
            ),
            SynthesisPoint(
              heading: 'La croissance vient après.',
              body: 'Le verset 47 met l\'accroissement au bout de la pratique, '
                  'pas à son origine.',
            ),
          ],
          caution: 'Relis les sources avant de prêcher.',
        ),
      ],
    );
  }

  /// Un message déjà prêché, avec le retour d'Urim.
  Preparation _hebrewsPreached(DateTime at) {
    final anchor = ClockAnchor(at);

    return Preparation(
      id: _ids.newId(),
      title: 'Hébreux 13:1-6 — prêché le 9 août',
      summary: 'Transcrit. Trois textes convoqués sans avoir été prévus. '
          'Un mouvement non repéré.',
      origin: PreparationOrigin.transcribed,
      createdAt: at,
      updatedAt: at,
      state: PreparationState.feedbackReady,
      serviceDate: DateTime(at.year, 8, 9),
      blocks: [
        UrimTurn(
          id: _ids.newId(),
          anchor: anchor,
          statement: 'Trois textes que tu n\'avais pas prévus sont venus '
              'pendant la prédication.',
          reasoning: 'Je les ai reconnus dans l\'enregistrement. Le mouvement '
              'sur l\'hospitalité n\'était dans aucune de tes notes.',
        ),
      ],
    );
  }

  /// Une dictée refusée : Urim dit pourquoi plutôt que d'inventer.
  Preparation _openMicrophone(DateTime at) {
    final anchor = ClockAnchor(at);

    return Preparation(
      id: _ids.newId(),
      title: '« ma voiture 406 a besoin de reparation »',
      summary: 'Refusé. Dictée sans texte lisible — probablement un micro '
          'resté ouvert.',
      origin: PreparationOrigin.written,
      createdAt: at,
      updatedAt: at,
      state: PreparationState.refused,
      blocks: [
        UserBlock(
          id: _ids.newId(),
          anchor: anchor,
          text: 'ma voiture 406 a besoin de reparation',
        ),
        UrimTurn(
          id: _ids.newId(),
          anchor: anchor,
          statement: 'Je ne vois pas de texte là-dedans.',
          reasoning: 'Aucun mot de cette phrase ne suit un ordre biblique, et '
              'aucune intention de prédication ne s\'en dégage. Je préfère te '
              'le dire plutôt que de te servir un passage au hasard.',
          trace: 'Recherche menée sur l\'ordre des mots, puis sur '
              'l\'intention : les deux sont revenues vides.',
        ),
      ],
    );
  }

  /// Identifiant du fil guidé d'exemple.
  String? get seededId => _store.keys.isEmpty ? null : _store.keys.first;
}

final preparationRepositoryProvider = Provider<InMemoryPreparationRepository>(
  (ref) {
    // Le magasin est la seule copie des préparations : le libérer parce que
    // plus personne ne l'écoute effacerait le travail en cours.
    ref.keepAlive();

    final repository = InMemoryPreparationRepository(
      clock: ref.watch(clockProvider),
      ids: ref.watch(idGeneratorProvider),
    );
    ref.onDispose(repository.dispose);
    return repository;
  },
);
