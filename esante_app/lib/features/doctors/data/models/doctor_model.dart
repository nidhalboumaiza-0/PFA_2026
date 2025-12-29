import '../../domain/entities/doctor_entity.dart';

/// Data model for doctor search results from API
class DoctorModel extends DoctorEntity {
  const DoctorModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.specialty,
    super.subSpecialty,
    super.profilePhoto,
    super.clinicName,
    super.clinicAddress,
    super.rating,
    super.reviewCount,
    super.distance,
    super.isVerified,
    super.isActive,
    super.consultationFee,
    super.yearsOfExperience,
    super.languages,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      specialty: json['specialty'] ?? 'General Practice',
      subSpecialty: json['subSpecialty'],
      profilePhoto: json['profilePhoto'],
      clinicName: json['clinicName'],
      clinicAddress: json['clinicAddress'] != null
          ? DoctorAddressModel.fromJson(json['clinicAddress'])
          : null,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: json['reviewCount'] as int?,
      distance: (json['distance'] as num?)?.toDouble(),
      isVerified: json['isVerified'] ?? false,
      isActive: json['isActive'] ?? true,
      consultationFee: json['consultationFee'] as int?,
      yearsOfExperience: json['yearsOfExperience'] as int?,
      languages: json['languages'] != null
          ? List<String>.from(json['languages'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'firstName': firstName,
      'lastName': lastName,
      'specialty': specialty,
      'subSpecialty': subSpecialty,
      'profilePhoto': profilePhoto,
      'clinicName': clinicName,
      'clinicAddress': clinicAddress != null
          ? (clinicAddress as DoctorAddressModel).toJson()
          : null,
      'rating': rating,
      'reviewCount': reviewCount,
      'distance': distance,
      'isVerified': isVerified,
      'isActive': isActive,
      'consultationFee': consultationFee,
      'yearsOfExperience': yearsOfExperience,
      'languages': languages,
    };
  }
}

class DoctorAddressModel extends DoctorAddressEntity {
  const DoctorAddressModel({
    super.street,
    super.city,
    super.state,
    super.postalCode,
    super.country,
    super.coordinates,
  });

  factory DoctorAddressModel.fromJson(Map<String, dynamic> json) {
    return DoctorAddressModel(
      street: json['street'],
      city: json['city'],
      state: json['state'],
      postalCode: json['postalCode'],
      country: json['country'],
      coordinates: json['coordinates'] != null
          ? CoordinatesModel.fromJson(json['coordinates'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
      'coordinates': coordinates != null
          ? (coordinates as CoordinatesModel).toJson()
          : null,
    };
  }
}

class CoordinatesModel extends CoordinatesEntity {
  const CoordinatesModel({
    super.type,
    required super.coordinates,
  });

  factory CoordinatesModel.fromJson(Map<String, dynamic> json) {
    return CoordinatesModel(
      type: json['type'] ?? 'Point',
      coordinates: json['coordinates'] != null
          ? List<double>.from(
              (json['coordinates'] as List).map((e) => (e as num).toDouble()))
          : [0, 0],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'coordinates': coordinates,
    };
  }
}
