import '../../domain/entities/doctor_profile_entity.dart';

class DoctorProfileModel extends DoctorProfileEntity {
  const DoctorProfileModel({
    required super.id,
    required super.odoctorId,
    required super.firstName,
    required super.lastName,
    super.email,
    required super.specialty,
    super.subSpecialty,
    required super.phone,
    super.profilePhoto,
    required super.licenseNumber,
    super.yearsOfExperience,
    super.education,
    super.languages,
    super.clinicName,
    super.clinicAddress,
    super.about,
    super.consultationFee,
    super.acceptsInsurance,
    super.rating,
    super.totalReviews,
    super.workingHours,
    super.isVerified,
    super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory DoctorProfileModel.fromJson(Map<String, dynamic> json) {
    return DoctorProfileModel(
      id: json['_id'] ?? json['id'] ?? '',
      odoctorId: json['userId'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'],
      specialty: json['specialty'] ?? '',
      subSpecialty: json['subSpecialty'],
      phone: json['phone'] ?? '',
      profilePhoto: json['profilePhoto'],
      licenseNumber: json['licenseNumber'] ?? '',
      yearsOfExperience: json['yearsOfExperience'] ?? 0,
      education: (json['education'] as List<dynamic>?)
              ?.map((e) => EducationModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      languages: (json['languages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      clinicName: json['clinicName'],
      clinicAddress: json['clinicAddress'] != null
          ? ClinicAddressModel.fromJson(json['clinicAddress'])
          : null,
      about: json['about'],
      consultationFee: (json['consultationFee'] ?? 0).toDouble(),
      acceptsInsurance: json['acceptsInsurance'] ?? false,
      rating: (json['rating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      workingHours: (json['workingHours'] as List<dynamic>?)
              ?.map((e) => WorkingHoursModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isVerified: json['isVerified'] ?? false,
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': odoctorId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'specialty': specialty,
      'subSpecialty': subSpecialty,
      'phone': phone,
      'profilePhoto': profilePhoto,
      'licenseNumber': licenseNumber,
      'yearsOfExperience': yearsOfExperience,
      'education': education
          .map((e) => (e as EducationModel).toJson())
          .toList(),
      'languages': languages,
      'clinicName': clinicName,
      'clinicAddress': clinicAddress != null
          ? (clinicAddress as ClinicAddressModel).toJson()
          : null,
      'about': about,
      'consultationFee': consultationFee,
      'acceptsInsurance': acceptsInsurance,
      'rating': rating,
      'totalReviews': totalReviews,
      'workingHours': workingHours
          .map((e) => (e as WorkingHoursModel).toJson())
          .toList(),
      'isVerified': isVerified,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DoctorProfileModel.fromEntity(DoctorProfileEntity entity) {
    return DoctorProfileModel(
      id: entity.id,
      odoctorId: entity.odoctorId,
      firstName: entity.firstName,
      lastName: entity.lastName,
      email: entity.email,
      specialty: entity.specialty,
      subSpecialty: entity.subSpecialty,
      phone: entity.phone,
      profilePhoto: entity.profilePhoto,
      licenseNumber: entity.licenseNumber,
      yearsOfExperience: entity.yearsOfExperience,
      education: entity.education
          .map((e) => EducationModel.fromEntity(e))
          .toList(),
      languages: entity.languages,
      clinicName: entity.clinicName,
      clinicAddress: entity.clinicAddress != null
          ? ClinicAddressModel.fromEntity(entity.clinicAddress!)
          : null,
      about: entity.about,
      consultationFee: entity.consultationFee,
      acceptsInsurance: entity.acceptsInsurance,
      rating: entity.rating,
      totalReviews: entity.totalReviews,
      workingHours: entity.workingHours
          .map((e) => WorkingHoursModel.fromEntity(e))
          .toList(),
      isVerified: entity.isVerified,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}

class EducationModel extends EducationEntity {
  const EducationModel({
    required super.degree,
    required super.institution,
    super.year,
  });

  factory EducationModel.fromJson(Map<String, dynamic> json) {
    return EducationModel(
      degree: json['degree'] ?? '',
      institution: json['institution'] ?? '',
      year: json['year'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'degree': degree,
      'institution': institution,
      'year': year,
    };
  }

  factory EducationModel.fromEntity(EducationEntity entity) {
    return EducationModel(
      degree: entity.degree,
      institution: entity.institution,
      year: entity.year,
    );
  }
}

class ClinicAddressModel extends ClinicAddressEntity {
  const ClinicAddressModel({
    super.street,
    required super.city,
    super.state,
    super.zipCode,
    required super.country,
    super.latitude,
    super.longitude,
  });

  factory ClinicAddressModel.fromJson(Map<String, dynamic> json) {
    double? lat;
    double? lng;
    
    // Handle GeoJSON format
    if (json['coordinates'] != null) {
      final coords = json['coordinates'];
      if (coords is Map) {
        if (coords['coordinates'] is List && coords['coordinates'].length >= 2) {
          lng = (coords['coordinates'][0] as num?)?.toDouble();
          lat = (coords['coordinates'][1] as num?)?.toDouble();
        }
      }
    }
    
    return ClinicAddressModel(
      street: json['street'],
      city: json['city'] ?? '',
      state: json['state'],
      zipCode: json['zipCode'],
      country: json['country'] ?? '',
      latitude: lat ?? json['latitude']?.toDouble(),
      longitude: lng ?? json['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
      if (latitude != null && longitude != null)
        'coordinates': {
          'type': 'Point',
          'coordinates': [longitude, latitude],
        },
    };
  }

  factory ClinicAddressModel.fromEntity(ClinicAddressEntity entity) {
    return ClinicAddressModel(
      street: entity.street,
      city: entity.city,
      state: entity.state,
      zipCode: entity.zipCode,
      country: entity.country,
      latitude: entity.latitude,
      longitude: entity.longitude,
    );
  }
}

class WorkingHoursModel extends WorkingHoursEntity {
  const WorkingHoursModel({
    required super.day,
    super.isAvailable,
    super.slots,
  });

  factory WorkingHoursModel.fromJson(Map<String, dynamic> json) {
    return WorkingHoursModel(
      day: json['day'] ?? '',
      isAvailable: json['isAvailable'] ?? false,
      slots: (json['slots'] as List<dynamic>?)
              ?.map((e) => TimeSlotModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'isAvailable': isAvailable,
      'slots': slots.map((e) => (e as TimeSlotModel).toJson()).toList(),
    };
  }

  factory WorkingHoursModel.fromEntity(WorkingHoursEntity entity) {
    return WorkingHoursModel(
      day: entity.day,
      isAvailable: entity.isAvailable,
      slots: entity.slots.map((e) => TimeSlotModel.fromEntity(e)).toList(),
    );
  }
}

class TimeSlotModel extends TimeSlotEntity {
  const TimeSlotModel({
    required super.startTime,
    required super.endTime,
  });

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) {
    return TimeSlotModel(
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime,
      'endTime': endTime,
    };
  }

  factory TimeSlotModel.fromEntity(TimeSlotEntity entity) {
    return TimeSlotModel(
      startTime: entity.startTime,
      endTime: entity.endTime,
    );
  }
}
