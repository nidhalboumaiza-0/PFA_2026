/// Global application constants
class AppConstants {
  // API Base URL (use 10.0.2.2 for Android emulator)
  // API Base URL (use 10.0.2.2 for Android emulator)
  // Updated to include API Gateway prefix
  static const String baseUrl = 'http://192.168.1.204:3000/api/v1';

  // Auth endpoints
  static String get loginEndpoint => '$baseUrl/auth/login';
  static String get signupEndpoint => '$baseUrl/auth/register';
  static String get verifyEmailEndpoint => '$baseUrl/auth/verify-email';
  static String get resendVerificationEndpoint => '$baseUrl/auth/resend-verification';
  static String get forgotPasswordEndpoint => '$baseUrl/auth/forgot-password';
  static String get resetPasswordEndpoint => '$baseUrl/auth/reset-password';
  static String get changePasswordEndpoint => '$baseUrl/auth/change-password';
  static String get refreshTokenEndpoint => '$baseUrl/auth/refresh-token';
  static String get logoutEndpoint => '$baseUrl/auth/logout';
  static String get currentUserEndpoint => '$baseUrl/auth/me';

  // User endpoints
  static String get usersEndpoint => '$baseUrl/users';
  static String get getUserProfileEndpoint => '$baseUrl/users/me';
  // Specific endpoints for updating profiles based on role
  static String get updatePatientProfileEndpoint => '$baseUrl/users/patient/profile';
  static String get updateDoctorProfileEndpoint => '$baseUrl/users/doctor/profile';
  static String get updateProfileEndpoint => '$baseUrl/users/profile';
  
  static String get updateOneSignalPlayerIdEndpoint => '$baseUrl/users/updateOneSignalPlayerId';
  static String get getAllDoctorsEndpoint => '$baseUrl/users/doctors/search'; // Updated to match backend route
  static String get getDoctorEndpoint => '$baseUrl/users/doctors'; // Add ID when calling

  // Appointment endpoints
  static String get appointmentsEndpoint => '$baseUrl/appointments';

  // Conversation and messaging endpoints
  static String get conversationsEndpoint => '$baseUrl/conversations';

  // Notification endpoints
  static String get notificationsEndpoint => '$baseUrl/notifications';
  static String get myNotificationsEndpoint => '$baseUrl/notifications/my-notifications';
  static String get markNotificationReadEndpoint => '$baseUrl/notifications/mark-read';
  static String get markAllNotificationsReadEndpoint => '$baseUrl/notifications/mark-all-read';
  static String get unreadNotificationsCountEndpoint => '$baseUrl/notifications/unread-count';

  // Dashboard endpoints
  static String get dashboardEndpoint => '$baseUrl/dashboard';

  // Prescription endpoints
  static String get prescriptionsEndpoint => '$baseUrl/prescriptions';

  // Rating endpoints
  static String get ratingsEndpoint => '$baseUrl/ratings';

  // Referral endpoints
  static String get referralsEndpoint => '$baseUrl/referrals';

  // Speciality endpoints
  static String get specialitiesEndpoint => '$baseUrl/specialities';

  // Medical records endpoints
  static String get medicalRecordsEndpoint => '$baseUrl/medical-records';

  // Dossier Medical endpoints
  static String get dossierMedicalEndpoint => '$baseUrl/medical/dossier-medical';

  // Consultation endpoints
  static String get consultationsEndpoint => '$baseUrl/medical/consultations';

  // Medical Documents endpoints
  static String get medicalDocumentsEndpoint => '$baseUrl/medical/documents';

  // Patient medical history endpoint
  static String get patientMedicalHistoryEndpoint => '$baseUrl/medical/patients';

  // OneSignal Configuration
  static String get oneSignalAppId => 'YOUR-ONESIGNAL-APP-ID'; // Replace with your actual OneSignal App ID
}
