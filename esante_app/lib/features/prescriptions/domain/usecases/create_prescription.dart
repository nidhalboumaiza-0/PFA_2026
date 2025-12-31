import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/models/prescription_model.dart';
import '../entities/prescription_entity.dart';
import '../repositories/prescription_repository.dart';

class CreatePrescriptionUseCase implements UseCase<PrescriptionEntity, CreatePrescriptionParams> {
  final PrescriptionRepository repository;

  CreatePrescriptionUseCase(this.repository);

  @override
  Future<Either<Failure, PrescriptionEntity>> call(CreatePrescriptionParams params) async {
    return await repository.createPrescription(params);
  }
}

class CreatePrescriptionParams {
  final String consultationId;
  final String patientId;
  final String doctorId;
  final List<MedicationModel> medications; // Using Model for params as it maps to JSON
  final String? generalInstructions;
  final String? specialWarnings;
  final String? pharmacyName;
  final String? pharmacyAddress;

  CreatePrescriptionParams({
    required this.consultationId,
    required this.patientId,
    required this.doctorId,
    required this.medications,
    this.generalInstructions,
    this.specialWarnings,
    this.pharmacyName,
    this.pharmacyAddress,
  });

  Map<String, dynamic> toJson() {
    return {
      'consultationId': consultationId,
      'patientId': patientId,
      'doctorId': doctorId,
      'medications': medications.map((m) => m.toJson()).toList(),
      'generalInstructions': generalInstructions,
      'specialWarnings': specialWarnings,
      'pharmacyName': pharmacyName,
      'pharmacyAddress': pharmacyAddress,
    };
  }
}
