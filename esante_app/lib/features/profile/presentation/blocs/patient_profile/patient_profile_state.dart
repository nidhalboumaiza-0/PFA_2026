part of 'patient_profile_bloc.dart';

abstract class PatientProfileState extends Equatable {
  const PatientProfileState();

  @override
  List<Object?> get props => [];
}

class PatientProfileInitial extends PatientProfileState {}

class PatientProfileLoading extends PatientProfileState {}

class PatientProfileLoaded extends PatientProfileState {
  final PatientProfileEntity profile;

  const PatientProfileLoaded({required this.profile});

  @override
  List<Object?> get props => [profile];
}

class PatientProfileUpdating extends PatientProfileState {}

class PatientProfileUpdated extends PatientProfileState {
  final PatientProfileEntity profile;

  const PatientProfileUpdated({required this.profile});

  @override
  List<Object?> get props => [profile];
}

class PatientProfileError extends PatientProfileState {
  final Failure failure;

  const PatientProfileError({required this.failure});

  @override
  List<Object?> get props => [failure];
}

class PatientPhotoUploading extends PatientProfileState {}

class PatientPhotoUploaded extends PatientProfileState {
  final String photoUrl;

  const PatientPhotoUploaded({required this.photoUrl});

  @override
  List<Object?> get props => [photoUrl];
}

class PatientPhotoUploadError extends PatientProfileState {
  final Failure failure;

  const PatientPhotoUploadError({required this.failure});

  @override
  List<Object?> get props => [failure];
}
