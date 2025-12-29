import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/widgets/widgets.dart';
import '../signup_controller.dart';

class AccountDetailsStep extends StatefulWidget {
  final SignupController controller;
  final VoidCallback onSubmit;
  final bool isLoading;

  const AccountDetailsStep({
    super.key,
    required this.controller,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  State<AccountDetailsStep> createState() => _AccountDetailsStepState();
}

class _AccountDetailsStepState extends State<AccountDetailsStep> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;

  @override
  void initState() {
    super.initState();
    final data = widget.controller.data;
    _emailController = TextEditingController(text: data.email);
    _passwordController = TextEditingController(text: data.password);
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _saveData() {
    final data = widget.controller.data;
    data.email = _emailController.text;
    data.password = _passwordController.text;
  }

  bool _validate() {
    _saveData();
    
    if (!(_formKey.currentState?.validate() ?? false)) {
      return false;
    }

    if (!widget.controller.data.acceptedTerms) {
      AppSnackBar.warning(context, 'Please accept the terms and conditions');
      return false;
    }

    return true;
  }

  void _onSubmit() {
    if (_validate()) {
      widget.onSubmit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.controller.data;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              controller: _emailController,
              label: 'Email Address',
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
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            SizedBox(height: 20.h),
            CustomTextField(
              controller: _passwordController,
              label: 'Password',
              hintText: 'Create a password',
              prefixIcon: Icons.lock_outlined,
              isPassword: true,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                if (value.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                return null;
              },
            ),
            SizedBox(height: 20.h),
            CustomTextField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              hintText: 'Confirm your password',
              prefixIcon: Icons.lock_outlined,
              isPassword: true,
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            SizedBox(height: 24.h),
            // Terms checkbox
            _TermsCheckbox(
              value: data.acceptedTerms,
              onChanged: (value) {
                setState(() {
                  data.acceptedTerms = value ?? false;
                });
              },
            ),
            SizedBox(height: 32.h),
            CustomButton(
              text: 'Create Account',
              onPressed: _onSubmit,
              isLoading: widget.isLoading,
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _TermsCheckbox({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24.w,
          height: 24.h,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: RichText(
            text: TextSpan(
              text: 'I agree to the ',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.textSecondaryColor,
              ),
              children: [
                TextSpan(
                  text: 'Terms of Service',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      // TODO: Open terms
                    },
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      // TODO: Open privacy policy
                    },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
