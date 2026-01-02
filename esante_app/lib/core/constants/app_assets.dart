/// Centralized constants for all app assets
/// Makes it easier to reference and maintain asset paths
class AppAssets {
  AppAssets._();

  // ============== BASE PATHS ==============
  static const String _baseLottie = 'assets/lottie';
  static const String _baseImages = 'assets/images';
  static const String _healthLottie = 'assets/doctor & health/lottie';
  static const String _healthImages = 'assets/doctor & health/storyset';

  // ============================================================================
  // ORIGINAL LOTTIE ANIMATIONS (assets/lottie/)
  // ============================================================================
  
  /// Forgot password animation variant 1
  static const String forgotPasswordLottie = '$_baseLottie/Forgot Password.json';
  
  /// Forgot password animation variant 2
  static const String forgotPassword2Lottie = '$_baseLottie/Forgot Password (1).json';
  
  /// Login animation - default
  static const String loginLottie = '$_baseLottie/login.json';
  
  /// Login animation variant 2
  static const String login2Lottie = '$_baseLottie/Login 2.json';
  
  /// Login animation variant 3
  static const String login3Lottie = '$_baseLottie/login 3.json';
  
  /// Login success checkmark animation
  static const String loginSuccessLottie = '$_baseLottie/login success.json';
  
  /// Password typing animation
  static const String passwordAnimationLottie = '$_baseLottie/Password Animation.json';
  
  /// Password authentication/verification animation
  static const String passwordAuthLottie = '$_baseLottie/Password Authentication.json';
  
  /// Floating user avatar animation
  static const String userFloatingLottie = '$_baseLottie/User floating.json';

  // ============================================================================
  // ORIGINAL IMAGES (assets/images/)
  // ============================================================================
  
  /// Authentication illustration (pana style)
  static const String authenticationPanaImage = '$_baseImages/Authentication-pana.png';
  
  /// Enter password illustration variant 1
  static const String enterPasswordImage = '$_baseImages/enter password.png';
  
  /// Enter password illustration variant 2
  static const String enterPassword2Image = '$_baseImages/enter password 2.png';
  
  /// Forgot password illustration (cuate style)
  static const String forgotPasswordCuateImage = '$_baseImages/Forgot password-cuate.png';
  
  /// Forgot password illustration (pana style)
  static const String forgotPasswordPanaImage = '$_baseImages/Forgot password-pana.png';
  
  /// Login illustration variant 3
  static const String login3Image = '$_baseImages/login 3.png';
  
  /// Mobile login illustration (cuate style)
  static const String mobileLoginCuateImage = '$_baseImages/Mobile login-cuate.png';
  
  /// Mobile login illustration (pana style)
  static const String mobileLoginPanaImage = '$_baseImages/Mobile login-pana.png';
  
  /// Mobile login illustration (rafiki style)
  static const String mobileLoginRafikiImage = '$_baseImages/Mobile login-rafiki.png';
  
  /// Password illustration
  static const String passwordImage = '$_baseImages/paswword.png';
  
  /// Reset password illustration (amico style)
  static const String resetPasswordAmicoImage = '$_baseImages/Reset password-amico.png';
  
  /// Reset password illustration (cuate style)
  static const String resetPasswordCuateImage = '$_baseImages/Reset password-cuate.png';
  
  /// Tablet login illustration (amico style)
  static const String tabletLoginAmicoImage = '$_baseImages/Tablet login-amico.png';
  
  /// Two factor authentication illustration (pana style)
  static const String twoFactorAuthPanaImage = '$_baseImages/Two factor authentication-pana.png';

  // ============================================================================
  // HEALTH LOTTIE ANIMATIONS (assets/doctor & health/lottie/)
  // ============================================================================
  
  /// Chemistry lab animation - great for medical research or lab sections
  static const String chemistryLabLottie = '$_healthLottie/Chemistry Lab.json';
  
  /// Doctor consultation animation - ideal for booking or appointment confirmation
  static const String consultationLottie = '$_healthLottie/consultation.json';
  
  /// Doctor writing prescription animation
  static const String prescriptionLottie = '$_healthLottie/Doctor Prescription.json';
  
  /// Doctor animation - general purpose
  static const String doctorLottie = '$_healthLottie/Doctor.json';
  
  /// Floating health logo with medicine elements - splash/loading screen
  static const String healthLogoLottie = '$_healthLottie/floating logo of health with little medicament, receite, and two things floating.json';
  
  /// HealthLift branded logo animation
  static const String healthLiftLogoLottie = '$_healthLottie/HealthLift logo.json';
  
  /// Heartbeat animation - health status or vitals section
  static const String heartbeatLottie = '$_healthLottie/Heartbeat.json';
  
  /// Hospital building animation
  static const String hospitalLottie = '$_healthLottie/hospital.json';
  
  /// Medical app showcase animation
  static const String medicalAppLottie = '$_healthLottie/Medical App.json';
  
  /// Someone sick receiving medicine - prescription or medication section
  static const String sickPatientLottie = '$_healthLottie/someone sick and getting medicament.json';
  
  /// Waiting for appointment animation - booking queue or waiting state
  static const String waitingAppointmentLottie = '$_healthLottie/someone waiting to take rendez vous.json';
  
  /// Loading health animation - generic loading state for health-related screens
  static const String loadingHealthLottie = '$_healthLottie/Doctor.json';

  // ============================================================================
  // HEALTH STORYSET IMAGES (assets/doctor & health/storyset/)
  // ============================================================================
  
  /// Single doctor illustration (amico style)
  static const String doctorAmicoImage = '$_healthImages/Doctor-amico.png';
  
  /// Multiple doctors illustration (pana style)
  static const String doctorsPanaImage = '$_healthImages/Doctors-pana.png';
  
  /// Laboratory illustration
  static const String laboImage = '$_healthImages/labo.png';
  
  /// Laboratory illustration variant 2
  static const String labo2Image = '$_healthImages/labo2.png';
  
  /// Medical prescription (amico style)
  static const String prescriptionAmicoImage = '$_healthImages/Medical prescription-amico.png';
  
  /// Medical prescription (rafiki style)
  static const String prescriptionRafikiImage = '$_healthImages/Medical prescription-rafiki.png';
  
  /// Medical research illustration (pana style)
  static const String medicalResearchImage = '$_healthImages/Medical research-pana.png';
  
  /// Medicine illustration (amico style)
  static const String medicineAmicoImage = '$_healthImages/Medicine-amico.png';
  
  /// Medicine illustration (bro style)
  static const String medicineBroImage = '$_healthImages/Medicine-bro.png';
  
  /// Medicine illustration (rafiki style)
  static const String medicineRafikiImage = '$_healthImages/Medicine-rafiki.png';
  
  /// Online doctor illustration (amico style)
  static const String onlineDoctorAmicoImage = '$_healthImages/Online Doctor-amico.png';
  
  /// Online doctor illustration (amico style variant 2)
  static const String onlineDoctorAmico2Image = '$_healthImages/Online Doctor-amico (1).png';
  
  /// Online doctor illustration (pana style)
  static const String onlineDoctorPanaImage = '$_healthImages/Online Doctor-pana.png';
  
  /// Online doctor illustration (rafiki style)
  static const String onlineDoctorRafikiImage = '$_healthImages/Online Doctor-rafiki.png';
  
  /// Rheumatology illustration (amico style)
  static const String rheumatologyImage = '$_healthImages/Rheumatology-amico.png';
}
