import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required String id,
    required String name,
    required String email,
    String? phoneNumber,
    required String role,
    bool isOnline = false,
    DateTime? lastLogin,
    DateTime? createdAt,
  }) : super(
         id: id,
         name: name,
         email: email,
         phoneNumber: phoneNumber,
         role: role,
         isOnline: isOnline,
         lastLogin: lastLogin,
         createdAt: createdAt,
       );

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      role: json['role'] ?? UserEntity.ROLE_PATIENT,
      isOnline: json['isOnline'] ?? false,
      lastLogin:
          json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'isOnline': isOnline,
      'lastLogin': lastLogin?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      phoneNumber: entity.phoneNumber,
      role: entity.role,
      isOnline: entity.isOnline,
      lastLogin: entity.lastLogin,
      createdAt: entity.createdAt,
    );
  }
}
