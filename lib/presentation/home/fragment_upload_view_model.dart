import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/audio/fragment_outbox.dart';
import 'package:urim/data/datasources/fragment_remote_data_source.dart';

/// Ce que l'écran sait de la montée des fragments.
final class UploadState extends Equatable {
  const UploadState({
    this.pending = 0,
    this.sending = false,
    this.stopped = false,
  });

  /// Combien de fragments attendent encore, toutes captures confondues.
  final int pending;

  /// Un passage est en cours.
  final bool sending;

  /// ⚠️ **Le serveur a dit « cesse ».** Campagne de mesure close, ou droit
  /// retiré. Rien n'est perdu — les fragments restent jusqu'à leur purge — mais
  /// insister ne servirait à rien, et l'écran doit pouvoir le dire plutôt que
  /// d'afficher une file qui ne descend jamais.
  final bool stopped;

  bool get hasPending => pending > 0;

  @override
  List<Object?> get props => [pending, sending, stopped];
}

/// 🔴 **Le déclencheur — et son absence était le défaut le plus silencieux du
/// chantier.**
///
/// `FragmentOutbox` était livrée, testée, et remplie à chaque culte. Mais
/// `flush()` n'était appelé **par aucun écran, aucun modèle de vue, aucun
/// ordonnanceur** — seulement par ses propres tests. Une file parfaite qui ne
/// part jamais reste une file parfaite : rien ne cassait, rien ne se plaignait,
/// et aucun fragment ne serait jamais monté.
///
/// Deux moments déclenchent, et ils suffisent :
///
/// - **la fin d'une capture**, où les fragments viennent d'être posés et où le
///   pasteur a encore le téléphone en main ;
/// - **le retour de l'application au premier plan**, qui rattrape le culte
///   capté sans réseau — le cas ordinaire d'un dimanche matin.
///
/// ⚠️ **Aucune tâche de fond**, et c'est le même raisonnement que la purge des
/// captures : *une tâche de fond ne tourne pas sur un téléphone qu'on n'ouvre
/// pas*. La marge est de sept jours, largement de quoi rouvrir l'application.
final class FragmentUploader extends Notifier<UploadState> {
  @override
  UploadState build() {
    // La file survit aux écrans : la relâcher entre deux pages annulerait un
    // envoi en cours.
    ref.keepAlive();
    return const UploadState();
  }

  /// Attache une assemblée à une capture. **Ne fait plus rien partir** (D71).
  ///
  /// Rend faux si la capture est introuvable ou porte déjà une église — une
  /// capture ne change pas d'assemblée : le culte a eu lieu quelque part.
  ///
  /// ⚠️ **Le témoin d'église reste utile alors que le transport a cessé**, et
  /// ce n'est pas une contradiction. D68 l'écrit sur le disque à l'arrêt du
  /// micro parce que dix pasteurs desservent sept assemblées et qu'un culte
  /// rangé sous la mauvaise fausserait la mesure — laquelle compte trois
  /// églises **distinctes**. Ce qu'il servait à débloquer a changé ; ce qu'il
  /// atteste, non.
  Future<bool> attacher(String captureId, String churchId) =>
      ref.read(fragmentOutboxProvider).attacherEglise(captureId, churchId);

  /// Les captures qui attendent qu'on leur dise devant quelle assemblée elles
  /// ont été prêchées.
  ///
  /// 🔴 **Elles ne partiront jamais sans réponse**, et c'est voulu : deviner
  /// fausserait la mesure, dont le seuil compte trois églises **distinctes**.
  /// L'écran doit donc pouvoir les montrer et poser la question.
  Future<List<OutboxStatus>> sansEglise() =>
      ref.read(fragmentOutboxProvider).sansEglise();

  /// Recompte ce qui attend, sans rien envoyer.
  Future<void> refresh() async {
    final attente = await _pending();
    state = UploadState(
      pending: attente,
      sending: state.sending,
      stopped: state.stopped,
    );
  }

  /// Emporte ce qui peut l'être.
  ///
  /// Ne lève jamais, et **ne se superpose pas à lui-même** : deux passages
  /// simultanés liraient la même marque haute et enverraient deux fois les
  /// mêmes fragments. Le serveur les absorberait, mais ce serait deux fois le
  /// forfait.
  Future<int> flush() async {
    if (state.sending) return 0;

    state = UploadState(
      pending: state.pending,
      sending: true,
      stopped: state.stopped,
    );

    var partis = 0;
    try {
      partis = await ref.read(fragmentOutboxProvider).flush();
    } on Object {
      // Le transport ne lève pas ; si quelque chose passe quand même, la file
      // est intacte sur le disque et repartira. On ne fait pas tomber l'écran
      // du pasteur pour ça.
    }

    final reste = await _pending();

    state = UploadState(
      pending: reste,
      sending: false,
      // Rien n'est parti alors qu'il restait à envoyer : le serveur a refusé.
      // On le retient pour que l'écran cesse de promettre une montée.
      stopped: partis == 0 && reste > 0 && state.pending > 0,
    );

    return partis;
  }

  Future<int> _pending() async {
    final etats = await ref.read(fragmentOutboxProvider).pending();

    var total = 0;
    for (final etat in etats) {
      total += etat.pending;
    }
    return total;
  }
}

final fragmentUploaderProvider =
    NotifierProvider<FragmentUploader, UploadState>(FragmentUploader.new);
