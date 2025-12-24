import 'package:medical_app/features/authentication/domain/entities/user_entity.dart';

class MedecinEntity extends UserEntity {
  final String? speciality;
  final String? numLicence;
  final int appointmentDuration; // Duration in minutes for each appointment (default 30 minutes)
  final int? yearsOfExperience; // Added to match backend
  
  final String? subSpecialty;
  final String? clinicName;
  final Map<String, dynamic>? clinicAddress;
  final String? about;
  final List<String>? languages;
  final bool? isVerified;
  final bool? acceptsInsurance;

  // New fields from MongoDB schema
  final List<Map<String, dynamic>>? education; // List of education history (institution, degree, year - year is Number in backend)
  final List<Map<String, dynamic>>? experience; // List of professional experience (position, organization, years)
  final List<Map<String, dynamic>>? workingHours; // List of working hours
  final double? averageRating; // Average rating from patients (backend uses 'rating')
  final int? totalRatings; // Total number of ratings received (backend uses 'totalReviews')
  final double? consultationFee; // Fee charged for consultation
  final List<String>? acceptedInsurance; // List of accepted insurance providers

  MedecinEntity({
    String? id,
    required String name,
    required String lastName,
    required String email,
    required String role,
    required String gender,
    required String phoneNumber,
    DateTime? dateOfBirth,
    this.speciality,
    this.numLicence = '',
    this.appointmentDuration = 30, // Default 30 minutes
    this.yearsOfExperience,
    this.subSpecialty,
    this.clinicName,
    this.clinicAddress,
    this.about,
    this.languages,
    this.isVerified,
    this.acceptsInsurance,
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

  factory MedecinEntity.create({
    String? id,
    required String name,
    required String lastName,
    required String email,
    required String role,
    required String gender,
    required String phoneNumber,
    DateTime? dateOfBirth,
    String? speciality,
    String? numLicence = '',
    int appointmentDuration = 30, // Default 30 minutes
    int? yearsOfExperience,
    String? subSpecialty,
    String? clinicName,
    Map<String, dynamic>? clinicAddress,
    String? about,
    List<String>? languages,
    bool? isVerified,
    bool? acceptsInsurance,
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
    List<Map<String, dynamic>>? education,
    List<Map<String, dynamic>>? experience,
    List<Map<String, dynamic>>? workingHours,
    double? averageRating,
    int? totalRatings,
    double? consultationFee,
    List<String>? acceptedInsurance,
  }) {
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
  List<Object?> get props => [
    ...super.props,
    speciality,
    numLicence,
    appointmentDuration,
    yearsOfExperience,
    subSpecialty,
    clinicName,
    clinicAddress,
    about,
    languages,
    isVerified,
    acceptsInsurance,
    education,
    experience,
    workingHours,
    averageRating,
    totalRatings,
    consultationFee,
    acceptedInsurance,
  ];
}