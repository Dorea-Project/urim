import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/time/clock.dart';

/// Horloge de l'application. Les tests la remplacent par une horloge figée.
final clockProvider = Provider<Clock>((ref) => const SystemClock());
