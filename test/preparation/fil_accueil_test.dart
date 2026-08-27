import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urim/data/datasources/urim_remote_data_source.dart';
import 'package:urim/domain/entities/preparation/preached.dart';
import 'package:urim/domain/entities/preparation/study_summary.dart';
import 'package:urim/l10n/generated/app_text_fr.dart';
import 'package:urim/presentation/common/domain_labels.dart';

/// Répond ce qu'on lui a mis dans la bouche, sans réseau.
final class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.body);

  final String body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      ResponseBody.fromString(
        body,
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  void close({bool force = false}) {}
}

UrimRemoteDataSource sourceRendant(String json) {
  final dio = Dio(BaseOptions(baseUrl: 'http://serveur/api/mobile'))
    ..httpClientAdapter = _StubAdapter(json);
  return UrimRemoteDataSource(dio);
}

void main() {
  final texte = AppTextFr();

  group('le vocabulaire du moteur', () {
    test('les quatre issues traversent telles quelles', () {
      expect(TurnOutcome.fromWire('continue'), TurnOutcome.kept);
      expect(TurnOutcome.fromWire('await_decision'), TurnOutcome.handsBack);
      expect(TurnOutcome.fromWire('refuse'), TurnOutcome.refused);
      expect(TurnOutcome.fromWire('degrade'), TurnOutcome.degraded);
    });

    test('un mot que le serveur a appris seul ne fait pas tomber la ligne', () {
      // Un étage ajouté côté serveur avant que l'application ne suive : la
      // préparation doit rester dans le fil, sans pastille.
      expect(TurnOutcome.fromWire('arbitrate'), isNull);
      expect(TurnOutcome.fromWire(null), isNull);
    });

    test('« rend la main » est la seule issue qui attend une réponse', () {
      expect(
        TurnOutcome.values.where((o) => o.waitsForUser),
        [TurnOutcome.handsBack],
      );
    });

    test('chaque issue a son mot français, et un seul', () {
      final libelles = {
        for (final outcome in TurnOutcome.values)
          outcome: turnOutcomeLabel(texte, outcome),
      };

      expect(libelles.values.toSet(), hasLength(TurnOutcome.values.length));
      expect(libelles[TurnOutcome.handsBack], 'Rend la main');
      expect(
        libelles[TurnOutcome.degraded],
        isNot(libelles[TurnOutcome.refused]),
        reason: 'servir moins n\'est pas refuser : il y a de la matière',
      );
    });
  });

  group('l\'archive du prédicateur', () {
    // Ces lecteurs ont été écrits contre le contrat serveur sans compilateur.
    // Ce groupe est ce qui les tient.

    test('une ligne sans jour est ecartee, sans bruit', () async {
      // 🔴 **La date n'est jamais inventee.** Elle ordonne l'archive et nourrit
      // la couverture : poser « aujourd'hui » sur un sermon de l'an dernier le
      // remonterait en tete et fausserait le canon.
      final source = sourceRendant('''
        [
          {"id": "a", "preached_on": "2026-08-23", "reference": "Actes 1:1-14",
           "pericope_label": null, "axis_code": null, "theme": null,
           "capture_kind": "saisie", "preparation_id": null, "church_id": null},
          {"id": "b", "preached_on": null, "reference": "Jean 3:16",
           "pericope_label": null, "axis_code": null, "theme": null,
           "capture_kind": null, "preparation_id": null, "church_id": null}
        ]
      ''');

      final archive = await source.listPreached();

      expect(archive, hasLength(1));
      expect(archive.single.id, 'a');
    });

    test('un axe nul se garde : c\'est le rayon « non rangé »', () async {
      // Le serveur le dit dans son contrat : le client doit le nommer plutot
      // que de masquer la ligne. Hors unite curee, il n'y a aucun axe a retenir.
      final source = sourceRendant('''
        [
          {"id": "a", "preached_on": "2026-08-23", "reference": "Actes 1:1-14",
           "pericope_label": "Actes 1 — l'ascension", "axis_code": null,
           "theme": null, "capture_kind": "saisie", "preparation_id": "p1",
           "church_id": null}
        ]
      ''');

      final ligne = (await source.listPreached()).single;

      expect(ligne.axisCode, isNull);
      expect(ligne.preparationId, 'p1');
      expect(
        ligne.label,
        'Actes 1 — l\'ascension',
        reason: 'l\'unite en tete de ligne, la reference a defaut',
      );
    });

    test('sans unite, la reference tient lieu de titre', () {
      final ligne = PreachedSermon(
        id: 'a',
        preachedOn: DateTime(2026, 8, 23),
        reference: 'Psaume 125',
      );

      expect(ligne.label, 'Psaume 125');
    });

    test('la couverture garde ses deux nombres separes', () async {
      // ⚠️ **Jamais additionnes.** `passages` compte des lieux distincts —
      // precher deux fois le meme texte n'elargit pas un canon ; `preachings`
      // compte des evenements, parce que deux assemblees ont entendu.
      final source = sourceRendant('''
        {
          "books": [
            {"book": "Actes", "passages": 3, "preachings": 5,
             "last_preached_on": "2026-08-23"}
          ],
          "axes": [
            {"axis_code": null, "preachings": 2,
             "last_preached_on": "2026-08-16"}
          ],
          "books_untouched": 61
        }
      ''');

      final couverture = await source.preachingCoverage();

      expect(couverture.books.single.passages, 3);
      expect(couverture.books.single.preachings, 5);
      expect(couverture.axes.single.axisCode, isNull);
      expect(couverture.booksUntouched, 61);
    });

    test('une couverture vide n\'est pas une panne', () async {
      final source = sourceRendant('{"books": [], "axes": []}');

      final couverture = await source.preachingCoverage();

      expect(couverture.books, isEmpty);
      expect(couverture.axes, isEmpty);
      expect(
        couverture.booksUntouched,
        0,
        reason: 'un champ absent vaut zero, jamais une exception',
      );
    });
  });

  group('qui a signé', () {
    // 🔴 **La règle était écrite deux fois**, et elle avait divergé : une
    // version dans la recherche, une autre dans le fil. Celle de la recherche
    // comparait sans abaisser la casse. Ces tests tiennent le jugement à un
    // seul endroit, maintenant qu'il n'y en a plus qu'un.

    test('une signature absente compte pour une machine', () {
      // L'absence de relecture ne se présume jamais en faveur du texte.
      expect(signedByMachine(null), isTrue);
    });

    test('tout ce qui commence par « ia- » vient d\'un modèle', () {
      expect(signedByMachine('ia-mistral'), isTrue);
      expect(signedByMachine('ia-nimporte-quoi'), isTrue);
    });

    test('la casse ne fait pas passer un modèle pour un homme', () {
      // 🔴 Le défaut que l'extraction a fermé : la recherche comparait
      // `relu.startsWith('ia-')` sur la chaîne brute. « IA-Mistral » serait
      // arrivé à l'écran comme « relu par IA-Mistral ».
      expect(signedByMachine('IA-Mistral'), isTrue);
      expect(signedByMachine('Ia-Mistral'), isTrue);
    });

    test('le jeu de départ n\'est pas un relecteur', () {
      expect(signedByMachine('semis-demo'), isTrue);
      expect(signedByMachine('SEMIS-DEMO'), isTrue);
    });

    test('un nom d\'homme reste un nom d\'homme', () {
      // Une seule unité sur 4 561 en porte un. C'est elle que la règle protège.
      expect(signedByMachine('R. Gnanhi'), isFalse);
      expect(signedByMachine('Diallo'), isFalse);
    });

    test('« ia » sans tiret n\'est pas un préfixe de modèle', () {
      // Un relecteur qui s'appellerait « Iandolo » ne doit pas devenir une
      // machine parce que son nom commence par deux lettres.
      expect(signedByMachine('Iandolo'), isFalse);
    });
  });

  group('ce que le serveur envoie', () {
    test('une ligne complète devient un résumé', () async {
      final source = sourceRendant('''
[{
  "id": "3f6c1b2e-0000-4000-8000-000000000001",
  "raw_input": "l'amour fraternel n'existe plus dans l'église",
  "pericope_label": "Hébreux 13:1-6",
  "theme": "La communion comme pratique",
  "axis_code": "axe:ecclesiologie",
  "service_date": "2026-08-23",
  "status": "ouverte",
  "last_outcome": "await_decision",
  "last_stage_code": "weigh_conviction",
  "last_turn_at": "2026-08-16T21:14:00Z",
  "opened_at": "2026-08-15T09:00:00Z"
}]''');

      final ligne = (await source.listStudies()).single;

      expect(ligne.rawInput, startsWith('l\'amour fraternel'));
      expect(ligne.theme, 'La communion comme pratique');
      expect(ligne.pericopeLabel, 'Hébreux 13:1-6');
      expect(ligne.serviceDate, DateTime(2026, 8, 23));
      expect(ligne.lastOutcome, TurnOutcome.handsBack);
      expect(ligne.waitsForUser, isTrue);
      expect(ligne.isClosed, isFalse);
    });

    test('sans tour rendu, la dernière activité est l\'ouverture', () async {
      // Une préparation créée à l'instant n'a pas de `last_turn_at`. La
      // rabattre sur une date nulle la ferait tomber en fin de fil alors
      // qu'elle vient de naître.
      final source = sourceRendant('''
[{
  "id": "3f6c1b2e-0000-4000-8000-000000000002",
  "raw_input": "Actes 2",
  "status": "ouverte",
  "last_outcome": null,
  "last_turn_at": null,
  "opened_at": "2026-08-15T09:00:00Z"
}]''');

      final ligne = (await source.listStudies()).single;

      expect(ligne.lastOutcome, isNull);
      expect(ligne.lastActivity, DateTime.utc(2026, 8, 15, 9).toLocal());
      expect(ligne.subtitle, isNull);
    });

    test('le dernier tour prime sur l\'ouverture', () async {
      final source = sourceRendant('''
[{
  "id": "3f6c1b2e-0000-4000-8000-000000000003",
  "raw_input": "Actes 2",
  "status": "close",
  "last_outcome": "continue",
  "last_turn_at": "2026-08-16T21:14:00Z",
  "opened_at": "2026-08-15T09:00:00Z"
}]''');

      final ligne = (await source.listStudies()).single;

      expect(ligne.lastActivity, DateTime.utc(2026, 8, 16, 21, 14).toLocal());
      expect(ligne.isClosed, isTrue, reason: 'les closes restent au fil');
    });

    test('un fil vide reste un fil', () async {
      expect(await sourceRendant('[]').listStudies(), isEmpty);
    });
  });

  group('la deuxième ligne de la carte', () {
    StudySummary avec({String? theme, String? pericope}) => StudySummary(
          id: 'x',
          rawInput: 'brut',
          lastActivity: DateTime(2026, 8, 15),
          theme: theme,
          pericopeLabel: pericope,
        );

    test('le thème s\'il est arrêté, sinon l\'unité bornée', () {
      expect(avec(theme: 'La communion', pericope: 'Actes 2:42-47').subtitle,
          'La communion');
      expect(avec(pericope: 'Actes 2:42-47').subtitle, 'Actes 2:42-47');
      expect(avec().subtitle, isNull);
    });
  });
}
