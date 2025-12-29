import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../bloc/auth_bloc.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _emailSent = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            ForgotPasswordRequested(email: _emailController.text.trim()),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            AppSnackBar.error(context, state.message);
          } else if (state is ForgotPasswordSuccess) {
            setState(() {
              _emailSent = true;
            });
            _animationController.reset();
            _animationController.forward();
          }
        },
        child: Container(
          decoration: BoxDecoration(gradient: AppColors.backgroundGradient(context)),
          child: SafeArea(
            child: Column(
              children: [
                const CustomAppBar(title: ''),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _emailSent
                            ? _buildSuccessContent()
                            : _buildFormContent(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 20.h),
          Center(
            child: Lottie.asset(
              'assets/lottie/Forgot Password.json',
              width: 260.w,
              height: 200.h,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: 24.h),
          const AppTitle(text: 'Forgot Password?', emoji: '🔐'),
          SizedBox(height: 12.h),
          const AppSubtitle(
            text: "Don't worry! Enter your email address and we'll send you a link to reset your password.",
          ),
          SizedBox(height: 40.h),
          CustomTextField(
            controller: _emailController,
            labelText: 'Email Address',
            hintText: 'Enter your email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          SizedBox(height: 32.h),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              return CustomButton(
                text: 'Send Reset Link',
                icon: Icons.send_rounded,
                isLoading: state is AuthLoading,
                onPressed: _onSubmit,
              );
            },
          ),
          SizedBox(height: 24.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Remember your password? ',
                style: TextStyle(color: context.textSecondaryColor),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text(
                  'Sign In',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  Widget _buildSuccessContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 60.h),
        Center(
          child: Lottie.asset(
            'assets/lottie/login success.json',
            width: 200.w,
            height: 200.h,
            repeat: false,
          ),
        ),
        SizedBox(height: 32.h),
        Container(
          width: 80.w,
          height: 80.h,
          margin: EdgeInsets.symmetric(horizontal: 120.w),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20.r,
                offset: Offset(0, 8.h),
              ),
            ],
          ),
          child: Icon(
            Icons.mark_email_read_rounded,
            size: 40.sp,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 32.h),
        const AppTitle(text: 'Check Your Email!', emoji: '📧'),
        SizedBox(height: 12.h),
        AppSubtitle(
          text: 'We have sent a password reset link to\n${_emailController.text}',
        ),
        SizedBox(height: 40.h),
        CustomButton(
          text: 'Open Email App',
          icon: Icons.open_in_new_rounded,
          onPressed: () {},
        ),
        SizedBox(height: 16.h),
        TextButton(
          onPressed: () {
            setState(() {
              _emailSent = false;
            });
            _animationController.reset();
            _animationController.forward();
          },
          child: const Text(
            "Didn't receive the email? Try again",
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: 24.h),
        CustomButton(
          text: 'Back to Login',
          isOutlined: true,
          onPressed: () => Navigator.pop(context),
        ),
        SizedBox(height: 40.h),
      ],
    );
  }
}
