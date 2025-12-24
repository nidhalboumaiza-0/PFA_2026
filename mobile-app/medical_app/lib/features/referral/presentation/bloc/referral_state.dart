part of 'referral_bloc.dart';

abstract class ReferralState extends Equatable {
  const ReferralState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ReferralInitial extends ReferralState {
  const ReferralInitial();
}

/// Loading state
class ReferralLoading extends ReferralState {
  const ReferralLoading();
}

/// Sent referrals loaded (for referring doctor)
class SentReferralsLoaded extends ReferralState {
  final List<ReferralEntity> referrals;
  final int currentPage;
  final bool hasMore;

  const SentReferralsLoaded({
    required this.referrals,
    this.currentPage = 1,
    this.hasMore = true,
  });

  @override
  List<Object?> get props => [referrals, currentPage, hasMore];
}

/// Received referrals loaded (for target doctor)
class ReceivedReferralsLoaded extends ReferralState {
  final List<ReferralEntity> referrals;
  final int currentPage;
  final bool hasMore;

  const ReceivedReferralsLoaded({
    required this.referrals,
    this.currentPage = 1,
    this.hasMore = true,
  });

  @override
  List<Object?> get props => [referrals, currentPage, hasMore];
}

/// My referrals loaded (for patient)
class MyReferralsLoaded extends ReferralState {
  final List<ReferralEntity> referrals;
  final int currentPage;
  final bool hasMore;

  const MyReferralsLoaded({
    required this.referrals,
    this.currentPage = 1,
    this.hasMore = true,
  });

  @override
  List<Object?> get props => [referrals, currentPage, hasMore];
}

/// Single referral loaded
class ReferralDetailsLoaded extends ReferralState {
  final ReferralEntity referral;

  const ReferralDetailsLoaded({required this.referral});

  @override
  List<Object?> get props => [referral];
}

/// Referral created successfully
class ReferralCreated extends ReferralState {
  final ReferralEntity referral;

  const ReferralCreated({required this.referral});

  @override
  List<Object?> get props => [referral];
}

/// Specialists loaded for selection
class SpecialistsLoaded extends ReferralState {
  final List<MedecinEntity> specialists;

  const SpecialistsLoaded({required this.specialists});

  @override
  List<Object?> get props => [specialists];
}

/// Appointment booked for referral
class AppointmentBookedForReferral extends ReferralState {
  const AppointmentBookedForReferral();
}

/// Referral accepted
class ReferralAccepted extends ReferralState {
  final ReferralEntity referral;

  const ReferralAccepted({required this.referral});

  @override
  List<Object?> get props => [referral];
}

/// Referral rejected
class ReferralRejected extends ReferralState {
  final ReferralEntity referral;

  const ReferralRejected({required this.referral});

  @override
  List<Object?> get props => [referral];
}

/// Referral completed
class ReferralCompleted extends ReferralState {
  final ReferralEntity referral;

  const ReferralCompleted({required this.referral});

  @override
  List<Object?> get props => [referral];
}

/// Referral cancelled
class ReferralCancelled extends ReferralState {
  final ReferralEntity referral;

  const ReferralCancelled({required this.referral});

  @override
  List<Object?> get props => [referral];
}

/// Statistics loaded
class ReferralStatisticsLoaded extends ReferralState {
  final Map<String, dynamic> statistics;

  const ReferralStatisticsLoaded({required this.statistics});

  @override
  List<Object?> get props => [statistics];
}

/// Operation success with message
class ReferralOperationSuccess extends ReferralState {
  final String message;

  const ReferralOperationSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Error state
class ReferralError extends ReferralState {
  final String message;

  const ReferralError({required this.message});

  @override
  List<Object?> get props => [message];
}
