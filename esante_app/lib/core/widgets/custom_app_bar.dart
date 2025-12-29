import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import 'app_back_button.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final Widget? titleWidget;
  final Color? backgroundColor;
  final bool centerTitle;

  const CustomAppBar({
    super.key,
    this.title,
    this.showBackButton = true,
    this.onBackPressed,
    this.actions,
    this.titleWidget,
    this.backgroundColor,
    this.centerTitle = true,
  });

  @override
  Size get preferredSize => Size.fromHeight(60.h);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? Colors.transparent,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (showBackButton)
              Padding(
                padding: EdgeInsets.only(left: 8.w),
                child: AppBackButton(onPressed: onBackPressed),
              )
            else
              SizedBox(width: 56.w),
            
            if (centerTitle) const Spacer(),
            
            if (titleWidget != null)
              titleWidget!
            else if (title != null)
              Text(
                title!,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimaryColor,
                ),
              ),
            
            if (centerTitle) const Spacer(),
            
            if (actions != null)
              ...actions!
            else
              SizedBox(width: 56.w),
          ],
        ),
      ),
    );
  }
}
