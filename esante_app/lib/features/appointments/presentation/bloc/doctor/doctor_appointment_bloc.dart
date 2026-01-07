import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../../../../core/services/websocket_service.dart';
import '../../../domain/entities/appointment_entity.dart';
import '../../../domain/entities/time_slot_entity.dart';
import '../../../domain/repositories/appointment_repository.dart';
import '../../../domain/usecases/doctor/get_doctor_appointments_usecase.dart';
import '../../../domain/usecases/doctor/get_appointment_requests_usecase.dart';
import '../../../domain/usecases/doctor/get_doctor_schedule_usecase.dart';
import '../../../domain/usecases/doctor/set_availability_usecase.dart';
import '../../../domain/usecases/doctor/bulk_set_availability_usecase.dart';
import '../../../domain/usecases/doctor/confirm_appointment_usecase.dart';
import '../../../domain/usecases/doctor/reject_appointment_usecase.dart';
import '../../../domain/usecases/doctor/complete_appointment_usecase.dart';
import '../../../domain/usecases/doctor/reschedule_appointment_usecase.dart';
import '../../../domain/usecases/doctor/get_appointment_statistics_usecase.dart';
import '../../../domain/usecases/doctor/referral_booking_usecase.dart';

part 'doctor_appointment_event.dart';
part 'doctor_appointment_state.dart';

class DoctorAppointmentBloc
    extends Bloc<DoctorAppointmentEvent, DoctorAppointmentState> {
  final GetDoctorAppointmentsUseCase getDoctorAppointmentsUseCase;
  final GetAppointmentRequestsUseCase getAppointmentRequestsUseCase;
  final GetDoctorScheduleUseCase getDoctorScheduleUseCase;
  final SetAvailabilityUseCase setAvailabilityUseCase;
  final BulkSetAvailabilityUseCase bulkSetAvailabilityUseCase;
  final ConfirmAppointmentUseCase confirmAppointmentUseCase;
  final RejectAppointmentUseCase rejectAppointmentUseCase;
  final CompleteAppointmentUseCase completeAppointmentUseCase;
  final RescheduleAppointmentUseCase rescheduleAppointmentUseCase;
  final GetAppointmentStatisticsUseCase getAppointmentStatisticsUseCase;
  final ReferralBookingUseCase referralBookingUseCase;
  final AppointmentRepository repository; // Keep for approve/reject reschedule
  final WebSocketService webSocketService;
  
  StreamSubscription<WebSocketEvent>? _webSocketSubscription;
  String? _currentFilter;
  DateTime? _currentDate;

  DoctorAppointmentBloc({
    required this.getDoctorAppointmentsUseCase,
    required this.getAppointmentRequestsUseCase,
    required this.getDoctorScheduleUseCase,
    required this.setAvailabilityUseCase,
    required this.bulkSetAvailabilityUseCase,
    required this.confirmAppointmentUseCase,
    required this.rejectAppointmentUseCase,
    required this.completeAppointmentUseCase,
    required this.rescheduleAppointmentUseCase,
    required this.getAppointmentStatisticsUseCase,
    required this.referralBookingUseCase,
    required this.repository,
    required this.webSocketService,
  }) : super(DoctorAppointmentInitial()) {
    on<LoadDoctorAppointments>(_onLoadDoctorAppointments);
    on<LoadAppointmentRequests>(_onLoadAppointmentRequests);
    on<LoadDoctorSchedule>(_onLoadDoctorSchedule);
    on<SetDoctorAvailability>(_onSetAvailability);
    on<BulkSetDoctorAvailability>(_onBulkSetAvailability);
    on<ConfirmAppointmentRequest>(_onConfirmAppointment);
    on<RejectAppointmentRequest>(_onRejectAppointment);
    on<CompleteAppointmentAction>(_onCompleteAppointment);
    on<RescheduleByDoctor>(_onRescheduleByDoctor);
    on<CancelByDoctor>(_onCancelByDoctor);
    on<ApprovePatientReschedule>(_onApproveReschedule);
    on<RejectPatientReschedule>(_onRejectReschedule);
    on<LoadAppointmentStatistics>(_onLoadStatistics);
    on<SelectScheduleDate>(_onSelectScheduleDate);
    on<RefreshDoctorAppointments>(_onRefreshDoctorAppointments);
    on<OnNewAppointmentRequest>(_onNewAppointmentRequest);
    on<BookReferralAppointment>(_onBookReferralAppointment);
    
    // Subscribe to WebSocket events
    _subscribeToWebSocketEvents();
  }

  bool _lastWasDisconnected = false;

  void _log(String method, String message) {
    print('[DoctorAppointmentBloc.$method] $message');
  }

  void _subscribeToWebSocketEvents() {
    _webSocketSubscription = webSocketService.eventStream.listen((event) {
      // Avoid spamming logs for repeated disconnection events
      if (event.type == WebSocketEventType.disconnected) {
        if (!_lastWasDisconnected) {
          _log('_subscribeToWebSocketEvents', 'WebSocket disconnected');
          _lastWasDisconnected = true;
        }
        return;
      }
      
      _lastWasDisconnected = false;
      _log('_subscribeToWebSocketEvents', 'Received WebSocket event: ${event.type}');
      
      switch (event.type) {
        case WebSocketEventType.newAppointmentRequest:
          // Handle new appointment request specifically
          add(OnNewAppointmentRequest(data: event.data));
          break;
        case WebSocketEventType.appointmentUpdated:
        case WebSocketEventType.appointmentStatusChanged:
        case WebSocketEventType.appointmentConfirmed:
        case WebSocketEventType.appointmentRejected:
        case WebSocketEventType.appointmentCancelled:
        case WebSocketEventType.appointmentRescheduled:
        case WebSocketEventType.appointmentCompleted:
          // Refresh appointments when any relevant event occurs
          add(RefreshDoctorAppointments(
            appointmentId: event.data?['appointmentId']?.toString(),
            eventType: event.type.name,
          ));
          break;
        case WebSocketEventType.connected:
          _log('_subscribeToWebSocketEvents', 'WebSocket connected, refreshing appointments');
          add(RefreshDoctorAppointments(eventType: 'connected'));
          break;
        default:
          break;
      }
    });
  }

  @override
  Future<void> close() {
    _webSocketSubscription?.cancel();
    return super.close();
  }

  Future<void> _onRefreshDoctorAppointments(
    RefreshDoctorAppointments event,
    Emitter<DoctorAppointmentState> emit,
  ) async {
    _log('_onRefreshDoctorAppointments', 'Refreshing due to: ${event.eventType}');
    
    // Only refresh if we're in a loaded state
    final currentState = state;
    if (currentState is DoctorAppointmentsLoaded) {
      final result = await getDoctorAppointmentsUseCase(
        GetDoctorAppointmentsParams(
          status: _currentFilter,
          date: _currentDate,
        ),
      );

      result.fold(
        (failure) => _log('_onRefreshDoctorAppointments', 'Refresh failed: ${failure.message}'),
        (appointments) => emit(DoctorAppointmentsLoaded(
          appointments: appointments,
          currentFilter: _currentFilter,
          selectedDate: _currentDate,
        )),
      );
    } else if (currentState is AppointmentRequestsLoaded) {
      // Also refresh requests if that's the current view
      final result = await getAppointmentRequestsUseCase(
        const GetAppointmentRequestsParams(),
      );
      result.fold(
        (failure) => _log('_onRefreshDoctorAppointments', 'Refresh failed: ${failure.message}'),
        (requests) => emit(AppointmentRequestsLoaded(requests: requests)),
      );
    }
  }

  Future<void> _onNewAppointmentRequest(
    OnNewAppointmentRequest event,
    Emitter<DoctorAppointmentState> emit,
  ) async {
    _log('_onNewAppointmentRequest', 'New appointment request received');
    
    // Always refresh statistics when new appointment comes in (for dashboard pending count)
    final statsResult = await getAppointmentStatisticsUseCase(const NoParams());
    statsResult.fold(
      (failure) => _log('_onNewAppointmentRequest', 'Stats refresh failed: ${failure.message}'),
      (stats) {
        _log('_onNewAppointmentRequest', 'Stats refreshed: pending=${stats.pendingCount}');
        emit(StatisticsLoaded(statistics: stats));
      },
    );
    
    // Also refresh appointment requests if we're on that view
    final currentState = state;
    if (currentState is AppointmentRequestsLoaded) {
      final result = await getAppointmentRequestsUseCase(
        const GetAppointmentRequestsParams(),
      );
      result.fold(
        (failure) => _log('_onNewAppointmentRequest', 'Refresh failed: ${failure.message}'),
        (requests) => emit(AppointmentRequestsLoaded(requests: requests)),
      );
    }
  }

  Future<void> _onLoadDoctorAppointments(
    LoadDoctorAppointments event,
    Emitter<DoctorAppointmentState> emit,
  ) async {
    emit(DoctorAppointmentsLoading());
    _currentFilter = event.status;
    _currentDate = event.date;

    final result = await getDoctorAppointmentsUseCase(
      GetDoctorAppointmentsParams(
        status: event.status,
        date: event.date,
        page: event.page,
        limit: event.limit,
      ),
    );

    result.fold(
      (failure) => emit(DoctorAppointmentError(message: failure.message)),
      (appointments) => emit(DoctorAppointmentsLoaded(
        appointments: appointments,
        currentFilter: event.status,
        selectedDate: event.date,
      )),
    );
  }

  Future<void> _onLoadAppointmentRequests(
    LoadAppointmentRequests event,
    Emitter<DoctorAppointmentState> emit,
  ) async {
    emit(AppointmentRequestsLoading());

    final result = await getAppointmentRequestsUseCase(
      GetAppointmentRequestsParams(
        page: event.page,
        limit: event.limit,
      ),
    );

    result.fold(
      (failure) => emit(DoctorAppointmentError(message: failure.message)),
      (requests) => emit(AppointmentRequestsLoaded(requests: requests)),
    );
  }

  Future<void> _onLoadDoctorSchedule(
    LoadDoctorSchedule event,
    Emitter<DoctorAppointmentState> emit,
  ) async {
    emit(DoctorScheduleLoading());

    final result = await getDoctorScheduleUseCase(
      GetDoctorScheduleParams(
        startDate: event.startDate,
        endDate: event.endDate,
      ),
    );

    result.fold(
      (failure) => emit(DoctorAppointmentError(message: failure.message)),
      (availability) => emit(DoctorScheduleLoaded(
        availability: availability,
        selectedDate: null,
        selectedSlots: [],
      )),
    );
  }

  Future<void> _onSetAvailability(
    SetDoctorAvailability event,
    Emitter<DoctorAppointmentState> emit,
  ) async {
    emit(AvailabilityActionLoading());

    final result = await setAvailabilityUseCase(
      SetAvailabilityParams(
        date: event.date,
        timeSlots: event.timeSlots,
        specialNotes: event.specialNotes,
      ),
    );

    result.fold(
      (failure) => emit(DoctorAppointmentError(message: failure.message)),
      (slot) => emit(AvailabilitySetSuccess(timeSlot: slot)),
    );
  }

  Future<void> _onBulkSetAvailability(
    BulkSetDoctorAvailability event,
    Emitter<DoctorAppointmentState> emit,
  ) async {
    emit(AvailabilityActionLoading());

    final result = await bulkSetAvailabilityUseCase(
      BulkSetAvailabilityParams(
        availabilities: event.availabilities,
        skipExisting: event.skipExisting,
      ),
    );

    result.fold(
      (failure) => emit(DoctorAppointmentError(message: failure.message)),
      (resultData) => emit(BulkAvailabilitySetSuccess(
        created: resultData['created'] ?? 0,
        updated: resultData['updated'] ?? 0,
        skipped: resultData['skipped'] ?? 0,
      )),
    );
  }

  Future<void> _onConfirmAppointment(
    ConfirmAppointmentRequest event,
    Emitter<DoctorAppointmentState> emit,
  ) async {
    emit(AppointmentActionLoading());

    final result = await confirmAppointmentUseCase(
      ConfirmAppointmentParams(appointmentId: event.appointmentId),
    );

    result.fold(
      (failure) => emit(DoctorAppointmentError(message: failure.message)),
      (appointment) => emit(AppointmentConfirmed(appointment: appointment)),
    );
  }

  Future<void> _onRejectAppointment(
    RejectAppointmentRequest event,
    Emitter<DoctorAppointmentState> emit,
  ) async {
    emit(AppointmentActionLoading());

    final result = await rejectAppointmentUseCase(
      RejectAppointmentParams(
        appointmentId: event.appointmentId,
        reason: event.reason,
      ),
    );

    result.fold(
      (failure) => emit(DoctorAppointmentError(message: failure.message)),
      (appointment) => emit(AppointmentRejected(appointment: appointment)),
    );
  }

  Future<void> _onCompleteAppointment(
    CompleteAppointmentAction event,
    Emitter<DoctorAppointmentState> emit,
  ) async {
    emit(AppointmentActionLoading());

    final result = await completeAppointmentUseCase(
      CompleteAppointmentParams(
        appointmentId: event.appointmentId,
        notes: event.notes,
      ),
    );

    result.fold(
      (failure) => emit(DoctorAppointmentError(message: failure.message)),
      (appointment) => emit(AppointmentCompleted(appointment: appointment)),
    );
  }

  Future<void> _onRescheduleByDoctor(
    RescheduleByDoctor event,
    Emitter<DoctorAppointmentState> emit,
  ) async {
    emit(AppointmentActionLoading());

    final result = await rescheduleAppointmentUseCase(
      RescheduleAppointmentParams(
        appointmentId: event.appointmentId,
        newDate: event.newDate,
        newTime: event.newTime,
        reason: event.reason,
      ),
    );

    result.fold(
      (failure) => emit(DoctorAppointmentError(message: failure.message)),
      (appointment) =>
          emit(AppointmentRescheduled(appointment: appointment)),
    );
  }

  Future<void> _onCancelByDoctor(
    CancelByDoctor event,
    Emitter<DoctorAppointmentState> emit,
  ) async {
    emit(AppointmentActionLoading());

    // Using repository directly - same cancel endpoint works for both roles
    final result = await repository.cancelAppointment(
      appointmentId: event.appointmentId,
      reason: event.reason,
    );

    result.fold(
      (failure) => emit(DoctorAppointmentError(message: failure.message)),
      (appointment) => emit(AppointmentCancelledByDoctor(appointment: appointment)),
    );
  }

  Future<void> _onApproveReschedule(
    ApprovePatientReschedule event,
    Emitter<DoctorAppointmentState> emit,
  ) async {
    emit(AppointmentActionLoading());

    // Using repository directly as this doesn't have a dedicated use case
    final result = await repository.approveReschedule(
      appointmentId: event.appointmentId,
    );

    result.fold(
      (failure) => emit(DoctorAppointmentError(message: failure.message)),
      (appointment) =>
          emit(RescheduleApproved(appointment: appointment)),
    );
  }

  Future<void> _onRejectReschedule(
    RejectPatientReschedule event,
    Emitter<DoctorAppointmentState> emit,
  ) async {
    emit(AppointmentActionLoading());

    // Using repository directly as this doesn't have a dedicated use case
    final result = await repository.rejectReschedule(
      appointmentId: event.appointmentId,
      reason: event.reason,
    );

    result.fold(
      (failure) => emit(DoctorAppointmentError(message: failure.message)),
      (appointment) =>
          emit(RescheduleRejected(appointment: appointment)),
    );
  }

  Future<void> _onLoadStatistics(
    LoadAppointmentStatistics event,
    Emitter<DoctorAppointmentState> emit,
  ) async {
    emit(StatisticsLoading());

    final result = await getAppointmentStatisticsUseCase(const NoParams());

    result.fold(
      (failure) => emit(DoctorAppointmentError(message: failure.message)),
      (stats) => emit(StatisticsLoaded(statistics: stats)),
    );
  }

  void _onSelectScheduleDate(
    SelectScheduleDate event,
    Emitter<DoctorAppointmentState> emit,
  ) {
    final currentState = state;
    if (currentState is DoctorScheduleLoaded) {
      emit(currentState.copyWith(
        selectedDate: event.date,
        selectedSlots: event.slots ?? [],
      ));
    }
  }

  Future<void> _onBookReferralAppointment(
    BookReferralAppointment event,
    Emitter<DoctorAppointmentState> emit,
  ) async {
    _log('_onBookReferralAppointment', 'Booking referral for patient ${event.patientId} with doctor ${event.specialistDoctorId}');
    emit(ReferralBookingLoading());

    final result = await referralBookingUseCase(
      ReferralBookingParams(
        patientId: event.patientId,
        specialistDoctorId: event.specialistDoctorId,
        appointmentDate: event.appointmentDate,
        appointmentTime: event.appointmentTime,
        reason: event.reason,
        referralId: event.referralId,
        notes: event.notes,
      ),
    );

    result.fold(
      (failure) {
        _log('_onBookReferralAppointment', 'Failed: ${failure.message}');
        emit(DoctorAppointmentError(message: failure.message));
      },
      (appointment) {
        _log('_onBookReferralAppointment', 'Success: ${appointment.id}');
        emit(ReferralBookingSuccess(appointment: appointment));
      },
    );
  }
}
