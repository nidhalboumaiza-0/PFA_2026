part of 'doctor_profile_bloc.dart';

abstract class DoctorProfileState extends Equatable {
  const DoctorProfileState();
  
  @override
  List<Object?> get props => [];
}

class DoctorProfileInitial extends DoctorProfileState {}

class DoctorProfileLoading extends DoctorProfileState {}

class DoctorProfileLoaded extends DoctorProfileState {
  final DoctorProfileEntity profile;
  
  const DoctorProfileLoaded({required this.profile});
  
  @override
  List<Object?> get props => [profile];
}

class DoctorProfileUpdating extends DoctorProfileState {}

class DoctorProfileUpdated extends DoctorProfileState {
  final DoctorProfileEntity profile;
  
  const DoctorProfileUpdated({required this.profile});
  
  @override
  List<Object?> get props => [profile];
}

class DoctorPhotoUploading extends DoctorProfileState {}

class DoctorPhotoUploaded extends DoctorProfileState {
  final String photoUrl;
  
  const DoctorPhotoUploaded({required this.photoUrl});
  
  @override
  List<Object?> get props => [photoUrl];
}

class DoctorProfileError extends DoctorProfileState {
  final Failure failure;
  
  const DoctorProfileError({required this.failure});
  
  @override
  List<Object?> get props => [failure];
}
