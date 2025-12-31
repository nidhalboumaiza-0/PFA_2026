part of 'prescription_bloc.dart';

/// Base event for prescription BLoC
abstract class PrescriptionEvent extends Equatable {
  const PrescriptionEvent();

  @override
  List<Object?> get props => [];
}

/// Load patient's prescriptions
class LoadMyPrescriptions extends PrescriptionEvent {
  final String? status;
  final int page;
  final int limit;

  const LoadMyPrescriptions({
    this.status,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [status, page, limit];
}

/// Load prescription details by ID
class LoadPrescriptionDetails extends PrescriptionEvent {
  final String prescriptionId;

  const LoadPrescriptionDetails({required this.prescriptionId});

  @override
  List<Object?> get props => [prescriptionId];
}

class CreatePrescription extends PrescriptionEvent {
  final CreatePrescriptionParams params;

  const CreatePrescription({required this.params});

  @override
  List<Object?> get props => [params];
}

/// Clear prescription details (when navigating back)
class ClearPrescriptionDetails extends PrescriptionEvent {
  const ClearPrescriptionDetails();
}
