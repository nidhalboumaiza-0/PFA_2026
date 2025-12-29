import 'package:equatable/equatable.dart';

/// Doctor profile entity for profile feature
class DoctorProfileEntity extends Equatable {
  final String id;
  final String odoctorId;
  final String firstName;
  final String lastName;
  final String? email;
  final String specialty;
  final String? subSpecialty;
  final String phone;
  final String? profilePhoto;
  final String licenseNumber;
  final int yearsOfExperience;
  final List<EducationEntity> education;
  final List<String> languages;
  final String? clinicName;
  final ClinicAddressEntity? clinicAddress;
  final String? about;
  final double consultationFee;
  final bool acceptsInsurance;
  final double rating;
  final int totalReviews;
  final List<WorkingHoursEntity> workingHours;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DoctorProfileEntity({
    required this.id,
    required this.odoctorId,
    required this.firstName,
    required this.lastName,
    this.email,
    required this.specialty,
    this.subSpecialty,
    required this.phone,
    this.profilePhoto,
    required this.licenseNumber,
    this.yearsOfExperience = 0,
    this.education = const [],
    this.languages = const [],
    this.clinicName,
    this.clinicAddress,
    this.about,
    this.consultationFee = 0,
    this.acceptsInsurance = false,
    this.rating = 0,
    this.totalReviews = 0,
    this.workingHours = const [],
    this.isVerified = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get full name
  String get fullName => '$firstName $lastName';

  /// Check if profile is complete
  bool get isProfileComplete {
    return firstName.isNotEmpty &&
        lastName.isNotEmpty &&
        phone.isNotEmpty &&
        specialty.isNotEmpty &&
        licenseNumber.isNotEmpty &&
        clinicAddress != null &&
        clinicAddress!.city.isNotEmpty;
  }

  /// Get profile completion percentage
  int get profileCompletionPercentage {
    int total = 12;
    int completed = 0;

    if (firstName.isNotEmpty) completed++;
    if (lastName.isNotEmpty) completed++;
    if (phone.isNotEmpty) completed++;
    if (specialty.isNotEmpty) completed++;
    if (licenseNumber.isNotEmpty) completed++;
    if (profilePhoto != null && profilePhoto!.isNotEmpty) completed++;
    if (clinicAddress != null && clinicAddress!.city.isNotEmpty) completed++;
    if (about != null && about!.isNotEmpty) completed++;
    if (education.isNotEmpty) completed++;
    if (languages.isNotEmpty) completed++;
    if (workingHours.isNotEmpty) completed++;
    if (consultationFee > 0) completed++;

    return ((completed / total) * 100).round();
  }

  @override
  List<Object?> get props => [
        id,
        odoctorId,
        firstName,
        lastName,
        email,
        specialty,
        subSpecialty,
        phone,
        profilePhoto,
        licenseNumber,
        yearsOfExperience,
        education,
        languages,
        clinicName,
        clinicAddress,
        about,
        consultationFee,
        acceptsInsurance,
        rating,
        totalReviews,
        workingHours,
        isVerified,
        isActive,
        createdAt,
        updatedAt,
      ];
}

/// Education entity
class EducationEntity extends Equatable {
  final String degree;
  final String institution;
  final int? year;

  const EducationEntity({
    required this.degree,
    required this.institution,
    this.year,
  });

  @override
  List<Object?> get props => [degree, institution, year];
}

/// Clinic address entity
class ClinicAddressEntity extends Equatable {
  final String? street;
  final String city;
  final String? state;
  final String? zipCode;
  final String country;
  final double? latitude;
  final double? longitude;

  const ClinicAddressEntity({
    this.street,
    required this.city,
    this.state,
    this.zipCode,
    required this.country,
    this.latitude,
    this.longitude,
  });

  /// Get formatted address
  String get formattedAddress {
    final parts = <String>[];
    if (street != null && street!.isNotEmpty) parts.add(street!);
    if (city.isNotEmpty) parts.add(city);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    if (zipCode != null && zipCode!.isNotEmpty) parts.add(zipCode!);
    if (country.isNotEmpty) parts.add(country);
    return parts.join(', ');
  }

  @override
  List<Object?> get props => [street, city, state, zipCode, country, latitude, longitude];
}

/// Working hours entity
class WorkingHoursEntity extends Equatable {
  final String day;
  final bool isAvailable;
  final List<TimeSlotEntity> slots;

  const WorkingHoursEntity({
    required this.day,
    this.isAvailable = false,
    this.slots = const [],
  });

  @override
  List<Object?> get props => [day, isAvailable, slots];
}

/// Time slot entity
class TimeSlotEntity extends Equatable {
  final String startTime;
  final String endTime;

  const TimeSlotEntity({
    required this.startTime,
    required this.endTime,
  });

  @override
  List<Object?> get props => [startTime, endTime];
}
