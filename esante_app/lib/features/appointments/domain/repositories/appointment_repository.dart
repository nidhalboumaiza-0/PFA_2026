import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../presentation/bloc/doctor/doctor_appointment_bloc.dart';
import '../entities/appointment_entity.dart';
import '../entities/time_slot_entity.dart';

/// Repository interface for appointment operations
abstract class AppointmentRepository {
  // ============== Patient Operations ==============

  /// View doctor's availability for booking
  Future<Either<Failure, List<TimeSlotEntity>>> viewDoctorAvailability({
    required String doctorId,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Request an appointment
  Future<Either<Failure, AppointmentEntity>> requestAppointment({
    required String doctorId,
    required DateTime appointmentDate,
    required String appointmentTime,
    required String reason,
    String? notes,
  });

  /// Cancel an appointment (patient)
  Future<Either<Failure, AppointmentEntity>> cancelAppointment({
    required String appointmentId,
    required String reason,
  });

  /// Request reschedule (requires doctor approval)
  Future<Either<Failure, AppointmentEntity>> requestReschedule({
    required String appointmentId,
    required DateTime newDate,
    required String newTime,
    String? reason,
  });

  /// Get patient's appointments
  Future<Either<Failure, List<AppointmentEntity>>> getPatientAppointments({
    String? status,
    int page = 1,
    int limit = 20,
  });

  // ============== Doctor Operations ==============

  /// Set availability for a date
  Future<Either<Failure, TimeSlotEntity>> setAvailability({
    required DateTime date,
    required List<String> timeSlots,
    String? specialNotes,
  });

  /// Bulk set availability for multiple dates (template apply)
  Future<Either<Failure, Map<String, dynamic>>> bulkSetAvailability({
    required List<AvailabilityEntry> availabilities,
    bool skipExisting = true,
  });

  /// Get doctor's own availability
  Future<Either<Failure, List<TimeSlotEntity>>> getDoctorAvailability({
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Get appointment requests (pending)
  Future<Either<Failure, List<AppointmentEntity>>> getAppointmentRequests({
    int page = 1,
    int limit = 20,
  });

  /// Confirm an appointment
  Future<Either<Failure, AppointmentEntity>> confirmAppointment({
    required String appointmentId,
  });

  /// Reject an appointment
  Future<Either<Failure, AppointmentEntity>> rejectAppointment({
    required String appointmentId,
    required String reason,
  });

  /// Reschedule an appointment (direct, by doctor)
  Future<Either<Failure, AppointmentEntity>> rescheduleAppointment({
    required String appointmentId,
    required DateTime newDate,
    required String newTime,
    String? reason,
  });

  /// Approve patient's reschedule request
  Future<Either<Failure, AppointmentEntity>> approveReschedule({
    required String appointmentId,
  });

  /// Reject patient's reschedule request
  Future<Either<Failure, AppointmentEntity>> rejectReschedule({
    required String appointmentId,
    String? reason,
  });

  /// Complete an appointment
  Future<Either<Failure, AppointmentEntity>> completeAppointment({
    required String appointmentId,
    String? notes,
  });

  /// Get doctor's appointments
  Future<Either<Failure, List<AppointmentEntity>>> getDoctorAppointments({
    String? status,
    DateTime? date,
    int page = 1,
    int limit = 20,
  });

  /// Get appointment statistics
  Future<Either<Failure, AppointmentStatistics>> getAppointmentStatistics();

  // ============== Shared Operations ==============

  /// Get appointment details
  Future<Either<Failure, AppointmentEntity>> getAppointmentDetails({
    required String appointmentId,
  });
}

/// Statistics model for doctor dashboard
class AppointmentStatistics {
  final int totalAppointments;
  final int pendingCount;
  final int confirmedCount;
  final int completedCount;
  final int cancelledCount;
  final int todayAppointments;
  final int weekAppointments;

  const AppointmentStatistics({
    this.totalAppointments = 0,
    this.pendingCount = 0,
    this.confirmedCount = 0,
    this.completedCount = 0,
    this.cancelledCount = 0,
    this.todayAppointments = 0,
    this.weekAppointments = 0,
  });
}
