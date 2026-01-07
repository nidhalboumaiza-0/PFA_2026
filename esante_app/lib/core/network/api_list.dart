/// Centralized API endpoints for E-Santé application
/// 
/// This file contains all API endpoint paths used throughout the app.
/// Update this file when backend endpoints change.
library api_list;

class ApiList {
  ApiList._();

  // ============== Base Paths ==============
  static const String _authBase = '/api/v1/auth';
  static const String _usersBase = '/api/v1/users';
  static const String _doctorsBase = '/api/v1/users/doctors';
  static const String _appointmentsBase = '/api/v1/appointments';

  // ============== Auth Endpoints ==============
  static const String authRegister = '$_authBase/register';
  static const String authLogin = '$_authBase/login';
  static const String authLogout = '$_authBase/logout';
  static const String authLogoutAll = '$_authBase/logout-all';
  static const String authRefreshToken = '$_authBase/refresh-token';
  static const String authMe = '$_authBase/me';
  static String authVerifyEmail(String token) => '$_authBase/verify-email/$token';
  static const String authResendVerification = '$_authBase/resend-verification';
  static const String authForgotPassword = '$_authBase/forgot-password';
  static String authResetPassword(String token) => '$_authBase/reset-password/$token';
  static const String authChangePassword = '$_authBase/change-password';
  static const String authSessions = '$_authBase/sessions';

  /// Public auth endpoints (no token required)
  static const List<String> publicAuthEndpoints = [
    authLogin,
    authRegister,
    authForgotPassword,
    '$_authBase/reset-password', // Prefix for dynamic reset-password
    '$_authBase/verify-email', // Prefix for dynamic verify-email
    authResendVerification,
  ];

  // ============== Profile/User Endpoints ==============
  static const String userMe = '$_usersBase/me';
  static const String patientProfile = '$_usersBase/patient/profile';
  static const String doctorProfile = '$_usersBase/doctor/profile';
  static const String userUploadPhoto = '$_usersBase/upload-photo';
  static String patientById(String patientId) => '$_usersBase/patients/$patientId';
  static String profileById(String profileId) => '$_usersBase/profile/$profileId';

  // ============== Doctor Search Endpoints ==============
  static const String doctorsSearch = '$_doctorsBase/search';
  static const String doctorsNearby = '$_doctorsBase/nearby';
  static String doctorById(String doctorId) => '$_doctorsBase/$doctorId';

  // ============== Appointment Endpoints ==============
  
  // Patient operations
  static String appointmentDoctorAvailability(String doctorId) => 
      '$_appointmentsBase/doctors/$doctorId/availability';
  static const String appointmentRequest = '$_appointmentsBase/request';
  static String appointmentCancel(String appointmentId) => 
      '$_appointmentsBase/$appointmentId/cancel';
  static String appointmentRequestReschedule(String appointmentId) => 
      '$_appointmentsBase/$appointmentId/request-reschedule';
  static const String patientAppointments = '$_appointmentsBase/patient/my-appointments';

  // Doctor operations
  static const String doctorSetAvailability = '$_appointmentsBase/doctor/availability';
  static const String doctorBulkSetAvailability = '$_appointmentsBase/doctor/availability/bulk';
  static const String doctorGetAvailability = '$_appointmentsBase/doctor/availability';
  static const String doctorAppointmentRequests = '$_appointmentsBase/doctor/requests';
  static const String doctorAppointments = '$_appointmentsBase/doctor/my-appointments';
  static const String doctorStatistics = '$_appointmentsBase/doctor/statistics';
  static const String doctorReferralBooking = '$_appointmentsBase/referral-booking';
  
  static String appointmentConfirm(String appointmentId) => 
      '$_appointmentsBase/$appointmentId/confirm';
  static String appointmentReject(String appointmentId) => 
      '$_appointmentsBase/$appointmentId/reject';
  static String appointmentReschedule(String appointmentId) => 
      '$_appointmentsBase/$appointmentId/reschedule';
  static String appointmentApproveReschedule(String appointmentId) => 
      '$_appointmentsBase/$appointmentId/approve-reschedule';
  static String appointmentRejectReschedule(String appointmentId) => 
      '$_appointmentsBase/$appointmentId/reject-reschedule';
  static String appointmentComplete(String appointmentId) => 
      '$_appointmentsBase/$appointmentId/complete';

  // Shared
  static String appointmentDetails(String appointmentId) => 
      '$_appointmentsBase/$appointmentId';

  // Document attachments
  static const String appointmentUploadDocument = '$_appointmentsBase/upload-document';
  static String appointmentDocuments(String appointmentId) =>
      '$_appointmentsBase/$appointmentId/documents';
  static String appointmentDocumentDelete(String appointmentId, String documentId) =>
      '$_appointmentsBase/$appointmentId/documents/$documentId';

  // ============== Reviews Endpoints ==============
  static const String _reviewsBase = '/api/v1/reviews';
  static const String reviews = _reviewsBase;
  
  static String reviewsByDoctor(String doctorId) => '$_reviewsBase/doctors/$doctorId';
  static String reviewByAppointment(String appointmentId) => '$_reviewsBase/appointments/$appointmentId';
  static String reviewById(String reviewId) => '$_reviewsBase/$reviewId';

  // ============== Medical Records Endpoints ==============
  static const String _medicalBase = '/api/v1/medical';

  // Patient prescription endpoints
  static const String patientMyPrescriptions = '$_medicalBase/patients/my-prescriptions';
  static String prescriptionById(String prescriptionId) =>
      '$_medicalBase/prescriptions/$prescriptionId';

  // Patient medical history
  static const String patientMyMedicalHistory = '$_medicalBase/patients/my-history';

  // Doctor: get patient's medical history
  static String doctorPatientMedicalHistory(String patientId) =>
      '$_medicalBase/patient-history/$patientId';

  // Doctor prescription operations
  static const String doctorCreatePrescription = '$_medicalBase/prescriptions';

  // ============== Messaging Endpoints ==============
  static const String _messagesBase = '/api/v1/messages';
  
  // Conversations
  static const String conversations = '$_messagesBase/conversations';
  static String conversationMessages(String conversationId) =>
      '$_messagesBase/conversations/$conversationId/messages';
  static String conversationMarkRead(String conversationId) =>
      '$_messagesBase/conversations/$conversationId/mark-read';
  static String conversationSendFile(String conversationId) =>
      '$_messagesBase/conversations/$conversationId/send-file';
  
  // Messages
  static String deleteMessage(String messageId) => '$_messagesBase/$messageId';
  static const String unreadCount = '$_messagesBase/unread-count';
  static const String searchMessages = '$_messagesBase/search';
  static String userOnlineStatus(String userId) => '$_messagesBase/users/$userId/online-status';

  // ============== Notification Endpoints ==============
  static const String _notificationsBase = '/api/v1/notifications';
  
  static const String notifications = _notificationsBase;
  static const String notificationsUnreadCount = '$_notificationsBase/unread-count';
  static String notificationMarkRead(String notificationId) =>
      '$_notificationsBase/$notificationId/read';
  static const String notificationsMarkAllRead = '$_notificationsBase/mark-all-read';
  static const String notificationPreferences = '$_notificationsBase/preferences';
  static const String registerDevice = '$_notificationsBase/register-device';
  static const String unregisterDevice = '$_notificationsBase/devices';
  static String notificationDelete(String notificationId) =>
      '$_notificationsBase/$notificationId';
}
