import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';

/// Weekly template for setting default working hours
class WeeklyTemplateScreen extends StatefulWidget {
  final Map<String, List<String>>? initialTemplate;
  
  const WeeklyTemplateScreen({
    super.key,
    this.initialTemplate,
  });

  @override
  State<WeeklyTemplateScreen> createState() => _WeeklyTemplateScreenState();
}

class _WeeklyTemplateScreenState extends State<WeeklyTemplateScreen> {
  static const List<String> _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  
  static const List<String> _allTimeSlots = [
    '08:00', '08:30', '09:00', '09:30', '10:00', '10:30',
    '11:00', '11:30', '12:00', '12:30', '14:00', '14:30',
    '15:00', '15:30', '16:00', '16:30', '17:00', '17:30',
  ];

  // Map of day -> selected time slots
  final Map<String, Set<String>> _weeklySchedule = {};
  String? _selectedDay;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadTemplate();
  }

  Future<void> _loadTemplate() async {
    if (widget.initialTemplate != null) {
      for (final entry in widget.initialTemplate!.entries) {
        _weeklySchedule[entry.key] = Set.from(entry.value);
      }
      setState(() {});
      return;
    }
    
    // Load from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final templateJson = prefs.getString('weekly_template');
    if (templateJson != null) {
      try {
        final Map<String, dynamic> template = jsonDecode(templateJson);
        for (final entry in template.entries) {
          _weeklySchedule[entry.key] = Set<String>.from(entry.value as List);
        }
        setState(() {});
      } catch (e) {
        debugPrint('Error loading template: $e');
      }
    }
  }

  Future<void> _saveTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    final templateMap = <String, List<String>>{};
    for (final entry in _weeklySchedule.entries) {
      templateMap[entry.key] = entry.value.toList()..sort();
    }
    await prefs.setString('weekly_template', jsonEncode(templateMap));
    if (mounted) {
      AppSnackBar.success(context, 'Weekly template saved!');
      Navigator.pop(context, templateMap);
    }
  }

  void _copyToAllDays() {
    if (_selectedDay == null || !_weeklySchedule.containsKey(_selectedDay)) {
      AppSnackBar.warning(context, 'Select a day with slots first');
      return;
    }
    
    final slotsToShare = Set<String>.from(_weeklySchedule[_selectedDay]!);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const AppSubtitle(text: 'Copy Schedule'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBodyText(text: 'Copy ${_selectedDay}\'s schedule to:'),
            SizedBox(height: 16.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                _buildCopyChip(ctx, 'Weekdays', ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'], slotsToShare),
                _buildCopyChip(ctx, 'Weekend', ['Saturday', 'Sunday'], slotsToShare),
                _buildCopyChip(ctx, 'All Days', _days, slotsToShare),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyChip(BuildContext ctx, String label, List<String> targetDays, Set<String> slots) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        setState(() {
          for (final day in targetDays) {
            _weeklySchedule[day] = Set<String>.from(slots);
          }
          _hasChanges = true;
        });
        Navigator.pop(ctx);
        AppSnackBar.success(context, 'Copied to $label');
      },
    );
  }

  void _clearDay(String day) {
    setState(() {
      _weeklySchedule.remove(day);
      _hasChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Weekly Template',
        actions: [
          if (_hasChanges)
            IconButton(
              onPressed: _saveTemplate,
              icon: const Icon(Icons.save),
              tooltip: 'Save Template',
            ),
        ],
      ),
      body: Row(
        children: [
          // Left side - Days list
          SizedBox(
            width: 120.w,
            child: Container(
              color: Theme.of(context).cardColor,
              child: ListView.builder(
                itemCount: _days.length,
                itemBuilder: (context, index) {
                  final day = _days[index];
                  final slots = _weeklySchedule[day] ?? {};
                  final isSelected = _selectedDay == day;
                  final isWeekend = day == 'Saturday' || day == 'Sunday';
                  
                  return InkWell(
                    onTap: () => setState(() => _selectedDay = day),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : null,
                        border: Border(
                          left: BorderSide(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            width: 3.w,
                          ),
                          bottom: BorderSide(
                            color: AppColors.grey200,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppSubtitle(
                            text: day.substring(0, 3),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isWeekend ? AppColors.warning : null,
                          ),
                          SizedBox(height: 4.h),
                          AppSmallText(
                            text: slots.isEmpty ? 'Off' : '${slots.length} slots',
                            color: slots.isEmpty ? AppColors.grey400 : AppColors.success,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Right side - Time slots
          Expanded(
            child: _selectedDay == null
                ? _buildSelectDayPrompt()
                : _buildTimeSlotsEditor(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSelectDayPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.arrow_back, size: 48.sp, color: AppColors.grey400),
          SizedBox(height: 16.h),
        AppBodyText(
          text: 'Select a day to edit',
          color: AppColors.grey400,
        ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotsEditor() {
    final selectedSlots = _weeklySchedule[_selectedDay] ?? {};
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTitle(text: _selectedDay!),
                    AppSmallText(
                      text: '${selectedSlots.length} time slots selected',
                      color: AppColors.grey400,
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: _copyToAllDays,
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy'),
                  ),
                  TextButton.icon(
                    onPressed: selectedSlots.isEmpty ? null : () => _clearDay(_selectedDay!),
                    icon: Icon(Icons.clear, size: 18, color: selectedSlots.isEmpty ? AppColors.grey400 : AppColors.error),
                    label: Text('Clear', style: TextStyle(color: selectedSlots.isEmpty ? AppColors.grey400 : AppColors.error)),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),
          
          // Quick actions
          Row(
            children: [
              _buildQuickAction('Morning', ['08:00', '08:30', '09:00', '09:30', '10:00', '10:30', '11:00', '11:30']),
              SizedBox(width: 8.w),
              _buildQuickAction('Afternoon', ['14:00', '14:30', '15:00', '15:30', '16:00', '16:30', '17:00', '17:30']),
              SizedBox(width: 8.w),
              _buildQuickAction('All Day', _allTimeSlots),
            ],
          ),
          SizedBox(height: 24.h),
          
          // Morning slots
          _buildSlotSection('Morning', ['08:00', '08:30', '09:00', '09:30', '10:00', '10:30', '11:00', '11:30', '12:00', '12:30']),
          SizedBox(height: 16.h),
          
          // Afternoon slots
          _buildSlotSection('Afternoon', ['14:00', '14:30', '15:00', '15:30', '16:00', '16:30', '17:00', '17:30']),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String label, List<String> slots) {
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _weeklySchedule[_selectedDay!] = Set.from(slots);
          _hasChanges = true;
        });
      },
      child: Text(label, style: TextStyle(fontSize: 12.sp)),
    );
  }

  Widget _buildSlotSection(String title, List<String> slots) {
    final selectedSlots = _weeklySchedule[_selectedDay] ?? {};
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppBodyText(
          text: title,
          fontWeight: FontWeight.w600,
          color: AppColors.grey500,
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: slots.map((time) {
            final isSelected = selectedSlots.contains(time);
            return GestureDetector(
              onTap: () {
                setState(() {
                  _weeklySchedule[_selectedDay!] ??= {};
                  if (isSelected) {
                    _weeklySchedule[_selectedDay!]!.remove(time);
                  } else {
                    _weeklySchedule[_selectedDay!]!.add(time);
                  }
                  _hasChanges = true;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.grey300,
                  ),
                ),
                child: Text(
                  time,
                  style: TextStyle(
                    color: isSelected ? Colors.white : null,
                    fontWeight: isSelected ? FontWeight.w600 : null,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              flex: 2,
              child: CustomButton(
                text: 'Save Template',
                icon: Icons.save,
                onPressed: _hasChanges ? _saveTemplate : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
