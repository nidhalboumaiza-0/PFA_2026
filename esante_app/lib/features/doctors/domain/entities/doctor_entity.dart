import 'package:equatable/equatable.dart';

/// Entity representing a doctor's public profile for search results
class DoctorEntity extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String specialty;
  final String? subSpecialty;
  final String? profilePhoto;
  final String? clinicName;
  final DoctorAddressEntity? clinicAddress;
  final double? rating;
  final int? reviewCount;
  final double? distance; // Distance in km (only when searching by location)
  final bool isVerified;
  final bool isActive;
  final int? consultationFee;
  final int? yearsOfExperience;
  final List<String>? languages;

  const DoctorEntity({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.specialty,
    this.subSpecialty,
    this.profilePhoto,
    this.clinicName,
    this.clinicAddress,
    this.rating,
    this.reviewCount,
    this.distance,
    this.isVerified = false,
    this.isActive = true,
    this.consultationFee,
    this.yearsOfExperience,
    this.languages,
  });

  String get fullName => '$firstName $lastName';

  String get displaySpecialty =>
      subSpecialty != null ? '$specialty ($subSpecialty)' : specialty;

  String get displayDistance {
    if (distance == null) return '';
    if (distance! < 1) {
      return '${(distance! * 1000).toInt()} m';
    }
    return '${distance!.toStringAsFixed(1)} km';
  }

  @override
  List<Object?> get props => [
        id,
        firstName,
        lastName,
        specialty,
        subSpecialty,
        profilePhoto,
        clinicName,
        clinicAddress,
        rating,
        reviewCount,
        distance,
        isVerified,
        isActive,
        consultationFee,
        yearsOfExperience,
        languages,
      ];
}

/// Entity representing doctor's clinic address
class DoctorAddressEntity extends Equatable {
  final String? street;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final CoordinatesEntity? coordinates;

  const DoctorAddressEntity({
    this.street,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.coordinates,
  });

  String get fullAddress {
    final parts = <String>[];
    if (street != null && street!.isNotEmpty) parts.add(street!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    return parts.join(', ');
  }

  @override
  List<Object?> get props =>
      [street, city, state, postalCode, country, coordinates];
}

/// Entity representing geographical coordinates
class CoordinatesEntity extends Equatable {
  final String type; // "Point"
  final List<double> coordinates; // [longitude, latitude]

  const CoordinatesEntity({
    this.type = 'Point',
    required this.coordinates,
  });

  double get longitude => coordinates.isNotEmpty ? coordinates[0] : 0;
  double get latitude => coordinates.length > 1 ? coordinates[1] : 0;

  @override
  List<Object?> get props => [type, coordinates];
}
