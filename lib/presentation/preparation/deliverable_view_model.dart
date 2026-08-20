import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:urim/core/error/failure.dart';
import 'package:urim/data/repositories/study_repository_impl.dart';
import 'package:urim/domain/entities/preparation/deliverable.dart';

/// Ce que le pasteur obtient quand il demande un document.
sealed class DeliverableOutcome {
  const DeliverableOutcome();
}

/// Le document est là, et voici où il est posé.
final class DocumentReady extends DeliverableOutcome {
  const DocumentReady(this.path);

  final String path;
}

/// Le contrôle a refusé : au moins une citation n'est pas celle du corpus.
///
/// Ce n'est pas une panne — c'est le seul écran où un verset abîmé se voit
/// avant le dimanche.
final class CitationRefused extends DeliverableOutcome {
  const CitationRefused(this.dossier);

  final Deliverable dossier;
}

final class DeliverableFailed extends DeliverableOutcome {
  const DeliverableFailed(this.failure);

  final Failure failure;
}

/// Produire un document : soumettre, faire juger, prendre les octets, poser le
/// fichier.
///
/// **Trois appels et un seul geste.** Le pasteur touche « Fiche de chaire » ;
/// il n'a pas à savoir qu'un contrôle a lieu entre les deux, sauf s'il échoue —
/// et alors il doit tout savoir.
final class DeliverableProducer extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<DeliverableOutcome> produce({
    required String studyId,
    required String kind,
    List<Slide> slides = const [],
  }) async {
    state = const AsyncLoading();

    final repository = ref.read(studyRepositoryProvider);
    final soumis = await repository.submitDeliverable(
      studyId: studyId,
      kind: kind,
      slides: slides,
    );

    final dossier = soumis.valueOrNull;
    if (dossier == null) {
      state = const AsyncData(null);
      return DeliverableFailed(soumis.failureOrNull!);
    }

    // Le refus s'arrête ici, et il s'arrête **avant** de demander les octets :
    // le serveur les refuserait de toute façon, et une seconde requête pour
    // s'entendre dire non serait une seconde attente pour rien.
    if (!dossier.isConform) {
      state = const AsyncData(null);
      return CitationRefused(dossier);
    }

    final rendu = await repository.downloadDeliverable(dossier.id);
    state = const AsyncData(null);

    final fichier = rendu.valueOrNull;
    if (fichier == null) return DeliverableFailed(rendu.failureOrNull!);

    try {
      return DocumentReady(await _poser(fichier));
    } on Object catch (error) {
      return DeliverableFailed(
        CacheFailure(
          message: 'Le document n\'a pas pu être écrit : $error',
          code: 'document_write_failed',
        ),
      );
    }
  }

  /// Pose le fichier là où le pasteur peut le reprendre.
  ///
  /// ⚠️ **Le dossier externe d'abord, et c'est tout l'enjeu.** Un document
  /// écrit dans le bac à sable de l'application n'est ouvrable par personne :
  /// ni Word, ni l'imprimante de l'église, ni un envoi. Sur Android,
  /// `getExternalStorageDirectory` rend un dossier que les gestionnaires de
  /// fichiers voient. Ailleurs — et si ce dossier manque — on retombe sur les
  /// documents de l'application, ce qui vaut mieux que rien.
  Future<String> _poser(DeliverableFile fichier) async {
    final dossier = await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();

    final cible = File('${dossier.path}/${fichier.filename}');
    await cible.writeAsBytes(fichier.bytes, flush: true);

    return cible.path;
  }
}

final deliverableProducerProvider =
    NotifierProvider<DeliverableProducer, AsyncValue<void>>(
  DeliverableProducer.new,
);
