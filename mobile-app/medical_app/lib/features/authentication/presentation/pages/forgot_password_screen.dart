import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/core/utils/custom_snack_bar.dart';
import 'package:medical_app/core/widgets/common/common_widgets.dart';
import 'package:medical_app/features/authentication/presentation/blocs/forget%20password%20bloc/forgot_password_bloc.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  
  bool _emailSent = false;
  bool _isEmailFocused = false;

  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _floatingController;
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late AnimationController _successController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    // Fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    // Slide animation
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    // Floating animation for decorations
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _floatingAnimation = Tween<double>(begin: -15, end: 15).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    // Shimmer animation
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Success animation controller
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _floatingController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    _successController.dispose();
    emailController.dispose();
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
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Column(
                          children: [
                            SizedBox(height: 16.h),

                            // Back button
                            const AppBackButton(),

                            SizedBox(height: 20.h),

                            // Animated illustration
                            _buildAnimatedIllustration(),

                            SizedBox(height: 24.h),

                            // Title section
                            _buildTitleSection(isDark),

                            SizedBox(height: 32.h),

                            // Email form or success message
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0.1, 0),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                              child: _emailSent
                                  ? _buildSuccessContent(isDark)
                                  : _buildEmailForm(isDark),
                            ),

                            SizedBox(height: 24.h),

                            // Back to login
                            _buildBackToLogin(isDark),

                            SizedBox(height: 40.h),
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
            // Top right gradient blob
            Positioned(
              top: -100 + _floatingAnimation.value,
              right: -80,
              child: Container(
                width: 250.w,
                height: 250.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFF6B6B).withOpacity(0.2),
                      const Color(0xFFFF6B6B).withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom left gradient blob
            Positioned(
              bottom: 50 - _floatingAnimation.value,
              left: -100,
              child: Container(
                width: 280.w,
                height: 280.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryColor.withOpacity(0.2),
                      AppColors.primaryColor.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Center accent blob
            Positioned(
              top: 200.h + _floatingAnimation.value * 0.5,
              right: 50.w,
              child: Container(
                width: 100.w,
                height: 100.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF6C63FF).withOpacity(0.15),
                      const Color(0xFF6C63FF).withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Floating particles
            ...List.generate(6, (index) {
              final offset = _floatingAnimation.value * (index.isEven ? 1.2 : -1.2);
              return Positioned(
                top: (80 + index * 120).h + offset,
                left: (30 + index * 50).w,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 800 + index * 150),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: (value * 0.4).clamp(0.0, 1.0),
                      child: Transform.rotate(
                        angle: _floatingAnimation.value * 0.02,
                        child: Container(
                          width: (8 + index * 2).w,
                          height: (8 + index * 2).w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index.isEven
                                ? const Color(0xFFFF6B6B).withOpacity(0.5)
                                : AppColors.primaryColor.withOpacity(0.5),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedIllustration() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: (0.5 + 0.5 * value).clamp(0.0, 1.0),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _emailSent ? 1.0 : _pulseAnimation.value,
            child: SizedBox(
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
                          color: _emailSent
                              ? const Color(0xFF00C853).withOpacity(0.3)
                              : const Color(0xFFFF6B6B).withOpacity(0.3),
                          blurRadius: 50,
                          spreadRadius: 15,
                        ),
                      ],
                    ),
                  ),
                  // Lottie animation
                  Lottie.asset(
                    _emailSent
                        ? 'assets/lotties/done.json'
                        : 'assets/lotties/forgotpassword.json',
                    fit: BoxFit.contain,
                    repeat: !_emailSent,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTitleSection(bool isDark) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
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
                    colors: _emailSent
                        ? [
                            const Color(0xFF00C853),
                            const Color(0xFF69F0AE),
                            const Color(0xFF00C853),
                          ]
                        : [
                            const Color(0xFFFF6B6B),
                            AppColors.primaryColor,
                            const Color(0xFFFF6B6B),
                          ],
                    stops: [
                      0.0,
                      _shimmerController.value,
                      1.0,
                    ],
                  ).createShader(bounds);
                },
                child: Text(
                  _emailSent ? context.tr('forgot_password_screen.check_your_email') : context.tr('forgot_password_screen.title'),
                  style: GoogleFonts.raleway(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Text(
              _emailSent
                  ? context.tr('forgot_password_screen.email_sent_message')
                  : context.tr('forgot_password_screen.subtitle'),
              textAlign: TextAlign.center,
              style: GoogleFonts.raleway(
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailForm(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('email_form'),
        children: [
          // Email input card
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 700),
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.r),
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
                border: Border.all(
                  color: _isEmailFocused
                      ? AppColors.primaryColor
                      : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isEmailFocused
                        ? AppColors.primaryColor.withOpacity(0.2)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: _isEmailFocused ? 25 : 15,
                    offset: const Offset(0, 8),
                    spreadRadius: _isEmailFocused ? 2 : 0,
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(20.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Email label with icon
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.r),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            Icons.email_outlined,
                            color: AppColors.primaryColor,
                            size: 22.sp,
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Text(
                          context.tr('forgot_password_screen.email_label'),
                          style: GoogleFonts.raleway(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    // Email text field
                    Focus(
                      onFocusChange: (hasFocus) {
                        setState(() {
                          _isEmailFocused = hasFocus;
                        });
                      },
                      child: TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.raleway(
                          fontSize: 16.sp,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: context.tr('forgot_password_screen.email_hint'),
                          hintStyle: GoogleFonts.raleway(
                            color: Colors.grey[400],
                            fontSize: 15.sp,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey.shade50,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 18.h,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: BorderSide(
                              color: AppColors.primaryColor.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: const BorderSide(
                              color: Colors.redAccent,
                              width: 1,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: const BorderSide(
                              color: Colors.redAccent,
                              width: 1,
                            ),
                          ),
                          errorStyle: GoogleFonts.raleway(
                            color: Colors.redAccent,
                            fontSize: 12.sp,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return context.tr("email_required");
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                            return context.tr("invalid_email_message");
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: 28.h),

          // Submit button
          _buildSubmitButton(isDark),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(bool isDark) {
    return BlocConsumer<ForgotPasswordBloc, ForgotPasswordState>(
      listener: (context, state) {
        if (state is ForgotPasswordSuccess) {
          setState(() {
            _emailSent = true;
          });
          _successController.forward();
          showSuccessSnackBar(context, context.tr('forgot_password_screen.success_message'));
        } else if (state is ForgotPasswordError) {
          showErrorSnackBar(context, state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is ForgotPasswordLoading;
        
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 40 * (1 - value)),
              child: Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: child,
              ),
            );
          },
          child: Container(
            width: double.infinity,
            height: 62.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22.r),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFF6B6B),
                  Color(0xFF2196F3),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B6B).withOpacity(0.4),
                  blurRadius: 25,
                  offset: const Offset(0, 12),
                  spreadRadius: -5,
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
                          context.read<ForgotPasswordBloc>().add(
                                ForgotPasswordRequested(
                                  email: emailController.text.trim(),
                                ),
                              );
                        }
                      },
                borderRadius: BorderRadius.circular(22.r),
                child: Center(
                  child: isLoading
                      ? SizedBox(
                          width: 28.w,
                          height: 28.w,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              context.tr('forgot_password_screen.send_reset_link'),
                              style: GoogleFonts.raleway(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Container(
                              padding: EdgeInsets.all(10.r),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 20.sp,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuccessContent(bool isDark) {
    return Column(
      key: const ValueKey('success_content'),
      children: [
        // Email sent card
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value.clamp(0.0, 1.5),
              child: child,
            );
          },
          child: Container(
            padding: EdgeInsets.all(28.r),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28.r),
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00C853).withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              children: [
                // Email icon with check
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 80.w,
                      height: 80.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF00C853).withOpacity(0.2),
                            const Color(0xFF69F0AE).withOpacity(0.1),
                          ],
                        ),
                      ),
                    ),
                    Icon(
                      Icons.mark_email_read_rounded,
                      size: 44.sp,
                      color: const Color(0xFF00C853),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                Text(
                  emailController.text,
                  style: GoogleFonts.raleway(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  context.tr('forgot_password_screen.check_inbox'),
                  style: GoogleFonts.raleway(
                    fontSize: 14.sp,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 24.h),

        // Resend option
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
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
                context.tr('forgot_password_screen.didnt_receive'),
                style: GoogleFonts.raleway(
                  fontSize: 14.sp,
                  color: isDark ? Colors.white70 : Colors.grey.shade600,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _emailSent = false;
                  });
                },
                child: Text(
                  context.tr('forgot_password_screen.resend'),
                  style: GoogleFonts.raleway(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFF6B6B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBackToLogin(bool isDark) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.2)
                  : AppColors.primaryColor.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_back_rounded,
                size: 20.sp,
                color: AppColors.primaryColor,
              ),
              SizedBox(width: 10.w),
              Text(
                context.tr('forgot_password_screen.back_to_login'),
                style: GoogleFonts.raleway(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}