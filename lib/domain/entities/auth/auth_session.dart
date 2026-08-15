import 'package:equatable/equatable.dart';
import 'package:urim/domain/entities/auth/phone_number.dart';

/// Session ouverte après vérification du code SMS.
final class AuthSession extends Equatable {
  const AuthSession({
    required this.userId,
    required this.phone,
    required this.openedAt,
  });

  final String userId;
  final PhoneNumber phone;
  final DateTime openedAt;

  @override
  List<Object?> get props => [userId, phone, openedAt];

  @override
  String toString() => 'AuthSession($userId)';
}
