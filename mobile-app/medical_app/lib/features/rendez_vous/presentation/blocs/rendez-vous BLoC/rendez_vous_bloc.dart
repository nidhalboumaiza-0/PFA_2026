import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:medical_app/core/error/failures.dart';
import 'package:medical_app/features/authentication/domain/entities/medecin_entity.dart';
import 'package:medical_app/features/rendez_vous/domain/entities/rendez_vous_entity.dart';
import 'package:medical_app/features/rendez_vous/domain/usecases/create_rendez_vous_use_case.dart';
import 'package:medical_app/features/rendez_vous/domain/usecases/fetch_doctors_by_specialty_use_case.dart';
import 'package:medical_app/features/rendez_vous/domain/usecases/fetch_rendez_vous_use_case.dart';
import 'package:medical_app/features/rendez_vous/domain/usecases/update_rendez_vous_status_use_case.dart';
import 'package:medical_app/features/rendez_vous/domain/usecases/cancel_appointment_use_case.dart';
import 'package:medical_app/features/rendez_vous/domain/usecases/rate_doctor_use_case.dart';
import 'package:medical_app/features/rendez_vous/domain/usecases/get_doctor_appointments_for_day_use_case.dart';
import 'package:medical_app/features/rendez_vous/domain/usecases/accept_appointment_use_case.dart';
import 'package:medical_app/features/rendez_vous/domain/usecases/refuse_appointment_use_case.dart';
import 'package:medical_app/features/rendez_vous/domain/usecases/reschedule_appointment_use_case.dart';
import 'package:medical_app/features/rendez_vous/domain/usecases/request_reschedule_use_case.dart';
import 'package:medical_app/features/rendez_vous/domain/usecases/approve_reschedule_use_case.dart';
import 'package:medical_app/features/rendez_vous/domain/usecases/reject_reschedule_use_case.dart';
import 'package:medical_app/features/notifications/domain/entities/notification_entity.dart';
import 'package:medical_app/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:medical_app/features/notifications/presentation/bloc/notification_event.dart';

part 'rendez_vous_event.dart';
part 'rendez_vous_state.dart';

class RendezVousBloc extends Bloc<RendezVousEvent, RendezVousState> {
  final FetchRendezVousUseCase fetchRendezVousUseCase;
  final UpdateRendezVousStatusUseCase updateRendezVousStatusUseCase;
  final CreateRendezVousUseCase createRendezVousUseCase;
  final FetchDoctorsBySpecialtyUseCase fetchDoctorsBySpecialtyUseCase;
  final CancelAppointmentUseCase cancelAppointmentUseCase;
  final RateDoctorUseCase rateDoctorUseCase;
  final GetDoctorAppointmentsForDayUseCase getDoctorAppointmentsForDayUseCase;
  final AcceptAppointmentUseCase acceptAppointmentUseCase;
  final RefuseAppointmentUseCase refuseAppointmentUseCase;
  final RescheduleAppointmentUseCase rescheduleAppointmentUseCase;
  final RequestRescheduleUseCase requestRescheduleUseCase;
  final ApproveRescheduleUseCase approveRescheduleUseCase;
  final RejectRescheduleUseCase rejectRescheduleUseCase;
  final NotificationBloc? notificationBloc;

  RendezVousBloc({
    required this.fetchRendezVousUseCase,
    required this.updateRendezVousStatusUseCase,
    required this.createRendezVousUseCase,
    required this.fetchDoctorsBySpecialtyUseCase,
    required this.cancelAppointmentUseCase,
    required this.rateDoctorUseCase,
    required this.getDoctorAppointmentsForDayUseCase,
    required this.acceptAppointmentUseCase,
    required this.refuseAppointmentUseCase,
    required this.rescheduleAppointmentUseCase,
    required this.requestRescheduleUseCase,
    required this.approveRescheduleUseCase,
    required this.rejectRescheduleUseCase,
    this.notificationBloc,
  }) : super(RendezVousInitial()) {
    on<FetchRendezVous>(_onFetchRendezVous);
    on<UpdateRendezVousStatus>(_onUpdateRendezVousStatus);
    on<CreateRendezVous>(_onCreateRendezVous);
    on<FetchDoctorsBySpecialty>(_onFetchDoctorsBySpecialty);
    on<CancelAppointment>(_onCancelAppointment);
    on<RateDoctor>(_onRateDoctor);
    on<GetDoctorAppointmentsForDay>(_onGetDoctorAppointmentsForDay);
    on<AcceptAppointment>(_onAcceptAppointment);
    on<RefuseAppointment>(_onRefuseAppointment);
    on<RescheduleAppointment>(_onRescheduleAppointment);
    on<RequestReschedule>(_onRequestReschedule);
    on<ApproveReschedule>(_onApproveReschedule);
    on<RejectReschedule>(_onRejectReschedule);
  }

  Future<void> _onFetchRendezVous(
      FetchRendezVous event,
      Emitter<RendezVousState> emit,
      ) async {
    emit(RendezVousLoading());
    
    if (event.appointmentId != null) {
      try {
        // This would need to be updated to use the getRendezVousDetails use case
        emit(
          RendezVousError(
            'Direct appointment lookup by ID not implemented yet',
          ),
        );
      } catch (e) {
        emit(RendezVousError('Error fetching appointment: $e'));
      }
      return;
    }
    
    // Fetch appointments based on patient or doctor ID
    final failureOrRendezVous = await fetchRendezVousUseCase(
      patientId: event.patientId,
      doctorId: event.doctorId,
    );

    emit(
      failureOrRendezVous.fold(
          (failure) => RendezVousError(_mapFailureToMessage(failure)),
          (rendezVous) => RendezVousLoaded(rendezVous),
      ),
    );
  }

  Future<void> _onUpdateRendezVousStatus(
      UpdateRendezVousStatus event,
      Emitter<RendezVousState> emit,
      ) async {
    try {
      emit(UpdatingRendezVousState());
      
      // Update the status using the use case
      final failureOrUnit = await updateRendezVousStatusUseCase(
        rendezVousId: event.rendezVousId,
        status: event.status,
      );
      
      emit(
        failureOrUnit.fold(
            (failure) => RendezVousError(_mapFailureToMessage(failure)),
          (_) => RendezVousStatusUpdatedState(
            id: event.rendezVousId,
            status: event.status,
          ),
        ),
      );
    } catch (e) {
      emit(RendezVousErrorState(message: e.toString()));
    }
  }

  Future<void> _onCreateRendezVous(
      CreateRendezVous event,
      Emitter<RendezVousState> emit,
      ) async {
    try {
      emit(AddingRendezVousState());
      final result = await createRendezVousUseCase(event.rendezVous);
      
      result.fold(
        (failure) => emit(RendezVousErrorState(message: failure.message)),
        (_) {
          // Emit RendezVousCreated state for navigation in UI
          emit(RendezVousCreated());
        },
      );
    } catch (e) {
      emit(RendezVousErrorState(message: e.toString()));
    }
  }

  Future<void> _onFetchDoctorsBySpecialty(
      FetchDoctorsBySpecialty event,
      Emitter<RendezVousState> emit,
      ) async {
    emit(RendezVousLoading());
    final failureOrDoctors = await fetchDoctorsBySpecialtyUseCase(
      event.specialty,
      startDate: event.startDate,
      endDate: event.endDate,
    );
    emit(
      failureOrDoctors.fold(
          (failure) => RendezVousError(_mapFailureToMessage(failure)),
          (doctors) => DoctorsLoaded(doctors),
      ),
    );
  }

  Future<void> _onCancelAppointment(
    CancelAppointment event,
      Emitter<RendezVousState> emit,
      ) async {
    try {
      emit(UpdatingRendezVousState());

      final result = await cancelAppointmentUseCase(event.appointmentId);

    emit(
        result.fold(
          (failure) => RendezVousError(_mapFailureToMessage(failure)),
          (_) => AppointmentCancelled(event.appointmentId),
      ),
    );
    } catch (e) {
      emit(RendezVousErrorState(message: e.toString()));
    }
  }

  Future<void> _onRateDoctor(
    RateDoctor event,
    Emitter<RendezVousState> emit,
  ) async {
    try {
      emit(RatingDoctorState());

      final result = await rateDoctorUseCase(
        appointmentId: event.appointmentId,
        rating: event.rating,
      );

      emit(
        result.fold(
          (failure) => RendezVousError(_mapFailureToMessage(failure)),
          (_) => DoctorRated(event.appointmentId, event.rating),
        ),
      );
    } catch (e) {
      emit(RendezVousErrorState(message: e.toString()));
    }
  }

  Future<void> _onGetDoctorAppointmentsForDay(
    GetDoctorAppointmentsForDay event,
    Emitter<RendezVousState> emit,
  ) async {
    try {
      emit(RendezVousLoading());

      final result = await getDoctorAppointmentsForDayUseCase(
        doctorId: event.doctorId,
        date: event.date,
      );

      emit(
        result.fold(
          (failure) => RendezVousError(_mapFailureToMessage(failure)),
          (appointments) =>
              DoctorDailyAppointmentsLoaded(appointments, event.date),
        ),
      );
    } catch (e) {
      emit(RendezVousErrorState(message: e.toString()));
    }
  }

  Future<void> _onAcceptAppointment(
    AcceptAppointment event,
    Emitter<RendezVousState> emit,
  ) async {
    try {
      emit(UpdatingRendezVousState());

      final result = await acceptAppointmentUseCase(event.appointmentId);

      emit(
        result.fold(
          (failure) => RendezVousError(_mapFailureToMessage(failure)),
          (_) => AppointmentAccepted(event.appointmentId),
        ),
      );
    } catch (e) {
      emit(RendezVousErrorState(message: e.toString()));
    }
  }

  Future<void> _onRefuseAppointment(
    RefuseAppointment event,
    Emitter<RendezVousState> emit,
  ) async {
    try {
      emit(UpdatingRendezVousState());

      final result = await refuseAppointmentUseCase(event.appointmentId);

      emit(
        result.fold(
          (failure) => RendezVousError(_mapFailureToMessage(failure)),
          (_) => AppointmentRefused(event.appointmentId),
        ),
      );
    } catch (e) {
      emit(RendezVousErrorState(message: e.toString()));
    }
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return failure.message;
      case EmptyCacheFailure:
        return 'No cached data found';
      case OfflineFailure:
        return 'No internet connection';
      default:
        return 'Unexpected error';
    }
  }

  // Helper methods to send notifications
  void _sendNewAppointmentNotification(RendezVousEntity rendezVous) {
    if (notificationBloc != null &&
        rendezVous.patient.isNotEmpty &&
        rendezVous.medecin.isNotEmpty) {
      // Format date for better readability
      String formattedDate = rendezVous.startDate.toString().substring(0, 10);
      String formattedTime = _formatTime(rendezVous.startDate);

      // Create notification data
      Map<String, dynamic> notificationData = {
        'patientName': rendezVous.patientName ?? 'Unknown',
        'doctorName': rendezVous.medecinName ?? 'Unknown',
        'appointmentDate': formattedDate,
        'appointmentTime': formattedTime,
        'speciality': rendezVous.medecinSpeciality ?? '',
        'type': 'newAppointment',
        'senderId': rendezVous.patient,
        'recipientId': rendezVous.medecin,
        'appointmentId': rendezVous.id,
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      };

      // Send through NotificationBloc (uses backend notification-service)
      notificationBloc!.add(
        SendNotificationEvent(
          title: 'Nouveau rendez-vous',
          body:
              '${rendezVous.patientName ?? "Un patient"} a demandé un rendez-vous pour le $formattedDate à $formattedTime',
          senderId: rendezVous.patient,
          recipientId: rendezVous.medecin,
          type: NotificationType.newAppointment,
          appointmentId: rendezVous.id,
          data: notificationData,
        ),
      );

      print(
        'Sent notification for new appointment to doctor ${rendezVous.medecin}',
      );
    } else {
      print(
        'Could not send notification: ${notificationBloc == null ? "NotificationBloc is null" : "Missing patient or doctor ID"}',
      );
    }
  }

  // Helper method for time formatting
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _sendAppointmentAcceptedNotification(RendezVousEntity rendezVous) {
    if (notificationBloc != null &&
        rendezVous.patient.isNotEmpty &&
        rendezVous.medecin.isNotEmpty) {
      notificationBloc!.add(
        SendNotificationEvent(
          title: 'Appointment Accepted',
          body:
              'Dr. ${rendezVous.medecinName ?? "Unknown"} has accepted your appointment for ${rendezVous.startDate.toString().substring(0, 10)} at ${_formatTime(rendezVous.startDate)}',
          senderId: rendezVous.medecin,
          recipientId: rendezVous.patient,
          type: NotificationType.appointmentAccepted,
          appointmentId: rendezVous.id,
          data: {
            'doctorName': rendezVous.medecinName ?? 'Unknown',
            'patientName': rendezVous.patientName ?? 'Unknown',
            'appointmentDate': rendezVous.startDate.toString().substring(0, 10),
            'appointmentTime': _formatTime(rendezVous.startDate),
          },
        ),
      );
    }
  }

  void _sendAppointmentRejectedNotification(RendezVousEntity rendezVous) {
    if (notificationBloc != null &&
        rendezVous.patient.isNotEmpty &&
        rendezVous.medecin.isNotEmpty) {
      notificationBloc!.add(
        SendNotificationEvent(
          title: 'Appointment Rejected',
          body:
              'Dr. ${rendezVous.medecinName ?? "Unknown"} has rejected your appointment for ${rendezVous.startDate.toString().substring(0, 10)} at ${_formatTime(rendezVous.startDate)}',
          senderId: rendezVous.medecin,
          recipientId: rendezVous.patient,
          type: NotificationType.appointmentRejected,
          appointmentId: rendezVous.id,
          data: {
            'doctorName': rendezVous.medecinName ?? 'Unknown',
            'patientName': rendezVous.patientName ?? 'Unknown',
            'appointmentDate': rendezVous.startDate.toString().substring(0, 10),
            'appointmentTime': _formatTime(rendezVous.startDate),
          },
        ),
      );
    }
  }

  // ==================== RESCHEDULE EVENT HANDLERS ====================

  /// Doctor: Reschedule appointment directly
  Future<void> _onRescheduleAppointment(
    RescheduleAppointment event,
    Emitter<RendezVousState> emit,
  ) async {
    emit(ReschedulingAppointment());

    final result = await rescheduleAppointmentUseCase(
      appointmentId: event.appointmentId,
      newDate: event.newDate,
      newTime: event.newTime,
      reason: event.reason,
    );

    emit(
      result.fold(
        (failure) => RescheduleError(_mapFailureToMessage(failure)),
        (_) => AppointmentRescheduled(
          appointmentId: event.appointmentId,
          newDate: event.newDate,
          newTime: event.newTime,
        ),
      ),
    );
  }

  /// Patient: Request to reschedule (needs doctor approval)
  Future<void> _onRequestReschedule(
    RequestReschedule event,
    Emitter<RendezVousState> emit,
  ) async {
    emit(ReschedulingAppointment());

    final result = await requestRescheduleUseCase(
      appointmentId: event.appointmentId,
      newDate: event.newDate,
      newTime: event.newTime,
      reason: event.reason,
    );

    emit(
      result.fold(
        (failure) => RescheduleError(_mapFailureToMessage(failure)),
        (_) => RescheduleRequested(event.appointmentId),
      ),
    );
  }

  /// Doctor: Approve patient's reschedule request
  Future<void> _onApproveReschedule(
    ApproveReschedule event,
    Emitter<RendezVousState> emit,
  ) async {
    emit(ReschedulingAppointment());

    final result = await approveRescheduleUseCase(event.appointmentId);

    emit(
      result.fold(
        (failure) => RescheduleError(_mapFailureToMessage(failure)),
        (_) => RescheduleApproved(event.appointmentId),
      ),
    );
  }

  /// Doctor: Reject patient's reschedule request
  Future<void> _onRejectReschedule(
    RejectReschedule event,
    Emitter<RendezVousState> emit,
  ) async {
    emit(ReschedulingAppointment());

    final result = await rejectRescheduleUseCase(
      event.appointmentId,
      reason: event.reason,
    );

    emit(
      result.fold(
        (failure) => RescheduleError(_mapFailureToMessage(failure)),
        (_) => RescheduleRejected(event.appointmentId),
      ),
    );
  }
}
