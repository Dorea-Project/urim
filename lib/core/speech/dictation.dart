import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Écrire dans un champ en parlant.
///
/// ⚠️ **Ceci n'est pas Q2.** La question non tranchée porte sur la
/// *transcription d'une prédication* : un enregistrement long, découpé en
/// fragments, aligné sur le squelette, dont le serveur porte déjà la file
/// (`urim_capture_job`, natures `transcrire` / `aligner`). Rien de tout cela
/// n'est en jeu ici. Dicter une phrase de départ, c'est de la saisie clavier
/// faite avec la bouche : le système sait le faire, l'audio ne devient jamais
/// un document d'Urim, et aucune file ne s'ouvre. Les deux gestes partagent une
/// icône, pas un problème.
///
/// Interface, et non appel direct au greffon, pour la raison habituelle : un
/// moteur natif ne répond que sur un vrai appareil, et le brancher en dur
/// rendrait l'écran d'ouverture intestable.
abstract interface class Dictation {
  /// Ouvre le micro.
  ///
  /// Ne lève jamais : un refus est une réponse, pas une panne. C'est à
  /// l'appelant de dire au pasteur ce qui manque.
  Future<DictationStart> start();

  /// Termine l'écoute en laissant au moteur le temps de rendre sa dernière
  /// phrase.
  Future<void> stop();

  /// Coupe sans rien attendre — l'écran se referme, ce qui a été dit ne servira
  /// plus.
  Future<void> cancel();

  bool get isListening;

  void dispose();
}

/// Ce qu'a donné [Dictation.start].
sealed class DictationStart {
  const DictationStart();
}

/// Le micro est ouvert. [heard] se ferme quand l'écoute s'arrête, quelle qu'en
/// soit la raison — arrêt demandé, silence prolongé, erreur.
final class DictationListening extends DictationStart {
  const DictationListening(this.heard);

  final Stream<DictationWords> heard;
}

/// Le micro n'a pas pu s'ouvrir, et on sait pourquoi.
final class DictationRefused extends DictationStart {
  const DictationRefused(this.reason);

  final DictationRefusal reason;
}

/// Pourquoi la dictée n'a pas commencé.
///
/// Trois cas séparés parce qu'ils appellent trois phrases différentes : un
/// appareil sans moteur ne se répare pas, une permission refusée se rouvre dans
/// les réglages, et une panne se retente.
enum DictationRefusal {
  /// Aucun moteur de reconnaissance vocale sur cet appareil.
  noEngine,

  /// Le micro a été refusé à l'application.
  micRefused,

  /// Le moteur est là mais n'a pas démarré.
  engineFailed,
}

/// Ce que le moteur a entendu jusqu'ici.
///
/// [text] est **cumulatif** : chaque événement porte la phrase entière telle
/// que le moteur la comprend à cet instant, pas le morceau qui vient de
/// s'ajouter. Un moteur se corrige en cours de route — « perse verrance »
/// devient « persévérance » — et seul un texte complet permet de montrer la
/// correction au lieu d'empiler les deux.
final class DictationWords {
  const DictationWords({required this.text, required this.settled});

  final String text;

  /// Le moteur ne reviendra plus sur cette phrase.
  final bool settled;
}

/// La dictée du système : `SpeechRecognizer` sur Android, `Speech` sur iOS.
final class PlatformDictation implements Dictation {
  PlatformDictation({SpeechToText? engine, this.onDeviceOnly = false})
      : _engine = engine ?? SpeechToText();

  final SpeechToText _engine;

  /// Exiger que la reconnaissance reste sur l'appareil.
  ///
  /// ⚠️ **Faux par défaut, et c'est une décision à consigner.** À `true`, une
  /// dictée échoue tant que le pasteur n'a pas téléchargé le modèle hors ligne
  /// de sa langue — le bouton redeviendrait mort, ce qu'on est précisément en
  /// train de réparer. À `false`, le moteur du système peut passer par ses
  /// serveurs : la phrase de départ sort alors de l'appareil, chez l'éditeur du
  /// système et non chez Urim. La politique de confidentialité parle de l'audio
  /// de prédication ; elle ne dit rien de ce cas-ci. Tant qu'elle ne le dit
  /// pas, ce drapeau est le seul endroit où basculer.
  final bool onDeviceOnly;

  bool _prepared = false;
  String? _locale;
  DictationRefusal? _lastRefusal;
  StreamController<DictationWords>? _session;
  Timer? _filet;

  @override
  bool get isListening => _engine.isListening;

  @override
  Future<DictationStart> start() async {
    // Une seule écoute à la fois : deux flux écrivant dans le même champ
    // s'écraseraient l'un l'autre.
    if (_engine.isListening) await cancel();

    _lastRefusal = null;

    if (!_prepared) {
      try {
        _prepared = await _engine.initialize(
          onError: _noterErreur,
          onStatus: _noterStatut,
        );
      } on Exception {
        _prepared = false;
      }

      if (!_prepared) return DictationRefused(await _diagnostic());

      _locale = await _langueParlee();
    }

    final session = _session = StreamController<DictationWords>.broadcast();

    try {
      await _engine.listen(
        onResult: (resultat) => _emettre(session, resultat),
        listenOptions: SpeechListenOptions(
          localeId: _locale,
          // Ce qu'on attend n'est pas une commande de deux mots mais une
          // phrase — parfois trois.
          listenMode: ListenMode.dictation,
          // Le champ se remplit pendant qu'il parle : un pasteur qui ne voit
          // rien venir croit que ça ne marche pas, et s'arrête.
          partialResults: true,
          onDevice: onDeviceOnly,
          cancelOnError: true,
          // Un homme qui cherche sa phrase se tait pour réfléchir. Quatre
          // secondes, c'est plus long qu'une hésitation et plus court qu'un
          // abandon.
          pauseFor: const Duration(seconds: 4),
          listenFor: const Duration(minutes: 2),
        ),
      );
    } on Exception {
      await _fermer();
      return const DictationRefused(DictationRefusal.engineFailed);
    }

    return DictationListening(session.stream);
  }

  @override
  Future<void> stop() async {
    if (!_engine.isListening) {
      await _fermer();
      return;
    }

    // On ne ferme pas le flux ici : le moteur doit encore rendre sa dernière
    // phrase, et c'est celle qui corrige les mots devinés en chemin. La
    // fermeture viendra du statut `done`.
    await _engine.stop();

    // ⚠️ **Filet.** Certains appareils ne renvoient jamais `done`. Sans lui,
    // l'écran resterait à afficher « Urim t'écoute » sur un micro fermé.
    _filet?.cancel();
    _filet = Timer(const Duration(seconds: 3), _fermer);
  }

  @override
  Future<void> cancel() async {
    if (_engine.isListening) await _engine.cancel();
    await _fermer();
  }

  @override
  void dispose() {
    _filet?.cancel();
    unawaited(cancel());
  }

  void _emettre(
    StreamController<DictationWords> session,
    SpeechRecognitionResult resultat,
  ) {
    if (session.isClosed) return;

    session.add(
      DictationWords(
        text: resultat.recognizedWords,
        settled: resultat.finalResult,
      ),
    );
  }

  void _noterStatut(String statut) {
    // `notListening` précède la dernière phrase sur plusieurs appareils :
    // fermer là couperait le moteur au moment où il se corrige. Seul `done`
    // dit qu'il n'y a plus rien à recevoir.
    if (statut == 'done') unawaited(_fermer());
  }

  void _noterErreur(SpeechRecognitionError erreur) {
    final raison = _raisonDe(erreur.errorMsg);
    _lastRefusal = raison;

    // Ne pas confondre « il n'a rien dit » avec « ça ne marche pas ». Un
    // silence, un délai dépassé : le moteur s'arrête, l'écran revient au repos,
    // et personne n'a besoin d'un message d'erreur.
    if (!erreur.permanent) return;

    final session = _session;
    if (session != null && !session.isClosed) session.addError(raison);
  }

  Future<void> _fermer() async {
    _filet?.cancel();
    _filet = null;

    final session = _session;
    _session = null;
    if (session != null && !session.isClosed) await session.close();
  }

  /// `initialize` rend `false` sans dire pourquoi. La permission, elle, se
  /// demande.
  Future<DictationRefusal> _diagnostic() async {
    if (_lastRefusal case final raison?) return raison;

    try {
      if (!await _engine.hasPermission) return DictationRefusal.micRefused;
    } on Exception {
      // Le greffon n'a pas répondu : c'est un appareil sans moteur.
    }

    return DictationRefusal.noEngine;
  }

  static DictationRefusal _raisonDe(String message) => switch (message) {
        'error_permission' => DictationRefusal.micRefused,
        'error_speech_recognizer_not_available' => DictationRefusal.noEngine,
        _ => DictationRefusal.engineFailed,
      };

  /// Le français si l'appareil le porte, sinon la langue du système.
  ///
  /// Pas de `fr_FR` en dur : un pasteur ivoirien ou québécois a un appareil
  /// réglé sur sa variante, et lui imposer celle de France dégraderait la
  /// reconnaissance sans rien apporter.
  Future<String?> _langueParlee() async {
    try {
      final connues = await _engine.locales();

      for (final locale in connues) {
        if (locale.localeId.toLowerCase().startsWith('fr')) {
          return locale.localeId;
        }
      }
    } on Exception {
      // On laissera le moteur choisir.
    }

    return null;
  }
}

final dictationProvider = Provider<Dictation>((ref) {
  final dictee = PlatformDictation();
  ref.onDispose(dictee.dispose);
  return dictee;
});
