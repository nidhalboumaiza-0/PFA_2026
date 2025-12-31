import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'location_permission_screen.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../injection_container.dart';
import '../../../dashboard/presentation/screens/doctor_main_navigation.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../bloc/auth_bloc.dart';
import 'forgot_password_screen.dart';
import 'signup/signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            LoginRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  void _handleAuthError(AuthError state) {
    print('[LoginScreen._handleAuthError] Error: ${state.message}');
    print('[LoginScreen._handleAuthError] isEmailNotVerified: ${state.isEmailNotVerified}');
    print('[LoginScreen._handleAuthError] details: ${state.details}');
    if (state.isEmailNotVerified) {
      final canResend = state.details?['canResend'] == true;
      AppDialog.emailVerification(
        context,
        message: state.message,
        canResend: canResend,
        onResend: () {
          // TODO: Trigger resend verification
          AppSnackBar.success(context, 'Verification email sent!');
        },
      );
    } else {
      AppSnackBar.error(context, state.message);
    }
  }

  Future<void> _handleSuccessfulLogin(UserEntity user) async {
    print('[LoginScreen._handleSuccessfulLogin] Starting post-login flow...');
    print('[LoginScreen._handleSuccessfulLogin] User role: ${user.role}');
    
    // If user is a doctor, navigate directly to doctor dashboard
    if (user.role == UserRole.doctor) {
      if (mounted) {
        context.pushAndClearStack(
          const DoctorMainNavigation(),
          transition: NavTransition.fadeScale,
        );
      }
      return;
    }

    // For patients, continue with profile completion check
    bool shouldShowProfileDialog = false;
    int completionPercentage = 0;
    
    // First, try to fetch and cache the profile
    try {
      final profileRepository = sl<ProfileRepository>();
      final profileResult = await profileRepository.getPatientProfile();
      
      profileResult.fold(
        (failure) {
          print('[LoginScreen._handleSuccessfulLogin] Failed to fetch profile: ${failure.message}');
        },
        (profile) {
          print('[LoginScreen._handleSuccessfulLogin] Profile fetched: ${profile.fullName}');
          print('[LoginScreen._handleSuccessfulLogin] Profile complete: ${profile.isProfileComplete}');
          
          // Check if profile needs completion
          if (!profile.isProfileComplete) {
            shouldShowProfileDialog = true;
            completionPercentage = profile.profileCompletionPercentage;
          }
        },
      );
    } catch (e) {
      print('[LoginScreen._handleSuccessfulLogin] Error fetching profile: $e');
    }

    // Navigate to Location Permission Screen
    if (mounted) {
      context.pushAndClearStack(
        LocationPermissionScreen(
          user: user,
          showProfileCompletionDialog: shouldShowProfileDialog,
          profileCompletionPercentage: completionPercentage,
        ),
        transition: NavTransition.fadeScale,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          print('[LoginScreen.BlocListener] State changed to: ${state.runtimeType}');
          if (state is AuthError) {
            print('[LoginScreen.BlocListener] AuthError received');
            _handleAuthError(state);
          } else if (state is AuthSuccess) {
            print('[LoginScreen.BlocListener] AuthSuccess received, user: ${state.user.email}, role: ${state.user.role}');
            AppSnackBar.success(context, 'Login successful!');
            // Navigate to profile and check completion
            _handleSuccessfulLogin(state.user);
          }
        },
        child: Container(
          decoration: BoxDecoration(gradient: AppColors.backgroundGradient(context)),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 20.h),
                        // Lottie Animation
                        Center(
                          child: Lottie.asset(
                            AppAssets.consultationLottie,
                            width: 280.w,
                            height: 220.h,
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        // Welcome Text
                        Text(
                          'Welcome Back! 👋',
                          style: theme.textTheme.displaySmall,
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Sign in to continue to eSanté',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: context.textSecondaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 40.h),
                        // Email Field
                        CustomTextField(
                          controller: _emailController,
                          label: 'Email',
                          hintText: 'Enter your email',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20.h),
                        // Password Field
                        CustomTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hintText: 'Enter your password',
                          prefixIcon: Icons.lock_outline,
                          isPassword: true,
                          textInputAction: TextInputAction.done,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 12.h),
                        // Forgot Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              context.pushPage(const ForgotPasswordScreen());
                            },
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 24.h),
                        // Login Button
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            return CustomButton(
                              text: 'Sign In',
                              isLoading: state is AuthLoading,
                              onPressed: _onLogin,
                            );
                          },
                        ),
                        SizedBox(height: 24.h),
                        // Divider
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1.h,
                                color: context.dividerColor,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: Text(
                                'or',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: context.textSecondaryColor,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1.h,
                                color: context.dividerColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24.h),
                        // Sign Up
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: context.textSecondaryColor,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                context.pushPage(const SignupScreen());
                              },
                              child: Text(
                                'Sign Up',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 40.h),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

