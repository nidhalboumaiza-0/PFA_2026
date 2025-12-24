import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:lottie/lottie.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/core/utils/custom_snack_bar.dart';
import 'package:medical_app/core/widgets/common/common_widgets.dart';
import 'package:medical_app/features/profile/presentation/pages/blocs/BLoC%20update%20profile/update_user_bloc.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('change_password'),
          style: GoogleFonts.raleway(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: BlocListener<UpdateUserBloc, UpdateUserState>(
        listener: (context, state) {
          if (state is ChangePasswordSuccess) {
            showSuccessSnackBar(context, context.tr('password_changed_success'));
            Navigator.pop(context);
          } else if (state is ChangePasswordFailure) {
            showErrorSnackBar(context, state.message);
          }
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Lottie Animation
                Lottie.asset(
                  'assets/lotties/reset.json',
                  height: 200.h,
                  width: 200.w,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback if asset is missing
                    return Icon(
                      Icons.lock_reset,
                      size: 100.sp,
                      color: AppColors.primaryColor,
                    );
                  },
                ),
                SizedBox(height: 30.h),

                Text(
                  context.tr('create_new_password'),
                  style: GoogleFonts.raleway(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  context.tr('enter_new_password_message'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.raleway(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 30.h),

                // Current Password
                _buildPasswordField(
                  controller: _currentPasswordController,
                  label: context.tr('current_password'),
                  obscureText: _obscureCurrent,
                  onToggleVisibility: () {
                    setState(() {
                      _obscureCurrent = !_obscureCurrent;
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
                  controller: _newPasswordController,
                  label: context.tr('new_password'),
                  obscureText: _obscureNew,
                  onToggleVisibility: () {
                    setState(() {
                      _obscureNew = !_obscureNew;
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

                // Confirm Password
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  label: context.tr('confirm_new_password'),
                  obscureText: _obscureConfirm,
                  onToggleVisibility: () {
                    setState(() {
                      _obscureConfirm = !_obscureConfirm;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.tr('confirm_password_required');
                    }
                    if (value != _newPasswordController.text) {
                      return context.tr('passwords_dont_match');
                    }
                    return null;
                  },
                ),
                SizedBox(height: 40.h),

                // Submit Button
                BlocBuilder<UpdateUserBloc, UpdateUserState>(
                  builder: (context, state) {
                    return SizedBox(
                      width: double.infinity,
                      height: 55.h,
                      child: ElevatedButton(
                        onPressed: state is ChangePasswordLoading
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  context.read<UpdateUserBloc>().add(
                                        ChangePasswordRequested(
                                          currentPassword:
                                              _currentPasswordController.text,
                                          newPassword:
                                              _newPasswordController.text,
                                        ),
                                      );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          elevation: 2,
                        ),
                        child: state is ChangePasswordLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text(
                                context.tr('change_password'),
                                style: GoogleFonts.raleway(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        style: GoogleFonts.raleway(fontSize: 14.sp),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.raleway(color: AppColors.primaryColor),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          contentPadding: EdgeInsets.symmetric(
            vertical: 16.h,
            horizontal: 16.w,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide.none,
          ),
          prefixIcon: Icon(
            Icons.lock_outline,
            color: AppColors.primaryColor,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off : Icons.visibility,
              color: AppColors.primaryColor,
            ),
            onPressed: onToggleVisibility,
          ),
        ),
      ),
    );
  }
}
