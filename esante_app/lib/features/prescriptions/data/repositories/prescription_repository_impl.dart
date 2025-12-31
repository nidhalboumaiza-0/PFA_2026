import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/prescription_entity.dart';
import '../../domain/repositories/prescription_repository.dart';
import '../../domain/usecases/create_prescription.dart';
import '../datasources/prescription_remote_data_source.dart';
import '../models/prescription_model.dart';

/// Implementation of PrescriptionRepository
class PrescriptionRepositoryImpl implements PrescriptionRepository {
  final PrescriptionRemoteDataSource remoteDataSource;

  PrescriptionRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<PrescriptionEntity>>> getMyPrescriptions({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final prescriptions = await remoteDataSource.getMyPrescriptions(
        status: status,
        page: page,
        limit: limit,
      );
      return Right(prescriptions.map(_mapModelToEntity).toList());
    } catch (e) {
      return Left(ServerFailure(code: 'SERVER_ERROR', message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PrescriptionEntity>> getPrescriptionById(
    String prescriptionId,
  ) async {
    try {
      final prescription = await remoteDataSource.getPrescriptionById(prescriptionId);
      return Right(_mapModelToEntity(prescription));
    } catch (e) {
      return Left(ServerFailure(code: 'SERVER_ERROR', message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PrescriptionEntity>> createPrescription(
    CreatePrescriptionParams params,
  ) async {
    try {
      final prescription = await remoteDataSource.createPrescription(params);
      return Right(_mapModelToEntity(prescription));
    } catch (e) {
      return Left(ServerFailure(code: 'SERVER_ERROR', message: e.toString()));
    }
  }

  /// Maps PrescriptionModel to PrescriptionEntity
  PrescriptionEntity _mapModelToEntity(PrescriptionModel model) {
    return PrescriptionEntity(
      id: model.id,
      date: model.date,
      doctor: PrescriptionDoctorEntity(
        name: model.doctor.name,
        specialty: model.doctor.specialty,
      ),
      appointment: model.appointment != null
          ? AppointmentInfoEntity(
              consultationDate: model.appointment!.consultationDate,
              consultationType: model.appointment!.consultationType,
              chiefComplaint: model.appointment!.chiefComplaint,
              diagnosis: model.appointment!.diagnosis,
            )
          : null,
      medications: model.medications
          .map((m) => MedicationEntity(
                name: m.name,
                dosage: m.dosage,
                form: m.form,
                frequency: m.frequency,
                duration: m.duration,
                instructions: m.instructions,
              ))
          .toList(),
      medicationCount: model.medicationCount,
      generalInstructions: model.generalInstructions,
      specialWarnings: model.specialWarnings,
      pharmacyName: model.pharmacyName,
      status: model.status,
      createdAt: model.createdAt,
    );
  }
}
