import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:medical_app/core/network/network_info.dart';
import 'package:medical_app/core/services/api_service.dart';
import 'package:medical_app/core/utils/constants.dart';
import 'package:medical_app/cubit/theme_cubit/theme_cubit.dart';
import 'package:medical_app/cubit/toggle%20cubit/toggle_cubit.dart';
import 'package:medical_app/features/authentication/data/data%20sources/auth_local_data_source.dart';
import 'package:medical_app/features/authentication/data/data%20sources/auth_remote_data_source.dart';
import 'package:medical_app/core/network/authenticated_http_client.dart';
import 'package:medical_app/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:medical_app/features/authentication/domain/repositories/auth_repository.dart';
import 'package:medical_app/features/authentication/domain/usecases/create_account_use_case.dart';
// import 'package:medical_app/features/authentication/domain/usecases/send_verification_code_use_case.dart'; // DISABLED - deprecated
import 'package:medical_app/features/authentication/domain/usecases/change_password_use_case.dart';
import 'package:medical_app/features/authentication/domain/usecases/login_usecase.dart';
  // import 'package:medical_app/features/authentication/domain/usecases/update_user_use_case.dart'; // MOVED to profile feature
// import 'package:medical_app/features/authentication/domain/usecases/verify_code_use_case.dart'; // DISABLED - deprecated
import 'package:medical_app/features/authentication/domain/usecases/verify_email_use_case.dart';
import 'package:medical_app/features/authentication/domain/usecases/forgot_password_use_case.dart';
import 'package:medical_app/features/authentication/domain/usecases/logout_use_case.dart';
import 'package:medical_app/features/authentication/presentation/blocs/logout_bloc/logout_bloc.dart';
import 'package:medical_app/features/profile/data/datasources/user_remote_data_source.dart';
import 'package:medical_app/features/profile/data/repositories/user_repository_impl.dart';
import 'package:medical_app/features/profile/domain/repositories/user_repository.dart';
import 'package:medical_app/features/profile/domain/usecases/get_user_profile_use_case.dart';
import 'package:medical_app/features/profile/domain/usecases/update_user_use_case.dart';
import 'package:medical_app/features/authentication/presentation/blocs/Signup%20BLoC/signup_bloc.dart';
import 'package:medical_app/features/authentication/presentation/blocs/login%20BLoC/login_bloc.dart';
import 'package:medical_app/features/messagerie/data/data_sources/message_local_datasource.dart';

// New Messagerie Feature imports
import 'package:medical_app/features/messagerie/data/data_sources/conversation_api_data_source.dart';
import 'package:medical_app/features/messagerie/data/data_sources/socket_service.dart';
import 'package:medical_app/features/messagerie/data/repositories/conversation_repository_impl.dart';
import 'package:medical_app/features/messagerie/domain/repositories/conversation_repository.dart';
import 'package:medical_app/features/messagerie/domain/use_cases/connect_to_socket.dart';
import 'package:medical_app/features/messagerie/domain/use_cases/get_conversations.dart';
import 'package:medical_app/features/messagerie/domain/use_cases/get_messages.dart';
import 'package:medical_app/features/messagerie/domain/use_cases/mark_messages_as_read.dart';
import 'package:medical_app/features/messagerie/domain/use_cases/send_message.dart';
import 'package:medical_app/features/messagerie/presentation/blocs/conversation/conversation_bloc.dart';
import 'package:medical_app/features/messagerie/presentation/blocs/message/message_bloc.dart';
import 'package:medical_app/features/messagerie/presentation/blocs/online_status/online_status_cubit.dart';
import 'package:medical_app/features/messagerie/presentation/blocs/socket/socket_bloc.dart';
import 'package:medical_app/features/authentication/domain/usecases/get_current_user_use_case.dart';

import 'package:medical_app/features/rendez_vous/data/data%20sources/rdv_local_data_source.dart';
import 'package:medical_app/features/rendez_vous/data/data%20sources/rdv_remote_data_source.dart';
import 'package:medical_app/features/rendez_vous/data/repositories/rendez_vous_repository_impl.dart';
import 'package:medical_app/features/rendez_vous/domain/repositories/rendez_vous_repository.dart';
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
import 'package:medical_app/features/rendez_vous/presentation/blocs/rendez-vous%20BLoC/rendez_vous_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/authentication/presentation/blocs/forget password bloc/forgot_password_bloc.dart';
import 'features/authentication/presentation/blocs/reset password bloc/reset_password_bloc.dart';
import 'package:medical_app/features/authentication/domain/usecases/reset_password_use_case.dart';
// import 'features/authentication/presentation/blocs/verify code bloc/verify_code_bloc.dart'; // DISABLED
import 'features/profile/presentation/pages/blocs/BLoC update profile/update_user_bloc.dart';
import 'package:medical_app/features/ratings/data/datasources/rating_remote_datasource.dart';
import 'package:medical_app/features/ratings/data/repositories/rating_repository_impl.dart';
import 'package:medical_app/features/ratings/domain/repositories/rating_repository.dart';
import 'package:medical_app/features/ratings/domain/usecases/submit_doctor_rating_use_case.dart';
import 'package:medical_app/features/ratings/domain/usecases/has_patient_rated_appointment_use_case.dart';
import 'package:medical_app/features/ratings/presentation/bloc/rating_bloc.dart';
import 'package:medical_app/features/ratings/domain/usecases/get_doctor_ratings_use_case.dart';
import 'package:medical_app/features/ratings/domain/usecases/get_doctor_average_rating_use_case.dart';
import 'package:medical_app/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:medical_app/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:medical_app/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:medical_app/features/dashboard/domain/usecases/get_doctor_dashboard_stats_use_case.dart';
import 'package:medical_app/features/dashboard/domain/usecases/get_upcoming_appointments_use_case.dart';
import 'package:medical_app/features/dashboard/presentation/blocs/dashboard%20BLoC/dashboard_bloc.dart';
import 'package:medical_app/features/ordonnance/data/datasources/prescription_remote_datasource.dart';
import 'package:medical_app/features/ordonnance/data/repositories/prescription_repository_impl.dart';
import 'package:medical_app/features/ordonnance/domain/repositories/prescription_repository.dart';
import 'package:medical_app/features/ordonnance/domain/usecases/create_prescription_use_case.dart';
import 'package:medical_app/features/ordonnance/domain/usecases/edit_prescription_use_case.dart';
import 'package:medical_app/features/ordonnance/domain/usecases/get_doctor_prescriptions_use_case.dart';
import 'package:medical_app/features/ordonnance/domain/usecases/get_patient_prescriptions_use_case.dart';
import 'package:medical_app/features/ordonnance/domain/usecases/get_prescription_by_appointment_id_use_case.dart';
import 'package:medical_app/features/ordonnance/domain/usecases/get_prescription_by_id_use_case.dart';
import 'package:medical_app/features/ordonnance/domain/usecases/update_prescription_status_use_case.dart';
import 'package:medical_app/features/ordonnance/presentation/bloc/prescription_bloc.dart';
import 'package:medical_app/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:medical_app/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:medical_app/features/notifications/domain/repositories/notification_repository.dart';
import 'package:medical_app/features/notifications/domain/usecases/delete_notification_use_case.dart';
import 'package:medical_app/features/notifications/domain/usecases/get_notifications_use_case.dart';
import 'package:medical_app/features/notifications/domain/usecases/get_unread_notifications_count_use_case.dart';
import 'package:medical_app/features/notifications/domain/usecases/mark_all_notifications_as_read_use_case.dart';
import 'package:medical_app/features/notifications/domain/usecases/mark_notification_as_read_use_case.dart';
import 'package:medical_app/features/notifications/domain/usecases/send_notification_use_case.dart';
import 'package:medical_app/features/notifications/domain/usecases/initialize_onesignal_use_case.dart';
import 'package:medical_app/features/notifications/domain/usecases/set_external_user_id_use_case.dart';
import 'package:medical_app/features/notifications/domain/usecases/get_onesignal_player_id_use_case.dart';
import 'package:medical_app/features/notifications/domain/usecases/save_onesignal_player_id_use_case.dart';
import 'package:medical_app/features/notifications/domain/usecases/logout_onesignal_use_case.dart';
import 'package:medical_app/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:medical_app/features/notifications/utils/onesignal_service.dart';
import 'package:medical_app/features/authentication/presentation/blocs/update_password_bloc/update_password_bloc.dart';
// import 'package:medical_app/features/authentication/domain/usecases/update_password_direct_use_case.dart'; // DISABLED - deprecated
import 'package:medical_app/features/dossier_medical/data/datasources/dossier_medical_remote_datasource.dart';
import 'package:medical_app/features/dossier_medical/data/repositories/dossier_medical_repository_impl.dart';
import 'package:medical_app/features/dossier_medical/domain/repositories/dossier_medical_repository.dart';
import 'package:medical_app/features/dossier_medical/domain/usecases/get_dossier_medical.dart';
import 'package:medical_app/features/dossier_medical/domain/usecases/has_dossier_medical.dart';
import 'package:medical_app/features/dossier_medical/presentation/bloc/dossier_medical_bloc.dart';
import 'package:medical_app/features/referral/data/datasources/referral_remote_data_source.dart';
import 'package:medical_app/features/referral/data/repositories/referral_repository_impl.dart';
import 'package:medical_app/features/referral/domain/repositories/referral_repository.dart';
import 'package:medical_app/features/referral/presentation/bloc/referral_bloc.dart';
import 'package:medical_app/features/medical_records/data/datasources/medical_records_remote_datasource.dart';
import 'package:medical_app/features/medical_records/data/repositories/medical_records_repository_impl.dart';
import 'package:medical_app/features/medical_records/domain/repositories/medical_records_repository.dart';
import 'package:medical_app/features/medical_records/presentation/bloc/medical_records_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Blocs and Cubits
  sl.registerFactory(() => ThemeCubit());
  sl.registerFactory(() => LoginBloc(loginUseCase: sl()));
  sl.registerFactory(() => SignupBloc(createAccountUseCase: sl()));
  sl.registerFactory(() => UpdateUserBloc(updateUserUseCase: sl()));
  sl.registerFactory(() => ToggleCubit());
  sl.registerFactory(
    () => ForgotPasswordBloc(forgotPasswordUseCase: sl()),
  );
  sl.registerFactory(() => LogoutBloc(
    logoutUseCase: sl(),
    conversationRepository: sl<ConversationRepository>(),
  ));
  // sl.registerFactory(() => VerifyCodeBloc(verifyCodeUseCase: sl())); // DISABLED - deprecated
  sl.registerFactory(() => ResetPasswordBloc(resetPasswordUseCase: sl()));
  sl.registerFactory(
    () => UpdatePasswordBloc(changePasswordUseCase: sl()),
  );
  sl.registerFactory(
    () => RendezVousBloc(
      fetchRendezVousUseCase: sl(),
      updateRendezVousStatusUseCase: sl(),
      createRendezVousUseCase: sl(),
      fetchDoctorsBySpecialtyUseCase: sl(),
      cancelAppointmentUseCase: sl(),
      rateDoctorUseCase: sl(),
      getDoctorAppointmentsForDayUseCase: sl(),
      acceptAppointmentUseCase: sl(),
      refuseAppointmentUseCase: sl(),
      rescheduleAppointmentUseCase: sl(),
      requestRescheduleUseCase: sl(),
      approveRescheduleUseCase: sl(),
      rejectRescheduleUseCase: sl(),
      notificationBloc: sl<NotificationBloc>(),
    ),
  );

  // Messagerie Feature BLoCs (Backend API + Socket.IO)
  sl.registerFactory(
    () => ConversationBloc(getConversations: sl(), getCurrentUser: sl()),
  );

  sl.registerFactory(
    () => MessageBloc(
      getMessages: sl(),
      sendMessage: sl(),
      sendFileMessage: sl<SendFileMessage>(),
      markMessagesAsRead: sl(),
      getCurrentUser: sl(),
      conversationRepository: sl<ConversationRepository>(),
    ),
  );

  sl.registerFactory(
    () =>
        SocketBloc(connectToSocket: sl(), repository: sl(), messageBloc: sl()),
  );

  // Online Status Cubit for tracking user presence
  sl.registerLazySingleton(
    () => OnlineStatusCubit(repository: sl<ConversationRepository>()),
  );

  // Dashboard BLoC
  sl.registerFactory(
    () => DashboardBloc(
      getDoctorDashboardStatsUseCase: sl(),
      getUpcomingAppointmentsUseCase: sl(),
    ),
  );

  // Prescription BLoC
  sl.registerFactory(
    () => PrescriptionBloc(
      createPrescriptionUseCase: sl(),
      editPrescriptionUseCase: sl(),
      getPatientPrescriptionsUseCase: sl(),
      getDoctorPrescriptionsUseCase: sl(),
      getPrescriptionByIdUseCase: sl(),
      getPrescriptionByAppointmentIdUseCase: sl(),
      updatePrescriptionStatusUseCase: sl(),
      notificationBloc: sl<NotificationBloc>(),
    ),
  );

  // Notification BLoC
  sl.registerFactory(
    () => NotificationBloc(
      getNotificationsUseCase: sl(),
      sendNotificationUseCase: sl(),
      markNotificationAsReadUseCase: sl(),
      markAllNotificationsAsReadUseCase: sl(),
      deleteNotificationUseCase: sl(),
      getUnreadNotificationsCountUseCase: sl(),
      initializeOneSignalUseCase: sl(),
      setExternalUserIdUseCase: sl(),
      getOneSignalPlayerIdUseCase: sl(),
      saveOneSignalPlayerIdUseCase: sl(),
      logoutOneSignalUseCase: sl(),
    ),
  );

  // Rating BLoC
  sl.registerFactory(
    () => RatingBloc(
      submitDoctorRatingUseCase: sl(),
      hasPatientRatedAppointmentUseCase: sl(),
      getDoctorRatingsUseCase: sl(),
      getDoctorAverageRatingUseCase: sl(),
    ),
  );

  // Dossier Medical BLoC
  sl.registerFactory(
    () => DossierMedicalBloc(
      repository: sl(),
      getDossierMedicalUseCase: sl(),
      hasDossierMedicalUseCase: sl(),
    ),
  );

  // Referral BLoC
  sl.registerFactory(
    () => ReferralBloc(referralRepository: sl()),
  );

  // Medical Records BLoC
  sl.registerFactory(
    () => MedicalRecordsBloc(repository: sl()),
  );

  // Use Cases - Auth
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => CreateAccountUseCase(sl()));
  // sl.registerLazySingleton(() => UpdateUserUseCase(sl())); // MOVED to User Service section
  // sl.registerLazySingleton(() => VerifyCodeUseCase(sl())); // DISABLED - deprecated
  sl.registerLazySingleton(() => ChangePasswordUseCase(sl()));
  sl.registerLazySingleton(() => ResetPasswordUseCase(sl()));
  // sl.registerLazySingleton(() => SendVerificationCodeUseCase(sl())); // DISABLED - deprecated
  sl.registerLazySingleton(() => ForgotPasswordUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  // sl.registerLazySingleton(() => UpdatePasswordDirectUseCase(sl())); // DISABLED - deprecated
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => VerifyEmailUseCase(sl()));

  // User Service
  sl.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(client: sl(), localDataSource: sl()),
  );
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton(() => GetUserProfileUseCase(sl()));
  sl.registerLazySingleton(() => UpdateUserUseCase(sl()));

  // Use Cases - Rendez-vous
  sl.registerLazySingleton(() => FetchRendezVousUseCase(sl()));
  sl.registerLazySingleton(() => UpdateRendezVousStatusUseCase(sl()));
  sl.registerLazySingleton(() => CreateRendezVousUseCase(sl()));
  sl.registerLazySingleton(() => FetchDoctorsBySpecialtyUseCase(sl()));
  sl.registerLazySingleton(() => CancelAppointmentUseCase(sl()));
  sl.registerLazySingleton(() => RateDoctorUseCase(sl()));
  sl.registerLazySingleton(() => GetDoctorAppointmentsForDayUseCase(sl()));
  sl.registerLazySingleton(() => AcceptAppointmentUseCase(sl()));
  sl.registerLazySingleton(() => RefuseAppointmentUseCase(sl()));
  sl.registerLazySingleton(() => RescheduleAppointmentUseCase(sl()));
  sl.registerLazySingleton(() => RequestRescheduleUseCase(sl()));
  sl.registerLazySingleton(() => ApproveRescheduleUseCase(sl()));
  sl.registerLazySingleton(() => RejectRescheduleUseCase(sl()));

  // Use Cases - Messagerie Feature (Backend API + Socket.IO)
  sl.registerLazySingleton(() => GetConversations(sl()));
  sl.registerLazySingleton(() => GetMessages(sl()));
  sl.registerLazySingleton(() => SendMessage(sl()));
  sl.registerLazySingleton(() => SendFileMessage(sl()));
  sl.registerLazySingleton(() => MarkMessagesAsRead(sl()));
  sl.registerLazySingleton(() => ConnectToSocket(sl()));

  // Dashboard Use Cases
  sl.registerLazySingleton(() => GetDoctorDashboardStatsUseCase(sl()));
  sl.registerLazySingleton(() => GetUpcomingAppointmentsUseCase(sl()));

  // Prescription Use Cases
  sl.registerLazySingleton(() => CreatePrescriptionUseCase(sl()));
  sl.registerLazySingleton(() => EditPrescriptionUseCase(sl()));
  sl.registerLazySingleton(() => GetPatientPrescriptionsUseCase(sl()));
  sl.registerLazySingleton(() => GetDoctorPrescriptionsUseCase(sl()));
  sl.registerLazySingleton(() => GetPrescriptionByIdUseCase(sl()));
  sl.registerLazySingleton(() => GetPrescriptionByAppointmentIdUseCase(sl()));
  sl.registerLazySingleton(() => UpdatePrescriptionStatusUseCase(sl()));

  // Notification Use Cases
  sl.registerLazySingleton(() => GetNotificationsUseCase(sl()));
  sl.registerLazySingleton(() => SendNotificationUseCase(sl()));
  sl.registerLazySingleton(() => MarkNotificationAsReadUseCase(sl()));
  sl.registerLazySingleton(() => MarkAllNotificationsAsReadUseCase(sl()));
  sl.registerLazySingleton(() => DeleteNotificationUseCase(sl()));
  sl.registerLazySingleton(() => GetUnreadNotificationsCountUseCase(sl()));
  sl.registerLazySingleton(() => InitializeOneSignalUseCase(sl()));
  sl.registerLazySingleton(() => SetExternalUserIdUseCase(sl()));
  sl.registerLazySingleton(() => GetOneSignalPlayerIdUseCase(sl()));
  sl.registerLazySingleton(() => SaveOneSignalPlayerIdUseCase(sl()));
  sl.registerLazySingleton(() => LogoutOneSignalUseCase(sl()));

  // Rating Use Cases
  sl.registerLazySingleton(() => SubmitDoctorRatingUseCase(sl()));
  sl.registerLazySingleton(() => HasPatientRatedAppointmentUseCase(sl()));
  sl.registerLazySingleton(() => GetDoctorRatingsUseCase(sl()));
  sl.registerLazySingleton(() => GetDoctorAverageRatingUseCase(sl()));

  // Dossier Medical Use Cases
  sl.registerLazySingleton(() => GetDossierMedical(sl()));
  sl.registerLazySingleton(() => HasDossierMedical(sl()));

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton<RendezVousRepository>(
    () => RendezVousRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton<ConversationRepository>(
    () => ConversationRepositoryImpl(
      apiDataSource: sl(),
      socketService: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton<PrescriptionRepository>(
    () => PrescriptionRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton<RatingRepository>(
    () => RatingRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton<DossierMedicalRepository>(
    () =>
        DossierMedicalRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton<ReferralRepository>(
    () => ReferralRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
      sharedPreferences: sl(),
    ),
  );
  sl.registerLazySingleton<MedicalRecordsRepository>(
    () => MedicalRecordsRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
      sharedPreferences: sl(),
    ),
  );

  // Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(localDataSource: sl(), client: sl()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sharedPreferences: sl()),
  );
  sl.registerLazySingleton<RendezVousRemoteDataSource>(
    () => RendezVousRemoteDataSourceImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton<RendezVousLocalDataSource>(
    () => RendezVousLocalDataSourceImpl(sharedPreferences: sl()),
  );
  sl.registerLazySingleton<MessagingLocalDataSource>(
    () => MessagingLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<ConversationApiDataSource>(
    () => ConversationApiDataSourceImpl(
      client: sl(),
      baseUrl: kBaseUrl,
      headersBuilder: () => {
        'Content-Type': 'application/json',
        'Authorization':
            'Bearer ${sl<SharedPreferences>().getString(kTokenKey) ?? ''}',
      },
      currentUserIdGetter: () {
        // Extract userId from cached user JSON
        final userJson = sl<SharedPreferences>().getString('CACHED_USER');
        if (userJson != null) {
          try {
            final userMap = jsonDecode(userJson) as Map<String, dynamic>;
            return userMap['id']?.toString();
          } catch (_) {
            return null;
          }
        }
        return null;
      },
    ),
  );
  sl.registerLazySingleton<SocketService>(() {
    return SocketService(
      userInfoGetter: () {
        // Always get fresh user info from SharedPreferences
        final prefs = sl<SharedPreferences>();
        final userJson = prefs.getString('CACHED_USER');
        String? id;
        String? name;
        
        if (userJson != null) {
          try {
            final userMap = jsonDecode(userJson) as Map<String, dynamic>;
            id = userMap['id']?.toString();
            name = userMap['name']?.toString();
          } catch (_) {}
        }
        
        return SocketUserInfo(
          id: id,
          name: name,
          token: prefs.getString(kTokenKey),
        );
      },
      networkInfo: sl(),
      baseUrl: kSocketUrl,
    );
  });
  sl.registerLazySingleton<DashboardRemoteDataSource>(
    () => MongoDBDashboardRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<PrescriptionRemoteDataSource>(
    () => PrescriptionRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () =>
        NotificationRemoteDataSourceImpl(client: sl(), oneSignalService: sl()),
  );
  sl.registerLazySingleton<RatingRemoteDataSource>(
    () => RatingRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<DossierMedicalRemoteDataSource>(
    () => DossierMedicalRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<ReferralRemoteDataSource>(
    () => ReferralRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<MedicalRecordsRemoteDataSource>(
    () => MedicalRecordsRemoteDataSourceImpl(client: sl()),
  );

  // Services
  sl.registerLazySingleton<OneSignalService>(() => OneSignalService());

  // Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);
  sl.registerLazySingleton(() => GoogleSignIn());
  sl.registerLazySingleton<InternetConnectionChecker>(
    () => InternetConnectionChecker.instance,
  );
  sl.registerLazySingleton<http.Client>(() {
    final innerClient = http.Client();
    return AuthenticatedHttpClient(innerClient, sl());
  });
  sl.registerLazySingleton(() => ApiService());
}
