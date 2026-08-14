import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/config/app_config_provider.dart';

/// Client HTTP partagé par tous les `*RemoteDataSource`.
///
/// Un seul [Dio] pour toute l'application : les intercepteurs (authentification,
/// rejeu, télémétrie) s'ajoutent ici et s'appliquent partout.
final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: config.connectTimeout,
      receiveTimeout: config.receiveTimeout,
      headers: const {'Accept': 'application/json'},
      // Les statuts d'erreur doivent lever : ils sont convertis en
      // AppException par `mapDioException`.
      validateStatus: (status) => status != null && status >= 200 && status < 300,
    ),
  );

  // L'intercepteur d'authentification vient ici, une fois la piste
  // « session » définie : injection du jeton, rafraîchissement sur 401.

  if (config.enableVerboseLogging) {
    dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true),
    );
  }

  ref.onDispose(dio.close);

  return dio;
});
