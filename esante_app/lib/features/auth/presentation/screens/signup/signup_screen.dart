import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/navigation_utils.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../bloc/auth_bloc.dart';
import '../login_screen.dart';
import 'signup_controller.dart';
import 'steps/steps.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  late final SignupController _controller;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = SignupController();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _handleRoleContinue() {
    if (_controller.data.role == null) {
      AppSnackBar.warning(context, 'Please select your role to continue');
      return;
    }
    _controller.nextStep();
  }

  void _handleSubmit() {
    final data = _controller.data;
    context.read<AuthBloc>().add(RegisterRequested(
          email: data.email.trim(),
          password: data.password,
          role: data.roleString,
          profileData: data.toProfileData(),
        ));
  }

  void _handleBack() {
    if (_controller.isFirstStep) {
      context.popPage();
    } else {
      _controller.previousStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthRegistrationSuccess) {
          AppDialog.success(
            context,
            title: 'Account Created! 🎉',
            message: '${state.message}\n\nYou can complete your profile information later in the settings to unlock all features.',
            buttonText: 'Go to Login',
            onPressed: () {
              context.popPage(); // Close dialog
              context.popPage(); // Go back to login
            },
          );
        } else if (state is AuthError) {
          AppSnackBar.error(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _SignupHeader(
                  controller: _controller,
                  onBack: _handleBack,
                ),
                // Progress bar
                ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) {
                    if (_controller.data.role == null) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: StepProgressBar(
                        currentStep: _controller.currentStep,
                        totalSteps: _controller.totalSteps,
                      ),
                    );
                  },
                ),
                SizedBox(height: 24.h),
                // Page content
                Expanded(
                  child: ListenableBuilder(
                    listenable: _controller,
                    builder: (context, _) {
                      return PageView(
                        controller: _controller.pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: _buildSteps(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSteps() {
    final role = _controller.data.role;

    return [
      RoleSelectionStep(
        controller: _controller,
        onContinue: _handleRoleContinue,
        onSignIn: () => context.popPage(),
      ),
      if (role != null)
        PersonalInfoStep(
          controller: _controller,
          onContinue: _controller.nextStep,
        ),
      if (role != null)
        role == UserRoleOption.patient
            ? PatientHealthStep(
                controller: _controller,
                onContinue: _controller.nextStep,
              )
            : DoctorProfessionalStep(
                controller: _controller,
                onContinue: _controller.nextStep,
              ),
      if (role != null)
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            return AccountDetailsStep(
              controller: _controller,
              onSubmit: _handleSubmit,
              isLoading: state is AuthLoading,
            );
          },
        ),
    ];
  }
}

class _SignupHeader extends StatelessWidget {
  final SignupController controller;
  final VoidCallback onBack;

  const _SignupHeader({
    required this.controller,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          AppBackButton(onPressed: onBack),
          SizedBox(width: 12.w),
          Expanded(
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.stepTitle,
                      style: theme.textTheme.headlineMedium,
                    ),
                    if (controller.data.role != null)
                      Text(
                        'Step ${controller.currentStep + 1} of ${controller.totalSteps}',
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
