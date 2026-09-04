import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/audio/capture_store.dart';
import 'package:urim/core/audio/recorded_sermon_capture.dart';
import 'package:urim/core/audio/sermon_capture.dart';
import 'package:urim/core/time/clock_provider.dart';
import 'package:urim/data/repositories/account_repository_impl.dart';
import 'package:urim/presentation/home/fragment_upload_view_model.dart';

/// Ce que l'écran sait de la capture en cours.
final class CaptureState {
  const CaptureState({
    this.running,
    this.refusal,
    this.level = 0,
    this.fragments = 0,
  });

  /// L'enregistrement en cours, ou nul.
  final CaptureInProgress? running;

  /// Le dernier refus, ou nul. Un refus est une réponse, pas une panne.
  final CaptureRefusal? refusal;

  /// 🔴 **Ce que le micro entend, de 0 à 1** — A2.
  ///
  /// L'écran n'avait qu'un chronomètre. Or un chronomètre avance aussi quand le
  /// micro est coupé, quand une housse le bouche, quand une autre application
  /// l'a pris — et le pasteur ne l'apprenait qu'après le culte, sur un fichier
  /// vide. *Ce qui n'est pas capté dimanche est perdu pour toujours.*
  final double level;

  /// Combien de fragments sont **posés sur le disque** — écrits, atomiquement.
  final int fragments;

  bool get isRunning => running != null;

  CaptureState copyWith({double? level, int? fragments}) => CaptureState(
        running: running,
        refusal: refusal,
        level: level ?? this.level,
        fragments: fragments ?? this.fragments,
      );
}

/// Le micro de la prédication, tenu **au-dessus des deux pages**.
///
/// ⚠️ **C'est la seule chose qui traverse la bascule.** Le pasteur va chercher
/// son plan pendant qu'il prêche ; si le bandeau disparaissait en changeant de
/// page, il croirait avoir coupé le micro — et il le rouvrirait, ou pire, il
/// s'arrêterait de prêcher pour vérifier.
///
/// `keepAlive` pour la même raison : libérer ce notifier parce qu'aucun écran
/// ne l'écoute une fraction de seconde couperait un enregistrement en cours.
final class SermonCaptureNotifier extends Notifier<CaptureState> {
  StreamSubscription<CaptureSignal>? _temoin;

  @override
  CaptureState build() {
    ref.keepAlive();

    // ⚠️ **Écouté une fois, pour toute la vie du notifier.** S'abonner au
    // démarrage de chaque capture laisserait un abonnement par prédication, et
    // le bandeau afficherait le niveau de la première.
    _temoin ??= ref.read(sermonCaptureProvider).signal.listen((signal) {
      // Rien à peindre quand rien n'enregistre : le dernier niveau resterait
      // figé sous les yeux du pasteur, et lui dirait que le micro entend.
      if (!state.isRunning) return;

      state = state.copyWith(level: signal.level, fragments: signal.fragments);
    });
    ref.onDispose(() => _temoin?.cancel());

    return CaptureState(running: ref.read(sermonCaptureProvider).current);
  }

  /// Ouvre le micro.
  ///
  /// 🔴 **Rien ne s'interpose** : pas de confirmation, pas de choix de
  /// préparation à rattacher, pas d'attente de réseau. *« Ce qui n'est pas
  /// capté dimanche est perdu pour toujours. »* On rattachera après.
  Future<void> start() async {
    final debut = await ref.read(sermonCaptureProvider).start();

    state = switch (debut) {
      CaptureRunning(:final capture) => CaptureState(running: capture),
      CaptureRefused(:final reason) => CaptureState(refusal: reason),
    };
  }

  /// Ferme le micro et rend la capture au magasin.
  Future<CapturedSermon?> stop() async {
    final capture = await ref.read(sermonCaptureProvider).stop();

    state = const CaptureState();
    // Le fichier vient d'être posé : la liste des prédications a vieilli.
    ref.invalidate(localCapturesProvider);

    // ⛔ **Plus rien ne part d'ici** (D71, 06/09). Ce geste faisait monter cent
    // quatre-vingts fragments vers un serveur qui ne les lit jamais ; on ne
    // transcrit plus la matière brute, seule une pièce se transcrit.
    //
    // ⚠️ **Mais l'assemblée s'écrit toujours, et à cet instant précis** (D68).
    // Le témoin va sur le disque à l'arrêt du micro, jamais au démarrage —
    // *rien ne s'interpose entre le pasteur et son micro*. Ce qu'il débloquait
    // a changé ; ce qu'il atteste, non.
    if (capture != null) unawaited(_rattacher(capture.id));

    return capture;
  }

  /// Attache l'assemblée quand elle ne fait aucun doute.
  ///
  /// 🔴 **Une seule église : on ne demande rien.** *Rien ne s'interpose* — le
  /// pasteur vient de finir de prêcher, lui poser une question dont la réponse
  /// est évidente serait un geste pour rien.
  ///
  /// 🔴 **Plusieurs, ou aucune : on ne devine pas, et on ne bloque pas non
  /// plus.** La capture reste sur l'appareil avec ses sept jours devant elle ;
  /// c'est l'écran qui posera la question, quand le pasteur y reviendra. Dix
  /// pasteurs desservent sept assemblées : celui qui en a deux prêche dans
  /// **l'une** d'elles ce dimanche-là, et lui en attribuer une au hasard
  /// fausserait la mesure sans que personne ne le voie.
  Future<void> _rattacher(String captureId) async {
    // ⚠️ **`preachingChurchIds` et non `churches`.** Le profil veut une liste
    // nommée que l'API mobile ne sert pas encore ; la capture veut un
    // identifiant et le droit d'y déposer, et ça, le serveur le sert.
    final eglises =
        (await ref.read(accountRepositoryProvider).preachingChurchIds()).fold(
      onSuccess: (valeur) => valeur,
      onFailure: (_) => const <String>[],
    );

    // Plusieurs assemblées, ou aucune : on ne devine pas. La capture reste sur
    // l'appareil avec ses sept jours devant elle, et `sansEglise()` la rend
    // listable pour que l'écran puisse poser la question.
    if (eglises.length != 1) return;

    await ref
        .read(fragmentUploaderProvider.notifier)
        .attacher(captureId, eglises.single);
  }
}

final sermonCaptureNotifierProvider =
    NotifierProvider<SermonCaptureNotifier, CaptureState>(
  SermonCaptureNotifier.new,
);

/// Les captures posées sur l'appareil, purgées de ce qui a passé sept jours.
///
/// ⚠️ **La purge se fait à la lecture**, et c'est délibéré : une tâche de fond
/// ne tourne pas sur un téléphone qu'on n'ouvre pas, et la promesse serait tenue
/// « quand l'application y pense ». Ici, personne ne peut voir la liste sans que
/// l'échéance ait été appliquée juste avant.
final localCapturesProvider = FutureProvider<List<CapturedSermon>>((ref) async {
  final magasin = ref.watch(captureStoreProvider);

  await magasin.purge(now: ref.watch(clockProvider).now());

  return magasin.list();
});
