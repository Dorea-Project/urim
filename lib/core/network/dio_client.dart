import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urim/core/config/app_config.dart';
import 'package:urim/core/config/app_config_provider.dart';
import 'package:urim/core/network/auth_interceptor.dart';
import 'package:urim/core/network/token_refresher.dart';
import 'package:urim/core/security/token_store.dart';

/// Client HTTP **sans authentification**, pour les routes d'entrée et pour le
/// rafraîchissement lui-même.
///
/// Séparé du client authentifié parce qu'un rafraîchissement qui traverserait
/// l'intercepteur d'authentification se rappellerait lui-même en boucle au
/// premier 401.
final anonymousDioProvider = Provider<Dio>((ref) {
  final dio = _baseDio(ref.watch(appConfigProvider));
  ref.onDispose(dio.close);
  return dio;
});

/// Client HTTP partagé par tous les `*RemoteDataSource`.
///
/// Un seul [Dio] pour toute l'application : le jeton, sa rotation et la
/// journalisation s'ajoutent ici, et s'appliquent partout.
final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final dio = _baseDio(config);

  dio.interceptors.add(
    AuthInterceptor(
      store: ref.watch(tokenStoreProvider),
      refresh: ref.watch(tokenRefresherProvider),
      // Le rejeu passe par le client anonyme : l'en-tête est déjà posé à la
      // main, et repasser par les intercepteurs relancerait la mécanique.
      retrier: ref.watch(anonymousDioProvider),
    ),
  );

  if (config.enableVerboseLogging) {
    dio.interceptors.add(_RedactingLogInterceptor());
  }

  ref.onDispose(dio.close);

  return dio;
});

Dio _baseDio(AppConfig config) => Dio(
      BaseOptions(
        baseUrl: config.apiRoot,
        connectTimeout: config.connectTimeout,
        receiveTimeout: config.receiveTimeout,
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        // Les statuts d'erreur doivent lever : ils sont convertis en
        // AppException par `mapDioException`.
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
      ),
    );

/// Journalisation de développement, **sans les secrets**.
///
/// `LogInterceptor` imprime les en-têtes et les corps tels quels : le jeton, le
/// code SMS et le code secret finiraient dans les journaux de l'appareil, où
/// n'importe quelle application autorisée peut les lire.
class _RedactingLogInterceptor extends Interceptor {
  static const Set<String> _sensitiveFields = {
    'secret_code',
    'new_secret_code',
    'otp',
    'access_token',
    'refresh_token',
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // ignore: avoid_print
    print('→ ${options.method} ${options.uri} ${_redact(options.data)}');
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    // ignore: avoid_print
    print('← ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // ignore: avoid_print
    print('✗ ${err.response?.statusCode} ${err.requestOptions.uri} '
        '${err.response?.data}');
    handler.next(err);
  }

  Object? _redact(Object? data) {
    if (data is! Map) return data;

    return {
      for (final entry in data.entries)
        entry.key: _sensitiveFields.contains(entry.key) ? '•••' : entry.value,
    };
  }
}
