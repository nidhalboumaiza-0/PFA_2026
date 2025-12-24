import 'package:dartz/dartz.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/authentication/domain/entities/medecin_entity.dart';
import 'package:medical_app/features/referral/domain/entities/referral_entity.dart';

/// Repository interface for referral operations
abstract class ReferralRepository {
  /// Create a new referral (referring doctor)
  Future<Either<Failure, ReferralEntity>> createReferral({
    required String targetDoctorId,
    required String patientId,
    required String reason,
    required String specialty,
    String urgency = 'routine',
    String? diagnosis,
    List<String>? symptoms,
    String? relevantHistory,
    String? currentMedications,
    String? specificConcerns,
    List<String>? attachedDocuments,
    bool includeFullHistory = true,
    List<DateTime>? preferredDates,
    String? referralNotes,
  });

  /// Get referral by ID
  Future<Either<Failure, ReferralEntity>> getReferralById(String referralId);

  /// Search specialists for referral (referring doctor)
  Future<Either<Failure, List<MedecinEntity>>> searchSpecialists({
    required String specialty,
    String? city,
    String? name,
  });

  /// Book appointment for referral (referring doctor)
  Future<Either<Failure, Unit>> bookAppointmentForReferral({
    required String referralId,
    required String appointmentDate,
    required String appointmentTime,
    String? notes,
  });

  /// Get sent referrals (referring doctor)
  Future<Either<Failure, List<ReferralEntity>>> getSentReferrals({
    String? status,
    int page = 1,
    int limit = 20,
  });

  /// Get received referrals (target doctor)
  Future<Either<Failure, List<ReferralEntity>>> getReceivedReferrals({
    String? status,
    int page = 1,
    int limit = 20,
  });

  /// Accept referral (target doctor)
  Future<Either<Failure, ReferralEntity>> acceptReferral({
    required String referralId,
    String? responseNotes,
  });

  /// Reject referral (target doctor)
  Future<Either<Failure, ReferralEntity>> rejectReferral({
    required String referralId,
    required String reason,
  });

  /// Complete referral (target doctor)
  Future<Either<Failure, ReferralEntity>> completeReferral({
    required String referralId,
    String? completionNotes,
  });

  /// Cancel referral (referring doctor or patient)
  Future<Either<Failure, ReferralEntity>> cancelReferral({
    required String referralId,
    required String reason,
  });

  /// Get my referrals (patient)
  Future<Either<Failure, List<ReferralEntity>>> getMyReferrals({
    String? status,
    int page = 1,
    int limit = 20,
  });

  /// Get referral statistics (doctor)
  Future<Either<Failure, Map<String, dynamic>>> getReferralStatistics();
}
