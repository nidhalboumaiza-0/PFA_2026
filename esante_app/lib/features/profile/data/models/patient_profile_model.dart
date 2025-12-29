import '../../domain/entities/patient_profile_entity.dart';

class PatientProfileModel extends PatientProfileEntity {
  const PatientProfileModel({
    required super.id,
    required super.userId,
    required super.firstName,
    required super.lastName,
    super.email,
    required super.dateOfBirth,
    required super.gender,
    required super.phone,
    super.address,
    super.profilePhoto,
    super.bloodType,
    super.allergies,
    super.chronicDiseases,
    super.emergencyContact,
    super.insuranceInfo,
    super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory PatientProfileModel.fromJson(Map<String, dynamic> json) {
    return PatientProfileModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'],
      dateOfBirth: DateTime.tryParse(json['dateOfBirth'] ?? '') ?? DateTime.now(),
      gender: json['gender'] ?? 'other',
      phone: json['phone'] ?? '',
      address: json['address'] != null 
          ? AddressModel.fromJson(json['address']) 
          : null,
      profilePhoto: json['profilePhoto'],
      bloodType: json['bloodType'],
      allergies: (json['allergies'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      chronicDiseases: (json['chronicDiseases'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      emergencyContact: json['emergencyContact'] != null
          ? EmergencyContactModel.fromJson(json['emergencyContact'])
          : null,
      insuranceInfo: json['insuranceInfo'] != null
          ? InsuranceInfoModel.fromJson(json['insuranceInfo'])
          : null,
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'gender': gender,
      'phone': phone,
      'address': address != null ? (address as AddressModel).toJson() : null,
      'profilePhoto': profilePhoto,
      'bloodType': bloodType,
      'allergies': allergies,
      'chronicDiseases': chronicDiseases,
      'emergencyContact': emergencyContact != null 
          ? (emergencyContact as EmergencyContactModel).toJson() 
          : null,
      'insuranceInfo': insuranceInfo != null 
          ? (insuranceInfo as InsuranceInfoModel).toJson() 
          : null,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PatientProfileModel.fromEntity(PatientProfileEntity entity) {
    return PatientProfileModel(
      id: entity.id,
      userId: entity.userId,
      firstName: entity.firstName,
      lastName: entity.lastName,
      email: entity.email,
      dateOfBirth: entity.dateOfBirth,
      gender: entity.gender,
      phone: entity.phone,
      address: entity.address != null 
          ? AddressModel.fromEntity(entity.address!) 
          : null,
      profilePhoto: entity.profilePhoto,
      bloodType: entity.bloodType,
      allergies: entity.allergies,
      chronicDiseases: entity.chronicDiseases,
      emergencyContact: entity.emergencyContact != null 
          ? EmergencyContactModel.fromEntity(entity.emergencyContact!) 
          : null,
      insuranceInfo: entity.insuranceInfo != null 
          ? InsuranceInfoModel.fromEntity(entity.insuranceInfo!) 
          : null,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}

class AddressModel extends AddressEntity {
  const AddressModel({
    super.street,
    super.city,
    super.state,
    super.zipCode,
    super.country,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      street: json['street'],
      city: json['city'],
      state: json['state'],
      zipCode: json['zipCode'],
      country: json['country'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
    };
  }

  factory AddressModel.fromEntity(AddressEntity entity) {
    return AddressModel(
      street: entity.street,
      city: entity.city,
      state: entity.state,
      zipCode: entity.zipCode,
      country: entity.country,
    );
  }
}

class EmergencyContactModel extends EmergencyContactEntity {
  const EmergencyContactModel({
    super.name,
    super.relationship,
    super.phone,
  });

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      name: json['name'],
      relationship: json['relationship'],
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'relationship': relationship,
      'phone': phone,
    };
  }

  factory EmergencyContactModel.fromEntity(EmergencyContactEntity entity) {
    return EmergencyContactModel(
      name: entity.name,
      relationship: entity.relationship,
      phone: entity.phone,
    );
  }
}

class InsuranceInfoModel extends InsuranceInfoEntity {
  const InsuranceInfoModel({
    super.provider,
    super.policyNumber,
    super.expiryDate,
  });

  factory InsuranceInfoModel.fromJson(Map<String, dynamic> json) {
    return InsuranceInfoModel(
      provider: json['provider'],
      policyNumber: json['policyNumber'],
      expiryDate: json['expiryDate'] != null 
          ? DateTime.tryParse(json['expiryDate']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'policyNumber': policyNumber,
      'expiryDate': expiryDate?.toIso8601String(),
    };
  }

  factory InsuranceInfoModel.fromEntity(InsuranceInfoEntity entity) {
    return InsuranceInfoModel(
      provider: entity.provider,
      policyNumber: entity.policyNumber,
      expiryDate: entity.expiryDate,
    );
  }
}
