import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_patient_medical_history_usecase.dart';
import 'patient_history_event.dart';
import 'patient_history_state.dart';

/// BLoC for managing patient medical history
class PatientHistoryBloc
    extends Bloc<PatientHistoryEvent, PatientHistoryState> {
  final GetPatientMedicalHistoryUseCase getPatientMedicalHistoryUseCase;

  String? _currentPatientId;
  String? _currentPatientName;

  PatientHistoryBloc({
    required this.getPatientMedicalHistoryUseCase,
  }) : super(const PatientHistoryInitial()) {
    on<LoadPatientHistoryEvent>(_onLoadPatientHistory);
    on<RefreshPatientHistoryEvent>(_onRefreshPatientHistory);
  }

  void _log(String method, String message) {
    print('[PatientHistoryBloc.$method] $message');
  }

  Future<void> _onLoadPatientHistory(
    LoadPatientHistoryEvent event,
    Emitter<PatientHistoryState> emit,
  ) async {
    _log('_onLoadPatientHistory', 'Loading history for patient: ${event.patientId}');
    
    _currentPatientId = event.patientId;
    _currentPatientName = event.patientName;
    
    emit(const PatientHistoryLoading());

    final result = await getPatientMedicalHistoryUseCase(
      GetPatientMedicalHistoryParams(patientId: event.patientId),
    );

    result.fold(
      (failure) {
        _log('_onLoadPatientHistory', 'Failed: ${failure.message}');
        emit(PatientHistoryError(
          message: failure.message,
          code: failure.code,
        ));
      },
      (history) {
        _log('_onLoadPatientHistory', 'Success: ${history.summary.totalConsultations} consultations');
        emit(PatientHistoryLoaded(
          history: history,
          patientName: event.patientName,
        ));
      },
    );
  }

  Future<void> _onRefreshPatientHistory(
    RefreshPatientHistoryEvent event,
    Emitter<PatientHistoryState> emit,
  ) async {
    if (_currentPatientId == null) return;

    _log('_onRefreshPatientHistory', 'Refreshing history');
    
    add(LoadPatientHistoryEvent(
      patientId: _currentPatientId!,
      patientName: _currentPatientName,
    ));
  }
}
