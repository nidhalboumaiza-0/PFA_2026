part of 'referral_bloc.dart';

abstract class ReferralEvent extends Equatable {
  const ReferralEvent();

  @override
  List<Object?> get props => [];
}

/// Load sent referrals (for referring doctor)
class LoadSentReferralsEvent extends ReferralEvent {
  final String? status;
  final int page;
  final int limit;

  const LoadSentReferralsEvent({
    this.status,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [status, page, limit];
}

/// Load received referrals (for target doctor)
class LoadReceivedReferralsEvent extends ReferralEvent {
  final String? status;
  final int page;
  final int limit;

  const LoadReceivedReferralsEvent({
    this.status,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [status, page, limit];
}

/// Load my referrals (for patient)
class LoadMyReferralsEvent extends ReferralEvent {
  final String? status;
  final int page;
  final int limit;

  const LoadMyReferralsEvent({
    this.status,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [status, page, limit];
}

/// Load referral by ID
class LoadReferralByIdEvent extends ReferralEvent {
  final String referralId;

  const LoadReferralByIdEvent({required this.referralId});

  @override
  List<Object?> get props => [referralId];
}

/// Create a new referral
class CreateReferralEvent extends ReferralEvent {
  final String targetDoctorId;
  final String patientId;
  final String reason;
  final String specialty;
  final String urgency;
  final String? diagnosis;
  final List<String>? symptoms;
  final String? relevantHistory;
  final String? currentMedications;
  final String? specificConcerns;
  final List<String>? attachedDocuments;
  final bool includeFullHistory;
  final List<DateTime>? preferredDates;
  final String? referralNotes;

  const CreateReferralEvent({
    required this.targetDoctorId,
    required this.patientId,
    required this.reason,
    required this.specialty,
    this.urgency = 'routine',
    this.diagnosis,
    this.symptoms,
    this.relevantHistory,
    this.currentMedications,
    this.specificConcerns,
    this.attachedDocuments,
    this.includeFullHistory = true,
    this.preferredDates,
    this.referralNotes,
  });

  @override
  List<Object?> get props => [
        targetDoctorId,
        patientId,
        reason,
        specialty,
        urgency,
        diagnosis,
        symptoms,
        relevantHistory,
        currentMedications,
        specificConcerns,
        attachedDocuments,
        includeFullHistory,
        preferredDates,
        referralNotes,
      ];
}

/// Search specialists for referral
class SearchSpecialistsEvent extends ReferralEvent {
  final String specialty;
  final String? city;
  final String? name;

  const SearchSpecialistsEvent({
    required this.specialty,
    this.city,
    this.name,
  });

  @override
  List<Object?> get props => [specialty, city, name];
}

/// Book appointment for referral
class BookAppointmentForReferralEvent extends ReferralEvent {
  final String referralId;
  final String appointmentDate;
  final String appointmentTime;
  final String? notes;

  const BookAppointmentForReferralEvent({
    required this.referralId,
    required this.appointmentDate,
    required this.appointmentTime,
    this.notes,
  });

  @override
  List<Object?> get props => [referralId, appointmentDate, appointmentTime, notes];
}

/// Accept referral (target doctor)
class AcceptReferralEvent extends ReferralEvent {
  final String referralId;
  final String? responseNotes;

  const AcceptReferralEvent({
    required this.referralId,
    this.responseNotes,
  });

  @override
  List<Object?> get props => [referralId, responseNotes];
}

/// Reject referral (target doctor)
class RejectReferralEvent extends ReferralEvent {
  final String referralId;
  final String reason;

  const RejectReferralEvent({
    required this.referralId,
    required this.reason,
  });

  @override
  List<Object?> get props => [referralId, reason];
}

/// Complete referral (target doctor)
class CompleteReferralEvent extends ReferralEvent {
  final String referralId;
  final String? completionNotes;

  const CompleteReferralEvent({
    required this.referralId,
    this.completionNotes,
  });

  @override
  List<Object?> get props => [referralId, completionNotes];
}

/// Cancel referral
class CancelReferralEvent extends ReferralEvent {
  final String referralId;
  final String reason;

  const CancelReferralEvent({
    required this.referralId,
    required this.reason,
  });

  @override
  List<Object?> get props => [referralId, reason];
}

/// Load referral statistics
class LoadReferralStatisticsEvent extends ReferralEvent {
  const LoadReferralStatisticsEvent();
}

/// Clear referral error
class ClearReferralErrorEvent extends ReferralEvent {
  const ClearReferralErrorEvent();
}

/// Clear success message
class ClearReferralSuccessEvent extends ReferralEvent {
  const ClearReferralSuccessEvent();
}
