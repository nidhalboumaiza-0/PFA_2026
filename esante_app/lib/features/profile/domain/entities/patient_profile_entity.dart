import 'package:equatable/equatable.dart';

/// Patient profile entity
class PatientProfileEntity extends Equatable {
  final String id;
  final String userId;
  final String firstName;
  final String lastName;
  final String? email;
  final DateTime dateOfBirth;
  final String gender;
  final String phone;
  final AddressEntity? address;
  final String? profilePhoto;
  final String? bloodType;
  final List<String> allergies;
  final List<String> chronicDiseases;
  final EmergencyContactEntity? emergencyContact;
  final InsuranceInfoEntity? insuranceInfo;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PatientProfileEntity({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.email,
    required this.dateOfBirth,
    required this.gender,
    required this.phone,
    this.address,
    this.profilePhoto,
    this.bloodType,
    this.allergies = const [],
    this.chronicDiseases = const [],
    this.emergencyContact,
    this.insuranceInfo,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get full name
  String get fullName => '$firstName $lastName';

  /// Get age from date of birth
  int get age {
    final today = DateTime.now();
    int age = today.year - dateOfBirth.year;
    if (today.month < dateOfBirth.month ||
        (today.month == dateOfBirth.month && today.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  /// Check if profile is complete (has all required fields filled)
  bool get isProfileComplete {
    return firstName.isNotEmpty &&
        lastName.isNotEmpty &&
        phone.isNotEmpty &&
        address != null &&
        address!.city != null &&
        address!.city!.isNotEmpty;
  }

  /// Get profile completion percentage
  int get profileCompletionPercentage {
    int total = 10;
    int completed = 0;

    if (firstName.isNotEmpty) completed++;
    if (lastName.isNotEmpty) completed++;
    if (phone.isNotEmpty) completed++;
    if (profilePhoto != null && profilePhoto!.isNotEmpty) completed++;
    if (address != null && address!.city != null) completed++;
    if (bloodType != null) completed++;
    if (allergies.isNotEmpty) completed++;
    if (chronicDiseases.isNotEmpty) completed++;
    if (emergencyContact != null && emergencyContact!.phone != null) completed++;
    if (insuranceInfo != null && insuranceInfo!.provider != null) completed++;

    return ((completed / total) * 100).round();
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        firstName,
        lastName,
        email,
        dateOfBirth,
        gender,
        phone,
        address,
        profilePhoto,
        bloodType,
        allergies,
        chronicDiseases,
        emergencyContact,
        insuranceInfo,
        isActive,
        createdAt,
        updatedAt,
      ];
}

/// Address entity
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

  /// Get formatted address
  String get formattedAddress {
    final parts = <String>[];
    if (street != null && street!.isNotEmpty) parts.add(street!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    if (zipCode != null && zipCode!.isNotEmpty) parts.add(zipCode!);
    if (country != null && country!.isNotEmpty) parts.add(country!);
    return parts.join(', ');
  }

  @override
  List<Object?> get props => [street, city, state, zipCode, country];
}

/// Emergency contact entity
class EmergencyContactEntity extends Equatable {
  final String? name;
  final String? relationship;
  final String? phone;

  const EmergencyContactEntity({
    this.name,
    this.relationship,
    this.phone,
  });

  @override
  List<Object?> get props => [name, relationship, phone];
}

/// Insurance info entity
class InsuranceInfoEntity extends Equatable {
  final String? provider;
  final String? policyNumber;
  final DateTime? expiryDate;

  const InsuranceInfoEntity({
    this.provider,
    this.policyNumber,
    this.expiryDate,
  });

  /// Check if insurance is expired
  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  @override
  List<Object?> get props => [provider, policyNumber, expiryDate];
}
