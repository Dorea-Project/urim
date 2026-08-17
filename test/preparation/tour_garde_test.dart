import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:urim/core/result/cached.dart';
import 'package:urim/core/id/id_generator.dart';
import 'package:urim/core/time/clock.dart';
import 'package:urim/data/datasources/pending_gestures_local_data_source.dart';
import 'package:urim/data/datasources/turn_cache_local_data_source.dart';
import 'package:urim/data/repositories/study_repository_impl.dart';
import 'package:urim/data/datasources/urim_remote_data_source.dart';
import 'package:urim/domain/entities/preparation/turn.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/core/result/result.dart';
import 'package:urim/core/storage/shared_preferences_provider.dart';
import 'package:urim/domain/entities/preparation/study.dart';
import 'package:urim/presentation/common/stale_banner.dart';
import 'package:urim/presentation/preparation/preparation_page.dart';
import '../support/fake_documents.dart';
import '../support/pump_app.dart';
import '../support/tours_reels.dart';

/// Une doublure qui a **deja** quelque chose de garde.
base class _DepotAvecGarde extends DepotFige {
  _DepotAvecGarde(super.etude, this.recu, {this.reseauCoupe = false});

  final DateTime recu;
  final bool reseauCoupe;
  int lectures = 0;

  /// Le serveur ne repond que quand le test le decide : c'est la seule facon
  /// de distinguer « affiche tout de suite » de « affiche apres reponse ».
  final Completer<void> serveur = Completer<void>();

  @override
  Future<Cached<Study>?> cachedById(String studyId) async =>
      Cached.at(etude, recu);

  @override
  Future<Result<Study>> getById(String studyId) async {
    lectures++;
    await serveur.future;
    if (reseauCoupe) {
      return const Result.failed(
        NetworkFailure(message: 'Pas de reseau.', code: 'offline'),
      );
    }
    return Result.success(etude);
  }
}

/// Etape 2 de Q4 : huit secondes de blanc deviennent zero, et un ecran vide
/// devient un ecran.
///
/// Ce qui se verifie ici est autant l'honnetete que la vitesse : un tour garde
/// **doit** porter l'heure ou il a ete recu. Le moteur rejoue a chaque lecture
/// (D28), donc ce qui a ete garde hier soir est ce qu'il disait hier soir.

final class _SequentialIds implements IdGenerator {
  int _next = 0;

  @override
  String newId() => 'cle-${_next++}';
}

final class _FixedClock implements Clock {
  const _FixedClock(this._now);
  final DateTime _now;

  @override
  DateTime now() => _now;
}

/// Repond une fois, puis refuse — comme un reseau qui tombe.
final class _AdapteurTombant implements HttpClientAdapter {
  _AdapteurTombant(this.corps);

  final String corps;
  int appels = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    appels++;
    if (appels > 1) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'coupe',
      );
    }
    return ResponseBody.fromString(
      corps,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  final recu = DateTime(2026, 8, 16, 21, 14);
  final maintenant = DateTime(2026, 8, 17, 9);

  ({
    RemoteStudyRepository depot,
    FakeDocuments documents,
    _AdapteurTombant reseau,
  }) monter({required String corps, DateTime? horloge}) {
    final documents = FakeDocuments();
    final cache = TurnCacheLocalDataSource(
      documents: documents,
      clock: _FixedClock(horloge ?? recu),
    );
    final reseau = _AdapteurTombant(corps);
    final dio = Dio(BaseOptions(baseUrl: 'http://serveur/api/mobile'))
      ..httpClientAdapter = reseau;

    return (
      depot: RemoteStudyRepository(
        UrimRemoteDataSource(dio, cache: cache),
        cache,
        PendingGesturesLocalDataSource(
          documents: documents,
          clock: _FixedClock(horloge ?? recu),
        ),
        _SequentialIds(),
      ),
      documents: documents,
      reseau: reseau,
    );
  }

  group('l\'ecriture au passage', () {
    test('lire une preparation la garde, telle que le serveur l\'a envoyee',
        () async {
      final m = monter(corps: ToursReels.json(ToursReels.miseEnForme));

      await m.depot.getById('peu-importe');

      // Le JSON brut, pas l'objet analyse : aucun second code de
      // serialisation a tenir d'accord avec le contrat.
      final garde = m.documents.contenu.values.single;
      final enveloppe = jsonDecode(garde) as Map<String, dynamic>;
      expect(enveloppe['at'], recu.toIso8601String());
      expect(
        (enveloppe['body'] as Map)['turn'],
        (jsonDecode(ToursReels.json(ToursReels.miseEnForme))
            as Map)['turn'],
      );
    });

    test('n\'importe quel geste garde le tour, pas seulement la lecture',
        () async {
      // Ouvrir, decider, ecarter, parler passent tous par le meme point
      // d'analyse : le tour garde est donc toujours le dernier recu.
      final m = monter(corps: ToursReels.json(ToursReels.theme));

      await m.depot.decide(
        studyId: 'x',
        stageCode: 'bear_axes',
        optionCode: 'anthropologie',
      );

      expect(m.documents.contenu, isNotEmpty);
    });

    test('lire le fil le garde aussi', () async {
      final m = monter(corps: ToursReels.json(ToursReels.fil));

      await m.depot.listMine();

      expect(m.documents.contenu.keys.single, 'fil');
    });
  });

  group('la relecture locale', () {
    test('rend le tour et l\'heure ou il est arrive', () async {
      final m = monter(corps: ToursReels.json(ToursReels.miseEnForme));
      await m.depot.getById('etude-1');

      final garde = await m.depot.cachedById(
        (studyFromWire(jsonDecode(ToursReels.json(ToursReels.miseEnForme))
                as Map<String, dynamic>))
            .id,
      );

      expect(garde, isNotNull);
      expect(garde!.receivedAt, recu);
      expect(garde.isStale, isTrue);
      // Et c'est bien le tour entier, blocs compris.
      expect(garde.value.turn!.blocks.whereType<BearingsBlock>().single.items,
          hasLength(10));
    });

    test('rien de garde rend nul, pas une erreur', () async {
      final m = monter(corps: ToursReels.json(ToursReels.theme));

      expect(await m.depot.cachedById('jamais-vue'), isNull);
      expect(await m.depot.cachedFeed(), isNull);
    });

    test('un tour garde par un contrat plus ancien ne casse rien', () async {
      // Un champ obligatoire disparu, une forme changee : on repart du serveur
      // plutot que de rendre un ecran de travers.
      final m = monter(corps: ToursReels.json(ToursReels.theme));
      m.documents.contenu['tour/etude-1'] =
          jsonEncode({'at': recu.toIso8601String(), 'body': {'pas': 'une etude'}});

      expect(await m.depot.cachedById('etude-1'), isNull);
    });

    test('un fichier abime vaut un fichier absent', () async {
      final m = monter(corps: ToursReels.json(ToursReels.theme));
      m.documents.contenu['tour/etude-1'] = 'ceci n\'est pas du json';

      expect(await m.depot.cachedById('etude-1'), isNull);
    });
  });

  group('quand le reseau tombe', () {
    test('le tour garde reste lisible', () async {
      // Le cas qui justifie l'etape : un samedi soir, sans reseau.
      final m = monter(corps: ToursReels.json(ToursReels.miseEnForme));
      final premier = await m.depot.getById('etude-1');
      final id = premier.valueOrNull!.id;

      // Le reseau tombe.
      final second = await m.depot.getById(id);
      expect(second.isFailure, isTrue, reason: 'le serveur ne repond plus');

      // Et pourtant le pasteur a encore son tour.
      final garde = await m.depot.cachedById(id);
      expect(garde!.value.turn!.say, isNotEmpty);
      expect(garde.receivedAt, recu);
    });
  });

  group('le menage', () {
    test('ne garde que les preparations encore au fil', () async {
      final documents = FakeDocuments();
      final cache = TurnCacheLocalDataSource(
        documents: documents,
        clock: _FixedClock(maintenant),
      );

      await cache.writeStudy('vivante', {'id': 'vivante'});
      await cache.writeStudy('abandonnee', {'id': 'abandonnee'});
      documents.contenu['brouillon/saisie/vivante'] = 'pas a moi';

      await cache.keepOnly(['vivante']);

      expect(await cache.readStudy('vivante'), isNotNull);
      expect(await cache.readStudy('abandonnee'), isNull);
      expect(documents.contenu, contains('brouillon/saisie/vivante'),
          reason: 'le menage des tours ne touche pas aux brouillons');
    });
  });

  group('l\'ecran le dit', () {
    testWidgets('un tour garde porte sa provenance, et la perd en se rafraichissant',
        (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final preferences = await SharedPreferences.getInstance();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final etude = ToursReels.etude(ToursReels.miseEnForme);
      final depot = _DepotAvecGarde(etude, recu);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
            demoConfigOverride,
            studyRepositoryProvider.overrideWithValue(depot),
          ],
          child: wrapScreen(const PreparationPage(preparationId: 'etude-1')),
        ),
      );
      // Le serveur n'a pas encore repondu, et pourtant l'ecran est plein :
      // c'est tout l'objet de l'etape.
      await tester.pumpAndSettle();
      expect(find.byType(StaleBanner), findsOneWidget);
      expect(find.text(etude.turn!.say), findsOneWidget);
      expect(depot.lectures, 1, reason: 'le rafraichissement est bien parti');

      // Le rafraichissement arrive : la provenance disparait.
      depot.serveur.complete();
      await tester.pumpAndSettle();
      expect(find.byType(StaleBanner), findsNothing);
    });

    testWidgets('sans reseau, la provenance reste et l\'ecran tient',
        (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final preferences = await SharedPreferences.getInstance();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final etude = ToursReels.etude(ToursReels.miseEnForme);
      final depot = _DepotAvecGarde(etude, recu, reseauCoupe: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
            demoConfigOverride,
            studyRepositoryProvider.overrideWithValue(depot),
          ],
          child: wrapScreen(const PreparationPage(preparationId: 'etude-1')),
        ),
      );
      await tester.pumpAndSettle();
      depot.serveur.complete();
      await tester.pumpAndSettle();

      // Un echec de rafraichissement ne doit pas effacer ce qui etait lisible :
      // ce serait faire payer la panne deux fois.
      expect(find.byType(StaleBanner), findsOneWidget);
      expect(find.text(etude.turn!.say), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('quand le corpus a bouge', () {
    testWidgets('l\'ecran le dit une fois, et n\'empeche rien',
        (tester) async {
      // Le serveur signale `corpus_drifted` depuis le premier jour et personne
      // ne l'ecoutait. Le tour n'est pas faux : le moteur rejoue contre un
      // corpus qui a bouge, et il n'est plus mot pour mot celui que le pasteur
      // avait sous les yeux.
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final preferences = await SharedPreferences.getInstance();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final brut = jsonDecode(ToursReels.json(ToursReels.theme))
          as Map<String, dynamic>;
      final etude = studyFromWire({...brut, 'corpus_drifted': true});
      expect(etude.corpusDrifted, isTrue);

      final depot = DepotFige(etude);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
            demoConfigOverride,
            studyRepositoryProvider.overrideWithValue(depot),
          ],
          child: wrapScreen(const PreparationPage(preparationId: 'etude-1')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DriftNotice), findsOneWidget);
      // Et le tour reste entierement utilisable : c'est une mention, pas un mur.
      expect(find.text(etude.turn!.say), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('rien ne s\'affiche quand le corpus n\'a pas bouge',
        (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final preferences = await SharedPreferences.getInstance();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
            demoConfigOverride,
            studyRepositoryProvider
                .overrideWithValue(DepotFige(ToursReels.etude(ToursReels.theme))),
          ],
          child: wrapScreen(const PreparationPage(preparationId: 'etude-1')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DriftNotice), findsNothing);
    });
  });

  group('la fraicheur', () {
    test('frais et garde ne se confondent pas', () {
      expect(const Cached.fresh(1).isStale, isFalse);
      expect(Cached.at(1, recu).isStale, isTrue);
      expect(Cached.at(1, recu).map((v) => v + 1).receivedAt, recu,
          reason: 'transformer la valeur ne rajeunit pas la reponse');
    });
  });
}
