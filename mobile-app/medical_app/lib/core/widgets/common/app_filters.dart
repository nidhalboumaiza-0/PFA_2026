import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medical_app/core/utils/app_colors.dart';

/// A reusable filter chip row widget
class FilterChipsRow extends StatelessWidget {
  /// List of filter options
  final List<FilterOption> options;
  
  /// Currently selected value
  final String? selectedValue;
  
  /// Callback when a filter is selected
  final ValueChanged<String?> onSelected;
  
  /// Padding around the row
  final EdgeInsetsGeometry? padding;
  
  /// Whether to show an "All" option
  final bool showAllOption;
  
  /// Label for the "All" option
  final String allLabel;

  const FilterChipsRow({
    super.key,
    required this.options,
    this.selectedValue,
    required this.onSelected,
    this.padding,
    this.showAllOption = true,
    this.allLabel = 'All',
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding ?? EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          if (showAllOption) ...[
            _FilterChip(
              label: allLabel,
              isSelected: selectedValue == null,
              onTap: () => onSelected(null),
            ),
            SizedBox(width: 8.w),
          ],
          ...options.map((option) => Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: _FilterChip(
              label: option.label,
              icon: option.icon,
              color: option.color,
              isSelected: selectedValue == option.value,
              onTap: () => onSelected(option.value),
            ),
          )),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.icon,
    this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primaryColor;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? chipColor : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16.sp,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
              SizedBox(width: 6.w),
            ],
            Text(
              label,
              style: GoogleFonts.raleway(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A filter option model
class FilterOption {
  final String value;
  final String label;
  final IconData? icon;
  final Color? color;

  const FilterOption({
    required this.value,
    required this.label,
    this.icon,
    this.color,
  });
}

/// A date range filter widget
class DateRangeFilter extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final String hint;

  const DateRangeFilter({
    super.key,
    this.startDate,
    this.endDate,
    required this.onTap,
    this.onClear,
    this.hint = 'Select date range',
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = startDate != null || endDate != null;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: hasSelection ? AppColors.primaryColor.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: hasSelection ? AppColors.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today,
              size: 16.sp,
              color: hasSelection ? AppColors.primaryColor : Colors.grey.shade600,
            ),
            SizedBox(width: 8.w),
            Text(
              hasSelection
                  ? _formatDateRange()
                  : hint,
              style: GoogleFonts.raleway(
                fontSize: 14.sp,
                color: hasSelection ? AppColors.primaryColor : Colors.grey.shade600,
              ),
            ),
            if (hasSelection && onClear != null) ...[
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: onClear,
                child: Icon(
                  Icons.close,
                  size: 16.sp,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateRange() {
    if (startDate != null && endDate != null) {
      return '${_formatDate(startDate!)} - ${_formatDate(endDate!)}';
    } else if (startDate != null) {
      return 'From ${_formatDate(startDate!)}';
    } else if (endDate != null) {
      return 'Until ${_formatDate(endDate!)}';
    }
    return '';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// A dropdown filter widget
class DropdownFilter<T> extends StatelessWidget {
  final T? value;
  final List<DropdownFilterItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String hint;
  final IconData? icon;

  const DropdownFilter({
    super.key,
    this.value,
    required this.items,
    required this.onChanged,
    this.hint = 'Select...',
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18.sp, color: Colors.grey.shade600),
                SizedBox(width: 8.w),
              ],
              Text(
                hint,
                style: GoogleFonts.raleway(
                  fontSize: 14.sp,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item.value,
              child: Text(
                item.label,
                style: GoogleFonts.raleway(fontSize: 14.sp),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// A dropdown filter item model
class DropdownFilterItem<T> {
  final T value;
  final String label;

  const DropdownFilterItem({
    required this.value,
    required this.label,
  });
}
