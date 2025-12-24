import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// A reusable search bar widget with consistent styling
class AppSearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;
  final TextEditingController? controller;
  final bool showFilter;
  final bool autofocus;
  final FocusNode? focusNode;

  const AppSearchBar({
    super.key,
    this.hint = 'Search...',
    this.onChanged,
    this.onFilterTap,
    this.controller,
    this.showFilter = false,
    this.autofocus = false,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        onChanged: onChanged,
        style: GoogleFonts.raleway(fontSize: 16.sp),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.raleway(
            color: Colors.grey.shade400,
            fontSize: 16.sp,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey.shade400,
            size: 22.sp,
          ),
          suffixIcon: showFilter
              ? IconButton(
                  icon: Icon(
                    Icons.tune,
                    color: Colors.grey.shade600,
                    size: 22.sp,
                  ),
                  onPressed: onFilterTap,
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 14.h,
          ),
        ),
      ),
    );
  }
}

/// A minimal search bar for in-app bar use
class InlineSearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final VoidCallback? onClear;

  const InlineSearchBar({
    super.key,
    this.hint = 'Search...',
    this.onChanged,
    this.controller,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 20.sp, color: Colors.grey.shade500),
          SizedBox(width: 8.w),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: GoogleFonts.raleway(fontSize: 14.sp),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.raleway(
                  color: Colors.grey.shade400,
                  fontSize: 14.sp,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (onClear != null && controller?.text.isNotEmpty == true)
            GestureDetector(
              onTap: () {
                controller?.clear();
                onClear?.call();
              },
              child: Icon(Icons.close, size: 18.sp, color: Colors.grey.shade500),
            ),
        ],
      ),
    );
  }
}
