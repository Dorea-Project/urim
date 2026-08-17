import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/core/time/clock.dart';
import 'package:urim/data/datasources/pending_gestures_local_data_source.dart';
import 'package:urim/data/datasources/turn_cache_local_data_source.dart';
import 'package:urim/data/datasources/urim_remote_data_source.dart';
import 'package:urim/data/repositories/study_repository_impl.dart';
import 'package:urim/domain/entities/preparation/gesture_outcome.dart';
import '../support/fake_documents.dart';
import '../support/tours_reels.dart';

/// Etape 3a de Q4 : decider et ecarter sans reseau.
///
/// **Ce que la file ne fait pas, et c'est le coeur de l'etape :** elle ne
/// simule pas le moteur. Le tour suivant est ce que le pipeline aurait
/// repondu ; le fabriquer ici serait inventer une phrase d'Urim. Le geste est
/// garde, et le tour arrive au retour du reseau.

final class _FixedClock implements Clock {
  const _FixedClock(this._now);
  final DateTime _now;

  @override
  DateTime now() => _now;
}

/// Un reseau qu'on allume et qu'on eteint.
final class _Reseau implements HttpClientAdapter {
  _Reseau(this.corps, {this.debout = true});

  final String corps;
  bool debout;

  /// 422 : le serveur a **juge**, il n'est pas absent.
  bool refuse = false;

  final List<String> chemins = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (!debout) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'coupe',
      );
    }

    chemins.add(options.path);

    if (refuse) {
      return ResponseBody.fromString(
        '{"error":{"code":"URIM_STAGE_CLOSED","message":"Cet etage n\'attend plus."}}',
        422,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
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
  final maintenant = DateTime(2026, 8, 17, 21, 14);

  ({
    RemoteStudyRepository depot,
    FakeDocuments documents,
    _Reseau reseau,
    PendingGesturesLocalDataSource file,
  }) monter({bool debout = true}) {
    final documents = FakeDocuments();
    final horloge = _FixedClock(maintenant);
    final cache =
        TurnCacheLocalDataSource(documents: documents, clock: horloge);
    final file =
        PendingGesturesLocalDataSource(documents: documents, clock: horloge);
    final reseau = _Reseau(ToursReels.json(ToursReels.theme), debout: debout);
    final dio = Dio(BaseOptions(baseUrl: 'http://serveur/api/mobile'))
      ..httpClientAdapter = reseau;

    return (
      depot: RemoteStudyRepository(
        UrimRemoteDataSource(dio, cache: cache),
        cache,
        file,
      ),
      documents: documents,
      reseau: reseau,
      file: file,
    );
  }

  group('avec le reseau', () {
    test('le geste part, et rien ne s\'accumule', () async {
      final m = monter();

      final issue = await m.depot.decide(
        studyId: 'etude-1',
        stageCode: 'bear_axes',
        optionCode: 'anthropologie',
        label: 'Anthropologie',
      );

      expect(issue.valueOrNull, isA<Served>());
      expect(await m.depot.pending('etude-1'), isEmpty);
    });
  });

  group('sans reseau', () {
    test('le geste est note, pas perdu — et aucun tour n\'est invente',
        () async {
      final m = monter(debout: false);

      final issue = await m.depot.decide(
        studyId: 'etude-1',
        stageCode: 'weigh_conviction',
        optionCode: 'axe:ecclesiologie',
        label: 'L\'Eglise sans amour',
      );

      // `Queued` ne porte pas d'etude, et c'est le point : le tour suivant
      // n'existe pas encore.
      expect(issue.valueOrNull, isA<Queued>());

      final attente = await m.depot.pending('etude-1');
      expect(attente, hasLength(1));
      expect(attente.single.optionCode, 'axe:ecclesiologie');
      expect(attente.single.stageCode, 'weigh_conviction');
      expect(attente.single.label, 'L\'Eglise sans amour',
          reason: 'ce que le pasteur a vu, pour le lui remontrer');
      expect(attente.single.madeAt, maintenant);
    });

    test('l\'etage du bloc est garde, pas celui du tour', () async {
      // Une pesee se decide sur `bear_axes` meme quand le tour est ailleurs.
      // Refabriquer l'etage au moment du rejeu le refabriquerait faux.
      final m = monter(debout: false);

      await m.depot.decide(
        studyId: 'etude-1',
        stageCode: 'bear_axes',
        optionCode: 'christologie',
      );

      expect((await m.depot.pending('etude-1')).single.stageCode, 'bear_axes');
    });

    test('plusieurs rejets s\'empilent dans l\'ordre', () async {
      // Tous portent sur le meme tour : on ne peut pas agir sur un tour qu'on
      // n'a pas recu.
      final m = monter(debout: false);

      for (final code in ['axe:angelologie', 'axe:demonologie']) {
        await m.depot.dismiss(
          studyId: 'etude-1',
          stageCode: 'weigh_conviction',
          optionCode: code,
        );
      }

      expect(
        (await m.depot.pending('etude-1')).map((g) => g.optionCode),
        ['axe:angelologie', 'axe:demonologie'],
      );
    });

    test('parler echoue au lieu d\'etre mis en file', () async {
      // Une phrase rejouee deux fois couterait deux passages du repondeur,
      // donc deux appels de modele : il faut une cle d'idempotence, etape 3b.
      // La phrase n'est pas perdue pour autant — le brouillon la garde (D32).
      final m = monter(debout: false);

      final issue = await m.depot.say(studyId: 'etude-1', rawInput: 'Bonjour');

      expect(issue.isFailure, isTrue);
      expect(await m.depot.pending('etude-1'), isEmpty);
    });
  });

  group('un refus du serveur n\'est pas un contretemps', () {
    test('il remonte comme un echec, et ne s\'accumule pas', () async {
      // Le renvoyer plus tard ne le rendrait pas acceptable, et l'accumuler
      // ferait une file qui ne se videra jamais.
      final m = monter();
      m.reseau.refuse = true;

      final issue = await m.depot.decide(
        studyId: 'etude-1',
        stageCode: 'weigh_conviction',
        optionCode: 'axe:inconnu',
      );

      expect(issue.isFailure, isTrue);
      expect(issue.failureOrNull, isNot(isA<NetworkFailure>()));
      expect(await m.depot.pending('etude-1'), isEmpty,
          reason: 'un jugement du serveur ne se rejoue pas');
    });
  });

  group('au retour du reseau', () {
    test('la file part dans l\'ordre, et se vide', () async {
      final m = monter(debout: false);

      await m.depot.dismiss(
        studyId: 'etude-1',
        stageCode: 'weigh_conviction',
        optionCode: 'axe:angelologie',
      );
      await m.depot.decide(
        studyId: 'etude-1',
        stageCode: 'weigh_conviction',
        optionCode: 'axe:ecclesiologie',
      );

      m.reseau.debout = true;
      final rejeu = await m.depot.flush('etude-1');

      expect(rejeu, isNotNull);
      expect(rejeu!.isSuccess, isTrue);
      expect(
        m.reseau.chemins,
        ['/urim/studies/etude-1/dismissals', '/urim/studies/etude-1/decisions'],
        reason: 'l\'ordre d\'emission est ce qui rend le rejeu equivalent',
      );
      expect(await m.depot.pending('etude-1'), isEmpty);
    });

    test('rien en attente ne fait rien', () async {
      final m = monter();

      expect(await m.depot.flush('etude-1'), isNull);
      expect(m.reseau.chemins, isEmpty);
    });

    test('un geste suivant vide d\'abord ce qui attendait', () async {
      final m = monter(debout: false);
      await m.depot.dismiss(
        studyId: 'etude-1',
        stageCode: 'weigh_conviction',
        optionCode: 'axe:angelologie',
      );

      m.reseau.debout = true;
      await m.depot.decide(
        studyId: 'etude-1',
        stageCode: 'weigh_conviction',
        optionCode: 'axe:ecclesiologie',
      );

      expect(
        m.reseau.chemins,
        ['/urim/studies/etude-1/dismissals', '/urim/studies/etude-1/decisions'],
      );
      expect(await m.depot.pending('etude-1'), isEmpty);
    });

    test('ce qui est parti ne repart pas si la suite echoue', () async {
      // Le reseau retombe au milieu du rejeu : le premier geste est passe, le
      // second doit rester en attente — et le premier ne doit pas repartir.
      final m = monter(debout: false);
      for (final code in ['axe:angelologie', 'axe:demonologie']) {
        await m.depot.dismiss(
          studyId: 'etude-1',
          stageCode: 'weigh_conviction',
          optionCode: code,
        );
      }

      m.reseau.debout = true;
      m.reseau.refuse = false;
      // Un reseau qui tombe apres le premier envoi.
      var envois = 0;
      final dio = Dio(BaseOptions(baseUrl: 'http://serveur/api/mobile'))
        ..httpClientAdapter = _ReseauQuiTombeApres(
          ToursReels.json(ToursReels.theme),
          () => ++envois > 1,
        );
      final depot = RemoteStudyRepository(
        UrimRemoteDataSource(
          dio,
          cache: TurnCacheLocalDataSource(
            documents: m.documents,
            clock: _FixedClock(maintenant),
          ),
        ),
        TurnCacheLocalDataSource(
          documents: m.documents,
          clock: _FixedClock(maintenant),
        ),
        m.file,
      );

      final rejeu = await depot.flush('etude-1');

      expect(rejeu!.isFailure, isTrue);
      final reste = await depot.pending('etude-1');
      expect(reste, hasLength(1));
      expect(reste.single.optionCode, 'axe:demonologie');
    });
  });
}

/// Repond, puis tombe.
final class _ReseauQuiTombeApres implements HttpClientAdapter {
  _ReseauQuiTombeApres(this.corps, this.tombe);

  final String corps;
  final bool Function() tombe;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (tombe()) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'coupe en route',
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
