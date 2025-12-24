import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/core/utils/custom_snack_bar.dart';
import 'package:medical_app/core/utils/navigation_with_transition.dart';
import 'package:medical_app/core/widgets/common/common_widgets.dart';
import 'package:lottie/lottie.dart';
import '../blocs/reset password bloc/reset_password_bloc.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String token;

  const ResetPasswordScreen({
    Key? key,
    required this.email,
    required this.token,
  }) : super(key: key);

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isObscureNewPassword = true;
  bool _isObscureConfirmPassword = true;

  @override
  void dispose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AppColors.primaryColor,
          elevation: 0,
          title: Text(
            context.tr('change_password.reset_password'),
            style: GoogleFonts.raleway(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Get.back(),
          ),
        ),
        body: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Top curved container with animation
                Container(
                  height: 300.h,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(50.r),
                      bottomRight: Radius.circular(50.r),
                    ),
                  ),
                  child: Center(
                    child: Lottie.asset(
                      "assets/lotties/reset.json",
                      height: 200.h,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                SizedBox(height: 30.h),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and instructions
                      Center(
                        child: Text(
                          context.tr('change_password.new_password_title'),
                          style: GoogleFonts.raleway(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      SizedBox(height: 12.h),

                      Center(
                        child: Text(
                          '${context.tr('change_password.create_new_password_for')} ${widget.email}',
                          style: GoogleFonts.raleway(
                            fontSize: 14.sp,
                            color: Colors.black54,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      SizedBox(height: 40.h),

                      // New password field
                      Text(
                        context.tr('change_password.new_password'),
                        style: GoogleFonts.raleway(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),

                      SizedBox(height: 10.h),

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
                          controller: newPasswordController,
                          obscureText: _isObscureNewPassword,
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
                            hintText: context.tr('change_password.new_password_placeholder'),
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
                                _isObscureNewPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: AppColors.primaryColor,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isObscureNewPassword =
                                      !_isObscureNewPassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return context.tr('change_password.password_required');
                            }
                            if (value.length < 6) {
                              return context.tr('change_password.password_too_short');
                            }
                            return null;
                          },
                        ),
                      ),

                      SizedBox(height: 24.h),

                      // Confirm password field
                      Text(
                        context.tr('change_password.confirm_password'),
                        style: GoogleFonts.raleway(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),

                      SizedBox(height: 10.h),

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
                            hintText: context.tr('change_password.confirm_password_placeholder'),
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
                              return context.tr('change_password.confirm_new_password_required');
                            }
                            if (value != newPasswordController.text) {
                              return context.tr('change_password.passwords_dont_match');
                            }
                            return null;
                          },
                        ),
                      ),

                      SizedBox(height: 40.h),

                      // Submit button
                      BlocConsumer<ResetPasswordBloc, ResetPasswordState>(
                        listener: (context, state) {
                          if (state is ResetPasswordSuccess) {
                            showSuccessSnackBar(
                              context,
                              context.tr('change_password.password_reset_success'),
                            );
                            navigateToAnotherScreenWithSlideTransitionFromRightToLeftPushReplacement(
                              context,
                              const LoginScreen(),
                            );
                          } else if (state is ResetPasswordError) {
                            showErrorSnackBar(context, state.message);
                          }
                        },
                        builder: (context, state) {
                          return Container(
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
                                  state is ResetPasswordLoading
                                      ? null
                                      : () {
                                        if (_formKey.currentState!.validate()) {
                                          context.read<ResetPasswordBloc>().add(
                                            ResetPasswordSubmitted(
                                              email: widget.email,
                                              newPassword:
                                                  newPasswordController.text,
                                              token:
                                                  widget.token,
                                            ),
                                          );
                                        }
                                      },
                              child:
                                  state is ResetPasswordLoading
                                      ? CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      )
                                      : Text(
                                        context.tr('change_password.reset_password'),
                                        style: GoogleFonts.raleway(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
