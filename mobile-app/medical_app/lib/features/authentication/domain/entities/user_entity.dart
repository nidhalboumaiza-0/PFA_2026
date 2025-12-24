import 'package:equatable/equatable.dart';

/// Unified UserEntity class that combines all user-related fields
/// Used across authentication, messaging, and other features
class UserEntity extends Equatable {
  final String? id;
  final String name;
  final String lastName;
  final String email;
  final String role;
  final String gender;
  final String phoneNumber;
  final DateTime? dateOfBirth;
  final bool? accountStatus;
  
  // Verification fields
  final int? verificationCode;
  final DateTime? validationCodeExpiresAt;
  final bool? isEmailVerified;
  final bool? isActive;
  
  // Session/Token fields
  final String? fcmToken;
  final String? token; // JWT token for API calls and SocketService
  final String? refreshToken;
  final DateTime? lastLogin;
  final DateTime? lastActive;

  // Address and location fields
  final Map<String, String?>? address; // street, city, state, zipCode, country
  final Map<String, dynamic>? location; // type and coordinates for geospatial queries
  
  // Profile fields
  final String? profilePicture;
  final bool? isOnline;
  final String? oneSignalPlayerId;
  
  // Password reset fields
  final String? passwordResetCode;
  final DateTime? passwordResetExpires;

  const UserEntity({
    this.id,
    required this.name,
    required this.lastName,
    required this.email,
    required this.role,
    required this.gender,
    required this.phoneNumber,
    this.dateOfBirth,
    this.accountStatus,
    this.verificationCode,
    this.validationCodeExpiresAt,
    this.isEmailVerified,
    this.isActive,
    this.fcmToken,
    this.token,
    this.refreshToken,
    this.lastLogin,
    this.lastActive,
    this.address,
    this.location,
    this.profilePicture,
    this.isOnline,
    this.oneSignalPlayerId,
    this.passwordResetCode,
    this.passwordResetExpires,
  });

  factory UserEntity.create({
    String? id,
    required String name,
    required String lastName,
    required String email,
    required String role,
    required String gender,
    required String phoneNumber,
    DateTime? dateOfBirth,
    bool? accountStatus,
    int? verificationCode,
    DateTime? validationCodeExpiresAt,
    bool? isEmailVerified,
    bool? isActive,
    String? fcmToken,
    String? token,
    String? refreshToken,
    DateTime? lastLogin,
    DateTime? lastActive,
    Map<String, String?>? address,
    Map<String, dynamic>? location,
    String? profilePicture,
    bool? isOnline,
    String? oneSignalPlayerId,
    String? passwordResetCode,
    DateTime? passwordResetExpires,
  }) {
    return UserEntity(
      id: id,
      name: name,
      lastName: lastName,
      email: email,
      role: role,
      gender: gender,
      phoneNumber: phoneNumber,
      dateOfBirth: dateOfBirth,
      accountStatus: accountStatus,
      verificationCode: verificationCode,
      validationCodeExpiresAt: validationCodeExpiresAt,
      isEmailVerified: isEmailVerified,
      isActive: isActive,
      fcmToken: fcmToken,
      token: token,
      refreshToken: refreshToken,
      lastLogin: lastLogin,
      lastActive: lastActive,
      address: address,
      location: location,
      profilePicture: profilePicture,
      isOnline: isOnline,
      oneSignalPlayerId: oneSignalPlayerId,
      passwordResetCode: passwordResetCode,
      passwordResetExpires: passwordResetExpires,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    lastName,
    email,
    role,
    gender,
    phoneNumber,
    dateOfBirth,
    accountStatus,
    verificationCode,
    validationCodeExpiresAt,
    isEmailVerified,
    isActive,
    fcmToken,
    token,
    refreshToken,
    lastLogin,
    lastActive,
    address,
    location,
    profilePicture,
    isOnline,
    oneSignalPlayerId,
    passwordResetCode,
    passwordResetExpires,
  ];
}
