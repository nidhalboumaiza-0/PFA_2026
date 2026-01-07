import 'package:equatable/equatable.dart';
import '../../domain/entities/medical_history_entity.dart';

/// States for Patient Medical History BLoC
abstract class PatientHistoryState extends Equatable {
  const PatientHistoryState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class PatientHistoryInitial extends PatientHistoryState {
  const PatientHistoryInitial();
}

/// Loading state
class PatientHistoryLoading extends PatientHistoryState {
  const PatientHistoryLoading();
}

/// Loaded state with medical history
class PatientHistoryLoaded extends PatientHistoryState {
  final MedicalHistoryEntity history;
  final String? patientName;

  const PatientHistoryLoaded({
    required this.history,
    this.patientName,
  });

  @override
  List<Object?> get props => [history, patientName];
}

/// Error state
class PatientHistoryError extends PatientHistoryState {
  final String message;
  final String code;

  const PatientHistoryError({
    required this.message,
    required this.code,
  });

  @override
  List<Object?> get props => [message, code];
}
