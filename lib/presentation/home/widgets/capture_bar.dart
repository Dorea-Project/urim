import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/audio/sermon_capture.dart';
import 'package:urim/core/time/clock_provider.dart';
import 'package:urim/l10n/generated/app_text.dart';
import 'package:urim/presentation/home/capture_view_model.dart';
import 'package:urim/presentation/theme/app_dimensions.dart';

/// « Enregistrement · 12:04 · Arrêter ».
///
/// ⚠️ **Il traverse la bascule, et c'est la seule chose qui le fasse.** Le
/// pasteur va chercher son plan pendant qu'il prêche : si le bandeau
/// disparaissait en changeant de page, il croirait avoir coupé le micro. Il
/// s'arrêterait de prêcher pour vérifier — ou pire, il rouvrirait un second
/// enregistrement.
class CaptureBar extends ConsumerStatefulWidget {
  const CaptureBar({super.key, required this.capture});

  final CaptureInProgress capture;

  @override
  ConsumerState<CaptureBar> createState() => _CaptureBarState();
}

class _CaptureBarState extends ConsumerState<CaptureBar> {
  Timer? _battement;

  @override
  void initState() {
    super.initState();
    // Une seconde : le chronomètre doit avancer sous les yeux. Un bandeau figé
    // à « 00:00 » ressemble à un enregistrement qui n'a pas démarré.
    _battement = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _battement?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = AppText.of(context);
    final ecoule = widget.capture.elapsed(ref.watch(clockProvider).now());

    return Material(
      color: theme.colorScheme.primaryContainer,
      child: InkWell(
        onTap: () => ref.read(sermonCaptureNotifierProvider.notifier).stop(),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(
                Icons.fiber_manual_record,
                size: 12,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                text.homeCaptureRunning,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                formatElapsed(ecoule),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const Spacer(),
              Text(
                text.homeCaptureStop,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// « 12:04 », « 1:02:33 » — l'heure n'apparaît qu'après soixante minutes.
///
/// Un sermon dure quarante minutes : afficher « 00:12:04 » gaspille deux
/// caractères sur le seul chiffre que personne ne regarde.
String formatElapsed(Duration ecoule) {
  final secondes = ecoule.inSeconds.remainder(60).toString().padLeft(2, '0');
  final minutes = ecoule.inMinutes.remainder(60);

  if (ecoule.inHours == 0) {
    return '${minutes.toString().padLeft(2, '0')}:$secondes';
  }

  return '${ecoule.inHours}:${minutes.toString().padLeft(2, '0')}:$secondes';
}
