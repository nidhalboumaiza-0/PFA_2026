import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../injection_container.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../dashboard/presentation/screens/patient_main_navigation.dart';
import '../../../dashboard/presentation/screens/doctor_main_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkAuthStatus();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();
  }

  Future<void> _checkAuthStatus() async {
    // Wait for animation to play and give a nice UX
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    try {
      final authRepository = sl<AuthRepository>();
      final isLoggedIn = await authRepository.isLoggedIn();
      final cachedUser = await authRepository.getCachedUser();

      if (!mounted) return;

      if (isLoggedIn && cachedUser != null) {
        // User is logged in, restore session (initializes WebSocket)
        debugPrint('[SplashScreen] User found: ${cachedUser.email}, role: ${cachedUser.role}');
        await authRepository.restoreSession();
        
        // Register device for push notifications on session restore
        try {
          final pushService = PushNotificationService();
          await pushService.setExternalUserId(cachedUser.id);
          await pushService.registerDeviceWithBackend();
          debugPrint('[SplashScreen] Push notification device registered');
        } catch (e) {
          debugPrint('[SplashScreen] Push registration failed (non-blocking): $e');
        }
        
        if (cachedUser.role == UserRole.doctor) {
          _navigateToDoctorDashboard();
        } else {
          _navigateToPatientDashboard();
        }
      } else {
        // No valid session, go to login
        debugPrint('[SplashScreen] No valid session, navigating to login');
        _navigateToLogin();
      }
    } catch (e) {
      debugPrint('[SplashScreen] Error checking auth status: $e');
      // On error, default to login screen
      _navigateToLogin();
    }
  }

  void _navigateToPatientDashboard() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const PatientMainNavigation(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _navigateToDoctorDashboard() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const DoctorMainNavigation(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Animation
                    SizedBox(
                      width: 180.w,
                      height: 180.h,
                      child: Lottie.asset(
                        AppAssets.healthLogoLottie,
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    // App Name
                    Text(
                      'eSanté',
                      style: TextStyle(
                        fontSize: 36.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Your Health, Your Way',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.white.withOpacity(0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 48.h),
                    // Loading indicator
                    SizedBox(
                      width: 24.w,
                      height: 24.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.w,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
