import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:lottie/lottie.dart';
import 'package:medical_app/core/widgets/common/common_widgets.dart';
import 'package:medical_app/features/authentication/presentation/pages/signup_medecin_screen.dart';
import 'package:medical_app/features/authentication/presentation/pages/signup_patient_screen.dart';
import '../../../../core/utils/app_colors.dart';
import '../../domain/entities/medecin_entity.dart';
import '../../domain/entities/patient_entity.dart';
import 'package:medical_app/core/utils/navigation_with_transition.dart';

class SignupScreen extends StatefulWidget {
  final String selectedRole;

  const SignupScreen({super.key, required this.selectedRole});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with TickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController nomController = TextEditingController();
  final TextEditingController prenomController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController birthdayController = TextEditingController();

  String gender = 'Homme';
  DateTime? selectedDate;
  PhoneNumber? phoneNumber;
  bool isPhoneValid = false;

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
    nomController.dispose();
    prenomController.dispose();
    emailController.dispose();
    birthdayController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _floatingController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime today = DateTime.now();
    final DateTime minimumBirthDate = DateTime(
      today.year - 16,
      today.month,
      today.day,
    );

    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate:
            selectedDate ?? DateTime(today.year - 25, today.month, today.day),
        firstDate: DateTime(1900),
        lastDate: minimumBirthDate,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppColors.primaryColor,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
              dialogBackgroundColor: Colors.white,
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryColor,
                ),
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        setState(() {
          selectedDate = picked;
          birthdayController.text = DateFormat('dd/MM/yyyy').format(picked);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr("error"))),
      );
    }
  }

  bool isUserAtLeast16() {
    if (selectedDate == null) return false;
    final DateTime today = DateTime.now();
    final DateTime minimumBirthDate = DateTime(
      today.year - 16,
      today.month,
      today.day,
    );
    return selectedDate!.isBefore(minimumBirthDate) ||
        selectedDate!.isAtSameMomentAs(minimumBirthDate);
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() && isPhoneValid) {
      final completePhoneNumber = phoneNumber?.completeNumber ?? '';

      if (widget.selectedRole == 'patient') {
        final patientEntity = PatientEntity(
          name: nomController.text,
          lastName: prenomController.text,
          email: emailController.text,
          role: 'patient',
          gender: gender,
          phoneNumber: completePhoneNumber,
          dateOfBirth: selectedDate!,
          antecedent: '',
        );
        navigateToAnotherScreenWithSlideTransitionFromRightToLeft(
          context,
          SignupPatientScreen(patientEntity: patientEntity),
        );
      } else {
        final medecinEntity = MedecinEntity(
          name: nomController.text,
          lastName: prenomController.text,
          email: emailController.text,
          role: 'medecin',
          gender: gender,
          phoneNumber: completePhoneNumber,
          dateOfBirth: selectedDate!,
          speciality: '',
          numLicence: '',
        );
        navigateToAnotherScreenWithSlideTransitionFromRightToLeft(
          context,
          SignupMedecinScreen(medecinEntity: medecinEntity),
        );
      }
    } else if (!isPhoneValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr("phone_number_required")),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPatient = widget.selectedRole == 'patient';

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
              _buildFloatingDecorations(isDark, isPatient),

              // Main content
              Column(
                children: [
                  // Header
                  _buildAnimatedHeader(isDark, isPatient),

                  // Content
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          physics: const BouncingScrollPhysics(),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 16.h),

                                // Step indicator
                                _buildAnimatedStepIndicator(isDark),

                                SizedBox(height: 16.h),

                                // Welcome card with Lottie
                                _buildWelcomeCard(isDark),

                                SizedBox(height: 16.h),

                                // Form fields with staggered animations
                                _buildAnimatedFormFields(isDark),

                                SizedBox(height: 20.h),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Bottom button
                  _buildAnimatedBottomButton(isDark),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingDecorations(bool isDark, bool isPatient) {
    final Color accentColor = isPatient 
        ? const Color(0xFF00C853) 
        : AppColors.primaryColor;

    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: -60 + _floatingAnimation.value,
              right: -40,
              child: Container(
                width: 180.w,
                height: 180.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accentColor.withOpacity(0.2),
                      accentColor.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 200 - _floatingAnimation.value,
              left: -60,
              child: Container(
                width: 160.w,
                height: 160.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryColor.withOpacity(0.15),
                      AppColors.primaryColor.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Animated particles
            ...List.generate(6, (index) {
              return Positioned(
                top: (80 + index * 120).h + _floatingAnimation.value * (index.isEven ? 1 : -1),
                right: (20 + index * 50).w,
                child: Container(
                  width: (5 + index).w,
                  height: (5 + index).w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (index.isEven ? accentColor : AppColors.primaryColor)
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

  Widget _buildAnimatedHeader(bool isDark, bool isPatient) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -30 * (1 - value)),
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1A1A2E).withOpacity(0.9), Colors.transparent]
                : [Colors.white.withOpacity(0.9), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            // Animated back button
            const AppBackButton(),
            Expanded(
              child: Column(
                children: [
                  Text(
                    context.tr("signup_title"),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.raleway(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  // Animated role badge
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isPatient
                              ? [const Color(0xFF00C853), const Color(0xFF69F0AE)]
                              : [AppColors.primaryColor, const Color(0xFF64B5F6)],
                        ),
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: (isPatient 
                                    ? const Color(0xFF00C853) 
                                    : AppColors.primaryColor)
                                .withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPatient ? Icons.favorite_rounded : Icons.medical_services_rounded,
                            color: Colors.white,
                            size: 14.sp,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            isPatient ? context.tr("patient") : context.tr("doctor"),
                            style: GoogleFonts.raleway(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 44.w),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedStepIndicator(bool isDark) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final isActive = index == 0;
            final isCompleted = false;
            return Expanded(
              child: Row(
                children: [
                  if (index > 0)
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: isCompleted
                              ? LinearGradient(
                                  colors: [AppColors.primaryColor, const Color(0xFF64B5F6)],
                                )
                              : null,
                          color: isCompleted ? null : (isDark ? Colors.white24 : Colors.grey.shade200),
                        ),
                      ),
                    ),
                  _buildStepCircle(index + 1, isActive, isCompleted, isDark),
                  if (index < 2)
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: isDark ? Colors.white24 : Colors.grey.shade200,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildStepCircle(int step, bool isActive, bool isCompleted, bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: 44.w,
      height: 44.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isActive || isCompleted
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryColor, const Color(0xFF64B5F6)],
              )
            : null,
        color: isActive || isCompleted ? null : Colors.transparent,
        border: Border.all(
          color: isActive || isCompleted
              ? Colors.transparent
              : (isDark ? Colors.white30 : Colors.grey.shade300),
          width: 2,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.primaryColor.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Center(
        child: isCompleted
            ? Icon(Icons.check_rounded, color: Colors.white, size: 20.sp)
            : Text(
                step.toString(),
                style: GoogleFonts.raleway(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: isActive
                      ? Colors.white
                      : (isDark ? Colors.white60 : Colors.grey.shade500),
                ),
              ),
      ),
    );
  }

  Widget _buildWelcomeCard(bool isDark) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        );
      },
      child: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryColor.withOpacity(0.1),
              const Color(0xFF64B5F6).withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: AppColors.primaryColor.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.r),
                child: Lottie.asset(
                  'assets/lotties/login.json',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedBuilder(
                    animation: _shimmerController,
                    builder: (context, child) {
                      return ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            colors: [
                              isDark ? Colors.white : const Color(0xFF1E293B),
                              AppColors.primaryColor,
                              isDark ? Colors.white : const Color(0xFF1E293B),
                            ],
                            stops: [
                              0.0,
                              _shimmerController.value,
                              1.0,
                            ],
                          ).createShader(bounds);
                        },
                        child: Text(
                          context.tr("personal_information"),
                          style: GoogleFonts.raleway(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    context.tr("fill_your_details"),
                    style: GoogleFonts.raleway(
                      fontSize: 13.sp,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedFormFields(bool isDark) {
    return Column(
      children: [
        // Name fields row
        _buildStaggeredField(
          delay: 100,
          child: Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: nomController,
                  label: context.tr("name_label"),
                  hint: context.tr("name_hint"),
                  icon: Icons.person_outline_rounded,
                  isDark: isDark,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.tr("name_required");
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: AppTextField(
                  controller: prenomController,
                  label: context.tr("first_name_label"),
                  hint: context.tr("first_name_hint"),
                  icon: Icons.person_outline_rounded,
                  isDark: isDark,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.tr("first_name_required");
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 20.h),

        // Email field
        _buildStaggeredField(
          delay: 200,
          child: AppTextField(
            controller: emailController,
            label: context.tr("email"),
            hint: context.tr("email_hint"),
            icon: Icons.email_outlined,
            isDark: isDark,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return context.tr("email_required");
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return context.tr("invalid_email_message");
              }
              return null;
            },
          ),
        ),

        SizedBox(height: 20.h),

        // Phone field
        _buildStaggeredField(
          delay: 300,
          child: _buildPhoneField(isDark),
        ),

        SizedBox(height: 20.h),

        // Date field
        _buildStaggeredField(
          delay: 400,
          child: _buildDateField(isDark),
        ),

        SizedBox(height: 20.h),

        // Gender selector
        _buildStaggeredField(
          delay: 500,
          child: _buildGenderSelector(isDark),
        ),
      ],
    );
  }

  Widget _buildStaggeredField({required int delay, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOut,
      builder: (context, value, _) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        );
      },
    );
  }

  Widget _buildPhoneField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr("phone_number_label"),
          style: GoogleFonts.raleway(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IntlPhoneField(
            decoration: InputDecoration(
              hintText: context.tr("phone_number_hint"),
              hintStyle: GoogleFonts.raleway(
                fontSize: 14.sp,
                color: isDark ? Colors.white38 : Colors.grey.shade400,
              ),
              filled: false,
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
            ),
            initialCountryCode: 'TN',
            style: GoogleFonts.raleway(
              fontSize: 14.sp,
              color: isDark ? Colors.white : Colors.black87,
            ),
            dropdownTextStyle: GoogleFonts.raleway(
              fontSize: 14.sp,
              color: isDark ? Colors.white : Colors.black87,
            ),
            flagsButtonPadding: EdgeInsets.only(left: 16.w),
            dropdownIconPosition: IconPosition.trailing,
            dropdownIcon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.primaryColor,
            ),
            onChanged: (phone) {
              phoneNumber = phone;
              setState(() {
                isPhoneValid = phone.isValidNumber();
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr("date_of_birth_label"),
          style: GoogleFonts.raleway(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: AbsorbPointer(
            child: TextFormField(
              controller: birthdayController,
              style: GoogleFonts.raleway(
                fontSize: 14.sp,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: context.tr("date_of_birth_hint"),
                hintStyle: GoogleFonts.raleway(
                  fontSize: 14.sp,
                  color: isDark ? Colors.white38 : Colors.grey.shade400,
                ),
                prefixIcon: Container(
                  margin: EdgeInsets.all(8.r),
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.calendar_today_rounded,
                    color: AppColors.primaryColor,
                    size: 20.sp,
                  ),
                ),
                suffixIcon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primaryColor,
                ),
                filled: true,
                fillColor: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
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
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return context.tr("date_of_birth_required");
                }
                if (!isUserAtLeast16()) {
                  return context.tr("must_be_16_years");
                }
                return null;
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr("gender"),
          style: GoogleFonts.raleway(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _buildGenderOption(
                isDark: isDark,
                value: 'Homme',
                label: context.tr("Male"),
                icon: Icons.male_rounded,
                gradientColors: [const Color(0xFF2196F3), const Color(0xFF64B5F6)],
                isSelected: gender == 'Homme',
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: _buildGenderOption(
                isDark: isDark,
                value: 'Femme',
                label: context.tr("Female"),
                icon: Icons.female_rounded,
                gradientColors: [const Color(0xFFE91E63), const Color(0xFFF48FB1)],
                isSelected: gender == 'Femme',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderOption({
    required bool isDark,
    required String value,
    required String label,
    required IconData icon,
    required List<Color> gradientColors,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          gender = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(vertical: 18.h),
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
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? Colors.white12 : Colors.grey.shade200),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: gradientColors[0].withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.white.withOpacity(0.25)
                    : gradientColors[0].withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : gradientColors[0],
                size: 22.sp,
              ),
            ),
            SizedBox(width: 10.w),
            Text(
              label,
              style: GoogleFonts.raleway(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.grey.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBottomButton(bool isDark) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        );
      },
      child: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [Colors.transparent, const Color(0xFF1A1A2E)]
                : [Colors.transparent, Colors.white],
          ),
        ),
        child: Container(
          width: double.infinity,
          height: 60.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryColor, const Color(0xFF64B5F6)],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withOpacity(0.5),
                blurRadius: 25,
                offset: const Offset(0, 12),
                spreadRadius: -5,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _submitForm,
              borderRadius: BorderRadius.circular(20.r),
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
                  SizedBox(width: 12.w),
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12.r),
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
