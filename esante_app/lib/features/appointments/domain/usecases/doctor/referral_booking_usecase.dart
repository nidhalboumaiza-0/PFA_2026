import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../entities/appointment_entity.dart';
import '../../repositories/appointment_repository.dart';

/// Use case for doctors to book referral appointments for their patients
/// with specialist doctors
class ReferralBookingUseCase
    implements UseCase<AppointmentEntity, ReferralBookingParams> {
  final AppointmentRepository repository;

  ReferralBookingUseCase(this.repository);

  @override
  Future<Either<Failure, AppointmentEntity>> call(
      ReferralBookingParams params) {
    return repository.referralBooking(
      patientId: params.patientId,
      specialistDoctorId: params.specialistDoctorId,
      appointmentDate: params.appointmentDate,
      appointmentTime: params.appointmentTime,
      reason: params.reason,
      referralId: params.referralId,
      notes: params.notes,
    );
  }
}

/// Parameters for referral booking
class ReferralBookingParams extends Equatable {
  /// The patient being referred
  final String patientId;

  /// The specialist doctor to book with
  final String specialistDoctorId;

  /// Appointment date
  final DateTime appointmentDate;

  /// Appointment time slot
  final String appointmentTime;

  /// Reason for referral/appointment
  final String reason;

  /// Optional: ID of the referral document (if created via referral-service)
  final String? referralId;

  /// Additional notes for the specialist
  final String? notes;

  const ReferralBookingParams({
    required this.patientId,
    required this.specialistDoctorId,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.reason,
    this.referralId,
    this.notes,
  });

  @override
  List<Object?> get props => [
        patientId,
        specialistDoctorId,
        appointmentDate,
        appointmentTime,
        reason,
        referralId,
        notes,
      ];
}
