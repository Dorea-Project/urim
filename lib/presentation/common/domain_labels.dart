import 'package:urim/domain/entities/preparation/preparation.dart';
import 'package:urim/domain/entities/preparation/preparation_block.dart';
import 'package:urim/domain/entities/preparation/study_summary.dart';
import 'package:urim/domain/entities/transcription/transcription_review.dart';
import 'package:urim/l10n/generated/app_text.dart';

/// Comment l'interface nomme ce que le domaine distingue.
///
/// Ces valeurs sont des **faits métier** : à qui est la main, ce qu'un texte
/// fait à la lecture, comment un passage est apparu dans une prédication. Le
/// domaine les distingue et les fait respecter ; il ne les nomme pas.
///
/// Rassemblées ici plutôt qu'éparpillées dans les écrans : le même état
/// s'affiche sur l'accueil et dans le fil, et deux `switch` finiraient par
/// diverger d'un mot — celui qu'un pasteur remarquerait.
/// Cette signature est-elle celle d'une machine ?
///
/// 🔴 **La règle était écrite deux fois**, et elle avait déjà divergé : une
/// version dans la recherche, une autre dans le fil, deux fonctions privées du
/// même nom, l'une acceptant `null` et l'autre non. Le jour où un troisième
/// préfixe de modèle apparaît, l'une des deux l'aurait connu et l'autre pas —
/// et l'écran aurait dit « relu » d'un texte que personne n'a lu.
///
/// **Ce qui est partagé est le jugement, pas le mot.** Chaque écran garde son
/// libellé — le fil dit « Découpage relu par… », la recherche dit autrement —
/// parce que la place et le contexte ne sont pas les mêmes. Ce qui ne peut pas
/// différer, c'est la réponse à la question : un homme a-t-il lu ceci ?
///
/// ⚠️ **`ia-mistral` n'est pas un relecteur : c'est le modèle qui a écrit.**
/// Les confondre ferait passer une production pour une relecture. Le chiffre
/// qui justifie la distinction : **4 552 unités sur 4 561 sont produites par le
/// modèle et n'ont jamais été relues.** Une seule porte un nom d'homme.
bool signedByMachine(String? signature) {
  if (signature == null) return true;

  final propre = signature.toLowerCase();
  return propre.startsWith('ia-') || _machines.contains(propre);
}

/// Les signatures qui ne sont pas des hommes.
///
/// `semis-demo` est le jeu de départ ; tout ce qui commence par `ia-` vient
/// d'un modèle. Une signature absente compte pour une machine : **l'absence de
/// relecture ne se présume jamais en faveur du texte.**
const Set<String> _machines = {'semis-demo'};

/// Comment le fil nomme le dernier tour du moteur.
///
/// Le `switch` est la seule traduction entre le vocabulaire du serveur et le
/// français affiché. Elle vit ici, à un seul endroit : le moteur dit
/// `await_decision`, l'écran dit « Rend la main », et rien entre les deux n'a
/// le droit d'inventer un troisième mot.
String turnOutcomeLabel(AppText text, TurnOutcome outcome) => switch (outcome) {
      TurnOutcome.handsBack => text.stateHandsBack,
      TurnOutcome.kept => text.stateServed,
      TurnOutcome.refused => text.stateRefused,
      TurnOutcome.degraded => text.stateDegraded,
    };

String preparationStateLabel(AppText text, PreparationState state) =>
    switch (state) {
      PreparationState.handsBack => text.stateHandsBack,
      PreparationState.served => text.stateServed,
      PreparationState.feedbackReady => text.stateFeedbackReady,
      PreparationState.refused => text.stateRefused,
    };

String textStanceLabel(AppText text, TextStance stance) => switch (stance) {
      TextStance.subject => text.stanceSubject,
      TextStance.supports => text.stanceSupports,
      TextStance.complicates => text.stanceComplicates,
    };

String convocationKindLabel(AppText text, ConvocationKind kind) =>
    switch (kind) {
      ConvocationKind.announced => text.transcriptionConvokedAnnounced,
      ConvocationKind.recognizedInQuote =>
        text.transcriptionConvokedRecognised,
    };

/// Comment l'écran nomme une section du squelette.
///
/// Le serveur tient une liste **fermée** de codes ; le pasteur, lui, lit des
/// mots. La traduction vit ici comme les autres, à un seul endroit — et un code
/// inconnu se rend tel quel plutôt que de disparaître : mieux vaut un mot brut
/// qu'une section qui s'évapore de son plan.
String planSectionLabel(AppText text, String code) => switch (code) {
      'titre' => text.preparationSectionTitre,
      'introduction' => text.preparationSectionIntroduction,
      'proposition' => text.preparationSectionProposition,
      'phrase_interrogative' => text.preparationSectionPhraseInterrogative,
      'phrase_de_transition' => text.preparationSectionPhraseDeTransition,
      'divisions' => text.preparationSectionDivisions,
      'subdivisions' => text.preparationSectionSubdivisions,
      'illustrations' => text.preparationSectionIllustrations,
      'application' => text.preparationSectionApplication,
      'conclusion' => text.preparationSectionConclusion,
      'objectif' => text.preparationSectionObjectif,
      'contexte' => text.preparationSectionContexte,
      'definitions' => text.preparationSectionDefinitions,
      'nb' => text.preparationSectionNb,
      'temoignage' => text.preparationSectionTemoignage,
      _ => code,
    };
