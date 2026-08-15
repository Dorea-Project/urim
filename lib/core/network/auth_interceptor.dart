import 'dart:async';

import 'package:dio/dio.dart';
import 'package:urim/core/security/auth_tokens.dart';
import 'package:urim/core/security/token_store.dart';

/// Signature du rafraîchissement, fournie par la couche data.
///
/// L'intercepteur ne connaît pas la route `/auth/refresh` : la lui donner
/// ferait dépendre le socle réseau d'un contexte métier, et l'appel de
/// rafraîchissement passerait par l'intercepteur qui l'a déclenché.
typedef RefreshSession = Future<AuthTokens> Function(String refreshToken);

/// Pose le jeton sur chaque requête, et rejoue une fois après un 401.
///
/// Deux règles portent tout le fichier :
///
/// - **Un seul rafraîchissement à la fois.** Trois écrans qui échouent
///   ensemble ne doivent pas déclencher trois rotations : la deuxième
///   invaliderait le jeton obtenu par la première.
/// - **Un seul rejeu.** Si la requête rejouée échoue encore, la session est
///   morte : on l'efface et l'erreur remonte. Boucler produirait une
///   application qui tourne sans jamais rien afficher.
final class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required TokenStore store,
    required RefreshSession refresh,
    required Dio retrier,
    DateTime Function()? now,
  })  : _store = store,
        _refresh = refresh,
        _retrier = retrier,
        _now = now ?? DateTime.now;

  /// Routes jouées sans jeton : ce sont elles qui en délivrent un.
  static const Set<String> anonymousPaths = {
    '/auth/register',
    '/auth/verify-registration',
    '/auth/login',
    '/auth/verify-device',
    '/auth/reset-secret-code/request',
    '/auth/reset-secret-code/confirm',
    '/auth/refresh',
  };

  /// Marque une requête déjà rejouée, pour ne pas y revenir.
  static const String _retriedFlag = 'urim.retried';

  final TokenStore _store;
  final RefreshSession _refresh;
  final Dio _retrier;
  final DateTime Function() _now;

  Future<AuthTokens?>? _inFlight;

  static bool _isAnonymous(RequestOptions options) =>
      anonymousPaths.any(options.path.endsWith);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isAnonymous(options)) return handler.next(options);

    var tokens = await _store.read();

    // Rafraîchissement préventif : l'accès expiré est connu d'avance, autant
    // s'en occuper avant de dépenser un aller-retour pour un 401 certain.
    if (tokens != null && tokens.isStale(_now())) {
      tokens = await _refreshOnce(tokens.refreshToken);
    }

    if (tokens != null) {
      options.headers['Authorization'] = tokens.authorizationHeader;
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;

    final isRetryable = err.response?.statusCode == 401 &&
        !_isAnonymous(options) &&
        options.extra[_retriedFlag] != true;

    if (!isRetryable) return handler.next(err);

    final stored = await _store.read();
    if (stored == null) return handler.next(err);

    final refreshed = await _refreshOnce(stored.refreshToken);
    if (refreshed == null) return handler.next(err);

    options
      ..extra[_retriedFlag] = true
      ..headers['Authorization'] = refreshed.authorizationHeader;

    try {
      final response = await _retrier.fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (retryError) {
      return handler.next(retryError);
    }
  }

  /// Rotation des jetons, partagée par tous les appelants simultanés.
  Future<AuthTokens?> _refreshOnce(String refreshToken) {
    return _inFlight ??= _performRefresh(refreshToken).whenComplete(() {
      _inFlight = null;
    });
  }

  Future<AuthTokens?> _performRefresh(String refreshToken) async {
    try {
      final tokens = await _refresh(refreshToken);
      await _store.save(tokens);
      return tokens;
    } catch (_) {
      // Le rafraîchissement a échoué : le refresh est révoqué ou expiré. On
      // efface plutôt que de garder des jetons morts, sans quoi chaque écran
      // retenterait indéfiniment.
      await _store.clear();
      return null;
    }
  }
}
