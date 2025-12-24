import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/core/utils/custom_snack_bar.dart';
import 'package:medical_app/features/authentication/data/data%20sources/auth_local_data_source.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medical_app/injection_container.dart' as di;

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isCurrentPasswordObscured = true;
  bool _isNewPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  String _userEmail = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    try {
      final authLocalDataSource = di.sl<AuthLocalDataSource>();
      final user = await authLocalDataSource.getUser();
      setState(() {
        _userEmail = user.email;
      });
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, context.tr('error_loading_user_data'));
      }
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updatePassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Get Firebase Auth instance
        final auth = FirebaseAuth.instance;
        final user = auth.currentUser;

        if (user != null && _userEmail.isNotEmpty) {
          // Create credentials with current password
          final credential = EmailAuthProvider.credential(
            email: _userEmail,
            password: _currentPasswordController.text,
          );

          // Re-authenticate user
          await user.reauthenticateWithCredential(credential);

          // Update password
          await user.updatePassword(_newPasswordController.text);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.tr('password_update_success'),
                style: GoogleFonts.raleway(),
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Return to previous screen
          Navigator.pop(context);
        } else {
          showErrorSnackBar(context, context.tr('user_not_found'));
        }
      } catch (e) {
        // Handle different error types
        if (e is FirebaseAuthException) {
          if (e.code == 'wrong-password') {
            showErrorSnackBar(context, context.tr('current_password_incorrect'));
          } else {
            showErrorSnackBar(context, context.tr('password_update_error'));
          }
        } else {
          showErrorSnackBar(context, context.tr('password_update_error'));
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('change_password'),
          style: GoogleFonts.raleway(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryColor,
              AppColors.primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top curved container with background
              Container(
                height: 150.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30.r),
                    bottomRight: Radius.circular(30.r),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.lock_reset,
                    size: 80.sp,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30.r),
                      topRight: Radius.circular(30.r),
                    ),
                  ),
                  margin: EdgeInsets.only(top: 20.h),
                  padding: EdgeInsets.all(20.w),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 20.h),
                          Center(
                            child: Text(
                              context.tr('update_password'),
                              style: GoogleFonts.raleway(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Center(
                            child: Text(
                              context.tr('enter_current_and_new_password'),
                              style: GoogleFonts.raleway(
                                fontSize: 14.sp,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: 30.h),

                          // Current Password
                          _buildPasswordField(
                            context: context,
                            controller: _currentPasswordController,
                            label: context.tr('current_password'),
                            isObscured: _isCurrentPasswordObscured,
                            toggleObscured: () {
                              setState(() {
                                _isCurrentPasswordObscured =
                                    !_isCurrentPasswordObscured;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return context.tr('current_password_required');
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 20.h),

                          // New Password
                          _buildPasswordField(
                            context: context,
                            controller: _newPasswordController,
                            label: context.tr('new_password'),
                            isObscured: _isNewPasswordObscured,
                            toggleObscured: () {
                              setState(() {
                                _isNewPasswordObscured =
                                    !_isNewPasswordObscured;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return context.tr('new_password_required');
                              }
                              if (value.length < 6) {
                                return context.tr('password_min_length');
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 20.h),

                          // Confirm New Password
                          _buildPasswordField(
                            context: context,
                            controller: _confirmPasswordController,
                            label: context.tr('confirm_new_password'),
                            isObscured: _isConfirmPasswordObscured,
                            toggleObscured: () {
                              setState(() {
                                _isConfirmPasswordObscured =
                                    !_isConfirmPasswordObscured;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return context.tr('confirm_new_password_required');
                              }
                              if (value != _newPasswordController.text) {
                                return context.tr('passwords_dont_match');
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 40.h),

                          // Submit Button
                          Container(
                            width: double.infinity,
                            height: 55.h,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                              ),
                              onPressed: _isLoading ? null : _updatePassword,
                              child:
                                  _isLoading
                                      ? CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                      : Text(
                                        context.tr('update_password'),
                                        style: GoogleFonts.raleway(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                            ),
                          ),

                          SizedBox(height: 20.h),

                          // Cancel Button
                          Container(
                            width: double.infinity,
                            height: 55.h,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: AppColors.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.r),
                                  side: BorderSide(
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                context.tr('cancel'),
                                style: GoogleFonts.raleway(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required bool isObscured,
    required VoidCallback toggleObscured,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.raleway(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8.h),
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
            controller: controller,
            obscureText: isObscured,
            style: GoogleFonts.raleway(fontSize: 15.sp, color: Colors.black87),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText:
                  label == context.tr('current_password')
                      ? context.tr('current_password_placeholder')
                      : label == context.tr('new_password')
                      ? context.tr('new_password_placeholder')
                      : context.tr('confirm_password_placeholder'),
              hintStyle: GoogleFonts.raleway(
                color: Colors.grey[400],
                fontSize: 15.sp,
              ),
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
                borderSide: BorderSide(color: AppColors.primaryColor, width: 1),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              prefixIcon: Icon(
                Icons.lock_outline,
                color: AppColors.primaryColor,
                size: 22.sp,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  isObscured ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.primaryColor,
                ),
                onPressed: toggleObscured,
              ),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }
}
