import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';

class StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String>? stepLabels;
  final bool showLabels;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? completedColor;
  final double? dotSize;
  final double? lineHeight;
  final double? spacing;

  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.stepLabels,
    this.showLabels = false,
    this.activeColor,
    this.inactiveColor,
    this.completedColor,
    this.dotSize,
    this.lineHeight,
    this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    final active = activeColor ?? AppColors.primary;
    final inactive = inactiveColor ?? context.dividerColor;
    final completed = completedColor ?? AppColors.success;
    final dot = dotSize ?? 32.w;
    final line = lineHeight ?? 3.h;
    final space = spacing ?? 8.h;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: List.generate(totalSteps * 2 - 1, (index) {
            // Even indices are dots, odd indices are lines
            if (index.isEven) {
              final stepIndex = index ~/ 2;
              final isCompleted = stepIndex < currentStep;
              final isActive = stepIndex == currentStep;

              return _StepDot(
                stepNumber: stepIndex + 1,
                isCompleted: isCompleted,
                isActive: isActive,
                activeColor: active,
                inactiveColor: inactive,
                completedColor: completed,
                size: dot,
              );
            } else {
              final stepIndex = index ~/ 2;
              final isCompleted = stepIndex < currentStep;

              return Expanded(
                child: _StepLine(
                  isCompleted: isCompleted,
                  activeColor: active,
                  inactiveColor: inactive,
                  completedColor: completed,
                  height: line,
                ),
              );
            }
          }),
        ),
        if (showLabels && stepLabels != null) ...[
          SizedBox(height: space),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(totalSteps, (index) {
              final isCompleted = index < currentStep;
              final isActive = index == currentStep;

              return SizedBox(
                width: dot + 20.w,
                child: Text(
                  stepLabels![index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isCompleted || isActive
                        ? (isCompleted ? completed : active)
                        : Colors.grey,
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final int stepNumber;
  final bool isCompleted;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final Color completedColor;
  final double size;

  const _StepDot({
    required this.stepNumber,
    required this.isCompleted,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.completedColor,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color contentColor;
    Widget content;

    if (isCompleted) {
      backgroundColor = completedColor;
      contentColor = Colors.white;
      content = Icon(Icons.check, color: contentColor, size: size * 0.5);
    } else if (isActive) {
      backgroundColor = activeColor;
      contentColor = Colors.white;
      content = Text(
        '$stepNumber',
        style: TextStyle(
          color: contentColor,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.4,
        ),
      );
    } else {
      backgroundColor = inactiveColor;
      contentColor = Colors.grey;
      content = Text(
        '$stepNumber',
        style: TextStyle(
          color: contentColor,
          fontWeight: FontWeight.w500,
          fontSize: size * 0.4,
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: isActive || isCompleted
            ? [
                BoxShadow(
                  color: backgroundColor.withValues(alpha: 0.3),
                  blurRadius: 8.r,
                  offset: Offset(0, 2.h),
                ),
              ]
            : null,
      ),
      child: Center(child: content),
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool isCompleted;
  final Color activeColor;
  final Color inactiveColor;
  final Color completedColor;
  final double height;

  const _StepLine({
    required this.isCompleted,
    required this.activeColor,
    required this.inactiveColor,
    required this.completedColor,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: height,
      margin: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        color: isCompleted ? completedColor : inactiveColor,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}

/// A simpler progress bar style indicator
class StepProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final Color? activeColor;
  final Color? inactiveColor;
  final double? height;
  final double? borderRadius;

  const StepProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.activeColor,
    this.inactiveColor,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (currentStep + 1) / totalSteps;
    final active = activeColor ?? AppColors.primary;
    final inactive = inactiveColor ?? context.dividerColor;
    final h = height ?? 6.h;
    final radius = borderRadius ?? 3.r;

    return Container(
      height: h,
      decoration: BoxDecoration(
        color: inactive,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                width: constraints.maxWidth * progress,
                height: h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [active, active.withValues(alpha: 0.8)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(radius),
                  boxShadow: [
                    BoxShadow(
                      color: active.withValues(alpha: 0.3),
                      blurRadius: 4.r,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
