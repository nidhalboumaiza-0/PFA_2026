import 'package:equatable/equatable.dart';

/// Domain entity for patient profile - pure domain object
class PatientProfileEntity extends Equatable {
  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;
  final String gender;
  final String phone;
  final String? profilePhoto;
  final String? bloodType;
  final List<String>? allergies;
  final List<String>? chronicDiseases;
  final AddressEntity? address;
  final EmergencyContactEntity? emergencyContact;
  final InsuranceInfoEntity? insuranceInfo;
  final bool isActive;
  final String? oneSignalPlayerId;

  const PatientProfileEntity({
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.gender,
    required this.phone,
    this.profilePhoto,
    this.bloodType,
    this.allergies,
    this.chronicDiseases,
    this.address,
    this.emergencyContact,
    this.insuranceInfo,
    this.isActive = true,
    this.oneSignalPlayerId,
  });

  /// Computed property for full name (mirrors backend virtual)
  String get fullName => '$firstName $lastName';

  /// Computed property for age (mirrors backend virtual)
  int get age {
    final today = DateTime.now();
    int calculatedAge = today.year - dateOfBirth.year;
    if (today.month < dateOfBirth.month ||
        (today.month == dateOfBirth.month && today.day < dateOfBirth.day)) {
      calculatedAge--;
    }
    return calculatedAge;
  }

  @override
  List<Object?> get props => [
        firstName,
        lastName,
        dateOfBirth,
        gender,
        phone,
        profilePhoto,
        bloodType,
        allergies,
        chronicDiseases,
        address,
        emergencyContact,
        insuranceInfo,
        isActive,
        oneSignalPlayerId,
      ];
}

class AddressEntity extends Equatable {
  final String? street;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;

  const AddressEntity({
    this.street,
    this.city,
    this.state,
    this.zipCode,
    this.country,
  });

  @override
  List<Object?> get props => [street, city, state, zipCode, country];
}

class EmergencyContactEntity extends Equatable {
  final String name;
  final String relationship;
  final String phone;

  const EmergencyContactEntity({
    required this.name,
    required this.relationship,
    required this.phone,
  });

  @override
  List<Object?> get props => [name, relationship, phone];
}

class InsuranceInfoEntity extends Equatable {
  final String? provider;
  final String? policyNumber;
  final DateTime? expiryDate;

  const InsuranceInfoEntity({
    this.provider,
    this.policyNumber,
    this.expiryDate,
  });

  @override
  List<Object?> get props => [provider, policyNumber, expiryDate];
}
