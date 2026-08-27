import 'package:flutter_test/flutter_test.dart';
import 'package:urim/core/id/id_generator.dart';
import 'package:urim/core/time/clock.dart';
import 'package:urim/data/repositories/in_memory_preparation_repository.dart';
import 'package:urim/data/repositories/study_repository_impl.dart';
import 'package:urim/domain/entities/preparation/preparation.dart';
import 'package:urim/domain/entities/preparation/study_summary.dart';
import 'package:urim/presentation/home/opening_rule.dart';

final class _FixedClock implements Clock {
  const _FixedClock(this._now);
  final DateTime _now;

  @override
  DateTime now() => _now;
}

final class _SequentialIds implements IdGenerator {
  int _next = 0;

  @override
  String newId() => 'id-${_next++}';
}

/// Sur quelle page l'application s'ouvre — et pourquoi personne n'a eu à le
/// dire.
///
/// Ce fichier tient la seule règle qui déroge à l'ordinaire. Elle doit rester
/// lisible en une phrase : **on ouvre sur « préparer », sauf le jour du culte,
/// tant que rien n'a été capté ce jour-là.**
void main() {
  // Août 2026 : le 26 est un mercredi, le 30 un dimanche.
  final mercredi = DateTime(2026, 8, 26, 21, 40);
  final dimanche = DateTime(2026, 8, 30, 6, 50);

  StudySummary prepare({
    String id = 'p1',
    DateTime? service,
    DateTime? activity,
  }) =>
      StudySummary(
        id: id,
        rawInput: 'Le pardon entre deux familles',
        lastActivity: activity ?? DateTime(2026, 8, 25, 18),
        serviceDate: service,
      );

  StudySummary preche({required String id, required DateTime le}) =>
      StudySummary(
        id: id,
        rawInput: 'Prédication du ${le.day}',
        lastActivity: le,
        origin: PreparationOrigin.transcribed,
      );

  group('le jour ordinaire', () {
    test('un mercredi sans rien de particulier ouvre sur la préparation', () {
      expect(
        openingTab(now: mercredi, summaries: [prepare()]),
        HomeTab.prepare,
      );
    });

    test('la règle ne fait rien six jours sur sept', () {
      // Le corpus dit dimanche ; du lundi au samedi, elle se tait.
      final corpus = [
        preche(id: 'a', le: DateTime(2026, 8, 23, 10)),
        preche(id: 'b', le: DateTime(2026, 8, 16, 10)),
      ];

      final ouvertures = [
        for (var jour = 24; jour <= 29; jour++)
          openingTab(now: DateTime(2026, 8, jour, 8), summaries: corpus),
      ];

      expect(ouvertures, everyElement(HomeTab.prepare));
    });
  });

  group('le jour du culte', () {
    test('dimanche, rien de capté : on ouvre sur les prédications', () {
      expect(
        openingTab(now: dimanche, summaries: [prepare()]),
        HomeTab.preach,
      );
    });

    test('une fois le culte capté, la dérogation tombe d\'elle-même', () {
      final summaries = [
        prepare(),
        preche(id: 'culte', le: DateTime(2026, 8, 30, 10, 22)),
      ];

      expect(
        openingTab(now: DateTime(2026, 8, 30, 15, 40), summaries: summaries),
        HomeTab.prepare,
      );
    });

    test('la capture de dimanche dernier ne relâche pas celle d\'aujourd\'hui',
        () {
      // 🔴 Le piège : comparer « il existe une capture » au lieu de « il existe
      // une capture aujourd'hui » ferait taire la règle dès la deuxième semaine.
      final summaries = [preche(id: 'passe', le: DateTime(2026, 8, 23, 10))];

      expect(openingTab(now: dimanche, summaries: summaries), HomeTab.preach);
    });

    test('une préparation écrite le matin même n\'est pas une capture', () {
      final summaries = [prepare(activity: DateTime(2026, 8, 30, 7))];

      expect(openingTab(now: dimanche, summaries: summaries), HomeTab.preach);
    });
  });

  group('d\'où vient le jour du culte', () {
    test('source 1 : une préparation datée d\'aujourd\'hui, un mercredi', () {
      final summaries = [prepare(service: DateTime(2026, 8, 26))];

      expect(
        isServiceDay(now: mercredi, summaries: summaries),
        isTrue,
        reason: 'le pasteur a lui-même daté son culte : rien de plus sûr',
      );
      expect(openingTab(now: mercredi, summaries: summaries), HomeTab.preach);
    });

    test('source 2 : le corpus apprend qu\'on prêche le mercredi', () {
      final summaries = [
        preche(id: 'a', le: DateTime(2026, 8, 19, 19)),
        preche(id: 'b', le: DateTime(2026, 8, 12, 19)),
      ];

      expect(isServiceDay(now: mercredi, summaries: summaries), isTrue);
      expect(
        isServiceDay(now: dimanche, summaries: summaries),
        isFalse,
        reason: 'une assemblée qui se réunit le mercredi ne prêche pas dimanche',
      );
    });

    test('source 2 : à égalité, la prédication la plus récente l\'emporte', () {
      final summaries = [
        preche(id: 'merc', le: DateTime(2026, 8, 26, 19)),
        preche(id: 'dim', le: DateTime(2026, 8, 23, 10)),
      ];

      expect(isServiceDay(now: DateTime(2026, 9, 2, 8), summaries: summaries),
          isTrue);
    });

    test('source 3 : sans corpus ni date, c\'est dimanche', () {
      expect(isServiceDay(now: dimanche, summaries: const []), isTrue);
      expect(isServiceDay(now: mercredi, summaries: const []), isFalse);
    });

    test('le corpus ne prend pas le pas sur une date posée à la main', () {
      // Le corpus dit dimanche, mais ce mercredi-là porte un culte : la source
      // la plus précise gagne.
      final summaries = [
        preche(id: 'a', le: DateTime(2026, 8, 23, 10)),
        preche(id: 'b', le: DateTime(2026, 8, 16, 10)),
        prepare(service: DateTime(2026, 8, 26)),
      ];

      expect(openingTab(now: mercredi, summaries: summaries), HomeTab.preach);
    });
  });

  group('le jeu de démonstration rejoue les deux branches', () {
    // 🔴 **La règle était juste, et invisible.** La prédication transcrite du
    // jeu d'exemple était ancrée à « il y a six jours » : le jour de culte
    // déduit du corpus tombait donc toujours sur *demain*, et la dérogation ne
    // pouvait se déclencher aucun jour de l'année. Rien n'échouait — c'est bien
    // le problème : la démonstration ne rejouait qu'une moitié du schéma, et il
    // a fallu l'installer sur un téléphone pour s'en apercevoir.
    Future<List<StudySummary>> corpus(DateTime now) async {
      final repository = MockStudyRepository(
        InMemoryPreparationRepository(
          clock: _FixedClock(now),
          ids: _SequentialIds(),
        ),
      );

      final result = await repository.listMine();

      return result.fold(
        onSuccess: (summaries) => summaries,
        onFailure: (failure) => throw failure,
      );
    }

    test('le culte de démonstration tombe le dimanche précédent', () async {
      // Lundi 24 août 2026 : le dimanche d'avant est le 23.
      final summaries = await corpus(DateTime(2026, 8, 24, 9));
      final preached = summaries.singleWhere(
        (s) => s.origin == PreparationOrigin.transcribed,
      );

      expect(preached.lastActivity.weekday, DateTime.sunday);
      expect(preached.serviceDate, DateTime(2026, 8, 23));
      expect(
        preached.rawInput,
        contains('prêché le 23 août'),
        reason: 'le titre répète la date : deux valeurs figées divergeraient',
      );
    });

    test('un lundi, l\'accueil s\'ouvre sur les préparations', () async {
      final now = DateTime(2026, 8, 24, 9);

      expect(
        openingTab(now: now, summaries: await corpus(now)),
        HomeTab.prepare,
      );
    });

    test('un dimanche matin, il s\'ouvre sur les prédications', () async {
      final now = DateTime(2026, 8, 30, 8);

      expect(
        openingTab(now: now, summaries: await corpus(now)),
        HomeTab.preach,
        reason: 'le corpus enseigne le dimanche, et rien n\'est capté ce matin',
      );
    });
  });

  group('la date proposee au prochain culte', () {
    // 🔴 **La proposition etait « dimanche prochain », en dur.** Un pasteur qui
    // preche le mercredi soir se voyait proposer un dimanche a chaque
    // preparation, et corrigeait a la main chaque fois. La deduction qui choisit
    // l'ecran d'ouverture sait deja quel jour cette assemblee se reunit.
    test('sans corpus, c\'est dimanche', () {
      // Mercredi 26 aout 2026 : le dimanche suivant est le 30.
      expect(
        nextService(from: mercredi, summaries: const []),
        DateTime(2026, 8, 30),
      );
    });

    test('le corpus impose son jour : ici, le mercredi', () {
      final summaries = [
        preche(id: 'a', le: DateTime(2026, 8, 19, 19)),
        preche(id: 'b', le: DateTime(2026, 8, 12, 19)),
      ];

      // Depuis un dimanche, le prochain culte de cette assemblee est mercredi.
      expect(
        nextService(from: dimanche, summaries: summaries),
        DateTime(2026, 9, 2),
      );
    });

    test('le culte du jour ne se prepare plus : on passe au suivant', () {
      final summaries = [preche(id: 'a', le: DateTime(2026, 8, 23, 10))];

      // On est dimanche, et le corpus dit dimanche : c\'est celui d\'apres.
      expect(
        nextService(from: dimanche, summaries: summaries),
        DateTime(2026, 9, 6),
      );
    });
  });

  group('la conversation que l\'accueil reprend', () {
    // L'accueil **est** la conversation : il lui faut donc savoir laquelle
    // ouvrir. Aucun test ne tenait cette règle, et c'est la plus visible.
    StudySummary travail({
      required String id,
      DateTime? service,
      DateTime? activity,
      TurnOutcome? issue,
      bool close = false,
      PreparationOrigin origine = PreparationOrigin.written,
    }) =>
        StudySummary(
          id: id,
          rawInput: id,
          lastActivity: activity ?? DateTime(2026, 8, 20, 12),
          serviceDate: service,
          lastOutcome: issue,
          isClosed: close,
          origin: origine,
        );

    final maintenant = DateTime(2026, 8, 24, 9);

    test('rien a reprendre rend nul', () {
      expect(resumeId(const [], now: maintenant), isNull);
    });

    test('ce qui rend la main passe devant tout', () {
      final id = resumeId(
        [
          travail(id: 'proche', service: DateTime(2026, 8, 26)),
          travail(id: 'attend', issue: TurnOutcome.handsBack),
        ],
        now: maintenant,
      );

      expect(id, 'attend', reason: 'personne ne peut avancer a sa place');
    });

    test('sinon, le culte le plus proche', () {
      final id = resumeId(
        [
          travail(id: 'loin', service: DateTime(2026, 9, 6)),
          travail(id: 'proche', service: DateTime(2026, 8, 26)),
        ],
        now: maintenant,
      );

      expect(id, 'proche');
    });

    test('une date passee n\'est plus une echeance', () {
      // 🔴 Sans ce garde-fou, un culte d'il y a trois semaines passerait devant
      // celui de dimanche prochain, sous pretexte qu'il est « plus proche ».
      final id = resumeId(
        [
          travail(id: 'passe', service: DateTime(2026, 8, 2)),
          travail(id: 'avenir', service: DateTime(2026, 8, 30)),
        ],
        now: maintenant,
      );

      expect(id, 'avenir');
    });

    test('sans echeance, le dernier touche', () {
      final id = resumeId(
        [
          travail(id: 'vieux', activity: DateTime(2026, 8, 10)),
          travail(id: 'frais', activity: DateTime(2026, 8, 23, 21)),
        ],
        now: maintenant,
      );

      expect(id, 'frais');
    });

    test('une preparation close ne se reprend pas', () {
      // « J'ai preche celle-ci » n'est pas un travail en cours. Elle reste
      // dans le tiroir, ou on va la rechercher.
      final id = resumeId(
        [
          travail(id: 'close', close: true, issue: TurnOutcome.handsBack),
          travail(id: 'ouverte'),
        ],
        now: maintenant,
      );

      expect(id, 'ouverte');
    });

    test('une prediction transcrite n\'est pas une preparation', () {
      final id = resumeId(
        [travail(id: 'prechee', origine: PreparationOrigin.transcribed)],
        now: maintenant,
      );

      expect(id, isNull);
    });
  });

  group('capturedOn', () {
    test('ne regarde que les prédications, et que ce jour-là', () {
      final summaries = [
        prepare(activity: DateTime(2026, 8, 30, 9)),
        preche(id: 'hier', le: DateTime(2026, 8, 29, 10)),
      ];

      expect(capturedOn(dimanche, summaries: summaries), isFalse);

      expect(
        capturedOn(
          dimanche,
          summaries: [...summaries, preche(id: 'ce matin', le: dimanche)],
        ),
        isTrue,
      );
    });
  });
}
