import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:medical_app/core/utils/custom_snack_bar.dart';
import 'package:medical_app/core/utils/navigation_with_transition.dart';
import 'package:medical_app/core/widgets/common/common_widgets.dart';
import 'package:medical_app/features/authentication/presentation/pages/forgot_password_screen.dart';
import 'package:medical_app/features/authentication/presentation/pages/role_selection_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../home/presentation/pages/home_medecin.dart';
import '../../../home/presentation/pages/home_patient.dart';
import '../blocs/login BLoC/login_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isObsecureText = true;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _floatingController;
  late AnimationController _shimmerController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _floatingAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _floatingController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1A1A2E), const Color(0xFF16213E), const Color(0xFF0F3460)]
                : [const Color(0xFFE8F4FD), const Color(0xFFF5F9FF), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Animated background decorations
              _buildFloatingDecorations(isDark),

              // Main content
              GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          children: [
                            SizedBox(height: 20.h),

                            // Header with Lottie
                            _buildHeader(isDark),

                            SizedBox(height: 20.h),

                            // Welcome text
                            _buildWelcomeText(isDark),

                            SizedBox(height: 30.h),

                            // Login form card
                            _buildLoginCard(isDark),

                            SizedBox(height: 24.h),

                            // Or divider
                            _buildOrDivider(isDark),

                            SizedBox(height: 24.h),

                            // Social login
                            _buildSocialLogin(isDark),

                            SizedBox(height: 30.h),

                            // Sign up link
                            _buildSignUpLink(isDark),

                            SizedBox(height: 20.h),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingDecorations(bool isDark) {
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // Top right blob
            Positioned(
              top: -80 + _floatingAnimation.value,
              right: -50,
              child: Container(
                width: 200.w,
                height: 200.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryColor.withOpacity(0.25),
                      AppColors.primaryColor.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom left blob
            Positioned(
              bottom: 100 - _floatingAnimation.value,
              left: -80,
              child: Container(
                width: 220.w,
                height: 220.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00C853).withOpacity(0.15),
                      const Color(0xFF00C853).withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Floating particles
            ...List.generate(6, (index) {
              final offset = _floatingAnimation.value * (index.isEven ? 1.5 : -1.5);
              return Positioned(
                top: (60 + index * 100).h + offset,
                left: (20 + index * 50).w,
                child: Container(
                  width: (6 + index * 1.5).w,
                  height: (6 + index * 1.5).w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (index.isEven 
                        ? AppColors.primaryColor 
                        : const Color(0xFF00C853))
                        .withOpacity(0.3),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildHeader(bool isDark) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value.clamp(0.0, 1.0),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Container(
        height: 180.h,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glow effect
            Container(
              width: 160.w,
              height: 160.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.3),
                    blurRadius: 50,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
            // Lottie animation
            Lottie.asset(
              'assets/lotties/login.json',
              fit: BoxFit.contain,
              repeat: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeText(bool isDark) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          // Animated gradient title
          AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, child) {
              return ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    colors: [
                      AppColors.primaryColor,
                      const Color(0xFF64B5F6),
                      AppColors.primaryColor,
                    ],
                    stops: [
                      0.0,
                      _shimmerController.value,
                      1.0,
                    ],
                  ).createShader(bounds);
                },
                child: Text(
                  context.tr('login_screen.welcome_back'),
                  style: GoogleFonts.raleway(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 8.h),
          Text(
            context.tr('login_screen.sign_in_to_continue'),
            style: GoogleFonts.raleway(
              fontSize: 16.sp,
              color: isDark ? Colors.white70 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard(bool isDark) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(28.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
          border: Border.all(
            color: isDark 
                ? Colors.white.withOpacity(0.1) 
                : Colors.grey.shade100,
            width: 1,
          ),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Email field
              _buildStaggeredField(
                delay: 0,
                child: AppTextField(
                  controller: emailController,
                  label: context.tr('login_screen.email'),
                  hint: context.tr('login_screen.email_placeholder'),
                  icon: Icons.email_outlined,
                  isDark: isDark,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.tr('login_screen.email_required');
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return context.tr('login_screen.invalid_email_message');
                    }
                    return null;
                  },
                ),
              ),

              SizedBox(height: 20.h),

              // Password field
              _buildStaggeredField(
                delay: 100,
                child: _buildPasswordField(isDark),
              ),

              SizedBox(height: 12.h),

              // Forgot password
              _buildStaggeredField(
                delay: 200,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      navigateToAnotherScreenWithSlideTransitionFromRightToLeft(
                        context,
                        ForgotPasswordScreen(),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
                      child: Text(
                        context.tr('login_screen.forgot_password'),
                        style: GoogleFonts.raleway(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 24.h),

              // Login button
              _buildStaggeredField(
                delay: 300,
                child: _buildLoginButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaggeredField({required int delay, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOut,
      builder: (context, value, _) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildPasswordField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('login_screen.password'),
          style: GoogleFonts.raleway(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: 10.h),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: passwordController,
            obscureText: _isObsecureText,
            style: GoogleFonts.raleway(
              fontSize: 14.sp,
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: context.tr('login_screen.password_placeholder'),
              hintStyle: GoogleFonts.raleway(
                fontSize: 14.sp,
                color: isDark ? Colors.white38 : Colors.grey.shade400,
              ),
              prefixIcon: Container(
                margin: EdgeInsets.all(10.r),
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(Icons.lock_outline, color: AppColors.primaryColor, size: 20.sp),
              ),
              suffixIcon: GestureDetector(
                onTap: () {
                  setState(() {
                    _isObsecureText = !_isObsecureText;
                  });
                },
                child: Container(
                  margin: EdgeInsets.all(10.r),
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    _isObsecureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.primaryColor,
                    size: 22.sp,
                  ),
                ),
              ),
              filled: true,
              fillColor: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFF8FAFC),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(
                  color: isDark ? Colors.white12 : Colors.grey.shade200,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return context.tr("password_required");
              }
              if (value.length < 6) {
                return context.tr("password_too_short");
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return BlocConsumer<LoginBloc, LoginState>(
      listener: (context, state) async {
        if (state is LoginSuccess) {
          showSuccessSnackBar(context, context.tr('login_screen.login_success'));
          if (state.user.role == "medecin") {
            navigateToAnotherScreenWithSlideTransitionFromRightToLeftPushReplacement(
              context,
              const HomeMedecin(),
            );
          } else {
            navigateToAnotherScreenWithSlideTransitionFromRightToLeftPushReplacement(
              context,
              const HomePatient(),
            );
          }
        } else if (state is LoginError) {
          if (state.message.contains('Account is not activated') ||
              state.message.contains('verify your email')) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
                title: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28.sp),
                    SizedBox(width: 10.w),
                    Text(
                      context.tr('login_screen.verification_required'),
                      style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                content: Text(
                  context.tr('login_screen.account_not_activated'),
                  style: GoogleFonts.raleway(),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(
                      context.tr('common.ok'),
                      style: GoogleFonts.raleway(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            showErrorSnackBar(context, state.message);
          }
        }
      },
      builder: (context, state) {
        final isLoading = state is LoginLoading && state.isEmailPasswordLogin;
        return Container(
          width: double.infinity,
          height: 58.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isLoading
                  ? [Colors.grey.shade400, Colors.grey.shade500]
                  : [AppColors.primaryColor, const Color(0xFF64B5F6)],
            ),
            boxShadow: isLoading
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading
                  ? null
                  : () {
                      if (_formKey.currentState!.validate()) {
                        context.read<LoginBloc>().add(
                          LoginWithEmailAndPassword(
                            email: emailController.text,
                            password: passwordController.text,
                          ),
                        );
                      }
                    },
              borderRadius: BorderRadius.circular(18.r),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 24.w,
                        height: 24.w,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            context.tr('login_screen.sign_in'),
                            style: GoogleFonts.raleway(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Container(
                            padding: EdgeInsets.all(6.r),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 18.sp,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrDivider(bool isDark) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: child,
        );
      },
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    isDark ? Colors.white24 : Colors.grey.shade300,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                context.tr('login_screen.or_login_with'),
                style: GoogleFonts.raleway(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    isDark ? Colors.white24 : Colors.grey.shade300,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLogin(bool isDark) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: BlocConsumer<LoginBloc, LoginState>(
        listener: (context, state) async {
          if (state is LoginSuccess) {
            showSuccessSnackBar(context, context.tr('login_screen.login_success'));
            if (state.user.role == "medecin") {
              navigateToAnotherScreenWithSlideTransitionFromRightToLeftPushReplacement(
                context,
                const HomeMedecin(),
              );
            } else {
              navigateToAnotherScreenWithSlideTransitionFromRightToLeftPushReplacement(
                context,
                const HomePatient(),
              );
            }
          } else if (state is LoginError) {
            showErrorSnackBar(context, state.message);
          }
        },
        builder: (context, state) {
          final isEmailPasswordLoading = state is LoginLoading && state.isEmailPasswordLogin;
          final isGoogleLoading = state is LoginLoading && !state.isEmailPasswordLogin;

          return Container(
            width: double.infinity,
            height: 58.h,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(
                color: isDark ? Colors.white24 : Colors.grey.shade200,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isGoogleLoading || isEmailPasswordLoading
                    ? null
                    : () {
                        context.read<LoginBloc>().add(LoginWithGoogle());
                      },
                borderRadius: BorderRadius.circular(18.r),
                child: Center(
                  child: isGoogleLoading
                      ? SizedBox(
                          width: 24.w,
                          height: 24.w,
                          child: CircularProgressIndicator(
                            color: AppColors.primaryColor,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.r),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: Icon(
                                FontAwesomeIcons.google,
                                size: 18.sp,
                                color: const Color(0xFFDB4437),
                              ),
                            ),
                            SizedBox(width: 14.w),
                            Text(
                              context.tr('login_screen.continue_with_google'),
                              style: GoogleFonts.raleway(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSignUpLink(bool isDark) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            context.tr('login_screen.no_account'),
            style: GoogleFonts.raleway(
              fontSize: 14.sp,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: () {
              navigateToAnotherScreenWithSlideTransitionFromRightToLeft(
                context,
                const RoleSelectionScreen(),
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryColor.withOpacity(0.1),
                    const Color(0xFF64B5F6).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                context.tr('login_screen.sign_up'),
                style: GoogleFonts.raleway(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
