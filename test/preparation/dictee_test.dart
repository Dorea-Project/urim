import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urim/core/speech/dictation.dart';
import 'package:urim/core/storage/local_documents.dart';
import 'package:urim/core/storage/shared_preferences_provider.dart';
import 'package:urim/core/time/clock.dart';
import 'package:urim/core/time/clock_provider.dart';
import 'package:urim/data/datasources/draft_local_data_source.dart';
import 'package:urim/data/repositories/study_repository_impl.dart';
import 'package:urim/l10n/generated/app_text_fr.dart';
import 'package:urim/presentation/home/widgets/preparation_composer.dart';

import '../support/fake_documents.dart';
import '../support/pump_app.dart';
import '../support/tours_reels.dart';

/// Le micro du composeur, au bas de l'accueil.
///
/// Il a longtemps ete un rond dessine : un `Container` sans zone tactile, que
/// l'appui traversait sans rien declencher. Ces tests tiennent les deux choses
/// qu'on ne voit pas en regardant l'ecran — que ce qui est dit **arrive dans le
/// champ**, et que ce qui arrive par la voix est traite exactement comme ce qui
/// arrive par le clavier : garde en brouillon, et bouton allume.

final class _HorlogeFixe implements Clock {
  const _HorlogeFixe(this._maintenant);
  final DateTime _maintenant;

  @override
  DateTime now() => _maintenant;
}

/// Un moteur de dictee pilote a la main.
///
/// Le vrai ne repond que sur un appareil : sans cette doublure, rien de ce que
/// fait le micro ne serait verifiable ailleurs qu'en le prenant en main.
final class _DicteeFeinte implements Dictation {
  _DicteeFeinte({this.refus});

  /// Quand il est pose, `start` refuse au lieu d'ouvrir.
  final DictationRefusal? refus;

  StreamController<DictationWords>? _flux;
  int demarrages = 0;
  int arrets = 0;

  @override
  bool get isListening => _flux != null && !_flux!.isClosed;

  @override
  Future<DictationStart> start() async {
    demarrages++;
    if (refus case final raison?) return DictationRefused(raison);

    final flux = _flux = StreamController<DictationWords>.broadcast();
    return DictationListening(flux.stream);
  }

  /// Le moteur a entendu quelque chose.
  void entend(String texte, {bool arrete = false}) {
    _flux?.add(DictationWords(text: texte, settled: arrete));
  }

  /// Le moteur bute — micro coupe, service tombe.
  void bute(DictationRefusal raison) => _flux?.addError(raison);

  @override
  Future<void> stop() async {
    arrets++;
    await _flux?.close();
    _flux = null;
  }

  @override
  Future<void> cancel() async {
    await _flux?.close();
    _flux = null;
  }

  @override
  void dispose() {}
}

final texte = AppTextFr();

void main() {
  final maintenant = DateTime(2026, 8, 21, 1, 23);

  late FakeDocuments documents;
  late SharedPreferences preferences;

  setUp(() async {
    documents = FakeDocuments();
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });

  Future<void> ouvrirEcran(WidgetTester tester, _DicteeFeinte dictee) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          demoConfigOverride,
          clockProvider.overrideWithValue(_HorlogeFixe(maintenant)),
          localDocumentsProvider.overrideWithValue(documents),
          dictationProvider.overrideWithValue(dictee),
          studyRepositoryProvider.overrideWithValue(
            DepotFige(ToursReels.etude(ToursReels.ouverture)),
          ),
        ],
        child: wrapScreen(Scaffold(body: PreparationComposer(onOpened: (_) {}))),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Le micro se designe par son infobulle : `byType(IconButton)` ramene
  /// aussi la fleche d'ouverture, et l'ordre entre les deux n'est pas une
  /// chose sur laquelle un test doit parier.
  Finder micro({bool ecoute = false}) => find.byTooltip(
        ecoute
            ? texte.newPreparationDictateStop
            : texte.newPreparationDictateStart,
      );

  String champ(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).controller!.text;

  group('le micro de l ecran d ouverture', () {
    testWidgets('appuyer dessus declenche quelque chose', (tester) async {
      final dictee = _DicteeFeinte();
      await ouvrirEcran(tester, dictee);

      await tester.tap(micro());
      await tester.pumpAndSettle();

      // La regression d'origine : l'appui ne partait nulle part.
      expect(dictee.demarrages, 1);
      expect(micro(ecoute: true), findsOneWidget);
      // Le champ lui-meme dit qu'on l'ecoute : pas de second endroit a
      // regarder pour savoir si le micro est ouvert.
      expect(find.text(texte.newPreparationDictateListening), findsOneWidget);
    });

    testWidgets('ce qui est dit arrive dans le champ', (tester) async {
      final dictee = _DicteeFeinte();
      await ouvrirEcran(tester, dictee);

      await tester.tap(micro());
      await tester.pumpAndSettle();

      dictee.entend('je veux parler de la perse verrance');
      await tester.pump();
      expect(champ(tester), 'je veux parler de la perse verrance');

      // Le moteur se corrige : la phrase entiere remplace la precedente, elle
      // ne s'ajoute pas derriere.
      dictee.entend('je veux parler de la perseverance', arrete: true);
      await tester.pump();
      expect(champ(tester), 'je veux parler de la perseverance');
    });

    testWidgets('la dictee complete ce qui est deja tape', (tester) async {
      final dictee = _DicteeFeinte();
      await ouvrirEcran(tester, dictee);

      await tester.enterText(find.byType(TextField), 'Romains 8:15');
      await tester.pump();

      await tester.tap(micro());
      await tester.pumpAndSettle();

      dictee.entend('a des etudiants qui decrochent', arrete: true);
      await tester.pump();

      expect(champ(tester), 'Romains 8:15 a des etudiants qui decrochent');
    });

    testWidgets('une preparation entierement dictee peut s ouvrir',
        (tester) async {
      final dictee = _DicteeFeinte();
      await ouvrirEcran(tester, dictee);

      // Rien a ouvrir tant que rien n'est ecrit : la fleche n'existe pas.
      expect(find.byTooltip(texte.newPreparationOpen), findsNothing);

      await tester.tap(micro());
      await tester.pumpAndSettle();
      dictee.entend('que l amour fraternel continue', arrete: true);
      await tester.pumpAndSettle();

      // Ecrire par la voix passe par le controleur, donc `onChanged` ne part
      // pas. Sans le rattrapage, le pasteur voyait sa phrase et aucun moyen de
      // l'ouvrir.
      expect(find.byTooltip(texte.newPreparationOpen), findsOneWidget);
    });

    testWidgets('ce qui est dicte est garde comme ce qui est tape',
        (tester) async {
      final dictee = _DicteeFeinte();
      await ouvrirEcran(tester, dictee);

      await tester.tap(micro());
      await tester.pumpAndSettle();
      dictee.entend('que l amour fraternel continue', arrete: true);

      // Le brouillon n'ecrit pas a chaque mot : il attend le silence.
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        documents.contenu[DraftLocalDataSource.ouvertureKey],
        contains('que l amour fraternel continue'),
      );
    });

    testWidgets('appuyer une seconde fois referme le micro', (tester) async {
      final dictee = _DicteeFeinte();
      await ouvrirEcran(tester, dictee);

      await tester.tap(micro());
      await tester.pumpAndSettle();
      await tester.tap(micro(ecoute: true));
      await tester.pumpAndSettle();

      expect(dictee.arrets, 1);
      expect(micro(), findsOneWidget);
      expect(find.text(texte.homeComposerHint), findsOneWidget);
    });
  });

  group('quand la dictee ne peut pas commencer', () {
    testWidgets('un micro refuse le dit, et dit ou le rouvrir', (tester) async {
      final dictee = _DicteeFeinte(refus: DictationRefusal.micRefused);
      await ouvrirEcran(tester, dictee);

      await tester.tap(micro());
      await tester.pumpAndSettle();

      expect(
        find.text(texte.newPreparationDictateMicRefused),
        findsOneWidget,
      );
      // Le champ n'a pas bouge : rien n'a ete efface au passage.
      expect(champ(tester), isEmpty);
    });

    testWidgets('un appareil sans moteur renvoie vers le clavier',
        (tester) async {
      final dictee = _DicteeFeinte(refus: DictationRefusal.noEngine);
      await ouvrirEcran(tester, dictee);

      await tester.tap(micro());
      await tester.pumpAndSettle();

      expect(find.text(texte.newPreparationDictateNoEngine), findsOneWidget);
    });

    testWidgets('une panne en cours de route se dit sans perdre la phrase',
        (tester) async {
      final dictee = _DicteeFeinte();
      await ouvrirEcran(tester, dictee);

      await tester.tap(micro());
      await tester.pumpAndSettle();
      dictee.entend('que l amour fraternel');
      await tester.pump();

      dictee.bute(DictationRefusal.engineFailed);
      await tester.pumpAndSettle();

      expect(find.text(texte.newPreparationDictateFailed), findsOneWidget);
      // Ce qui avait ete entendu reste : une panne n'efface pas.
      expect(champ(tester), 'que l amour fraternel');
    });
  });
}
