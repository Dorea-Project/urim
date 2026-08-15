import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Instance de [SharedPreferences], résolue avant le premier `runApp`.
///
/// Sans valeur par défaut, comme `appConfigProvider` : l'obtention est
/// asynchrone, et la faire à la volée obligerait chaque lecture à traverser un
/// `AsyncValue`. On paie l'attente une fois, au démarrage.
///
/// En test : `SharedPreferences.setMockInitialValues({})` puis surcharge.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider doit être surchargé au démarrage '
    '(voir main.dart).',
  ),
);
