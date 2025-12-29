import 'package:equatable/equatable.dart';

enum UserRole { patient, doctor, admin }

class UserEntity extends Equatable {
  final String id;
  final String email;
  final UserRole role;
  final bool isEmailVerified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLogin;

  const UserEntity({
    required this.id,
    required this.email,
    required this.role,
    required this.isEmailVerified,
    required this.isActive,
    required this.createdAt,
    this.lastLogin,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        role,
        isEmailVerified,
        isActive,
        createdAt,
        lastLogin,
      ];
}
