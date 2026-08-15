import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/network/auth_interceptor.dart';
import 'package:urim/core/network/dio_client.dart';
import 'package:urim/core/network/dio_error_mapper.dart';
import 'package:urim/core/security/auth_tokens.dart';

/// Rotation des jetons : `POST /auth/refresh`.
///
/// Posé dans le socle réseau, et non dans la couche data, parce que
/// l'intercepteur en dépend au démarrage — le faire descendre du dépôt
/// d'authentification créerait un cycle entre le client HTTP et ce qui s'en
/// sert.
final tokenRefresherProvider = Provider<RefreshSession>((ref) {
  final dio = ref.watch(anonymousDioProvider);

  return (refreshToken) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      return tokensFromJson(response.data!, now: DateTime.now());
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  };
});

/// Lit une réponse `TokenResponse` du backend.
///
/// `expires_in` est une durée, pas une date : le serveur ignore l'heure de
/// l'appareil, souvent fausse de quelques minutes. On la convertit ici, une
/// seule fois, au moment où la réponse arrive.
AuthTokens tokensFromJson(Map<String, dynamic> json, {required DateTime now}) {
  final expiresIn = json['expires_in'];

  return AuthTokens(
    accessToken: json['access_token'] as String,
    refreshToken: json['refresh_token'] as String,
    tokenType: json['token_type'] as String? ?? 'bearer',
    expiresAt: now.add(
      Duration(seconds: expiresIn is int ? expiresIn : 3600),
    ),
  );
}
