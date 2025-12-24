import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/prescription_entity.dart';

abstract class PrescriptionRepository {
  /// Create a new prescription
  Future<Either<Failure, PrescriptionEntity>> createPrescription(
    PrescriptionEntity prescription,
  );

  /// Edit an existing prescription
  /// Only allowed within 12 hours of creation
  Future<Either<Failure, PrescriptionEntity>> editPrescription(
    PrescriptionEntity prescription,
  );

  /// Get all prescriptions for a specific patient
  Future<Either<Failure, List<PrescriptionEntity>>> getPatientPrescriptions(
    String patientId,
  );

  /// Get all prescriptions created by a specific doctor
  Future<Either<Failure, List<PrescriptionEntity>>> getDoctorPrescriptions(
    String doctorId,
  );

  /// Get a specific prescription by ID
  Future<Either<Failure, PrescriptionEntity>> getPrescriptionById(
    String prescriptionId,
  );

  /// Get prescriptions for a specific appointment
  Future<Either<Failure, PrescriptionEntity?>> getPrescriptionByAppointmentId(
    String appointmentId,
  );

  /// Update a prescription's status
  Future<Either<Failure, Unit>> updatePrescriptionStatus(
    String prescriptionId,
    String status,
  );
}
