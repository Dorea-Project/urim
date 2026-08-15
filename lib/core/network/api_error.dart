/// Corps d'erreur du backend, de forme stable quel que soit le contexte
/// émetteur :
///
/// ```json
/// { "error": { "code": "INVALID_CREDENTIALS", "message": "...", "details": {} } }
/// ```
final class ApiError {
  const ApiError({required this.code, required this.message, this.details = const {}});

  final String code;
  final String message;
  final Map<String, dynamic> details;

  /// Extrait l'erreur d'un corps de réponse, ou `null` si la réponse ne suit
  /// pas la forme attendue — un proxy ou une passerelle peuvent répondre du
  /// HTML, et l'application ne doit pas s'y casser.
  static ApiError? tryParse(Object? body) {
    if (body is! Map) return null;

    final error = body['error'];
    if (error is! Map) return null;

    final code = error['code'];
    final message = error['message'];
    if (code is! String || message is! String) return null;

    return ApiError(
      code: code,
      message: message,
      details: error['details'] is Map
          ? Map<String, dynamic>.from(error['details'] as Map)
          : const {},
    );
  }

  /// Erreurs par champ, telles que FastAPI les renvoie sur un 422 :
  /// `details.errors[].loc` = chemin du champ, `.msg` = motif.
  Map<String, String> get fieldErrors {
    final errors = details['errors'];
    if (errors is! List) return const {};

    final mapped = <String, String>{};

    for (final entry in errors) {
      if (entry is! Map) continue;

      final location = entry['loc'];
      final message = entry['msg'];
      if (message is! String) continue;

      // `loc` vaut ["body", "phone_number"] : le dernier segment nomme le
      // champ, les précédents disent seulement où il se trouvait.
      final field = location is List && location.isNotEmpty
          ? location.last.toString()
          : 'requête';

      mapped[field] = message;
    }

    return mapped;
  }

  @override
  String toString() => 'ApiError($code)';
}
