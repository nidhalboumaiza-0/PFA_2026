import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import '../theme/app_colors.dart';
import 'custom_button.dart';

enum DialogType { success, error, warning, info, custom }

class AppDialog {
  /// Show a simple alert dialog
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    DialogType type = DialogType.info,
    String? lottieAsset,
    String buttonText = 'OK',
    VoidCallback? onPressed,
    bool barrierDismissible = true,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => _AlertDialog(
        title: title,
        message: message,
        type: type,
        lottieAsset: lottieAsset,
        buttonText: buttonText,
        onPressed: onPressed,
      ),
    );
  }

  /// Show success dialog
  static Future<void> success(
    BuildContext context, {
    required String title,
    required String message,
    String? lottieAsset,
    String buttonText = 'Great!',
    VoidCallback? onPressed,
  }) {
    return show(
      context,
      title: title,
      message: message,
      type: DialogType.success,
      lottieAsset: lottieAsset ?? 'assets/lottie/login success.json',
      buttonText: buttonText,
      onPressed: onPressed,
    );
  }

  /// Show error dialog
  static Future<void> error(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'OK',
    VoidCallback? onPressed,
  }) {
    return show(
      context,
      title: title,
      message: message,
      type: DialogType.error,
      buttonText: buttonText,
      onPressed: onPressed,
    );
  }

  /// Show warning dialog
  static Future<void> warning(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'OK',
    VoidCallback? onPressed,
  }) {
    return show(
      context,
      title: title,
      message: message,
      type: DialogType.warning,
      buttonText: buttonText,
      onPressed: onPressed,
    );
  }

  /// Show confirmation dialog with two buttons
  static Future<bool?> confirm(
    BuildContext context, {
    required String title,
    required String message,
    DialogType type = DialogType.warning,
    String confirmText = 'Yes',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => _ConfirmDialog(
        title: title,
        message: message,
        type: type,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: isDestructive,
      ),
    );
  }

  /// Show custom dialog with actions
  static Future<T?> custom<T>(
    BuildContext context, {
    required String title,
    required String message,
    String? lottieAsset,
    Widget? icon,
    required List<DialogAction> actions,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => _CustomDialog<T>(
        title: title,
        message: message,
        lottieAsset: lottieAsset,
        icon: icon,
        actions: actions,
      ),
    );
  }

  /// Show email verification dialog (specific use case)
  static Future<void> emailVerification(
    BuildContext context, {
    required String message,
    required bool canResend,
    VoidCallback? onResend,
    VoidCallback? onDismiss,
  }) {
    return custom(
      context,
      title: 'Verify Your Email',
      message: message,
      lottieAsset: 'assets/lottie/Password Authentication.json',
      barrierDismissible: false,
      actions: [
        if (canResend)
          DialogAction(
            text: 'Resend Verification Email',
            icon: Icons.email_outlined,
            onPressed: () {
              Navigator.pop(context);
              onResend?.call();
            },
          ),
        DialogAction(
          text: 'OK, Got it',
          isOutlined: true,
          onPressed: () {
            Navigator.pop(context);
            onDismiss?.call();
          },
        ),
      ],
    );
  }
}

class DialogAction {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isOutlined;
  final bool isDestructive;

  const DialogAction({
    required this.text,
    this.icon,
    this.onPressed,
    this.isOutlined = false,
    this.isDestructive = false,
  });
}

// Private Alert Dialog Widget
class _AlertDialog extends StatelessWidget {
  final String title;
  final String message;
  final DialogType type;
  final String? lottieAsset;
  final String buttonText;
  final VoidCallback? onPressed;

  const _AlertDialog({
    required this.title,
    required this.message,
    required this.type,
    this.lottieAsset,
    required this.buttonText,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      backgroundColor: context.surfaceColor,
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (lottieAsset != null)
              Lottie.asset(
                lottieAsset!,
                width: 120.w,
                height: 120.h,
                repeat: type != DialogType.success,
              )
            else
              _buildIcon(),
            SizedBox(height: 16.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: context.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.sp,
                color: context.textSecondaryColor,
                height: 1.5,
              ),
            ),
            SizedBox(height: 24.h),
            CustomButton(
              text: buttonText,
              onPressed: () {
                Navigator.pop(context);
                onPressed?.call();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 72.w,
      height: 72.h,
      decoration: BoxDecoration(
        color: _getColor().withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(_getIcon(), size: 36.sp, color: _getColor()),
    );
  }

  IconData _getIcon() {
    switch (type) {
      case DialogType.success:
        return Icons.check_circle;
      case DialogType.error:
        return Icons.error;
      case DialogType.warning:
        return Icons.warning_amber_rounded;
      case DialogType.info:
      case DialogType.custom:
        return Icons.info;
    }
  }

  Color _getColor() {
    switch (type) {
      case DialogType.success:
        return AppColors.success;
      case DialogType.error:
        return AppColors.error;
      case DialogType.warning:
        return AppColors.warning;
      case DialogType.info:
      case DialogType.custom:
        return AppColors.info;
    }
  }
}

// Private Confirm Dialog Widget
class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final DialogType type;
  final String confirmText;
  final String cancelText;
  final bool isDestructive;

  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.type,
    required this.confirmText,
    required this.cancelText,
    required this.isDestructive,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      backgroundColor: context.surfaceColor,
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72.w,
              height: 72.h,
              decoration: BoxDecoration(
                color: _getColor().withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_getIcon(), size: 36.sp, color: _getColor()),
            ),
            SizedBox(height: 16.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: context.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.sp,
                color: context.textSecondaryColor,
                height: 1.5,
              ),
            ),
            SizedBox(height: 24.h),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: cancelText,
                    isOutlined: true,
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildConfirmButton(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    if (isDestructive) {
      return Container(
        height: 56.h,
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
          ),
          child: Text(
            confirmText,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      );
    }
    return CustomButton(
      text: confirmText,
      onPressed: () => Navigator.pop(context, true),
    );
  }

  IconData _getIcon() {
    switch (type) {
      case DialogType.success:
        return Icons.check_circle;
      case DialogType.error:
        return Icons.error;
      case DialogType.warning:
        return Icons.warning_amber_rounded;
      case DialogType.info:
      case DialogType.custom:
        return Icons.info;
    }
  }

  Color _getColor() {
    switch (type) {
      case DialogType.success:
        return AppColors.success;
      case DialogType.error:
        return AppColors.error;
      case DialogType.warning:
        return AppColors.warning;
      case DialogType.info:
      case DialogType.custom:
        return AppColors.info;
    }
  }
}

// Private Custom Dialog Widget
class _CustomDialog<T> extends StatelessWidget {
  final String title;
  final String message;
  final String? lottieAsset;
  final Widget? icon;
  final List<DialogAction> actions;

  const _CustomDialog({
    required this.title,
    required this.message,
    this.lottieAsset,
    this.icon,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      backgroundColor: context.surfaceColor,
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (lottieAsset != null)
              Lottie.asset(
                lottieAsset!,
                width: 120.w,
                height: 120.h,
                repeat: true,
              )
            else if (icon != null)
              icon!,
            SizedBox(height: 16.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: context.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.sp,
                color: context.textSecondaryColor,
                height: 1.5,
              ),
            ),
            SizedBox(height: 24.h),
            ...actions.map((action) => Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: _buildActionButton(action),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(DialogAction action) {
    if (action.isDestructive) {
      return SizedBox(
        width: double.infinity,
        height: 56.h,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: ElevatedButton(
            onPressed: action.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (action.icon != null) ...[
                  Icon(action.icon, size: 20.sp, color: Colors.white),
                  SizedBox(width: 8.w),
                ],
                Text(
                  action.text,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return CustomButton(
      text: action.text,
      icon: action.icon,
      isOutlined: action.isOutlined,
      onPressed: action.onPressed,
    );
  }
}
