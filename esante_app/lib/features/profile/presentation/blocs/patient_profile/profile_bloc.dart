import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../domain/entities/patient_profile_entity.dart';
import '../../../domain/usecases/get_patient_profile_usecase.dart';
import '../../../domain/usecases/update_patient_profile_usecase.dart';
import '../../../domain/usecases/upload_profile_photo_usecase.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetPatientProfileUseCase getPatientProfileUseCase;
  final UpdatePatientProfileUseCase updatePatientProfileUseCase;
  final UploadProfilePhotoUseCase uploadProfilePhotoUseCase;

  ProfileBloc({
    required this.getPatientProfileUseCase,
    required this.updatePatientProfileUseCase,
    required this.uploadProfilePhotoUseCase,
  }) : super(ProfileInitial()) {
    on<LoadProfile>(_onLoadProfile);
    on<UpdateProfile>(_onUpdateProfile);
    on<UploadPhoto>(_onUploadPhoto);
    on<ResetProfileState>(_onResetProfileState);
  }

  void _log(String method, String message) {
    print('[ProfileBloc.$method] $message');
  }

  Future<void> _onLoadProfile(
    LoadProfile event,
    Emitter<ProfileState> emit,
  ) async {
    _log('_onLoadProfile', 'Loading profile...');
    emit(ProfileLoading());

    final result = await getPatientProfileUseCase();

    result.fold(
      (failure) {
        _log('_onLoadProfile', 'Failed: ${failure.message}');
        emit(ProfileError(failure: failure));
      },
      (profile) {
        _log('_onLoadProfile', 'Success: ${profile.fullName}');
        emit(ProfileLoaded(profile: profile));
      },
    );
  }

  Future<void> _onUpdateProfile(
    UpdateProfile event,
    Emitter<ProfileState> emit,
  ) async {
    _log('_onUpdateProfile', 'Updating profile...');
    emit(ProfileUpdating());

    final result = await updatePatientProfileUseCase(event.params);

    result.fold(
      (failure) {
        _log('_onUpdateProfile', 'Failed: ${failure.message}');
        emit(ProfileError(failure: failure));
      },
      (profile) {
        _log('_onUpdateProfile', 'Success: ${profile.fullName}');
        emit(ProfileUpdated(profile: profile));
      },
    );
  }

  Future<void> _onUploadPhoto(
    UploadPhoto event,
    Emitter<ProfileState> emit,
  ) async {
    _log('_onUploadPhoto', 'Uploading photo...');
    emit(PhotoUploading());

    final result = await uploadProfilePhotoUseCase(event.filePath);

    result.fold(
      (failure) {
        _log('_onUploadPhoto', 'Failed: ${failure.message}');
        emit(PhotoUploadError(failure: failure));
      },
      (photoUrl) {
        _log('_onUploadPhoto', 'Success: $photoUrl');
        emit(PhotoUploaded(photoUrl: photoUrl));
        // Reload profile to get updated data
        add(LoadProfile());
      },
    );
  }

  void _onResetProfileState(
    ResetProfileState event,
    Emitter<ProfileState> emit,
  ) {
    emit(ProfileInitial());
  }
}
