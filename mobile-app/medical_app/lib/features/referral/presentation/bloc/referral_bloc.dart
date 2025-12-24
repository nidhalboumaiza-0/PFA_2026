import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medical_app/features/authentication/domain/entities/medecin_entity.dart';
import 'package:medical_app/features/referral/domain/entities/referral_entity.dart';
import 'package:medical_app/features/referral/domain/repositories/referral_repository.dart';

part 'referral_event.dart';
part 'referral_state.dart';

class ReferralBloc extends Bloc<ReferralEvent, ReferralState> {
  final ReferralRepository referralRepository;

  ReferralBloc({required this.referralRepository}) : super(const ReferralInitial()) {
    on<LoadSentReferralsEvent>(_onLoadSentReferrals);
    on<LoadReceivedReferralsEvent>(_onLoadReceivedReferrals);
    on<LoadMyReferralsEvent>(_onLoadMyReferrals);
    on<LoadReferralByIdEvent>(_onLoadReferralById);
    on<CreateReferralEvent>(_onCreateReferral);
    on<SearchSpecialistsEvent>(_onSearchSpecialists);
    on<BookAppointmentForReferralEvent>(_onBookAppointmentForReferral);
    on<AcceptReferralEvent>(_onAcceptReferral);
    on<RejectReferralEvent>(_onRejectReferral);
    on<CompleteReferralEvent>(_onCompleteReferral);
    on<CancelReferralEvent>(_onCancelReferral);
    on<LoadReferralStatisticsEvent>(_onLoadReferralStatistics);
    on<ClearReferralErrorEvent>(_onClearError);
    on<ClearReferralSuccessEvent>(_onClearSuccess);
  }

  Future<void> _onLoadSentReferrals(
    LoadSentReferralsEvent event,
    Emitter<ReferralState> emit,
  ) async {
    emit(const ReferralLoading());

    final result = await referralRepository.getSentReferrals(
      status: event.status,
      page: event.page,
      limit: event.limit,
    );

    result.fold(
      (failure) => emit(ReferralError(message: failure.message)),
      (referrals) => emit(SentReferralsLoaded(
        referrals: referrals,
        currentPage: event.page,
        hasMore: referrals.length >= event.limit,
      )),
    );
  }

  Future<void> _onLoadReceivedReferrals(
    LoadReceivedReferralsEvent event,
    Emitter<ReferralState> emit,
  ) async {
    emit(const ReferralLoading());

    final result = await referralRepository.getReceivedReferrals(
      status: event.status,
      page: event.page,
      limit: event.limit,
    );

    result.fold(
      (failure) => emit(ReferralError(message: failure.message)),
      (referrals) => emit(ReceivedReferralsLoaded(
        referrals: referrals,
        currentPage: event.page,
        hasMore: referrals.length >= event.limit,
      )),
    );
  }

  Future<void> _onLoadMyReferrals(
    LoadMyReferralsEvent event,
    Emitter<ReferralState> emit,
  ) async {
    emit(const ReferralLoading());

    final result = await referralRepository.getMyReferrals(
      status: event.status,
      page: event.page,
      limit: event.limit,
    );

    result.fold(
      (failure) => emit(ReferralError(message: failure.message)),
      (referrals) => emit(MyReferralsLoaded(
        referrals: referrals,
        currentPage: event.page,
        hasMore: referrals.length >= event.limit,
      )),
    );
  }

  Future<void> _onLoadReferralById(
    LoadReferralByIdEvent event,
    Emitter<ReferralState> emit,
  ) async {
    emit(const ReferralLoading());

    final result = await referralRepository.getReferralById(event.referralId);

    result.fold(
      (failure) => emit(ReferralError(message: failure.message)),
      (referral) => emit(ReferralDetailsLoaded(referral: referral)),
    );
  }

  Future<void> _onCreateReferral(
    CreateReferralEvent event,
    Emitter<ReferralState> emit,
  ) async {
    emit(const ReferralLoading());

    final result = await referralRepository.createReferral(
      targetDoctorId: event.targetDoctorId,
      patientId: event.patientId,
      reason: event.reason,
      specialty: event.specialty,
      urgency: event.urgency,
      diagnosis: event.diagnosis,
      symptoms: event.symptoms,
      relevantHistory: event.relevantHistory,
      currentMedications: event.currentMedications,
      specificConcerns: event.specificConcerns,
      attachedDocuments: event.attachedDocuments,
      includeFullHistory: event.includeFullHistory,
      preferredDates: event.preferredDates,
      referralNotes: event.referralNotes,
    );

    result.fold(
      (failure) => emit(ReferralError(message: failure.message)),
      (referral) => emit(ReferralCreated(referral: referral)),
    );
  }

  Future<void> _onSearchSpecialists(
    SearchSpecialistsEvent event,
    Emitter<ReferralState> emit,
  ) async {
    emit(const ReferralLoading());

    final result = await referralRepository.searchSpecialists(
      specialty: event.specialty,
      city: event.city,
      name: event.name,
    );

    result.fold(
      (failure) => emit(ReferralError(message: failure.message)),
      (specialists) => emit(SpecialistsLoaded(specialists: specialists)),
    );
  }

  Future<void> _onBookAppointmentForReferral(
    BookAppointmentForReferralEvent event,
    Emitter<ReferralState> emit,
  ) async {
    emit(const ReferralLoading());

    final result = await referralRepository.bookAppointmentForReferral(
      referralId: event.referralId,
      appointmentDate: event.appointmentDate,
      appointmentTime: event.appointmentTime,
      notes: event.notes,
    );

    result.fold(
      (failure) => emit(ReferralError(message: failure.message)),
      (_) => emit(const AppointmentBookedForReferral()),
    );
  }

  Future<void> _onAcceptReferral(
    AcceptReferralEvent event,
    Emitter<ReferralState> emit,
  ) async {
    emit(const ReferralLoading());

    final result = await referralRepository.acceptReferral(
      referralId: event.referralId,
      responseNotes: event.responseNotes,
    );

    result.fold(
      (failure) => emit(ReferralError(message: failure.message)),
      (referral) => emit(ReferralAccepted(referral: referral)),
    );
  }

  Future<void> _onRejectReferral(
    RejectReferralEvent event,
    Emitter<ReferralState> emit,
  ) async {
    emit(const ReferralLoading());

    final result = await referralRepository.rejectReferral(
      referralId: event.referralId,
      reason: event.reason,
    );

    result.fold(
      (failure) => emit(ReferralError(message: failure.message)),
      (referral) => emit(ReferralRejected(referral: referral)),
    );
  }

  Future<void> _onCompleteReferral(
    CompleteReferralEvent event,
    Emitter<ReferralState> emit,
  ) async {
    emit(const ReferralLoading());

    final result = await referralRepository.completeReferral(
      referralId: event.referralId,
      completionNotes: event.completionNotes,
    );

    result.fold(
      (failure) => emit(ReferralError(message: failure.message)),
      (referral) => emit(ReferralCompleted(referral: referral)),
    );
  }

  Future<void> _onCancelReferral(
    CancelReferralEvent event,
    Emitter<ReferralState> emit,
  ) async {
    emit(const ReferralLoading());

    final result = await referralRepository.cancelReferral(
      referralId: event.referralId,
      reason: event.reason,
    );

    result.fold(
      (failure) => emit(ReferralError(message: failure.message)),
      (referral) => emit(ReferralCancelled(referral: referral)),
    );
  }

  Future<void> _onLoadReferralStatistics(
    LoadReferralStatisticsEvent event,
    Emitter<ReferralState> emit,
  ) async {
    emit(const ReferralLoading());

    final result = await referralRepository.getReferralStatistics();

    result.fold(
      (failure) => emit(ReferralError(message: failure.message)),
      (statistics) => emit(ReferralStatisticsLoaded(statistics: statistics)),
    );
  }

  void _onClearError(
    ClearReferralErrorEvent event,
    Emitter<ReferralState> emit,
  ) {
    emit(const ReferralInitial());
  }

  void _onClearSuccess(
    ClearReferralSuccessEvent event,
    Emitter<ReferralState> emit,
  ) {
    emit(const ReferralInitial());
  }
}
