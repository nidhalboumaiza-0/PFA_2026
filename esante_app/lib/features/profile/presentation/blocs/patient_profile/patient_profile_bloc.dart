import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../domain/entities/patient_profile_entity.dart';
import '../../../domain/usecases/get_patient_profile_usecase.dart';
import '../../../domain/usecases/update_patient_profile_usecase.dart';
import '../../../domain/usecases/upload_profile_photo_usecase.dart';

part 'patient_profile_event.dart';
part 'patient_profile_state.dart';

class PatientProfileBloc extends Bloc<PatientProfileEvent, PatientProfileState> {
  final GetPatientProfileUseCase getPatientProfileUseCase;
  final UpdatePatientProfileUseCase updatePatientProfileUseCase;
  final UploadProfilePhotoUseCase uploadProfilePhotoUseCase;

  PatientProfileBloc({
    required this.getPatientProfileUseCase,
    required this.updatePatientProfileUseCase,
    required this.uploadProfilePhotoUseCase,
  }) : super(PatientProfileInitial()) {
    on<LoadPatientProfile>(_onLoadProfile);
    on<UpdatePatientProfile>(_onUpdateProfile);
    on<UploadPatientPhoto>(_onUploadPhoto);
    on<ResetPatientProfileState>(_onResetProfileState);
  }

  void _log(String method, String message) {
    print('[PatientProfileBloc.$method] $message');
  }

  Future<void> _onLoadProfile(
    LoadPatientProfile event,
    Emitter<PatientProfileState> emit,
  ) async {
    _log('_onLoadProfile', 'Loading profile...');
    emit(PatientProfileLoading());

    final result = await getPatientProfileUseCase();

    result.fold(
      (failure) {
        _log('_onLoadProfile', 'Failed: ${failure.message}');
        emit(PatientProfileError(failure: failure));
      },
      (profile) {
        _log('_onLoadProfile', 'Success: ${profile.fullName}');
        emit(PatientProfileLoaded(profile: profile));
      },
    );
  }

  Future<void> _onUpdateProfile(
    UpdatePatientProfile event,
    Emitter<PatientProfileState> emit,
  ) async {
    _log('_onUpdateProfile', 'Updating profile...');
    emit(PatientProfileUpdating());

    final result = await updatePatientProfileUseCase(event.params);

    result.fold(
      (failure) {
        _log('_onUpdateProfile', 'Failed: ${failure.message}');
        emit(PatientProfileError(failure: failure));
      },
      (profile) {
        _log('_onUpdateProfile', 'Success: ${profile.fullName}');
        emit(PatientProfileUpdated(profile: profile));
      },
    );
  }

  Future<void> _onUploadPhoto(
    UploadPatientPhoto event,
    Emitter<PatientProfileState> emit,
  ) async {
    _log('_onUploadPhoto', 'Uploading photo...');
    emit(PatientPhotoUploading());

    final result = await uploadProfilePhotoUseCase(event.filePath);

    result.fold(
      (failure) {
        _log('_onUploadPhoto', 'Failed: ${failure.message}');
        emit(PatientPhotoUploadError(failure: failure));
      },
      (photoUrl) {
        _log('_onUploadPhoto', 'Success: $photoUrl');
        emit(PatientPhotoUploaded(photoUrl: photoUrl));
        // Reload profile to get updated data
        add(LoadPatientProfile());
      },
    );
  }

  void _onResetProfileState(
    ResetPatientProfileState event,
    Emitter<PatientProfileState> emit,
  ) {
    emit(PatientProfileInitial());
  }
}
