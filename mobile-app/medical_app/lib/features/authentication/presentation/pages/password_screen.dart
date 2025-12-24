import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/core/utils/custom_snack_bar.dart';
import 'package:medical_app/core/utils/navigation_with_transition.dart';
import 'package:medical_app/core/widgets/common/common_widgets.dart';
import 'package:medical_app/features/authentication/presentation/blocs/Signup%20BLoC/signup_bloc.dart';
// import 'package:medical_app/features/authentication/presentation/pages/verify_code_screen.dart';
import 'package:medical_app/features/authentication/presentation/blocs/forget%20password%20bloc/forgot_password_bloc.dart';
import 'package:medical_app/features/authentication/presentation/pages/login_screen.dart';

class PasswordScreen extends StatefulWidget {
  final dynamic entity; // Can be PatientEntity or MedecinEntity

  const PasswordScreen({super.key, required this.entity});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  bool _isObscurePassword = true;
  bool _isObscureConfirmPassword = true;

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.whiteColor,
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Center(
                    child: Text(
                      context.tr("password"),
                      style: GoogleFonts.raleway(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Header image
                  Center(
                    child: Image.asset(
                      'assets/images/password.png',
                      height: 200.h,
                      width: 200.w,
                    ),
                  ),

                  SizedBox(height: 30.h),

                  // Form fields
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Password label
                        Text(
                          context.tr("password"),
                          style: GoogleFonts.raleway(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),

                        SizedBox(height: 10.h),

                        // Password field
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16.r),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: passwordController,
                            obscureText: _isObscurePassword,
                            style: GoogleFonts.raleway(
                              fontSize: 15.sp,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 16.h,
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
                                  color: AppColors.primaryColor,
                                  width: 1,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.r),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                  width: 1,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.r),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                  width: 1,
                                ),
                              ),
                              hintText: context.tr("password_hint"),
                              hintStyle: GoogleFonts.raleway(
                                color: Colors.grey[400],
                                fontSize: 15.sp,
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: AppColors.primaryColor,
                                size: 22.sp,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isObscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: AppColors.primaryColor,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isObscurePassword = !_isObscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return context.tr("password_required");
                              }
                              if (value.length < 6) {
                                return context.tr("password_min_length");
                              }
                              return null;
                            },
                          ),
                        ),

                        SizedBox(height: 24.h),

                        // Confirm Password label
                        Text(
                          context.tr("confirm_password_label"),
                          style: GoogleFonts.raleway(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),

                        SizedBox(height: 10.h),

                        // Confirm Password field
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16.r),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: confirmPasswordController,
                            obscureText: _isObscureConfirmPassword,
                            style: GoogleFonts.raleway(
                              fontSize: 15.sp,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 16.h,
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
                                  color: AppColors.primaryColor,
                                  width: 1,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.r),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                  width: 1,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.r),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                  width: 1,
                                ),
                              ),
                              hintText: context.tr("confirm_password_hint"),
                              hintStyle: GoogleFonts.raleway(
                                color: Colors.grey[400],
                                fontSize: 15.sp,
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: AppColors.primaryColor,
                                size: 22.sp,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isObscureConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: AppColors.primaryColor,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isObscureConfirmPassword =
                                        !_isObscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return context.tr("confirm_password_required");
                              }
                              if (value != passwordController.text) {
                                return context.tr("passwords_dont_match");
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 30.h),

                  // Submit button
                  BlocConsumer<SignupBloc, SignupState>(
                    listener: (context, state) {
                      if (state is SignupSuccess) {
                        // Updated success message explaining account activation
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              title: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 28.sp,
                                  ),
                                  SizedBox(width: 10.w),
                                  Text(
                                    context.tr("account_created"),
                                    style: GoogleFonts.raleway(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              content: Text(
                                context.tr("account_creation_success"),
                                style: GoogleFonts.raleway(height: 1.5),
                              ),
                              actions: [
                                TextButton(
                                  child: Text(
                                    context.tr("continue"),
                                    style: GoogleFonts.raleway(
                                      color: AppColors.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context); // Close dialog
                                    // Navigate to LoginScreen
                                    navigateToAnotherScreenWithSlideTransitionFromRightToLeft(
                                      context,
                                      const LoginScreen(),
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      } else if (state is SignupError) {
                        showErrorSnackBar(context, state.message);
                      }
                    },
                    builder: (context, state) {
                      final isLoading = state is SignupLoading;
                      return BlocListener<
                        ForgotPasswordBloc,
                        ForgotPasswordState
                      >(
                        listener: (context, forgotPasswordState) {
                          if (forgotPasswordState is ForgotPasswordLoading) {
                            // Show loading indicator while sending verification code
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) {
                                return Dialog(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16.r),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 30.h,
                                      horizontal: 20.w,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircularProgressIndicator(
                                          color: AppColors.primaryColor,
                                        ),
                                        SizedBox(height: 24.h),
                                        Text(
                                          context.tr("sending_verification_code"),
                                          style: GoogleFonts.raleway(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          } else if (forgotPasswordState
                              is ForgotPasswordSuccess) {
                            // Close loading dialog if it's open
                            Navigator.of(context).pop();

                            // Navigate to LoginScreen
                            navigateToAnotherScreenWithSlideTransitionFromRightToLeft(
                              context,
                              const LoginScreen(),
                            );
                          } else if (forgotPasswordState
                              is ForgotPasswordError) {
                            // Close loading dialog if it's open
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                            showErrorSnackBar(
                              context,
                              forgotPasswordState.message,
                            );
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          height: 55.h,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              elevation: 2,
                            ),
                            onPressed:
                                isLoading
                                    ? null
                                    : () {
                                      if (_formKey.currentState!.validate()) {
                                        context.read<SignupBloc>().add(
                                          SignupWithUserEntity(
                                            user: widget.entity,
                                            password: passwordController.text,
                                          ),
                                        );
                                      }
                                    },
                            child:
                                isLoading
                                    ? CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    )
                                    : Text(
                                      context.tr("register_button"),
                                      style: GoogleFonts.raleway(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 20.h),

                  // Back button
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        context.tr("cancel"),
                        style: GoogleFonts.raleway(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
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
