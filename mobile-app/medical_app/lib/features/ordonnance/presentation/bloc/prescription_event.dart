part of 'prescription_bloc.dart';

abstract class PrescriptionEvent extends Equatable {
  const PrescriptionEvent();

  @override
  List<Object?> get props => [];
}

class CreatePrescription extends PrescriptionEvent {
  final String consultationId;
  final String patientId;
  final String? patientName;
  final String doctorId;
  final String? doctorName;
  final List<MedicationEntity> medications;
  final String? generalInstructions;
  final String? specialWarnings;
  final String? pharmacyName;
  final String? pharmacyAddress;
  final String createdBy;

  const CreatePrescription({
    required this.consultationId,
    required this.patientId,
    this.patientName,
    required this.doctorId,
    this.doctorName,
    required this.medications,
    this.generalInstructions,
    this.specialWarnings,
    this.pharmacyName,
    this.pharmacyAddress,
    required this.createdBy,
  });

  @override
  List<Object?> get props => [
    consultationId,
    patientId,
    patientName,
    doctorId,
    doctorName,
    medications,
    generalInstructions,
    specialWarnings,
    pharmacyName,
    pharmacyAddress,
    createdBy,
  ];
}

class EditPrescription extends PrescriptionEvent {
  final PrescriptionEntity prescription;

  const EditPrescription({required this.prescription});

  @override
  List<Object> get props => [prescription];
}

class GetPatientPrescriptions extends PrescriptionEvent {
  final String patientId;

  const GetPatientPrescriptions({required this.patientId});

  @override
  List<Object> get props => [patientId];
}

class GetDoctorPrescriptions extends PrescriptionEvent {
  final String doctorId;

  const GetDoctorPrescriptions({required this.doctorId});

  @override
  List<Object> get props => [doctorId];
}

class GetPrescriptionById extends PrescriptionEvent {
  final String prescriptionId;

  const GetPrescriptionById({required this.prescriptionId});

  @override
  List<Object> get props => [prescriptionId];
}

class GetPrescriptionByConsultationId extends PrescriptionEvent {
  final String consultationId;

  const GetPrescriptionByConsultationId({required this.consultationId});

  @override
  List<Object> get props => [consultationId];
}

class UpdatePrescription extends PrescriptionEvent {
  final PrescriptionEntity prescription;

  const UpdatePrescription({required this.prescription});

  @override
  List<Object> get props => [prescription];
}

class UpdatePrescriptionStatus extends PrescriptionEvent {
  final String prescriptionId;
  final String status;

  const UpdatePrescriptionStatus({
    required this.prescriptionId,
    required this.status,
  });

  @override
  List<Object> get props => [prescriptionId, status];
}
