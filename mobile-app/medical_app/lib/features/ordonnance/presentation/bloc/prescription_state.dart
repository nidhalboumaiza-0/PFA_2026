part of 'prescription_bloc.dart';

abstract class PrescriptionState extends Equatable {
  const PrescriptionState();

  @override
  List<Object?> get props => [];
}

class PrescriptionInitial extends PrescriptionState {}

class PrescriptionLoading extends PrescriptionState {}

class PrescriptionCreated extends PrescriptionState {
  final PrescriptionEntity prescription;

  const PrescriptionCreated({required this.prescription});

  @override
  List<Object> get props => [prescription];
}

class PrescriptionUpdated extends PrescriptionState {
  final PrescriptionEntity prescription;

  const PrescriptionUpdated({required this.prescription});

  @override
  List<Object> get props => [prescription];
}

class PrescriptionStatusUpdated extends PrescriptionState {
  final String prescriptionId;
  final String status;

  const PrescriptionStatusUpdated({
    required this.prescriptionId,
    required this.status,
  });

  @override
  List<Object> get props => [prescriptionId, status];
}

class PrescriptionEdited extends PrescriptionState {
  final PrescriptionEntity prescription;

  const PrescriptionEdited({required this.prescription});

  @override
  List<Object> get props => [prescription];
}

class PrescriptionLoaded extends PrescriptionState {
  final PrescriptionEntity prescription;

  const PrescriptionLoaded({required this.prescription});

  @override
  List<Object> get props => [prescription];
}

class PrescriptionNotFound extends PrescriptionState {}

class PatientPrescriptionsLoaded extends PrescriptionState {
  final List<PrescriptionEntity> prescriptions;

  const PatientPrescriptionsLoaded({required this.prescriptions});

  @override
  List<Object> get props => [prescriptions];
}

class DoctorPrescriptionsLoaded extends PrescriptionState {
  final List<PrescriptionEntity> prescriptions;

  const DoctorPrescriptionsLoaded({required this.prescriptions});

  @override
  List<Object> get props => [prescriptions];
}

class PrescriptionError extends PrescriptionState {
  final String message;

  const PrescriptionError({required this.message});

  @override
  List<Object> get props => [message];
}
