part of 'profile_bloc.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final PatientProfileEntity profile;

  const ProfileLoaded({required this.profile});

  @override
  List<Object?> get props => [profile];
}

class ProfileUpdating extends ProfileState {}

class ProfileUpdated extends ProfileState {
  final PatientProfileEntity profile;

  const ProfileUpdated({required this.profile});

  @override
  List<Object?> get props => [profile];
}

class ProfileError extends ProfileState {
  final Failure failure;

  const ProfileError({required this.failure});

  @override
  List<Object?> get props => [failure];
}

class PhotoUploading extends ProfileState {}

class PhotoUploaded extends ProfileState {
  final String photoUrl;

  const PhotoUploaded({required this.photoUrl});

  @override
  List<Object?> get props => [photoUrl];
}

class PhotoUploadError extends ProfileState {
  final Failure failure;

  const PhotoUploadError({required this.failure});

  @override
  List<Object?> get props => [failure];
}
