import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/prescription_entity.dart';
import '../../domain/usecases/get_my_prescriptions.dart';
import '../../domain/usecases/get_prescription_by_id.dart';
import '../../domain/usecases/create_prescription.dart';

part 'prescription_event.dart';
part 'prescription_state.dart';

/// BLoC for managing prescription state
class PrescriptionBloc extends Bloc<PrescriptionEvent, PrescriptionState> {
  final GetMyPrescriptionsUseCase getMyPrescriptionsUseCase;
  final GetPrescriptionByIdUseCase getPrescriptionByIdUseCase;
  final CreatePrescriptionUseCase? createPrescriptionUseCase;

  PrescriptionBloc({
    required this.getMyPrescriptionsUseCase,
    required this.getPrescriptionByIdUseCase,
    this.createPrescriptionUseCase,
  }) : super(PrescriptionInitial()) {
    on<LoadMyPrescriptions>(_onLoadMyPrescriptions);
    on<LoadPrescriptionDetails>(_onLoadPrescriptionDetails);
    on<CreatePrescription>(_onCreatePrescription);
    on<ClearPrescriptionDetails>(_onClearPrescriptionDetails);
  }

  Future<void> _onLoadMyPrescriptions(
    LoadMyPrescriptions event,
    Emitter<PrescriptionState> emit,
  ) async {
    emit(const PrescriptionsLoading());

    final result = await getMyPrescriptionsUseCase(
      GetMyPrescriptionsParams(
        status: event.status,
        page: event.page,
        limit: event.limit,
      ),
    );

    result.fold(
      (failure) => emit(PrescriptionError(message: failure.message)),
      (prescriptions) => emit(PrescriptionsLoaded(prescriptions: prescriptions)),
    );
  }

  Future<void> _onLoadPrescriptionDetails(
    LoadPrescriptionDetails event,
    Emitter<PrescriptionState> emit,
  ) async {
    emit(const PrescriptionDetailsLoading());

    final result = await getPrescriptionByIdUseCase(event.prescriptionId);

    result.fold(
      (failure) => emit(PrescriptionError(message: failure.message)),
      (prescription) => emit(PrescriptionDetailsLoaded(prescription: prescription)),
    );
  }

  Future<void> _onCreatePrescription(
    CreatePrescription event,
    Emitter<PrescriptionState> emit,
  ) async {
    if (createPrescriptionUseCase == null) {
      emit(const PrescriptionError(message: 'Creation not supported'));
      return;
    }

    emit(PrescriptionCreating());
    final result = await createPrescriptionUseCase!(event.params);
    result.fold(
      (failure) => emit(PrescriptionError(message: failure.message)),
      (prescription) => emit(PrescriptionCreated(prescription: prescription)),
    );
  }

  void _onClearPrescriptionDetails(
    ClearPrescriptionDetails event,
    Emitter<PrescriptionState> emit,
  ) {
    emit(const PrescriptionInitial());
  }
}
