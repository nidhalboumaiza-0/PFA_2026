import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';

// Core
import 'core/network/api_client.dart';
import 'core/network/auth_interceptor.dart';
import 'core/storage/hive_storage_service.dart';
import 'core/services/websocket_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/messaging_socket_service.dart';

// Auth Feature
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/datasources/auth_local_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/forgot_password_usecase.dart';
import 'features/auth/domain/usecases/register_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

// Profile Feature
import 'features/profile/data/datasources/profile_remote_datasource.dart';
import 'features/profile/data/datasources/profile_local_datasource.dart';
import 'features/profile/data/repositories/profile_repository_impl.dart';
import 'features/profile/domain/repositories/profile_repository.dart';
import 'features/profile/domain/usecases/get_patient_profile_usecase.dart';
import 'features/profile/domain/usecases/update_patient_profile_usecase.dart';
import 'features/profile/domain/usecases/upload_profile_photo_usecase.dart';
import 'features/profile/domain/usecases/check_profile_completion_usecase.dart';
import 'features/profile/domain/usecases/get_doctor_profile_usecase.dart';
import 'features/profile/domain/usecases/update_doctor_profile_usecase.dart';
import 'features/profile/presentation/blocs/patient_profile/profile_bloc.dart';
import 'features/profile/presentation/blocs/patient_profile/patient_profile_bloc.dart';
import 'features/profile/presentation/blocs/doctor_profile/doctor_profile_bloc.dart';

// Doctors Feature
import 'features/doctors/data/datasources/doctor_remote_datasource.dart';
import 'features/doctors/data/datasources/review_remote_datasource.dart';
import 'features/doctors/data/repositories/doctor_repository_impl.dart';
import 'features/doctors/data/repositories/review_repository_impl.dart';
import 'features/doctors/domain/repositories/doctor_repository.dart';
import 'features/doctors/domain/repositories/review_repository.dart';
import 'features/doctors/domain/usecases/search_doctors_usecase.dart';
import 'features/doctors/domain/usecases/get_doctor_by_id_usecase.dart';
import 'features/doctors/domain/usecases/submit_review_usecase.dart';
import 'features/doctors/domain/usecases/get_doctor_reviews_usecase.dart';
import 'features/doctors/domain/usecases/get_appointment_review_usecase.dart';
import 'features/doctors/presentation/bloc/doctor_search/doctor_search_bloc.dart';

// Appointments Feature
import 'features/appointments/data/datasources/appointment_remote_datasource.dart';
import 'features/appointments/data/datasources/appointment_local_datasource.dart';
import 'features/appointments/data/repositories/appointment_repository_impl.dart';
import 'features/appointments/domain/repositories/appointment_repository.dart';
import 'features/appointments/domain/usecases/patient/get_patient_appointments_usecase.dart';
import 'features/appointments/domain/usecases/patient/get_doctor_availability_usecase.dart';
import 'features/appointments/domain/usecases/patient/request_appointment_usecase.dart';
import 'features/appointments/domain/usecases/patient/cancel_appointment_usecase.dart';
import 'features/appointments/domain/usecases/patient/request_reschedule_usecase.dart';
import 'features/appointments/domain/usecases/doctor/get_doctor_appointments_usecase.dart';
import 'features/appointments/domain/usecases/doctor/get_appointment_requests_usecase.dart';
import 'features/appointments/domain/usecases/doctor/get_doctor_schedule_usecase.dart';
import 'features/appointments/domain/usecases/doctor/set_availability_usecase.dart';
import 'features/appointments/domain/usecases/doctor/bulk_set_availability_usecase.dart';
import 'features/appointments/domain/usecases/doctor/confirm_appointment_usecase.dart';
import 'features/appointments/domain/usecases/doctor/reject_appointment_usecase.dart';
import 'features/appointments/domain/usecases/doctor/complete_appointment_usecase.dart';
import 'features/appointments/domain/usecases/doctor/reschedule_appointment_usecase.dart';
import 'features/appointments/domain/usecases/doctor/get_appointment_statistics_usecase.dart';
import 'features/appointments/domain/usecases/doctor/referral_booking_usecase.dart';
import 'features/appointments/domain/usecases/patient/add_document_usecase.dart';
import 'features/appointments/presentation/bloc/patient/patient_appointment_bloc.dart';
import 'features/appointments/presentation/bloc/doctor/doctor_appointment_bloc.dart';

// Prescriptions Feature
import 'features/prescriptions/data/datasources/prescription_remote_data_source.dart';
import 'features/prescriptions/data/repositories/prescription_repository_impl.dart';
import 'features/prescriptions/domain/repositories/prescription_repository.dart';
import 'features/prescriptions/domain/usecases/create_prescription.dart';
import 'features/prescriptions/domain/usecases/get_my_prescriptions.dart';
import 'features/prescriptions/domain/usecases/get_prescription_by_id.dart';
import 'features/prescriptions/presentation/bloc/prescription_bloc.dart';

// Messaging Feature
import 'features/messaging/data/datasources/messaging_remote_datasource.dart';
import 'features/messaging/data/repositories/messaging_repository_impl.dart';
import 'features/messaging/domain/repositories/messaging_repository.dart';
import 'features/messaging/domain/usecases/get_conversations_usecase.dart';
import 'features/messaging/domain/usecases/get_messages_usecase.dart';
import 'features/messaging/domain/usecases/create_conversation_usecase.dart';
import 'features/messaging/domain/usecases/mark_messages_read_usecase.dart';
import 'features/messaging/domain/usecases/send_file_message_usecase.dart';
import 'features/messaging/domain/usecases/get_unread_count_usecase.dart';
import 'features/messaging/presentation/bloc/messaging_bloc.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  print('[DI] Initializing dependencies...');
  
  // ============== Storage ==============
  print('[DI] Initializing Hive storage...');
  await HiveStorageService.init();

  // ============== Connectivity Service ==============
  print('[DI] Initializing connectivity service...');
  final connectivityService = ConnectivityService();
  await connectivityService.init();
  sl.registerLazySingleton<ConnectivityService>(() => connectivityService);

  // ============== External ==============
  sl.registerLazySingleton<Dio>(() {
    final dio = Dio(BaseOptions(
      baseUrl: 'http://10.0.2.2:3000', // Android emulator localhost
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add auth interceptor FIRST to attach token before logging
    dio.interceptors.add(AuthInterceptor());
    
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));

    return dio;
  });

  // ============== Core ==============
  sl.registerLazySingleton<ApiClient>(() => ApiClient(dio: sl()));

  // ============== Core Services ==============
  print('[DI] Registering Core services...');
  
  // WebSocket Service (Singleton) - for notifications
  sl.registerLazySingleton<WebSocketService>(() => WebSocketService());
  
  // Messaging Socket Service (Singleton) - for real-time messaging
  sl.registerLazySingleton<MessagingSocketService>(() => MessagingSocketService());

  // ============== Auth Feature ==============

  // Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(),
  );

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      webSocketService: sl(),
      messagingSocketService: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => ForgotPasswordUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));

  // Bloc
  sl.registerFactory(() => AuthBloc(
        loginUseCase: sl(),
        forgotPasswordUseCase: sl(),
        registerUseCase: sl(),
        logoutUseCase: sl(),
      ));

  // ============== Profile Feature ==============
  print('[DI] Registering Profile feature...');

  // Data Sources
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(
      apiClient: sl(),
      dio: sl(),
    ),
  );
  sl.registerLazySingleton<ProfileLocalDataSource>(
    () => ProfileLocalDataSourceImpl(),
  );

  // Repository
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );

  // Patient Profile Use Cases
  sl.registerLazySingleton(() => GetPatientProfileUseCase(sl()));
  sl.registerLazySingleton(() => UpdatePatientProfileUseCase(sl()));
  sl.registerLazySingleton(() => UploadProfilePhotoUseCase(sl()));
  sl.registerLazySingleton(() => CheckProfileCompletionUseCase(sl()));
  sl.registerLazySingleton(() => MarkProfileCompletionShownUseCase(sl()));

  // Doctor Profile Use Cases
  sl.registerLazySingleton(() => GetDoctorProfileUseCase(sl()));
  sl.registerLazySingleton(() => UpdateDoctorProfileUseCase(sl()));

  // Patient Profile Bloc (original)
  sl.registerFactory(() => ProfileBloc(
        getPatientProfileUseCase: sl(),
        updatePatientProfileUseCase: sl(),
        uploadProfilePhotoUseCase: sl(),
      ));

  // Patient Profile Bloc (used in dashboard)
  sl.registerFactory(() => PatientProfileBloc(
        getPatientProfileUseCase: sl(),
        updatePatientProfileUseCase: sl(),
        uploadProfilePhotoUseCase: sl(),
      ));

  // Doctor Profile Bloc
  sl.registerFactory(() => DoctorProfileBloc(
        getDoctorProfileUseCase: sl(),
        updateDoctorProfileUseCase: sl(),
        uploadProfilePhotoUseCase: sl(),
      ));

  // ============== Doctors Feature ==============
  print('[DI] Registering Doctors feature...');

  // Data Sources
  sl.registerLazySingleton<DoctorRemoteDataSource>(
    () => DoctorRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<ReviewRemoteDataSource>(
    () => ReviewRemoteDataSourceImpl(apiClient: sl()),
  );

  // Repository
  sl.registerLazySingleton<DoctorRepository>(
    () => DoctorRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<ReviewRepository>(
    () => ReviewRepositoryImpl(remoteDataSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => SearchDoctorsUseCase(sl()));
  sl.registerLazySingleton(() => GetDoctorByIdUseCase(sl()));
  sl.registerLazySingleton(() => SubmitReviewUseCase(sl()));
  sl.registerLazySingleton(() => GetDoctorReviewsUseCase(sl()));
  sl.registerLazySingleton(() => GetAppointmentReviewUseCase(sl()));

  // Bloc
  sl.registerFactory(() => DoctorSearchBloc(
        searchDoctorsUseCase: sl(),
      ));

  // ============== Appointments Feature ==============
  print('[DI] Registering Appointments feature...');

  // Data Sources
  sl.registerLazySingleton<AppointmentRemoteDataSource>(
    () => AppointmentRemoteDataSourceImpl(apiClient: sl()),
  );
  
  // Local Data Source - async initialization handled internally
  final appointmentLocalDataSource = AppointmentLocalDataSourceImpl();
  await appointmentLocalDataSource.init();
  sl.registerLazySingleton<AppointmentLocalDataSource>(
    () => appointmentLocalDataSource,
  );

  // Repository
  sl.registerLazySingleton<AppointmentRepository>(
    () => AppointmentRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );

  // Patient Use Cases
  sl.registerLazySingleton(() => GetPatientAppointmentsUseCase(sl()));
  sl.registerLazySingleton(() => GetDoctorAvailabilityUseCase(sl()));
  sl.registerLazySingleton(() => RequestAppointmentUseCase(sl()));
  sl.registerLazySingleton(() => CancelAppointmentUseCase(sl()));
  sl.registerLazySingleton(() => RequestRescheduleUseCase(sl()));

  // Doctor Use Cases
  sl.registerLazySingleton(() => GetDoctorAppointmentsUseCase(sl()));
  sl.registerLazySingleton(() => GetAppointmentRequestsUseCase(sl()));
  sl.registerLazySingleton(() => GetDoctorScheduleUseCase(sl()));
  sl.registerLazySingleton(() => SetAvailabilityUseCase(sl()));
  sl.registerLazySingleton(() => BulkSetAvailabilityUseCase(sl()));
  sl.registerLazySingleton(() => ConfirmAppointmentUseCase(sl()));
  sl.registerLazySingleton(() => RejectAppointmentUseCase(sl()));
  sl.registerLazySingleton(() => CompleteAppointmentUseCase(sl()));
  sl.registerLazySingleton(() => RescheduleAppointmentUseCase(sl()));
  sl.registerLazySingleton(() => GetAppointmentStatisticsUseCase(sl()));
  sl.registerLazySingleton(() => ReferralBookingUseCase(sl()));
  sl.registerLazySingleton(() => AddDocumentToAppointmentUseCase(sl()));

  // Patient Appointment Bloc (Singleton for WebSocket real-time updates)
  sl.registerLazySingleton(() => PatientAppointmentBloc(
    getPatientAppointmentsUseCase: sl(),
    getDoctorAvailabilityUseCase: sl(),
    requestAppointmentUseCase: sl(),
    cancelAppointmentUseCase: sl(),
    requestRescheduleUseCase: sl(),
    addDocumentUseCase: sl(),
    webSocketService: sl(),
  ));

  // Doctor Appointment Bloc (Singleton for WebSocket real-time updates)
  sl.registerLazySingleton(() => DoctorAppointmentBloc(
    getDoctorAppointmentsUseCase: sl(),
    getAppointmentRequestsUseCase: sl(),
    getDoctorScheduleUseCase: sl(),
    setAvailabilityUseCase: sl(),
    bulkSetAvailabilityUseCase: sl(),
    confirmAppointmentUseCase: sl(),
    rejectAppointmentUseCase: sl(),
    completeAppointmentUseCase: sl(),
    rescheduleAppointmentUseCase: sl(),
    getAppointmentStatisticsUseCase: sl(),
    referralBookingUseCase: sl(),
    repository: sl(), // For approve/reject reschedule operations
    webSocketService: sl(),
  ));

  // ============== Prescriptions Feature ==============
  print('[DI] Registering Prescriptions dependencies...');

  // Data Sources
  sl.registerLazySingleton<PrescriptionRemoteDataSource>(
    () => PrescriptionRemoteDataSourceImpl(apiClient: sl()),
  );

  // Repositories
  sl.registerLazySingleton<PrescriptionRepository>(
    () => PrescriptionRepositoryImpl(remoteDataSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetMyPrescriptionsUseCase(sl()));
  sl.registerLazySingleton(() => GetPrescriptionByIdUseCase(sl()));
  sl.registerLazySingleton(() => CreatePrescriptionUseCase(sl()));

  // Bloc (Factory - new instance per screen)
  sl.registerFactory(() => PrescriptionBloc(
    getMyPrescriptionsUseCase: sl(),
    getPrescriptionByIdUseCase: sl(),
    createPrescriptionUseCase: sl(),
  ));

  // ============== Messaging Feature ==============
  print('[DI] Registering Messaging dependencies...');

  // Data Sources
  sl.registerLazySingleton<MessagingRemoteDataSource>(
    () => MessagingRemoteDataSourceImpl(sl()),
  );

  // Repositories
  sl.registerLazySingleton<MessagingRepository>(
    () => MessagingRepositoryImpl(remoteDataSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetConversationsUseCase(sl()));
  sl.registerLazySingleton(() => GetMessagesUseCase(sl()));
  sl.registerLazySingleton(() => CreateConversationUseCase(sl()));
  sl.registerLazySingleton(() => MarkMessagesReadUseCase(sl()));
  sl.registerLazySingleton(() => SendFileMessageUseCase(sl()));
  sl.registerLazySingleton(() => GetUnreadCountUseCase(sl()));

  // Bloc (Factory - new instance per screen for independent state)
  sl.registerFactory(() => MessagingBloc(
    getConversationsUseCase: sl(),
    getMessagesUseCase: sl(),
    createConversationUseCase: sl(),
    markMessagesReadUseCase: sl(),
    sendFileMessageUseCase: sl(),
    getUnreadCountUseCase: sl(),
    messagingSocketService: sl<MessagingSocketService>(),
  ));
  
  print('[DI] All dependencies initialized successfully');
}
