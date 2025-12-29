part of 'profile_bloc.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadProfile extends ProfileEvent {}

class UpdateProfile extends ProfileEvent {
  final UpdatePatientProfileParams params;

  const UpdateProfile({required this.params});

  @override
  List<Object?> get props => [params];
}

class UploadPhoto extends ProfileEvent {
  final String filePath;

  const UploadPhoto({required this.filePath});

  @override
  List<Object?> get props => [filePath];
}

class ResetProfileState extends ProfileEvent {}
