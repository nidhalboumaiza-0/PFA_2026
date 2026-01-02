import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/services/websocket_service.dart';
import '../../../domain/entities/appointment_entity.dart';
import '../../../domain/entities/document_entity.dart';
import '../../../domain/entities/time_slot_entity.dart';
import '../../../domain/usecases/patient/get_patient_appointments_usecase.dart';
import '../../../domain/usecases/patient/get_doctor_availability_usecase.dart';
import '../../../domain/usecases/patient/request_appointment_usecase.dart';
import '../../../domain/usecases/patient/cancel_appointment_usecase.dart';
import '../../../domain/usecases/patient/request_reschedule_usecase.dart';
import '../../../domain/usecases/patient/add_document_usecase.dart';

part 'patient_appointment_event.dart';
part 'patient_appointment_state.dart';

class PatientAppointmentBloc
    extends Bloc<PatientAppointmentEvent, PatientAppointmentState> {
  final GetPatientAppointmentsUseCase getPatientAppointmentsUseCase;
  final GetDoctorAvailabilityUseCase getDoctorAvailabilityUseCase;
  final RequestAppointmentUseCase requestAppointmentUseCase;
  final CancelAppointmentUseCase cancelAppointmentUseCase;
  final RequestRescheduleUseCase requestRescheduleUseCase;
  final AddDocumentToAppointmentUseCase addDocumentUseCase;
  final WebSocketService webSocketService;
  
  StreamSubscription<WebSocketEvent>? _webSocketSubscription;
  String? _currentFilter;

  PatientAppointmentBloc({
    required this.getPatientAppointmentsUseCase,
    required this.getDoctorAvailabilityUseCase,
    required this.requestAppointmentUseCase,
    required this.cancelAppointmentUseCase,
    required this.requestRescheduleUseCase,
    required this.addDocumentUseCase,
    required this.webSocketService,
  }) : super(PatientAppointmentInitial()) {
    on<LoadPatientAppointments>(_onLoadPatientAppointments);
    on<LoadDoctorAvailability>(_onLoadDoctorAvailability);
    on<RequestAppointment>(_onRequestAppointment);
    on<CancelPatientAppointment>(_onCancelAppointment);
    on<RequestPatientReschedule>(_onRequestReschedule);
    on<SelectDate>(_onSelectDate);
    on<SelectTimeSlot>(_onSelectTimeSlot);
    on<ClearBookingSelection>(_onClearBookingSelection);
    on<RefreshPatientAppointments>(_onRefreshPatientAppointments);
    
    // Subscribe to WebSocket events
    _subscribeToWebSocketEvents();
  }

  bool _lastWasDisconnected = false;

  void _log(String method, String message) {
    print('[PatientAppointmentBloc.$method] $message');
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
        case WebSocketEventType.appointmentUpdated:
        case WebSocketEventType.appointmentStatusChanged:
        case WebSocketEventType.appointmentConfirmed:
        case WebSocketEventType.appointmentRejected:
        case WebSocketEventType.appointmentCancelled:
        case WebSocketEventType.appointmentRescheduled:
        case WebSocketEventType.appointmentCompleted:
          // Refresh appointments when any relevant event occurs
          add(RefreshPatientAppointments(
            appointmentId: event.data?['appointmentId']?.toString(),
            eventType: event.type.name,
          ));
          break;
        case WebSocketEventType.connected:
          _log('_subscribeToWebSocketEvents', 'WebSocket connected, refreshing appointments');
          add(RefreshPatientAppointments(eventType: 'connected'));
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

  Future<void> _onRefreshPatientAppointments(
    RefreshPatientAppointments event,
    Emitter<PatientAppointmentState> emit,
  ) async {
    _log('_onRefreshPatientAppointments', 'Refreshing due to: ${event.eventType}');
    
    // Only refresh if we're in a loaded state
    final currentState = state;
    if (currentState is PatientAppointmentsLoaded) {
      final result = await getPatientAppointmentsUseCase(
        GetPatientAppointmentsParams(status: _currentFilter),
      );

      result.fold(
        (failure) => _log('_onRefreshPatientAppointments', 'Refresh failed: ${failure.message}'),
        (appointments) => emit(PatientAppointmentsLoaded(
          appointments: appointments,
          currentFilter: _currentFilter,
        )),
      );
    }
  }

  Future<void> _onLoadPatientAppointments(
    LoadPatientAppointments event,
    Emitter<PatientAppointmentState> emit,
  ) async {
    emit(PatientAppointmentsLoading());
    _currentFilter = event.status;

    final result = await getPatientAppointmentsUseCase(
      GetPatientAppointmentsParams(
        status: event.status,
        page: event.page,
        limit: event.limit,
      ),
    );

    result.fold(
      (failure) => emit(PatientAppointmentError(message: failure.message)),
      (appointments) => emit(PatientAppointmentsLoaded(
        appointments: appointments,
        currentFilter: event.status,
      )),
    );
  }

  Future<void> _onLoadDoctorAvailability(
    LoadDoctorAvailability event,
    Emitter<PatientAppointmentState> emit,
  ) async {
    emit(DoctorAvailabilityLoading());

    final result = await getDoctorAvailabilityUseCase(
      GetDoctorAvailabilityParams(
        doctorId: event.doctorId,
        startDate: event.startDate,
        endDate: event.endDate,
      ),
    );

    result.fold(
      (failure) => emit(PatientAppointmentError(message: failure.message)),
      (availability) => emit(DoctorAvailabilityLoaded(
        doctorId: event.doctorId,
        availability: availability,
        selectedDate: null,
        selectedTime: null,
      )),
    );
  }

  Future<void> _onRequestAppointment(
    RequestAppointment event,
    Emitter<PatientAppointmentState> emit,
  ) async {
    emit(AppointmentRequestLoading());

    final result = await requestAppointmentUseCase(
      RequestAppointmentParams(
        doctorId: event.doctorId,
        appointmentDate: event.appointmentDate,
        appointmentTime: event.appointmentTime,
        reason: event.reason,
        notes: event.notes,
      ),
    );

    result.fold(
      (failure) => emit(PatientAppointmentError(message: failure.message)),
      (appointment) {
        // If there are attachments, upload them to the appointment
        if (event.attachments.isNotEmpty) {
          _log('_onRequestAppointment', 'Uploading ${event.attachments.length} documents');
          _uploadAttachments(appointment.id, event.attachments);
        }
        emit(AppointmentRequestSuccess(appointment: appointment));
      },
    );
  }

  /// Upload document attachments to an appointment
  Future<void> _uploadAttachments(String appointmentId, List<PendingDocumentAttachment> attachments) async {
    for (final attachment in attachments) {
      try {
        final addResult = await addDocumentUseCase(
          AddDocumentParams(
            appointmentId: appointmentId,
            name: attachment.fileName,
            url: 'file://${attachment.localPath}',
            type: attachment.type,
            description: attachment.description,
          ),
        );
        addResult.fold(
          (failure) => _log('_uploadAttachments', 'Failed to upload ${attachment.fileName}: ${failure.message}'),
          (_) => _log('_uploadAttachments', 'Uploaded ${attachment.fileName} successfully'),
        );
      } catch (e) {
        _log('_uploadAttachments', 'Error uploading ${attachment.fileName}: $e');
      }
    }
  }

  Future<void> _onCancelAppointment(
    CancelPatientAppointment event,
    Emitter<PatientAppointmentState> emit,
  ) async {
    emit(AppointmentActionLoading());

    final result = await cancelAppointmentUseCase(
      CancelAppointmentParams(
        appointmentId: event.appointmentId,
        reason: event.reason,
      ),
    );

    result.fold(
      (failure) => emit(PatientAppointmentError(message: failure.message)),
      (appointment) => emit(AppointmentCancelled(appointment: appointment)),
    );
  }

  Future<void> _onRequestReschedule(
    RequestPatientReschedule event,
    Emitter<PatientAppointmentState> emit,
  ) async {
    emit(AppointmentActionLoading());

    final result = await requestRescheduleUseCase(
      RequestRescheduleParams(
        appointmentId: event.appointmentId,
        newDate: event.newDate,
        newTime: event.newTime,
        reason: event.reason,
      ),
    );

    result.fold(
      (failure) => emit(PatientAppointmentError(message: failure.message)),
      (appointment) =>
          emit(RescheduleRequestSent(appointment: appointment)),
    );
  }

  void _onSelectDate(
    SelectDate event,
    Emitter<PatientAppointmentState> emit,
  ) {
    final currentState = state;
    if (currentState is DoctorAvailabilityLoaded) {
      emit(currentState.copyWith(
        selectedDate: event.date,
        selectedTime: null, // Clear time when date changes
      ));
    }
  }

  void _onSelectTimeSlot(
    SelectTimeSlot event,
    Emitter<PatientAppointmentState> emit,
  ) {
    final currentState = state;
    if (currentState is DoctorAvailabilityLoaded) {
      emit(currentState.copyWith(selectedTime: event.time));
    }
  }

  void _onClearBookingSelection(
    ClearBookingSelection event,
    Emitter<PatientAppointmentState> emit,
  ) {
    final currentState = state;
    if (currentState is DoctorAvailabilityLoaded) {
      emit(currentState.copyWith(
        selectedDate: null,
        selectedTime: null,
      ));
    }
  }
}
