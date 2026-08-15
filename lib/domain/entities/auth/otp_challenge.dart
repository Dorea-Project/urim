import 'package:equatable/equatable.dart';
import 'package:urim/domain/entities/auth/phone_number.dart';

/// Défi envoyé par SMS, en attente de vérification.
///
/// L'échéance est portée par le serveur, pas calculée sur l'appareil : une
/// horloge locale décalée ou trafiquée ne doit pas prolonger la validité.
final class OtpChallenge extends Equatable {
  const OtpChallenge({
    required this.id,
    required this.phone,
    required this.expiresAt,
    this.codeLength = defaultCodeLength,
  });

  /// Référence opaque rendue par le serveur. C'est elle qu'on renvoie à la
  /// vérification — jamais le numéro, qui n'a pas à circuler davantage.
  final String id;

  final PhoneNumber phone;
  final DateTime expiresAt;
  final int codeLength;

  /// Six chiffres : c'est ce que le serveur émet
  /// (`app/contexts/auth/infrastructure/otp.py`). L'écran de saisie s'y règle
  /// tout seul, mais un écart ferait échouer la vérification sans qu'aucun
  /// message ne l'explique.
  static const int defaultCodeLength = 6;
  static const Duration defaultValidity = Duration(minutes: 5);

  bool isExpired(DateTime now) => !now.isBefore(expiresAt);

  Duration remaining(DateTime now) {
    final left = expiresAt.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  @override
  List<Object?> get props => [id, phone, expiresAt, codeLength];

  @override
  String toString() => 'OtpChallenge($id, expire: $expiresAt)';
}
