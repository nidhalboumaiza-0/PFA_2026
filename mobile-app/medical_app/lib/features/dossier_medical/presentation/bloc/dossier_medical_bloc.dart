import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/dossier_medical/domain/entities/dossier_medical_entity.dart';
import 'package:medical_app/features/dossier_medical/domain/usecases/get_dossier_medical.dart'
    as get_dm;
import 'package:medical_app/features/dossier_medical/domain/usecases/has_dossier_medical.dart'
    as has_dm;
import '../../domain/repositories/dossier_medical_repository.dart';
import 'dossier_medical_event.dart';
import 'dossier_medical_state.dart';

// BLoC
class DossierMedicalBloc
    extends Bloc<DossierMedicalEvent, DossierMedicalState> {
  final DossierMedicalRepository repository;
  final get_dm.GetDossierMedical getDossierMedicalUseCase;
  final has_dm.HasDossierMedical hasDossierMedicalUseCase;

  DossierMedicalBloc({
    required this.repository,
    required this.getDossierMedicalUseCase,
    required this.hasDossierMedicalUseCase,
  }) : super(const DossierMedicalInitial()) {
    on<FetchDossierMedical>(_onFetchDossierMedical);
    on<CheckDossierMedicalExists>(_onCheckDossierMedicalExists);
    on<UploadSingleFile>(_onUploadSingleFile);
    on<UploadMultipleFiles>(_onUploadMultipleFiles);
    on<DeleteFile>(_onDeleteFile);
    on<UpdateFileDescription>(_onUpdateFileDescription);
  }

  Future<void> _onFetchDossierMedical(
    FetchDossierMedical event,
    Emitter<DossierMedicalState> emit,
  ) async {
    emit(const DossierMedicalLoading());
    final result = await getDossierMedicalUseCase(
      get_dm.Params(patientId: event.patientId),
    );
    _emitDossierMedicalResult(result, emit);
  }

  Future<void> _onCheckDossierMedicalExists(
    CheckDossierMedicalExists event,
    Emitter<DossierMedicalState> emit,
  ) async {
    emit(const CheckingDossierMedicalStatus());
    final result = await hasDossierMedicalUseCase(
      has_dm.Params(patientId: event.patientId),
    );

    result.fold(
      (failure) =>
          emit(DossierMedicalError(message: _mapFailureToMessage(failure))),
      (hasDossier) => emit(DossierMedicalExists(exists: hasDossier)),
    );
  }

  void _emitDossierMedicalResult(
    Either<Failure, DossierMedicalEntity> result,
    Emitter<DossierMedicalState> emit,
  ) {
    result.fold(
      (failure) =>
          emit(DossierMedicalError(message: _mapFailureToMessage(failure))),
      (dossierMedical) =>
          dossierMedical.files.isEmpty
              ? emit(DossierMedicalEmpty(patientId: dossierMedical.patientId))
              : emit(DossierMedicalLoaded(dossier: dossierMedical)),
    );
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return failure.message ?? 'Server failure';
      case NetworkFailure:
        return failure.message ?? 'Network failure';
      case FileFailure:
        return failure.message ?? 'File failure';
      default:
        return 'Unexpected error';
    }
  }

  Future<void> _onUploadSingleFile(
    UploadSingleFile event,
    Emitter<DossierMedicalState> emit,
  ) async {
    emit(const FileUploadLoading(isSingleFile: true));
    final result = await repository.addFileToDossier(
      event.patientId,
      event.filePath,
      event.description,
    );
    result.fold(
      (failure) =>
          emit(FileUploadError(message: failure.message, isSingleFile: true)),
      (dossier) =>
          emit(FileUploadSuccess(dossier: dossier, isSingleFile: true)),
    );
  }

  Future<void> _onUploadMultipleFiles(
    UploadMultipleFiles event,
    Emitter<DossierMedicalState> emit,
  ) async {
    emit(const FileUploadLoading(isSingleFile: false));
    final result = await repository.addFilesToDossier(
      event.patientId,
      event.filePaths,
      event.descriptions,
    );
    result.fold(
      (failure) =>
          emit(FileUploadError(message: failure.message, isSingleFile: false)),
      (dossier) =>
          emit(FileUploadSuccess(dossier: dossier, isSingleFile: false)),
    );
  }

  Future<void> _onDeleteFile(
    DeleteFile event,
    Emitter<DossierMedicalState> emit,
  ) async {
    emit(FileDeleteLoading(fileId: event.fileId));
    final result = await repository.deleteFile(event.patientId, event.fileId);
    result.fold(
      (failure) =>
          emit(FileDeleteError(message: failure.message, fileId: event.fileId)),
      (_) => emit(FileDeleteSuccess(fileId: event.fileId)),
    );

    // After delete, refresh the dossier
    add(FetchDossierMedical(patientId: event.patientId));
  }

  Future<void> _onUpdateFileDescription(
    UpdateFileDescription event,
    Emitter<DossierMedicalState> emit,
  ) async {
    emit(FileDescriptionUpdateLoading(fileId: event.fileId));
    final result = await repository.updateFileDescription(
      event.patientId,
      event.fileId,
      event.description,
    );
    result.fold(
      (failure) => emit(
        FileDescriptionUpdateError(
          message: failure.message,
          fileId: event.fileId,
        ),
      ),
      (_) => emit(FileDescriptionUpdateSuccess(fileId: event.fileId)),
    );

    // After update, refresh the dossier
    add(FetchDossierMedical(patientId: event.patientId));
  }
}
