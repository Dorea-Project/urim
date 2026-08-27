import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/audio/capture_store.dart';
import 'package:urim/core/audio/recorded_sermon_capture.dart';
import 'package:urim/core/audio/sermon_capture.dart';
import 'package:urim/core/time/clock_provider.dart';

/// Ce que l'écran sait de la capture en cours.
final class CaptureState {
  const CaptureState({this.running, this.refusal});

  /// L'enregistrement en cours, ou nul.
  final CaptureInProgress? running;

  /// Le dernier refus, ou nul. Un refus est une réponse, pas une panne.
  final CaptureRefusal? refusal;

  bool get isRunning => running != null;
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
  @override
  CaptureState build() {
    ref.keepAlive();
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

    return capture;
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
