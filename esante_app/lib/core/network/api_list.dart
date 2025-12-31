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

  // ============== Medical Records Endpoints ==============
  static const String _medicalBase = '/api/v1/medical';

  // Patient prescription endpoints
  static const String patientMyPrescriptions = '$_medicalBase/patients/my-prescriptions';
  static String prescriptionById(String prescriptionId) =>
      '$_medicalBase/prescriptions/$prescriptionId';

  // Patient medical history
  static const String patientMyMedicalHistory = '$_medicalBase/patients/my-history';

  // Doctor prescription operations
  static const String doctorCreatePrescription = '$_medicalBase/prescriptions';
}
