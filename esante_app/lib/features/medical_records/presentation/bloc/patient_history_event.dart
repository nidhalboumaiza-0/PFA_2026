import 'package:equatable/equatable.dart';

/// Events for Patient Medical History BLoC
abstract class PatientHistoryEvent extends Equatable {
  const PatientHistoryEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load a patient's medical history
class LoadPatientHistoryEvent extends PatientHistoryEvent {
  final String patientId;
  final String? patientName;

  const LoadPatientHistoryEvent({
    required this.patientId,
    this.patientName,
  });

  @override
  List<Object?> get props => [patientId, patientName];
}

/// Event to refresh patient history
class RefreshPatientHistoryEvent extends PatientHistoryEvent {
  const RefreshPatientHistoryEvent();
}
