import 'package:equatable/equatable.dart';

/// Domain entity for doctor profile - pure domain object
class DoctorProfileEntity extends Equatable {
  final String firstName;
  final String lastName;
  final String specialty;
  final String? subSpecialty;
  final String phone;
  final String? profilePhoto;
  final String licenseNumber;
  final int yearsOfExperience;
  final List<EducationEntity>? education;
  final List<String>? languages;
  final String? clinicName;
  final ClinicAddressEntity clinicAddress;
  final String? about;
  final double consultationFee;
  final bool acceptsInsurance;
  final double rating;
  final int totalReviews;
  final List<WorkingHoursEntity>? workingHours;
  final bool isVerified;
  final bool isActive;
  final String? oneSignalPlayerId;

  const DoctorProfileEntity({
    required this.firstName,
    required this.lastName,
    required this.specialty,
    this.subSpecialty,
    required this.phone,
    this.profilePhoto,
    required this.licenseNumber,
    this.yearsOfExperience = 0,
    this.education,
    this.languages,
    this.clinicName,
    required this.clinicAddress,
    this.about,
    this.consultationFee = 0,
    this.acceptsInsurance = false,
    this.rating = 0,
    this.totalReviews = 0,
    this.workingHours,
    this.isVerified = false,
    this.isActive = true,
    this.oneSignalPlayerId,
  });

  /// Computed property for full name
  String get fullName => '$firstName $lastName';

  @override
  List<Object?> get props => [
        firstName,
        lastName,
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
        oneSignalPlayerId,
      ];
}

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

  @override
  List<Object?> get props =>
      [street, city, state, zipCode, country, latitude, longitude];
}

class WorkingHoursEntity extends Equatable {
  final String day;
  final bool isAvailable;
  final List<TimeSlotEntity>? slots;

  const WorkingHoursEntity({
    required this.day,
    this.isAvailable = false,
    this.slots,
  });

  @override
  List<Object?> get props => [day, isAvailable, slots];
}

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

/// List of medical specialties
class MedicalSpecialties {
  static const List<String> list = [
    'General Practice',
    'Internal Medicine',
    'Cardiology',
    'Dermatology',
    'Endocrinology',
    'Gastroenterology',
    'Neurology',
    'Oncology',
    'Ophthalmology',
    'Orthopedics',
    'Pediatrics',
    'Psychiatry',
    'Pulmonology',
    'Radiology',
    'Rheumatology',
    'Surgery',
    'Urology',
    'Gynecology',
    'ENT (Otolaryngology)',
    'Anesthesiology',
    'Emergency Medicine',
    'Family Medicine',
    'Nephrology',
    'Hematology',
    'Infectious Disease',
    'Physical Medicine',
    'Allergy & Immunology',
    'Sports Medicine',
    'Geriatrics',
    'Palliative Care',
    'Other',
  ];
}
