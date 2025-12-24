import '../../domain/entities/patient_entity.dart';
import './user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientModel extends UserModel {
  final String? antecedent;
  final String? bloodType;
  final double? height;
  final double? weight;
  final List<String>? allergies;
  final List<String>? chronicDiseases;
  final Map<String, dynamic>? emergencyContact;
  final Map<String, dynamic>? insuranceInfo;

  PatientModel({
    String? id,
    required String name,
    required String lastName,
    required String email,
    required String role,
    required String gender,
    required String phoneNumber,
    DateTime? dateOfBirth,
    this.antecedent,
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
    this.bloodType,
    this.height,
    this.weight,
    this.allergies,
    this.chronicDiseases,
    this.emergencyContact,
    this.insuranceInfo,
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

  factory PatientModel.fromJson(Map<String, dynamic> json) {
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
        json['role'] is String ? json['role'] as String : 'patient';
    final String gender =
        json['gender'] is String ? json['gender'] as String : 'Homme';
    // Support both 'phone' (backend) and 'phoneNumber' (legacy) field names
    final String phoneNumber = json['phone'] is String 
        ? json['phone'] as String 
        : (json['phoneNumber'] is String ? json['phoneNumber'] as String : '');
    final String antecedent =
        json['antecedent'] is String ? json['antecedent'] as String : '';

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

    int? verificationCode;
    if (json['verificationCode'] is int) {
      verificationCode = json['verificationCode'] as int;
    } else if (json['verificationCode'] is String &&
        (json['verificationCode'] as String).isNotEmpty) {
      try {
        verificationCode = int.parse(json['verificationCode'] as String);
      } catch (_) {
        verificationCode = null;
      }
    }

    DateTime? validationCodeExpiresAt;
    if (json['validationCodeExpiresAt'] is String &&
        (json['validationCodeExpiresAt'] as String).isNotEmpty) {
      try {
        validationCodeExpiresAt = DateTime.parse(
          json['validationCodeExpiresAt'] as String,
        );
      } catch (_) {
        validationCodeExpiresAt = null;
      }
    }

    String? fcmToken;
    if (json['fcmToken'] is String) {
      fcmToken = json['fcmToken'] as String;
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

    // Handle profile picture - support both 'profilePhoto' (backend) and 'profilePicture' (legacy)
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

    // Handle lastActive
    DateTime? lastActive;
    if (json['lastActive'] is String &&
        (json['lastActive'] as String).isNotEmpty) {
      try {
        lastActive = DateTime.parse(json['lastActive'] as String);
      } catch (_) {
        lastActive = null;
      }
    }

    // Handle oneSignalPlayerId
    String? oneSignalPlayerId;
    if (json['oneSignalPlayerId'] is String) {
      oneSignalPlayerId = json['oneSignalPlayerId'] as String;
    }

    // Handle passwordResetCode
    String? passwordResetCode;
    if (json['passwordResetCode'] is String) {
      passwordResetCode = json['passwordResetCode'] as String;
    }

    // Handle passwordResetExpires
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

    // Handle refreshToken
    String? refreshToken;
    if (json['refreshToken'] is String) {
      refreshToken = json['refreshToken'] as String;
    }

    // New fields from MongoDB schema
    String? bloodType;
    if (json['bloodType'] is String) {
      bloodType = json['bloodType'] as String;
    }

    double? height;
    if (json['height'] is num) {
      height = (json['height'] as num).toDouble();
    }

    double? weight;
    if (json['weight'] is num) {
      weight = (json['weight'] as num).toDouble();
    }

    List<String>? allergies;
    if (json['allergies'] is List) {
      allergies = List<String>.from(
        (json['allergies'] as List).map((item) => item.toString()),
      );
    }

    List<String>? chronicDiseases;
    if (json['chronicDiseases'] is List) {
      chronicDiseases = List<String>.from(
        (json['chronicDiseases'] as List).map((item) => item.toString()),
      );
    }

    Map<String, dynamic>? emergencyContact;
    if (json['emergencyContact'] is Map) {
      emergencyContact = Map<String, dynamic>.from(json['emergencyContact'] as Map);
    }

    Map<String, dynamic>? insuranceInfo;
    if (json['insuranceInfo'] is Map) {
      insuranceInfo = Map<String, dynamic>.from(json['insuranceInfo'] as Map);
    }

    return PatientModel(
      id: id,
      name: name,
      lastName: lastName,
      email: email,
      role: role,
      gender: gender,
      phoneNumber: phoneNumber,
      dateOfBirth: dateOfBirth,
      antecedent: antecedent,
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
      bloodType: bloodType,
      height: height,
      weight: weight,
      allergies: allergies,
      chronicDiseases: chronicDiseases,
      emergencyContact: emergencyContact,
      insuranceInfo: insuranceInfo,
    );
  }

  /// Creates a valid PatientModel from potentially corrupted document data
  /// This can help recover accounts when data is malformed
  static PatientModel recoverFromCorruptDoc(
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
      'role': 'patient',
      'gender': 'Homme',
      'phoneNumber': '',
      'antecedent': '',
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
      if (docData['fcmToken'] is String)
        safeData['fcmToken'] = docData['fcmToken'];
      if (docData['antecedent'] is String)
        safeData['antecedent'] = docData['antecedent'];

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

      // New fields recovery
      if (docData['bloodType'] is String)
        safeData['bloodType'] = docData['bloodType'];

      if (docData['height'] is num) safeData['height'] = docData['height'];

      if (docData['weight'] is num) safeData['weight'] = docData['weight'];

      if (docData['allergies'] is List)
        safeData['allergies'] = docData['allergies'];

      if (docData['chronicDiseases'] is List)
        safeData['chronicDiseases'] = docData['chronicDiseases'];

      if (docData['emergencyContact'] is Map)
        safeData['emergencyContact'] = docData['emergencyContact'];

      if (docData['insuranceInfo'] is Map)
        safeData['insuranceInfo'] = docData['insuranceInfo'];
    }

    return PatientModel.fromJson(safeData);
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = super.toJson();
    data['antecedent'] = antecedent;

    if (bloodType != null) data['bloodType'] = bloodType;
    if (height != null) data['height'] = height;
    if (weight != null) data['weight'] = weight;
    if (allergies != null) data['allergies'] = allergies;
    if (chronicDiseases != null) data['chronicDiseases'] = chronicDiseases;
    if (emergencyContact != null) data['emergencyContact'] = emergencyContact;
    if (insuranceInfo != null) data['insuranceInfo'] = insuranceInfo;

    return data;
  }

  PatientEntity toEntity() {
    return PatientEntity(
      id: id,
      name: name,
      lastName: lastName,
      email: email,
      role: role,
      gender: gender,
      phoneNumber: phoneNumber,
      dateOfBirth: dateOfBirth,
      antecedent: antecedent,
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
      bloodType: bloodType,
      height: height,
      weight: weight,
      allergies: allergies,
      chronicDiseases: chronicDiseases,
      emergencyContact: emergencyContact,
      insuranceInfo: insuranceInfo,
    );
  }

  @override
  PatientModel copyWith({
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
    String? antecedent,
    Map<String, String?>? address,
    Map<String, dynamic>? location,
    String? profilePicture,
    bool? isOnline,
    String? oneSignalPlayerId,
    String? passwordResetCode,
    DateTime? passwordResetExpires,
    String? refreshToken,
    String? bloodType,
    double? height,
    double? weight,
    List<String>? allergies,
    List<String>? chronicDiseases,
    Map<String, dynamic>? emergencyContact,
    Map<String, dynamic>? insuranceInfo,
  }) {
    return PatientModel(
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
      antecedent: antecedent ?? this.antecedent,
      address: address ?? this.address,
      location: location ?? this.location,
      profilePicture: profilePicture ?? this.profilePicture,
      isOnline: isOnline ?? this.isOnline,
      oneSignalPlayerId: oneSignalPlayerId ?? this.oneSignalPlayerId,
      passwordResetCode: passwordResetCode ?? this.passwordResetCode,
      passwordResetExpires: passwordResetExpires ?? this.passwordResetExpires,
      refreshToken: refreshToken ?? this.refreshToken,
      bloodType: bloodType ?? this.bloodType,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      allergies: allergies ?? this.allergies,
      chronicDiseases: chronicDiseases ?? this.chronicDiseases,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      insuranceInfo: insuranceInfo ?? this.insuranceInfo,
    );
  }
}
