import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/core/utils/custom_snack_bar.dart';
import 'package:medical_app/core/utils/navigation_with_transition.dart';
import 'package:medical_app/features/authentication/data/data%20sources/auth_remote_data_source.dart';
import 'package:medical_app/widgets/reusable_text_widget.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:lottie/lottie.dart';
import 'package:medical_app/features/authentication/presentation/blocs/verify%20code%20bloc/verify_code_bloc.dart';
import 'package:medical_app/features/authentication/presentation/pages/reset_password_screen.dart';
import 'package:medical_app/features/authentication/presentation/pages/login_screen.dart';

class VerifyCodeScreen extends StatelessWidget {
  final String email;
  final bool isAccountCreation;

  const VerifyCodeScreen({
    Key? key,
    required this.email,
    this.isAccountCreation = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AppColors.primaryColor,
          elevation: 0,
          title: Text(
            "Vérification",
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
                    "assets/lotties/code.json",
                    height: 200.h,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              SizedBox(height: 30.h),

              // Title and instructions
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      isAccountCreation
                          ? "verify_account".tr
                          : "verify_identity".tr,
                      style: GoogleFonts.raleway(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 16.h),

                    Text(
                      isAccountCreation
                          ? "verification_code_sent_account".tr.replaceAll(
                            "{0}",
                            email,
                          )
                          : "verification_code_sent_reset".tr.replaceAll(
                            "{0}",
                            email,
                          ),
                      style: GoogleFonts.raleway(
                        fontSize: 14.sp,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 40.h),

                    Text(
                      "enter_verification_code".tr,
                      style: GoogleFonts.raleway(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // OTP Input Field with updated styling
                    BlocConsumer<VerifyCodeBloc, VerifyCodeState>(
                      listener: (context, state) {
                        if (state is VerifyCodeSuccess) {
                          showSuccessSnackBar(
                            context,
                            "code_verified_successfully".tr,
                          );
                          if (isAccountCreation) {
                            navigateToAnotherScreenWithSlideTransitionFromRightToLeftPushReplacement(
                              context,
                              const LoginScreen(),
                            );
                          } else {
                            navigateToAnotherScreenWithSlideTransitionFromRightToLeft(
                              context,
                              ResetPasswordScreen(
                                email: email,
                                verificationCode: state.verificationCode,
                              ),
                            );
                          }
                        } else if (state is VerifyCodeError) {
                          showErrorSnackBar(context, state.message);
                        }
                      },
                      builder: (context, state) {
                        return Column(
                          children: [
                            OtpTextField(
                              numberOfFields: 4,
                              borderColor: Colors.grey.shade300,
                              focusedBorderColor: AppColors.primaryColor,
                              showFieldAsBox: true,
                              borderWidth: 2.0,
                              fieldWidth: 60.w,
                              borderRadius: BorderRadius.circular(12.r),
                              textStyle: GoogleFonts.raleway(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              onSubmit: (String code) {
                                if (code.length == 4) {
                                  context.read<VerifyCodeBloc>().add(
                                    VerifyCodeSubmitted(
                                      email: email,
                                      verificationCode: int.parse(code),
                                      codeType:
                                          isAccountCreation
                                              ? VerificationCodeType
                                                  .activationDeCompte
                                              : VerificationCodeType
                                                  .motDePasseOublie,
                                    ),
                                  );
                                }
                              },
                            ),

                            SizedBox(height: 30.h),

                            // Loading indicator
                            if (state is VerifyCodeLoading)
                              Container(
                                width: double.infinity,
                                height: 55.h,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor.withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primaryColor,
                                    strokeWidth: 3,
                                  ),
                                ),
                              )
                            else
                              // Verify button for manual submission if needed
                              Container(
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
                                  onPressed: () {
                                    // This is just a visual button, the actual verification happens on code submit
                                    // The user can click this if they entered the code but didn't press "done" on keyboard
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "please_enter_complete_code".tr,
                                          style: GoogleFonts.raleway(),
                                        ),
                                        backgroundColor: Colors.amber.shade700,
                                      ),
                                    );
                                  },
                                  child: Text(
                                    "verify_code".tr,
                                    style: GoogleFonts.raleway(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),

                            SizedBox(height: 20.h),

                            // Didn't receive code option
                            TextButton(
                              onPressed: () {
                                // Could implement resend code functionality here
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "new_code_will_be_sent".tr,
                                      style: GoogleFonts.raleway(),
                                    ),
                                    backgroundColor: Colors.green.shade600,
                                  ),
                                );
                              },
                              child: Text(
                                "didnt_receive_code".tr,
                                style: GoogleFonts.raleway(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
