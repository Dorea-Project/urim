import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:urim/core/speech/dictation.dart';

/// Dicter **dans un champ** : l'écoute, son refus, et le recollage du texte.
///
/// Deux écrans dictent la même phrase de départ — le composeur de l'accueil et
/// le formulaire — et rien de ce qui suit n'est propre à l'un ou à l'autre :
/// le point de départ qui se fige, la phrase cumulative qu'il faut recoller
/// plutôt qu'empiler, le micro qu'on referme en partant. Deux copies auraient
/// divergé au premier correctif.
///
/// L'objet ne connaît ni `setState` ni `mounted` : il prévient par [onChanged],
/// et c'est à l'écran de vérifier qu'il est encore là avant de se redessiner.
final class FieldDictation {
  FieldDictation({
    required Dictation dictation,
    required TextEditingController controller,
    required VoidCallback onChanged,
  })  : _dictation = dictation,
        _controller = controller,
        _onChanged = onChanged;

  final Dictation _dictation;
  final TextEditingController _controller;
  final VoidCallback _onChanged;

  StreamSubscription<DictationWords>? _listening;
  DictationRefusal? _refusal;
  bool _disposed = false;

  /// Ce qu'il y avait dans le champ avant d'appuyer sur le micro.
  ///
  /// La dictée **complète**, elle n'efface pas : un pasteur qui a tapé une
  /// référence puis dicte son intention doit retrouver les deux. Chaque
  /// événement portant la phrase entière ([DictationWords.text] est cumulatif),
  /// c'est sur cette base qu'on la recolle à chaque fois.
  String? _before;

  bool get isListening => _listening != null;

  /// Le dernier refus, ou nul. Un refus est une réponse, pas une panne : c'est
  /// à l'écran de dire ce qui manque.
  DictationRefusal? get refusal => _refusal;

  /// Appuyer sur le micro : ouvrir l'écoute, ou la refermer.
  Future<void> toggle() async {
    if (_listening != null) {
      await _dictation.stop();
      return;
    }

    _refusal = null;
    _onChanged();

    final start = await _dictation.start();
    if (_disposed) return;

    switch (start) {
      case DictationRefused(:final reason):
        _refusal = reason;
        _onChanged();

      case DictationListening(:final heard):
        // Le point de départ se fige ici, pas à chaque mot : sinon la phrase
        // reconnue se recollerait derrière elle-même.
        _before = _controller.text;

        _listening = heard.listen(
          _write,
          onError: (Object error) {
            if (_disposed) return;
            _refusal = error is DictationRefusal
                ? error
                : DictationRefusal.engineFailed;
            _onChanged();
          },
          onDone: _finished,
          cancelOnError: true,
        );
        _onChanged();
    }
  }

  /// ⚠️ **Passe par [TextEditingController.value], donc `onChanged` du champ ne
  /// part pas.** Ce que la frappe déclenche — garder le brouillon, rallumer le
  /// bouton d'ouverture — doit être refait par [onChanged], sans quoi une
  /// préparation entièrement dictée resterait impossible à ouvrir et se
  /// perdrait au premier appel entrant.
  void _write(DictationWords words) {
    if (_disposed) return;

    final base = _before ?? '';
    final space = base.isEmpty || base.endsWith(' ') ? '' : ' ';
    final text = words.text.isEmpty ? base : '$base$space${words.text}';

    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );

    _onChanged();
  }

  void _finished() {
    _before = null;
    if (_disposed) return;

    _listening?.cancel();
    _listening = null;
    _onChanged();
  }

  /// Couper court avant de quitter l'écran.
  ///
  /// La fin d'une phrase reconnue après le départ n'irait nulle part : ce qui
  /// est déjà dans le champ est ce que le pasteur a voulu dire.
  Future<void> cancel() async {
    await _listening?.cancel();
    _listening = null;
    await _dictation.cancel();
  }

  /// Le micro se referme avec l'écran.
  ///
  /// ⚠️ Une écoute qui survit à sa page écrit dans un contrôleur détruit — et
  /// laisse le micro ouvert sur un écran que le pasteur croit avoir quitté.
  void dispose() {
    _disposed = true;
    _listening?.cancel();
    _listening = null;
    _dictation.cancel();
  }
}
