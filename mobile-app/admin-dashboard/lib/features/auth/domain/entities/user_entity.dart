import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String role;
  final bool isOnline;
  final DateTime? lastLogin;
  final DateTime? createdAt;

  static const String ROLE_ADMIN = 'admin';
  static const String ROLE_MEDECIN = 'medecin';
  static const String ROLE_PATIENT = 'patient';

  static const List<String> validRoles = [
    ROLE_ADMIN,
    ROLE_MEDECIN,
    ROLE_PATIENT,
  ];

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    required this.role,
    this.isOnline = false,
    this.lastLogin,
    this.createdAt,
  });

  bool get isAdmin => role == ROLE_ADMIN;
  bool get isMedecin => role == ROLE_MEDECIN;
  bool get isPatient => role == ROLE_PATIENT;

  bool hasPermission(List<String> allowedRoles) {
    return allowedRoles.contains(role);
  }

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    phoneNumber,
    role,
    isOnline,
    lastLogin,
    createdAt,
  ];
}
