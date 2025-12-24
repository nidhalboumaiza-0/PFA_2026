import '../../domain/entities/user_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel extends UserEntity {


  UserModel({
    String? id,
    required String name,
    required String lastName,
    required String email,
    required String role,
    required String gender,
    required String phoneNumber,
    DateTime? dateOfBirth,
    bool? accountStatus,
    bool? isEmailVerified,
    bool? isActive,
    DateTime? lastLogin,
    Map<String, String?>? address,
    Map<String, dynamic>? location,
    String? profilePicture,
    bool? isOnline,
    String? oneSignalPlayerId,
    String? passwordResetCode,
    DateTime? passwordResetExpires,
    String? refreshToken,
  }) : super(
         id: id,
         name: name,
         lastName: lastName,
         email: email,
         role: role,
         gender: gender,
         phoneNumber: phoneNumber,
         dateOfBirth: dateOfBirth,
         accountStatus: accountStatus,
         isEmailVerified: isEmailVerified,
         isActive: isActive,
         lastLogin: lastLogin,
         address: address,
         location: location,
         profilePicture: profilePicture,
         isOnline: isOnline,
         oneSignalPlayerId: oneSignalPlayerId,
         passwordResetCode: passwordResetCode,
         passwordResetExpires: passwordResetExpires,
         refreshToken: refreshToken,
       );

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle potential null or wrong types for each field
    // Support both '_id' (MongoDB) and 'id' field names
    final String id = json['_id'] is String 
        ? json['_id'] as String 
        : (json['id'] is String ? json['id'] as String : '');
    // Support both 'firstName' (backend) and 'name' (legacy) field names
    final String name = json['firstName'] is String 
        ? json['firstName'] as String 
        : (json['name'] is String ? json['name'] as String : '');
    final String lastName =
        json['lastName'] is String ? json['lastName'] as String : '';
    final String email = json['email'] is String ? json['email'] as String : '';
    final String role =
        json['role'] is String ? json['role'] as String : 'user';
    final String gender =
        json['gender'] is String ? json['gender'] as String : 'Homme';
    // Support both 'phone' (backend) and 'phoneNumber' (legacy) field names
    final String phoneNumber = json['phone'] is String 
        ? json['phone'] as String 
        : (json['phoneNumber'] is String ? json['phoneNumber'] as String : '');

    // Handle nullable fields with proper type checking
    DateTime? dateOfBirth;
    if (json['dateOfBirth'] is String &&
        (json['dateOfBirth'] as String).isNotEmpty) {
      try {
        dateOfBirth = DateTime.parse(json['dateOfBirth'] as String);
      } catch (_) {
        dateOfBirth = null;
      }
    }

    bool? accountStatus;
    if (json['accountStatus'] is bool) {
      accountStatus = json['accountStatus'] as bool;
    } else if (json['accountStatus'] is String) {
      accountStatus = (json['accountStatus'] as String).toLowerCase() == 'true';
    } else {
      accountStatus = false;
    }

    bool? isEmailVerified;
    if (json['isEmailVerified'] is bool) {
      isEmailVerified = json['isEmailVerified'] as bool;
    } else {
      isEmailVerified = false;
    }

    bool? isActive;
    if (json['isActive'] is bool) {
      isActive = json['isActive'] as bool;
    } else {
      isActive = true;
    }

    DateTime? lastLogin;
    if (json['lastLogin'] is String &&
        (json['lastLogin'] as String).isNotEmpty) {
      try {
        lastLogin = DateTime.parse(json['lastLogin'] as String);
      } catch (_) {
        lastLogin = null;
      }
    }

    String? oneSignalPlayerId;
    if (json['oneSignalPlayerId'] is String) {
      oneSignalPlayerId = json['oneSignalPlayerId'] as String;
    }

    String? passwordResetCode;
    if (json['passwordResetCode'] is String) {
      passwordResetCode = json['passwordResetCode'] as String;
    }

    DateTime? passwordResetExpires;
    if (json['passwordResetExpires'] is String &&
        (json['passwordResetExpires'] as String).isNotEmpty) {
      try {
        passwordResetExpires = DateTime.parse(
          json['passwordResetExpires'] as String,
        );
      } catch (_) {
        passwordResetExpires = null;
      }
    }

    String? refreshToken;
    if (json['refreshToken'] is String) {
      refreshToken = json['refreshToken'] as String;
    }

    // Handle address
    Map<String, String?>? address;
    if (json['address'] is Map) {
      address = Map<String, String?>.from(json['address'] as Map);
    }

    // Handle location
    Map<String, dynamic>? location;
    if (json['location'] is Map) {
      location = Map<String, dynamic>.from(json['location'] as Map);
    }

    // Handle profilePicture - support both 'profilePhoto' (backend) and 'profilePicture' (legacy)
    String? profilePicture;
    if (json['profilePhoto'] is String) {
      profilePicture = json['profilePhoto'] as String;
    } else if (json['profilePicture'] is String) {
      profilePicture = json['profilePicture'] as String;
    }

    // Handle isOnline
    bool? isOnline;
    if (json['isOnline'] is bool) {
      isOnline = json['isOnline'] as bool;
    }

    return UserModel(
      id: id,
      name: name,
      lastName: lastName,
      email: email,
      role: role,
      gender: gender,
      phoneNumber: phoneNumber,
      dateOfBirth: dateOfBirth,
      accountStatus: accountStatus,
      isEmailVerified: isEmailVerified,
      isActive: isActive,
      lastLogin: lastLogin,
      address: address,
      location: location,
      profilePicture: profilePicture,
      isOnline: isOnline,
      oneSignalPlayerId: oneSignalPlayerId,
      passwordResetCode: passwordResetCode,
      passwordResetExpires: passwordResetExpires,
      refreshToken: refreshToken,
    );
  }

  /// Creates a valid UserModel from potentially corrupted document data
  /// This can help recover accounts when data is malformed
  static UserModel recoverFromCorruptDoc(
    Map<String, dynamic>? docData,
    String userId,
    String userEmail,
  ) {
    // Default values for required fields if missing or corrupted
    final Map<String, dynamic> safeData = {
      'id': userId,
      'name': '',
      'lastName': '',
      'email': userEmail,
      'role': 'user',
      'gender': 'Homme',
      'phoneNumber': '',
      'accountStatus': true,
    };

    // Use existing data when available and valid
    if (docData != null) {
      if (docData['name'] is String) safeData['name'] = docData['name'];
      if (docData['lastName'] is String)
        safeData['lastName'] = docData['lastName'];
      if (docData['gender'] is String) safeData['gender'] = docData['gender'];
      if (docData['phoneNumber'] is String)
        safeData['phoneNumber'] = docData['phoneNumber'];
      if (docData['role'] is String) safeData['role'] = docData['role'];
      if (docData['fcmToken'] is String)
        safeData['fcmToken'] = docData['fcmToken'];

      // Handle new fields
      if (docData['address'] is Map) safeData['address'] = docData['address'];
      if (docData['location'] is Map)
        safeData['location'] = docData['location'];
      if (docData['profilePicture'] is String)
        safeData['profilePicture'] = docData['profilePicture'];
      if (docData['isOnline'] is bool)
        safeData['isOnline'] = docData['isOnline'];
      if (docData['oneSignalPlayerId'] is String)
        safeData['oneSignalPlayerId'] = docData['oneSignalPlayerId'];
      if (docData['passwordResetCode'] is String)
        safeData['passwordResetCode'] = docData['passwordResetCode'];
      if (docData['refreshToken'] is String)
        safeData['refreshToken'] = docData['refreshToken'];

      // Handle dateOfBirth properly
      if (docData['dateOfBirth'] is String &&
          (docData['dateOfBirth'] as String).isNotEmpty) {
        try {
          DateTime dateOfBirth = DateTime.parse(
            docData['dateOfBirth'] as String,
          );
          safeData['dateOfBirth'] = dateOfBirth.toIso8601String();
        } catch (_) {
          // Invalid date format, don't add to safeData
        }
      } else if (docData['dateOfBirth'] is Timestamp) {
        try {
          DateTime dateOfBirth = (docData['dateOfBirth'] as Timestamp).toDate();
          safeData['dateOfBirth'] = dateOfBirth.toIso8601String();
        } catch (_) {
          // Invalid timestamp, don't add to safeData
        }
      }

      // Handle lastActive
      if (docData['lastActive'] is String &&
          (docData['lastActive'] as String).isNotEmpty) {
        try {
          DateTime lastActive = DateTime.parse(docData['lastActive'] as String);
          safeData['lastActive'] = lastActive.toIso8601String();
        } catch (_) {
          // Invalid date format, don't add to safeData
        }
      } else if (docData['lastActive'] is Timestamp) {
        try {
          DateTime lastActive = (docData['lastActive'] as Timestamp).toDate();
          safeData['lastActive'] = lastActive.toIso8601String();
        } catch (_) {
          // Invalid timestamp, don't add to safeData
        }
      }

      // Handle passwordResetExpires
      if (docData['passwordResetExpires'] is String &&
          (docData['passwordResetExpires'] as String).isNotEmpty) {
        try {
          DateTime passwordResetExpires = DateTime.parse(
            docData['passwordResetExpires'] as String,
          );
          safeData['passwordResetExpires'] =
              passwordResetExpires.toIso8601String();
        } catch (_) {
          // Invalid date format, don't add to safeData
        }
      } else if (docData['passwordResetExpires'] is Timestamp) {
        try {
          DateTime passwordResetExpires =
              (docData['passwordResetExpires'] as Timestamp).toDate();
          safeData['passwordResetExpires'] =
              passwordResetExpires.toIso8601String();
        } catch (_) {
          // Invalid timestamp, don't add to safeData
        }
      }
    }

    return UserModel.fromJson(safeData);
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'firstName': name,  // Backend uses 'firstName'
      'lastName': lastName,
      'email': email,
      'role': role,
      'gender': gender,
      'phone': phoneNumber,  // Backend uses 'phone'
    };
    if (id != null) {
      data['_id'] = id;  // Backend uses '_id'
    }
    if (dateOfBirth != null) {
      data['dateOfBirth'] = dateOfBirth!.toIso8601String();
    }
    if (accountStatus != null) {
      data['accountStatus'] = accountStatus;
    }
    if (isEmailVerified != null) {
      data['isEmailVerified'] = isEmailVerified;
    }
    if (isActive != null) {
      data['isActive'] = isActive;
    }
    if (lastLogin != null) {
      data['lastLogin'] = lastLogin!.toIso8601String();
    }
    if (oneSignalPlayerId != null) {
      data['oneSignalPlayerId'] = oneSignalPlayerId;
    }
    if (passwordResetCode != null) {
      data['passwordResetCode'] = passwordResetCode;
    }
    if (passwordResetExpires != null) {
      data['passwordResetExpires'] = passwordResetExpires!.toIso8601String();
    }
    if (refreshToken != null) {
      data['refreshToken'] = refreshToken;
    }
    if (profilePicture != null) {
      data['profilePhoto'] = profilePicture;  // Backend uses 'profilePhoto'
    }
    if (address != null) {
      data['address'] = address;
    }

    return data;
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? lastName,
    String? email,
    String? role,
    String? gender,
    String? phoneNumber,
    DateTime? dateOfBirth,
    bool? accountStatus,
    bool? isEmailVerified,
    bool? isActive,
    DateTime? lastLogin,
    Map<String, String?>? address,
    Map<String, dynamic>? location,
    String? profilePicture,
    bool? isOnline,
    String? oneSignalPlayerId,
    String? passwordResetCode,
    DateTime? passwordResetExpires,
    String? refreshToken,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      role: role ?? this.role,
      gender: gender ?? this.gender,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      accountStatus: accountStatus ?? this.accountStatus,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isActive: isActive ?? this.isActive,
      lastLogin: lastLogin ?? this.lastLogin,
      address: address ?? this.address,
      location: location ?? this.location,
      profilePicture: profilePicture ?? this.profilePicture,
      isOnline: isOnline ?? this.isOnline,
      oneSignalPlayerId: oneSignalPlayerId ?? this.oneSignalPlayerId,
      passwordResetCode: passwordResetCode ?? this.passwordResetCode,
      passwordResetExpires: passwordResetExpires ?? this.passwordResetExpires,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }
}
