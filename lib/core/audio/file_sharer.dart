import 'dart:io';

import 'package:flutter/services.dart' show MissingPluginException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// Pourquoi la pièce n'est pas partie.
///
/// 🔴 **Même règle que la lecture : un silence n'est pas une réponse.** Le
/// pasteur appuie et attend ; s'il ne se passe rien, il doit lire ce qui manque
/// plutôt que de conclure que l'application est cassée.
enum ShareRefusal {
  /// Le fichier n'est plus là.
  ///
  /// ⚠️ Le cas le moins improbable : le pasteur a vidé le stockage, ou restauré
  /// l'appareil. L'écran doit le dire, pas se taire.
  fileMissing,

  /// Aucun partage sur cet appareil, ou le greffon n'a pas répondu.
  engineMissing,

  /// Il a répondu, et mal.
  engineFailed,
}

/// Faire sortir une pièce du téléphone — **le seul débouché qui existe
/// aujourd'hui**.
///
/// 🔴 **Sans ça, l'éditeur est un outil sans issue.** Un pasteur peut découper
/// son culte, nommer ses pièces, les réécouter — et rien n'en sort. Le canal
/// réel de son assemblée n'est pas une plateforme qui n'existe pas encore,
/// c'est **le partage du téléphone** : WhatsApp, un message, un dossier.
///
/// ⚠️ **Le mur qui bloquait ça est tombé sans que personne ne s'en aperçoive.**
/// `decisions.md` porte encore la note : *« `share_plus` exige `win32 ^5` et le
/// coffre à secrets `^4` ; le pasteur doit aller chercher le fichier avec un
/// gestionnaire de fichiers »*. Le coffre est passé en version 11 depuis, et le
/// conflit n'existe plus — vérifié en le résolvant, pas en relisant la note.
///
/// Interface plutôt qu'appel direct au greffon, même raison que le micro et le
/// lecteur : un partage ne répond que sur un vrai appareil, et le brancher en
/// dur rendrait l'écran intestable.
abstract interface class FileSharer {
  /// Propose [chemin] aux applications de l'appareil.
  ///
  /// Rend le motif du refus, `null` si la feuille de partage s'est ouverte —
  /// **y compris si le pasteur l'annule ensuite**. Annuler n'est pas un échec,
  /// et le dire comme tel inquiéterait pour rien.
  Future<ShareRefusal?> partager(String chemin, {String? titre});
}

/// Le partage réel, par la feuille du système.
final class DeviceFileSharer implements FileSharer {
  const DeviceFileSharer();

  @override
  Future<ShareRefusal?> partager(String chemin, {String? titre}) async {
    // ⚠️ **On regarde avant de proposer.** Le greffon rend des erreurs de
    // plateforme illisibles pour un fichier absent ; les distinguer ici donne à
    // l'écran la seule phrase que le pasteur puisse comprendre.
    if (!File(chemin).existsSync()) return ShareRefusal.fileMissing;

    try {
      final resultat = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(chemin)],
          subject: titre,
        ),
      );

      // `unavailable` est le seul état qui dise que rien ne s'est ouvert.
      // `dismissed` veut dire que le pasteur a refermé la feuille — c'est son
      // droit, pas une panne.
      return resultat.status == ShareResultStatus.unavailable
          ? ShareRefusal.engineMissing
          : null;
    } on MissingPluginException {
      return ShareRefusal.engineMissing;
    } on Object {
      return ShareRefusal.engineFailed;
    }
  }
}

final fileSharerProvider =
    Provider<FileSharer>((ref) => const DeviceFileSharer());
