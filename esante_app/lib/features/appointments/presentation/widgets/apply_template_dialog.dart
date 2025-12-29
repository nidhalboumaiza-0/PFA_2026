import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';

/// Result of applying template
class ApplyTemplateResult {
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, List<String>> template;
  final bool skipExisting;

  ApplyTemplateResult({
    required this.startDate,
    required this.endDate,
    required this.template,
    this.skipExisting = true,
  });
}

/// Dialog to apply weekly template to a date range
class ApplyTemplateDialog extends StatefulWidget {
  final Map<String, List<String>> template;
  
  const ApplyTemplateDialog({
    super.key,
    required this.template,
  });

  static Future<ApplyTemplateResult?> show(
    BuildContext context,
    Map<String, List<String>> template,
  ) {
    return showDialog<ApplyTemplateResult>(
      context: context,
      builder: (ctx) => ApplyTemplateDialog(template: template),
    );
  }

  @override
  State<ApplyTemplateDialog> createState() => _ApplyTemplateDialogState();
}

class _ApplyTemplateDialogState extends State<ApplyTemplateDialog> {
  String _selectedOption = 'next_week';
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  bool _skipExisting = true;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        width: 0.9.sw,
        constraints: BoxConstraints(maxWidth: 400.w),
        padding: EdgeInsets.all(20.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.date_range, color: AppColors.primary, size: 24.sp),
                SizedBox(width: 8.w),
                const AppTitle(text: 'Apply Template'),
              ],
            ),
            SizedBox(height: 8.h),
            AppBodyText(
              text: 'Apply your weekly schedule to multiple dates',
              color: AppColors.grey500,
            ),
            SizedBox(height: 20.h),
            
            // Quick options
            _buildOption('next_week', 'Next Week', _getNextWeekDescription()),
            _buildOption('next_2_weeks', '2 Weeks', _getNextTwoWeeksDescription()),
            _buildOption('next_month', 'Next Month', _getNextMonthDescription()),
            _buildOption('custom', 'Custom Range', 'Select specific dates'),
            
            // Custom date picker
            if (_selectedOption == 'custom') ...[
              SizedBox(height: 16.h),
              _buildCustomDatePickers(),
            ],
            
            SizedBox(height: 16.h),
            
            // Skip existing toggle
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _skipExisting,
                    onChanged: (v) => setState(() => _skipExisting = v ?? true),
                    activeColor: AppColors.primary,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppBodyText(
                          text: 'Skip days with existing availability',
                          fontWeight: FontWeight.w500,
                        ),
                        AppSmallText(
                          text: 'Won\'t overwrite your custom exceptions',
                          color: AppColors.grey500,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24.h),
            
            // Template preview
            _buildTemplatePreview(),
            
            SizedBox(height: 24.h),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  flex: 2,
                  child: CustomButton(
                    text: 'Apply',
                    icon: Icons.check,
                    onPressed: _canApply() ? _apply : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(String value, String title, String subtitle) {
    final isSelected = _selectedOption == value;
    
    return InkWell(
      onTap: () => setState(() => _selectedOption = value),
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : null,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _selectedOption,
              onChanged: (v) => setState(() => _selectedOption = v!),
              activeColor: AppColors.primary,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppBodyText(
                    text: title,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  AppSmallText(
                    text: subtitle,
                    color: AppColors.grey500,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomDatePickers() {
    return Row(
      children: [
        Expanded(
          child: _buildDateField(
            'Start Date',
            _customStartDate,
            (date) => setState(() => _customStartDate = date),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildDateField(
            'End Date',
            _customEndDate,
            (date) => setState(() => _customEndDate = date),
            minDate: _customStartDate,
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(
    String label,
    DateTime? value,
    ValueChanged<DateTime> onChanged, {
    DateTime? minDate,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now().add(const Duration(days: 1)),
          firstDate: minDate ?? DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) onChanged(date);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.grey300),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 16.sp, color: AppColors.grey500),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                value != null
                    ? '${value.day}/${value.month}/${value.year}'
                    : label,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: value != null ? null : AppColors.grey400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatePreview() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final fullDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSmallText(
          text: 'Template Preview',
          fontWeight: FontWeight.w600,
          color: AppColors.grey500,
        ),
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (i) {
            final slots = widget.template[fullDays[i]] ?? [];
            return Column(
              children: [
                Text(
                  days[i],
                  style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 4.h),
                Container(
                  width: 32.w,
                  height: 24.h,
                  decoration: BoxDecoration(
                    color: slots.isEmpty ? AppColors.grey200 : AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Center(
                    child: Text(
                      slots.isEmpty ? '-' : '${slots.length}',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: slots.isEmpty ? AppColors.grey500 : AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  String _getNextWeekDescription() {
    final now = DateTime.now();
    final daysUntilMonday = (8 - now.weekday) % 7;
    final nextMonday = now.add(Duration(days: daysUntilMonday == 0 ? 7 : daysUntilMonday));
    final nextSunday = nextMonday.add(const Duration(days: 6));
    return '${nextMonday.day}/${nextMonday.month} - ${nextSunday.day}/${nextSunday.month}';
  }

  String _getNextTwoWeeksDescription() {
    final now = DateTime.now();
    final daysUntilMonday = (8 - now.weekday) % 7;
    final nextMonday = now.add(Duration(days: daysUntilMonday == 0 ? 7 : daysUntilMonday));
    final endDate = nextMonday.add(const Duration(days: 13));
    return '${nextMonday.day}/${nextMonday.month} - ${endDate.day}/${endDate.month}';
  }

  String _getNextMonthDescription() {
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    final lastDay = DateTime(now.year, now.month + 2, 0);
    return '${nextMonth.day}/${nextMonth.month} - ${lastDay.day}/${lastDay.month}';
  }

  (DateTime, DateTime) _getDateRange() {
    final now = DateTime.now();
    
    switch (_selectedOption) {
      case 'next_week':
        final daysUntilMonday = (8 - now.weekday) % 7;
        final nextMonday = now.add(Duration(days: daysUntilMonday == 0 ? 7 : daysUntilMonday));
        return (nextMonday, nextMonday.add(const Duration(days: 6)));
        
      case 'next_2_weeks':
        final daysUntilMonday = (8 - now.weekday) % 7;
        final nextMonday = now.add(Duration(days: daysUntilMonday == 0 ? 7 : daysUntilMonday));
        return (nextMonday, nextMonday.add(const Duration(days: 13)));
        
      case 'next_month':
        final nextMonth = DateTime(now.year, now.month + 1, 1);
        final lastDay = DateTime(now.year, now.month + 2, 0);
        return (nextMonth, lastDay);
        
      case 'custom':
        return (_customStartDate!, _customEndDate!);
        
      default:
        return (now, now.add(const Duration(days: 7)));
    }
  }

  bool _canApply() {
    if (_selectedOption == 'custom') {
      return _customStartDate != null && _customEndDate != null;
    }
    return true;
  }

  void _apply() {
    final (start, end) = _getDateRange();
    Navigator.pop(context, ApplyTemplateResult(
      startDate: start,
      endDate: end,
      template: widget.template,
      skipExisting: _skipExisting,
    ));
  }
}
