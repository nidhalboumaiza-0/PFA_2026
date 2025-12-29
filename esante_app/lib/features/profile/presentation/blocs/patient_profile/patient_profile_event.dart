part of 'patient_profile_bloc.dart';

abstract class PatientProfileEvent extends Equatable {
  const PatientProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadPatientProfile extends PatientProfileEvent {}

class UpdatePatientProfile extends PatientProfileEvent {
  final UpdatePatientProfileParams params;

  const UpdatePatientProfile({required this.params});

  @override
  List<Object?> get props => [params];
}

class UploadPatientPhoto extends PatientProfileEvent {
  final String filePath;

  const UploadPatientPhoto({required this.filePath});

  @override
  List<Object?> get props => [filePath];
}

class ResetPatientProfileState extends PatientProfileEvent {}
