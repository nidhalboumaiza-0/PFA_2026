import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:lottie/lottie.dart';
import 'package:medical_app/core/widgets/common/common_widgets.dart';
import '../../../../core/utils/app_colors.dart';
import 'package:medical_app/core/utils/navigation_with_transition.dart';
import 'signup_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with TickerProviderStateMixin {
  String? selectedRole;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _floatingController;
  late AnimationController _shimmerController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();
    
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
    
    // Pulse animation for selected card
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Floating animation for decorations
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _floatingAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );
    
    // Shimmer animation
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
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
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      children: [
                        SizedBox(height: 16.h),
                        
                        // Back button
                        const AppBackButton(),

                        SizedBox(height: 8.h),

                        // Lottie Animation
                        _buildHeaderAnimation(),

                        SizedBox(height: 8.h),

                        // Title with animated gradient
                        _buildAnimatedTitle(isDark),

                        SizedBox(height: 16.h),

                        // Role cards
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Patient Card
                              _buildAnimatedRoleCard(
                                isDark: isDark,
                                role: 'patient',
                                imagePath: 'assets/images/med.png',
                                title: context.tr("patient"),
                                description: context.tr("patient_role_description"),
                                gradientColors: [const Color(0xFF00C853), const Color(0xFF69F0AE)],
                                iconData: Icons.favorite_rounded,
                                isSelected: selectedRole == 'patient',
                                delay: 0,
                                onTap: () {
                                  setState(() {
                                    selectedRole = 'patient';
                                  });
                                },
                              ),

                              SizedBox(height: 16.h),

                              // Doctor Card
                              _buildAnimatedRoleCard(
                                isDark: isDark,
                                role: 'medecin',
                                imagePath: 'assets/images/medecin.png',
                                title: context.tr("doctor"),
                                description: context.tr("doctor_role_description"),
                                gradientColors: [AppColors.primaryColor, const Color(0xFF64B5F6)],
                                iconData: Icons.medical_services_rounded,
                                isSelected: selectedRole == 'medecin',
                                delay: 200,
                                onTap: () {
                                  setState(() {
                                    selectedRole = 'medecin';
                                  });
                                },
                              ),
                            ],
                          ),
                        ),

                        // Continue button with animation
                        _buildAnimatedContinueButton(isDark),
                        
                        SizedBox(height: 24.h),
                      ],
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
              bottom: 80 - _floatingAnimation.value,
              left: -80,
              child: Container(
                width: 220.w,
                height: 220.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00C853).withOpacity(0.2),
                      const Color(0xFF00C853).withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Animated particles
            ...List.generate(8, (index) {
              final offset = _floatingAnimation.value * (index.isEven ? 1.5 : -1.5);
              return Positioned(
                top: (50 + index * 90).h + offset,
                left: (20 + index * 40).w,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 1000 + index * 200),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value * 0.5,
                      child: Container(
                        width: (6 + index * 1.5).w,
                        height: (6 + index * 1.5).w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index.isEven 
                              ? AppColors.primaryColor.withOpacity(0.4)
                              : const Color(0xFF00C853).withOpacity(0.4),
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

  Widget _buildHeaderAnimation() {
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
        height: 130.h,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glow effect behind Lottie
            Container(
              width: 140.w,
              height: 140.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.3),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
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

  Widget _buildAnimatedTitle(bool isDark) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
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
                      const Color(0xFF00C853),
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
                  context.tr("join_as"),
                  style: GoogleFonts.raleway(
                    fontSize: 34.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 10.h),
          Text(
            context.tr("select_your_role"),
            textAlign: TextAlign.center,
            style: GoogleFonts.raleway(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedRoleCard({
    required bool isDark,
    required String role,
    required String imagePath,
    required String title,
    required String description,
    required List<Color> gradientColors,
    required IconData iconData,
    required bool isSelected,
    required int delay,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 700 + delay),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.7 + (0.3 * value),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: isSelected ? _pulseAnimation.value : 1.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradientColors,
                        )
                      : null,
                  color: isSelected 
                      ? null 
                      : (isDark ? Colors.white.withOpacity(0.08) : Colors.white),
                  borderRadius: BorderRadius.circular(28.r),
                  border: Border.all(
                    color: isSelected 
                        ? Colors.transparent 
                        : gradientColors[0].withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: gradientColors[0].withOpacity(0.5),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                            spreadRadius: -5,
                          ),
                          BoxShadow(
                            color: gradientColors[1].withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                ),
                child: Row(
                  children: [
                    // Animated image container
                    Hero(
                      tag: 'role_$role',
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        width: 85.w,
                        height: 85.w,
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Colors.white.withOpacity(0.25)
                              : gradientColors[0].withOpacity(0.12),
                          borderRadius: BorderRadius.circular(22.r),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.3),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(22.r),
                              child: Image.asset(
                                imagePath,
                                fit: BoxFit.cover,
                                width: 85.w,
                                height: 85.w,
                              ),
                            ),
                            // Overlay icon when selected
                            if (isSelected)
                              Container(
                                decoration: BoxDecoration(
                                  color: gradientColors[0].withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(22.r),
                                ),
                                child: Icon(
                                  iconData,
                                  color: Colors.white,
                                  size: 40.sp,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(width: 18.w),

                    // Text content with animations
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: GoogleFonts.raleway(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                              color: isSelected 
                                  ? Colors.white 
                                  : (isDark ? Colors.white : const Color(0xFF1E293B)),
                            ),
                            child: Text(title),
                          ),
                          SizedBox(height: 8.h),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: GoogleFonts.raleway(
                              fontSize: 13.sp,
                              height: 1.4,
                              color: isSelected 
                                  ? Colors.white.withOpacity(0.9)
                                  : (isDark ? Colors.white60 : Colors.grey.shade600),
                            ),
                            child: Text(description),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: 8.w),

                    // Selection indicator with bounce animation
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 0.8 + (0.2 * value),
                          child: Container(
                            width: 32.w,
                            height: 32.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected 
                                  ? Colors.white 
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected 
                                    ? Colors.white 
                                    : (isDark ? Colors.white30 : Colors.grey.shade300),
                                width: 2.5,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.5),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check_rounded,
                                    size: 20.sp,
                                    color: gradientColors[0],
                                  )
                                : null,
                          ),
                        );
                      },
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

  Widget _buildAnimatedContinueButton(bool isDark) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 60 * (1 - value)),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: AnimatedOpacity(
        opacity: selectedRole != null ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 300),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: double.infinity,
          height: 62.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: selectedRole != null
                  ? [AppColors.primaryColor, const Color(0xFF64B5F6)]
                  : [Colors.grey.shade400, Colors.grey.shade500],
            ),
            boxShadow: selectedRole != null
                ? [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.5),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                      spreadRadius: -5,
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: selectedRole != null
                  ? () {
                      navigateToAnotherScreenWithSlideTransitionFromRightToLeft(
                        context,
                        SignupScreen(selectedRole: selectedRole!),
                      );
                    }
                  : null,
              borderRadius: BorderRadius.circular(22.r),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.tr("continue"),
                    style: GoogleFonts.raleway(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(selectedRole != null ? 0.25 : 0.15),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
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
  }
}
