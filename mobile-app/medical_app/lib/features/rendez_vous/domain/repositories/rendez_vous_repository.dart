import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/authentication/domain/entities/medecin_entity.dart';
import 'package:medical_app/features/rendez_vous/domain/entities/rendez_vous_entity.dart';

abstract class RendezVousRepository {
  Future<Either<Failure, List<RendezVousEntity>>> getRendezVous({
    String? patientId,
    String? doctorId,
  });

  Future<Either<Failure, Unit>> updateRendezVousStatus(
    String rendezVousId,
    String status,
  );

  Future<Either<Failure, Unit>> createRendezVous(RendezVousEntity rendezVous);

  Future<Either<Failure, List<MedecinEntity>>> getDoctorsBySpecialty(
    String specialty, {
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Either<Failure, RendezVousEntity>> getRendezVousDetails(
    String rendezVousId,
  );

  Future<Either<Failure, Unit>> cancelAppointment(String rendezVousId, {String? reason});

  Future<Either<Failure, Unit>> rateDoctor(String appointmentId, double rating);

  Future<Either<Failure, List<RendezVousEntity>>> getDoctorAppointmentsForDay(
    String doctorId,
    DateTime date,
  );

  Future<Either<Failure, Unit>> acceptAppointment(String rendezVousId, {String? notes});

  Future<Either<Failure, Unit>> refuseAppointment(String rendezVousId, {String? reason});

  Future<Either<Failure, Unit>> completeAppointment(String rendezVousId);

  Future<Either<Failure, List<RendezVousEntity>>> getAppointmentRequests();

  Future<Either<Failure, Map<String, dynamic>>> getDoctorAvailability();

  Future<Either<Failure, Unit>> setDoctorAvailability(Map<String, dynamic> availability);

  Future<Either<Failure, Map<String, dynamic>>> viewDoctorAvailability(String doctorId, {DateTime? date});

  Future<Either<Failure, Map<String, dynamic>>> getAppointmentStatistics();

  // ==================== RESCHEDULE METHODS ====================
  
  /// Doctor: Reschedule appointment directly (no patient approval needed)
  Future<Either<Failure, Unit>> rescheduleAppointment(
    String appointmentId, {
    required DateTime newDate,
    required String newTime,
    String? reason,
  });

  /// Patient: Request to reschedule an appointment (requires doctor approval)
  Future<Either<Failure, Unit>> requestReschedule(
    String appointmentId, {
    required DateTime newDate,
    required String newTime,
    String? reason,
  });

  /// Doctor: Approve a patient's reschedule request
  Future<Either<Failure, Unit>> approveReschedule(String appointmentId);

  /// Doctor: Reject a patient's reschedule request
  Future<Either<Failure, Unit>> rejectReschedule(String appointmentId, {String? reason});
}
