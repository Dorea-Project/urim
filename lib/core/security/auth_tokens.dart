import 'package:equatable/equatable.dart';

/// Paire de jetons émise par le serveur.
///
/// L'accès est court (une heure), le rafraîchissement long (trente jours) et
/// **tourne** à chaque usage : le serveur en émet un nouveau et invalide
/// l'ancien. Conserver l'ancien après un rafraîchissement réussi condamnerait
/// la session au prochain appel.
final class AuthTokens extends Equatable {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    this.tokenType = 'bearer',
  });

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final String tokenType;

  /// Vrai lorsque l'accès est périmé, ou sur le point de l'être.
  ///
  /// La marge évite le cas où le jeton expire pendant le trajet de la requête :
  /// on préfère rafraîchir une fois de trop qu'essuyer un 401 évitable.
  bool isStale(DateTime now, {Duration margin = const Duration(seconds: 30)}) =>
      !expiresAt.subtract(margin).isAfter(now);

  /// En-tête `Authorization` à poser sur les requêtes.
  String get authorizationHeader {
    final scheme = tokenType.isEmpty
        ? 'Bearer'
        : tokenType[0].toUpperCase() + tokenType.substring(1);

    return '$scheme $accessToken';
  }

  @override
  List<Object?> get props => [accessToken, refreshToken, expiresAt, tokenType];

  /// Jamais le contenu : un jeton dans un journal est un jeton perdu.
  @override
  String toString() => 'AuthTokens(expiresAt: $expiresAt)';
}
