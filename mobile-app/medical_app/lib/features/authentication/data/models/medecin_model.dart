import '../../domain/entities/medecin_entity.dart';
import './user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MedecinModel extends UserModel {
  final String speciality;
  final String numLicence;
  final int appointmentDuration; // Duration in minutes for each appointment
  final int? yearsOfExperience; // Added to match backend

  final String? subSpecialty;
  final String? clinicName;
  final Map<String, dynamic>? clinicAddress;
  final String? about;
  final List<String>? languages;
  final bool? isVerified;
  final bool? acceptsInsurance;

  // New fields from MongoDB schema
  final List<Map<String, dynamic>>? education; // Changed to dynamic to support backend's year as Number
  final List<Map<String, dynamic>>? experience; // Changed to dynamic for consistency
  final List<Map<String, dynamic>>? workingHours;
  final double? averageRating;
  final int? totalRatings;
  final double? consultationFee;
  final List<String>? acceptedInsurance;

  MedecinModel({
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
    required this.speciality,
    required this.numLicence,
    this.appointmentDuration = 30, // Default 30 minutes
    this.yearsOfExperience,
    this.subSpecialty,
    this.clinicName,
    this.clinicAddress,
    this.about,
    this.languages,
    this.isVerified,
    this.acceptsInsurance,
    Map<String, String?>? address,
    Map<String, dynamic>? location,
    String? profilePicture,
    bool? isOnline,
    String? oneSignalPlayerId,
    String? passwordResetCode,
    DateTime? passwordResetExpires,
    String? refreshToken,
    this.education,
    this.experience,
    this.workingHours,
    this.averageRating,
    this.totalRatings,
    this.consultationFee,
    this.acceptedInsurance,
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

  factory MedecinModel.fromJson(Map<String, dynamic> json) {
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
        json['role'] is String ? json['role'] as String : 'medecin';
    final String gender =
        json['gender'] is String ? json['gender'] as String : 'Homme';
    // Support both 'phone' (backend) and 'phoneNumber' (legacy) field names
    final String phoneNumber = json['phone'] is String 
        ? json['phone'] as String 
        : (json['phoneNumber'] is String ? json['phoneNumber'] as String : '');
    // Support both 'specialty' (backend) and 'speciality' (legacy) field names
    final String speciality = json['specialty'] is String 
        ? json['specialty'] as String 
        : (json['speciality'] is String ? json['speciality'] as String : '');
    // Support both 'licenseNumber' (backend) and 'numLicence' (legacy) field names
    final String numLicence = json['licenseNumber'] is String 
        ? json['licenseNumber'] as String 
        : (json['numLicence'] is String ? json['numLicence'] as String : '');
    final int appointmentDuration =
        json['appointmentDuration'] is int
            ? json['appointmentDuration'] as int
            : 30;
    
    // Handle yearsOfExperience from backend
    int? yearsOfExperience;
    if (json['yearsOfExperience'] is int) {
      yearsOfExperience = json['yearsOfExperience'] as int;
    } else if (json['yearsOfExperience'] is num) {
      yearsOfExperience = (json['yearsOfExperience'] as num).toInt();
    }

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
    }

    bool? isEmailVerified;
    if (json['isEmailVerified'] is bool) {
      isEmailVerified = json['isEmailVerified'] as bool;
    }

    bool? isActive;
    if (json['isActive'] is bool) {
      isActive = json['isActive'] as bool;
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

    // New fields
    String? subSpecialty;
    if (json['subSpecialty'] is String) {
      subSpecialty = json['subSpecialty'] as String;
    }

    String? clinicName;
    if (json['clinicName'] is String) {
      clinicName = json['clinicName'] as String;
    }

    Map<String, dynamic>? clinicAddress;
    if (json['clinicAddress'] is Map) {
      clinicAddress = (json['clinicAddress'] as Map).cast<String, dynamic>();
    }

    String? about;
    if (json['about'] is String) {
      about = json['about'] as String;
    }

    List<String>? languages;
    if (json['languages'] is List) {
      languages = (json['languages'] as List).cast<String>();
    }

    bool? isVerified;
    if (json['isVerified'] is bool) {
      isVerified = json['isVerified'] as bool;
    }

    bool? acceptsInsurance;
    if (json['acceptsInsurance'] is bool) {
      acceptsInsurance = json['acceptsInsurance'] as bool;
    }

    // Handle new fields
    Map<String, String?>? address;
    if (json['address'] is Map) {
      address = (json['address'] as Map).cast<String, String?>();
    }

    Map<String, dynamic>? location;
    if (json['location'] is Map) {
      location = (json['location'] as Map).cast<String, dynamic>();
    }

    // Handle profilePicture - support both 'profilePhoto' (backend) and 'profilePicture' (legacy)
    String? profilePicture;
    if (json['profilePhoto'] is String) {
      profilePicture = json['profilePhoto'] as String;
    } else if (json['profilePicture'] is String) {
      profilePicture = json['profilePicture'] as String;
    }

    bool? isOnline;
    if (json['isOnline'] is bool) {
      isOnline = json['isOnline'] as bool;
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

    // Handle doctor-specific fields
    List<Map<String, dynamic>>? education;
    if (json['education'] is List) {
      education =
          (json['education'] as List)
              .map((item) => (item as Map).cast<String, dynamic>())
              .toList();
    }

    List<Map<String, dynamic>>? experience;
    if (json['experience'] is List) {
      experience =
          (json['experience'] as List)
              .map((item) => (item as Map).cast<String, dynamic>())
              .toList();
    }

    List<Map<String, dynamic>>? workingHours;
    if (json['workingHours'] is List) {
      workingHours =
          (json['workingHours'] as List)
              .map((item) => (item as Map).cast<String, dynamic>())
              .toList();
    }

    // Support both 'rating' (backend) and 'averageRating' (legacy) field names
    double? averageRating;
    if (json['rating'] is num) {
      averageRating = (json['rating'] as num).toDouble();
    } else if (json['averageRating'] is num) {
      averageRating = (json['averageRating'] as num).toDouble();
    }

    // Support both 'totalReviews' (backend) and 'totalRatings' (legacy) field names
    int? totalRatings;
    if (json['totalReviews'] is int) {
      totalRatings = json['totalReviews'] as int;
    } else if (json['totalRatings'] is int) {
      totalRatings = json['totalRatings'] as int;
    }

    double? consultationFee;
    if (json['consultationFee'] is num) {
      consultationFee = (json['consultationFee'] as num).toDouble();
    }

    List<String>? acceptedInsurance;
    if (json['acceptedInsurance'] is List) {
      acceptedInsurance = (json['acceptedInsurance'] as List).cast<String>();
    }

    return MedecinModel(
      id: id,
      name: name,
      lastName: lastName,
      email: email,
      role: role,
      gender: gender,
      phoneNumber: phoneNumber,
      dateOfBirth: dateOfBirth,
      speciality: speciality,
      numLicence: numLicence,
      appointmentDuration: appointmentDuration,
      yearsOfExperience: yearsOfExperience,
      subSpecialty: subSpecialty,
      clinicName: clinicName,
      clinicAddress: clinicAddress,
      about: about,
      languages: languages,
      isVerified: isVerified,
      acceptsInsurance: acceptsInsurance,
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
      education: education,
      experience: experience,
      workingHours: workingHours,
      averageRating: averageRating,
      totalRatings: totalRatings,
      consultationFee: consultationFee,
      acceptedInsurance: acceptedInsurance,
    );
  }

  /// Creates a valid MedecinModel from potentially corrupted document data
  /// This can help recover accounts when data is malformed
  static MedecinModel recoverFromCorruptDoc(
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
      'role': 'medecin',
      'gender': 'Homme',
      'phoneNumber': '',
      'speciality': 'Généraliste',
      'numLicence': '',
      'appointmentDuration': 30,
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
      if (docData['speciality'] is String)
        safeData['speciality'] = docData['speciality'];
      if (docData['numLicence'] is String)
        safeData['numLicence'] = docData['numLicence'];

      // Handle appointment duration safely
      if (docData['appointmentDuration'] is int) {
        safeData['appointmentDuration'] = docData['appointmentDuration'];
      } else if (docData['appointmentDuration'] is String &&
          (docData['appointmentDuration'] as String).isNotEmpty) {
        try {
          safeData['appointmentDuration'] = int.parse(
            docData['appointmentDuration'] as String,
          );
        } catch (_) {
          // Keep default value if parsing fails
        }
      }

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
    }

    return MedecinModel.fromJson(safeData);
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = super.toJson();
    data['specialty'] = speciality;  // Backend uses 'specialty'
    data['licenseNumber'] = numLicence;  // Backend uses 'licenseNumber'
    data['appointmentDuration'] = appointmentDuration;

    if (yearsOfExperience != null) data['yearsOfExperience'] = yearsOfExperience;
    if (subSpecialty != null) data['subSpecialty'] = subSpecialty;
    if (clinicName != null) data['clinicName'] = clinicName;
    if (clinicAddress != null) data['clinicAddress'] = clinicAddress;
    if (about != null) data['about'] = about;
    if (languages != null) data['languages'] = languages;
    if (isVerified != null) data['isVerified'] = isVerified;
    if (acceptsInsurance != null) data['acceptsInsurance'] = acceptsInsurance;

    // Add new fields with backend field names
    if (education != null) {
      data['education'] = education;
    }
    if (experience != null) {
      data['experience'] = experience;
    }
    if (workingHours != null) {
      data['workingHours'] = workingHours;
    }
    if (averageRating != null) {
      data['rating'] = averageRating;  // Backend uses 'rating'
    }
    if (totalRatings != null) {
      data['totalReviews'] = totalRatings;  // Backend uses 'totalReviews'
    }
    if (consultationFee != null) {
      data['consultationFee'] = consultationFee;
    }
    if (acceptedInsurance != null) {
      data['acceptedInsurance'] = acceptedInsurance;
    }

    return data;
  }

  MedecinEntity toEntity() {
    return MedecinEntity(
      id: id,
      name: name,
      lastName: lastName,
      email: email,
      role: role,
      gender: gender,
      phoneNumber: phoneNumber,
      dateOfBirth: dateOfBirth,
      speciality: speciality,
      numLicence: numLicence,
      appointmentDuration: appointmentDuration,
      yearsOfExperience: yearsOfExperience,
      subSpecialty: subSpecialty,
      clinicName: clinicName,
      clinicAddress: clinicAddress,
      about: about,
      languages: languages,
      isVerified: isVerified,
      acceptsInsurance: acceptsInsurance,
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
      education: education,
      experience: experience,
      workingHours: workingHours,
      averageRating: averageRating,
      totalRatings: totalRatings,
      consultationFee: consultationFee,
      acceptedInsurance: acceptedInsurance,
    );
  }

  @override
  MedecinModel copyWith({
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
    String? speciality,
    String? numLicence,
    int? appointmentDuration,
    int? yearsOfExperience,
    String? subSpecialty,
    String? clinicName,
    Map<String, dynamic>? clinicAddress,
    String? about,
    List<String>? languages,
    bool? isVerified,
    bool? acceptsInsurance,
    Map<String, String?>? address,
    Map<String, dynamic>? location,
    String? profilePicture,
    bool? isOnline,
    String? oneSignalPlayerId,
    String? passwordResetCode,
    DateTime? passwordResetExpires,
    String? refreshToken,
    List<Map<String, dynamic>>? education,
    List<Map<String, dynamic>>? experience,
    List<Map<String, dynamic>>? workingHours,
    double? averageRating,
    int? totalRatings,
    double? consultationFee,
    List<String>? acceptedInsurance,
  }) {
    return MedecinModel(
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
      speciality: speciality ?? this.speciality,
      numLicence: numLicence ?? this.numLicence,
      appointmentDuration: appointmentDuration ?? this.appointmentDuration,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      subSpecialty: subSpecialty ?? this.subSpecialty,
      clinicName: clinicName ?? this.clinicName,
      clinicAddress: clinicAddress ?? this.clinicAddress,
      about: about ?? this.about,
      languages: languages ?? this.languages,
      isVerified: isVerified ?? this.isVerified,
      acceptsInsurance: acceptsInsurance ?? this.acceptsInsurance,
      address: address ?? this.address,
      location: location ?? this.location,
      profilePicture: profilePicture ?? this.profilePicture,
      isOnline: isOnline ?? this.isOnline,
      oneSignalPlayerId: oneSignalPlayerId ?? this.oneSignalPlayerId,
      passwordResetCode: passwordResetCode ?? this.passwordResetCode,
      passwordResetExpires: passwordResetExpires ?? this.passwordResetExpires,
      refreshToken: refreshToken ?? this.refreshToken,
      education: education ?? this.education,
      experience: experience ?? this.experience,
      workingHours: workingHours ?? this.workingHours,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
      consultationFee: consultationFee ?? this.consultationFee,
      acceptedInsurance: acceptedInsurance ?? this.acceptedInsurance,
    );
  }
}
