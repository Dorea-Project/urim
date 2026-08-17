import 'package:dio/dio.dart';
import 'package:urim/core/network/dio_error_mapper.dart';
import 'package:urim/domain/entities/preparation/preparation.dart';
import 'package:urim/domain/entities/preparation/study_summary.dart';

/// Le moteur Urim, canal mobile : `/api/mobile/urim`.
///
/// Les noms de champs sont ceux du serveur (`raw_input`, `last_outcome`,
/// `pericope_label`) : la conversion vers le vocabulaire du domaine se fait
/// ici, et nulle part ailleurs.
final class UrimRemoteDataSource {
  const UrimRemoteDataSource(this._dio);

  final Dio _dio;

  /// `GET /urim/studies` — le fil, sans rejouer le moteur.
  ///
  /// Ce que la réponse ne contient pas : aucune phrase d'Urim. Le serveur s'y
  /// refuse pour ne pas rejouer son pipeline vingt fois, et l'application n'a
  /// donc rien à en attendre.
  Future<List<StudySummary>> listStudies() async {
    final List<dynamic> rows;

    try {
      final response = await _dio.get<List<dynamic>>('/urim/studies');
      rows = response.data ?? const [];
    } on DioException catch (e) {
      throw mapDioException(e);
    }

    return [
      for (final row in rows)
        _summaryFromJson(row as Map<String, dynamic>),
    ];
  }
}

StudySummary _summaryFromJson(Map<String, dynamic> json) {
  final lastTurn = _dateFrom(json['last_turn_at']);
  final opened = _dateFrom(json['opened_at']);

  return StudySummary(
    id: json['id'] as String,
    rawInput: json['raw_input'] as String? ?? '',
    pericopeLabel: json['pericope_label'] as String?,
    theme: json['theme'] as String?,
    serviceDate: _dateFrom(json['service_date']),
    lastOutcome: TurnOutcome.fromWire(json['last_outcome'] as String?),
    // Le dernier tour, à défaut l'ouverture : une préparation créée à
    // l'instant n'a pas de tour, et tomberait en fin de fil alors qu'elle
    // vient de naître. Le serveur trie déjà ainsi ; on le redit ici parce que
    // le regroupement par récence s'appuie dessus.
    lastActivity: lastTurn ?? opened ?? DateTime.now(),
    isClosed: json['status'] == 'close',
    // Le moteur ne connaît que les préparations écrites : sa capture est
    // verrouillée à l'étape 1. Tout ce qui vient du serveur est donc écrit.
    origin: PreparationOrigin.written,
  );
}

DateTime? _dateFrom(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toLocal() : null;
