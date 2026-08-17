import 'dart:async';

import 'package:urim/data/datasources/draft_local_data_source.dart';

/// Retient ce qui est en train d'être écrit, sans écrire à chaque caractère.
///
/// Deux exigences qui tirent en sens contraire : ne rien perdre, et ne pas
/// toucher au disque trente fois par seconde. D'où le délai — court, parce que
/// c'est le temps pendant lequel une frappe n'est encore nulle part.
///
/// La règle qui compte est dans [dispose] : un champ détruit **écrit d'abord**.
/// C'est là que le texte se perdait, et un `Timer` en attente ne survit pas à la
/// destruction de son écran.
final class DraftKeeper {
  DraftKeeper({
    required DraftLocalDataSource source,
    required this.key,
    this.delay = const Duration(milliseconds: 350),
  }) : _source = source;

  final DraftLocalDataSource _source;
  final String key;
  final Duration delay;

  Timer? _minuteur;
  String? _enAttente;

  /// Ce qui avait été écrit et jamais envoyé, s'il y a quelque chose.
  Future<Draft?> restore() => _source.read(key);

  /// Note la frappe. L'écriture suit après [delay] de silence.
  void remember(String text) {
    _enAttente = text;
    _minuteur?.cancel();
    _minuteur = Timer(delay, _ecrire);
  }

  /// Le serveur a accusé réception : la copie locale n'a plus de raison d'être.
  ///
  /// Ne rend pas de `Future` **exprès**. Ranger un brouillon est du ménage, et
  /// aucun geste du pasteur — envoyer, naviguer — ne doit attendre le disque.
  void forget() {
    _minuteur?.cancel();
    _enAttente = null;
    _source.delete(key);
  }

  /// À appeler depuis le `dispose` de l'écran.
  ///
  /// N'attend pas la fin de l'écriture — on ne peut pas attendre dans un
  /// `dispose` —, mais la lance : le fichier se referme après la destruction du
  /// widget, et c'est suffisant.
  void dispose() {
    _minuteur?.cancel();
    _ecrire();
  }

  void _ecrire() {
    final texte = _enAttente;
    if (texte == null) return;
    _enAttente = null;
    _source.write(key, texte);
  }
}
