part of 'doctor_profile_bloc.dart';

abstract class DoctorProfileEvent extends Equatable {
  const DoctorProfileEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadDoctorProfile extends DoctorProfileEvent {}

class UpdateDoctorProfile extends DoctorProfileEvent {
  final UpdateDoctorProfileParams params;
  
  const UpdateDoctorProfile({required this.params});
  
  @override
  List<Object?> get props => [params];
}

class UploadDoctorPhoto extends DoctorProfileEvent {
  final String filePath;
  
  const UploadDoctorPhoto({required this.filePath});
  
  @override
  List<Object?> get props => [filePath];
}
