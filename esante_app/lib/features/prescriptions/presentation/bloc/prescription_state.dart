part of 'prescription_bloc.dart';

/// Base state for prescription BLoC
abstract class PrescriptionState extends Equatable {
  const PrescriptionState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class PrescriptionInitial extends PrescriptionState {
  const PrescriptionInitial();
}

/// Loading prescriptions
class PrescriptionsLoading extends PrescriptionState {
  const PrescriptionsLoading();
}

/// Prescriptions loaded successfully
class PrescriptionsLoaded extends PrescriptionState {
  final List<PrescriptionEntity> prescriptions;

  const PrescriptionsLoaded({required this.prescriptions});

  @override
  List<Object?> get props => [prescriptions];
}

/// Loading prescription details
class PrescriptionDetailsLoading extends PrescriptionState {
  const PrescriptionDetailsLoading();
}

/// Prescription details loaded
class PrescriptionDetailsLoaded extends PrescriptionState {
  final PrescriptionEntity prescription;

  const PrescriptionDetailsLoaded({required this.prescription});

  @override
  List<Object?> get props => [prescription];
}

class PrescriptionCreating extends PrescriptionState {}

class PrescriptionCreated extends PrescriptionState {
  final PrescriptionEntity prescription;

  const PrescriptionCreated({required this.prescription});

  @override
  List<Object?> get props => [prescription];
}

/// Error state
class PrescriptionError extends PrescriptionState {
  final String message;
  final bool isNetworkError;

  const PrescriptionError({
    required this.message,
    this.isNetworkError = false,
  });

  @override
  List<Object?> get props => [message, isNetworkError];
}
