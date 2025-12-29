import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../domain/entities/doctor_profile_entity.dart';
import '../../../domain/usecases/get_doctor_profile_usecase.dart';
import '../../../domain/usecases/update_doctor_profile_usecase.dart';
import '../../../domain/usecases/upload_profile_photo_usecase.dart';

part 'doctor_profile_event.dart';
part 'doctor_profile_state.dart';

class DoctorProfileBloc extends Bloc<DoctorProfileEvent, DoctorProfileState> {
  final GetDoctorProfileUseCase _getDoctorProfileUseCase;
  final UpdateDoctorProfileUseCase _updateDoctorProfileUseCase;
  final UploadProfilePhotoUseCase _uploadProfilePhotoUseCase;

  DoctorProfileBloc({
    required GetDoctorProfileUseCase getDoctorProfileUseCase,
    required UpdateDoctorProfileUseCase updateDoctorProfileUseCase,
    required UploadProfilePhotoUseCase uploadProfilePhotoUseCase,
  })  : _getDoctorProfileUseCase = getDoctorProfileUseCase,
        _updateDoctorProfileUseCase = updateDoctorProfileUseCase,
        _uploadProfilePhotoUseCase = uploadProfilePhotoUseCase,
        super(DoctorProfileInitial()) {
    on<LoadDoctorProfile>(_onLoadDoctorProfile);
    on<UpdateDoctorProfile>(_onUpdateDoctorProfile);
    on<UploadDoctorPhoto>(_onUploadDoctorPhoto);
  }

  void _log(String method, String message) {
    print('[DoctorProfileBloc.$method] $message');
  }

  Future<void> _onLoadDoctorProfile(
    LoadDoctorProfile event,
    Emitter<DoctorProfileState> emit,
  ) async {
    _log('_onLoadDoctorProfile', 'Loading doctor profile...');
    emit(DoctorProfileLoading());

    final result = await _getDoctorProfileUseCase();

    result.fold(
      (failure) {
        _log('_onLoadDoctorProfile', 'Failed: ${failure.message}');
        emit(DoctorProfileError(failure: failure));
      },
      (profile) {
        _log('_onLoadDoctorProfile', 'Success: ${profile.fullName}');
        emit(DoctorProfileLoaded(profile: profile));
      },
    );
  }

  Future<void> _onUpdateDoctorProfile(
    UpdateDoctorProfile event,
    Emitter<DoctorProfileState> emit,
  ) async {
    _log('_onUpdateDoctorProfile', 'Updating doctor profile...');
    emit(DoctorProfileUpdating());

    final result = await _updateDoctorProfileUseCase(event.params);

    result.fold(
      (failure) {
        _log('_onUpdateDoctorProfile', 'Failed: ${failure.message}');
        emit(DoctorProfileError(failure: failure));
      },
      (profile) {
        _log('_onUpdateDoctorProfile', 'Success: ${profile.fullName}');
        emit(DoctorProfileUpdated(profile: profile));
      },
    );
  }

  Future<void> _onUploadDoctorPhoto(
    UploadDoctorPhoto event,
    Emitter<DoctorProfileState> emit,
  ) async {
    _log('_onUploadDoctorPhoto', 'Uploading photo...');
    emit(DoctorPhotoUploading());

    final result = await _uploadProfilePhotoUseCase(event.filePath);

    result.fold(
      (failure) {
        _log('_onUploadDoctorPhoto', 'Failed: ${failure.message}');
        emit(DoctorProfileError(failure: failure));
      },
      (photoUrl) {
        _log('_onUploadDoctorPhoto', 'Success: $photoUrl');
        emit(DoctorPhotoUploaded(photoUrl: photoUrl));
        // Reload profile to get updated data
        add(LoadDoctorProfile());
      },
    );
  }
}
