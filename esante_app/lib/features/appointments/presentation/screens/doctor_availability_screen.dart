import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:convert';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../injection_container.dart';
import '../bloc/doctor/doctor_appointment_bloc.dart';
import '../widgets/apply_template_dialog.dart';
import 'weekly_template_screen.dart';

/// Improved availability screen with template support
class DoctorAvailabilityScreen extends StatelessWidget {
  final bool showBackButton;

  const DoctorAvailabilityScreen({
    super.key,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = sl<DoctorAppointmentBloc>();
    bloc.add(LoadDoctorSchedule(
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 90)),
    ));

    return BlocProvider.value(
      value: bloc,
      child: _DoctorAvailabilityView(showBackButton: showBackButton),
    );
  }
}

class _DoctorAvailabilityView extends StatefulWidget {
  final bool showBackButton;

  const _DoctorAvailabilityView({
    this.showBackButton = true,
  });

  @override
  State<_DoctorAvailabilityView> createState() => _DoctorAvailabilityViewState();
}

class _DoctorAvailabilityViewState extends State<_DoctorAvailabilityView>
    with SingleTickerProviderStateMixin {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Set<String> _selectedSlots = {};
  final TextEditingController _notesController = TextEditingController();
  Map<String, List<String>> _weeklyTemplate = {};
  bool _isApplyingTemplate = false;
  late TabController _tabController;
  
  // Cache the last loaded schedule to survive state changes from other screens
  DoctorScheduleLoaded? _cachedScheduleState;

  static const List<String> _allTimeSlots = [
    '08:00', '08:30', '09:00', '09:30', '10:00', '10:30',
    '11:00', '11:30', '12:00', '12:30', '14:00', '14:30',
    '15:00', '15:30', '16:00', '16:30', '17:00', '17:30',
  ];

  static const List<String> _dayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadWeeklyTemplate();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWeeklyTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    final templateJson = prefs.getString('weekly_template');
    if (templateJson != null) {
      try {
        final Map<String, dynamic> template = jsonDecode(templateJson);
        setState(() {
          _weeklyTemplate = template.map(
            (key, value) => MapEntry(key, List<String>.from(value as List)),
          );
        });
      } catch (e) {
        debugPrint('Error loading template: $e');
      }
    }
  }

  Future<void> _openTemplateScreen() async {
    final result = await Navigator.push<Map<String, List<String>>>(
      context,
      MaterialPageRoute(
        builder: (ctx) => WeeklyTemplateScreen(initialTemplate: _weeklyTemplate),
      ),
    );
    if (result != null) {
      setState(() => _weeklyTemplate = result);
    }
  }

  Future<void> _applyTemplate() async {
    if (_weeklyTemplate.isEmpty) {
      AppSnackBar.warning(context, 'Create a weekly template first');
      return;
    }

    final result = await ApplyTemplateDialog.show(context, _weeklyTemplate);
    if (result == null) return;

    setState(() => _isApplyingTemplate = true);

    try {
      // Generate availability entries for all dates in the range
      final availabilities = <AvailabilityEntry>[];
      var current = result.startDate;
      
      while (!current.isAfter(result.endDate)) {
        // Get day of week
        final dayName = _dayNames[current.weekday - 1];
        final slots = result.template[dayName] ?? [];

        if (slots.isNotEmpty) {
          availabilities.add(AvailabilityEntry(
            date: current,
            timeSlots: slots,
          ));
        }
        current = current.add(const Duration(days: 1));
      }

      if (availabilities.isEmpty) {
        if (mounted) {
          AppSnackBar.warning(context, 'No availability to apply');
          setState(() => _isApplyingTemplate = false);
        }
        return;
      }

      // Use bulk API for better performance
      context.read<DoctorAppointmentBloc>().add(
        BulkSetDoctorAvailability(
          availabilities: availabilities,
          skipExisting: result.skipExisting,
        ),
      );

    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Error applying template: $e');
        setState(() => _isApplyingTemplate = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Availability',
        showBackButton: widget.showBackButton,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'template') {
                _openTemplateScreen();
              } else if (value == 'apply') {
                _applyTemplate();
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'template',
                child: Row(
                  children: [
                    Icon(Icons.view_week, size: 20.sp, color: AppColors.primary),
                    SizedBox(width: 12.w),
                    const Text('Edit Weekly Template'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'apply',
                enabled: _weeklyTemplate.isNotEmpty,
                child: Row(
                  children: [
                    Icon(Icons.copy_all, size: 20.sp, 
                      color: _weeklyTemplate.isNotEmpty ? AppColors.primary : AppColors.grey400),
                    SizedBox(width: 12.w),
                    Text('Apply Template',
                      style: TextStyle(
                        color: _weeklyTemplate.isEmpty ? AppColors.grey400 : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      // Wrap body in BlocListener that's ALWAYS active (not conditional)
      // This ensures template application success/error states are caught
      body: BlocListener<DoctorAppointmentBloc, DoctorAppointmentState>(
        listener: (context, state) {
          if (state is AvailabilitySetSuccess) {
            AppSnackBar.success(context, 'Availability saved!');
            _selectedSlots.clear();
            _notesController.clear();
            context.read<DoctorAppointmentBloc>().add(
              LoadDoctorSchedule(
                startDate: DateTime.now(),
                endDate: DateTime.now().add(const Duration(days: 90)),
              ),
            );
          } else if (state is BulkAvailabilitySetSuccess) {
            setState(() => _isApplyingTemplate = false);
            AppSnackBar.success(
              context,
              'Template applied! ${state.created} created, ${state.updated} updated${state.skipped > 0 ? ', ${state.skipped} skipped' : ''}',
            );
            context.read<DoctorAppointmentBloc>().add(
              LoadDoctorSchedule(
                startDate: DateTime.now(),
                endDate: DateTime.now().add(const Duration(days: 90)),
              ),
            );
          } else if (state is DoctorAppointmentError) {
            setState(() => _isApplyingTemplate = false);
            AppSnackBar.error(context, state.message);
          }
        },
        child: _isApplyingTemplate
            ? _buildApplyingOverlay()
            : BlocBuilder<DoctorAppointmentBloc, DoctorAppointmentState>(
                // Only rebuild on states relevant to this screen
                buildWhen: (previous, current) {
                  return current is DoctorAppointmentInitial ||
                      current is DoctorScheduleLoading ||
                      current is DoctorScheduleLoaded ||
                      current is AvailabilityActionLoading ||
                      current is AvailabilitySetSuccess ||
                      current is BulkAvailabilitySetSuccess ||
                      current is DoctorAppointmentError;
                },
                builder: (context, state) {
                  // Cache schedule state when loaded
                  if (state is DoctorScheduleLoaded) {
                    _cachedScheduleState = state;
                  }
                  
                  // Show loading for initial state or schedule loading
                  if (state is DoctorAppointmentInitial || state is DoctorScheduleLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is AvailabilityActionLoading) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Saving...'),
                        ],
                      ),
                    );
                  }

                  if (state is DoctorScheduleLoaded) {
                    return _buildContent(context, state);
                  }
                  
                  // If we have a cached schedule, show that (handles case where 
                  // another screen emits a different state)
                  if (_cachedScheduleState != null) {
                    return _buildContent(context, _cachedScheduleState!);
                  }

                  // Only show error for actual error state
                  if (state is DoctorAppointmentError) {
                    return _buildErrorState(context);
                  }

                  // Default: show loading (in case of other transient states)
                  return const Center(child: CircularProgressIndicator());
                },
              ),
      ),
    );
  }

  Widget _buildApplyingOverlay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          SizedBox(height: 20.h),
          const AppSubtitle(text: 'Applying template...'),
          SizedBox(height: 8.h),
          AppBodyText(
            text: 'This may take a moment',
            color: AppColors.grey500,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64.sp, color: AppColors.error),
          SizedBox(height: 16.h),
          const AppSubtitle(text: 'Failed to load schedule'),
          SizedBox(height: 16.h),
          CustomButton(
            text: 'Retry',
            onPressed: () {
              context.read<DoctorAppointmentBloc>().add(
                LoadDoctorSchedule(
                  startDate: DateTime.now(),
                  endDate: DateTime.now().add(const Duration(days: 90)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, DoctorScheduleLoaded state) {
    return Column(
      children: [
        // Template banner if available
        if (_weeklyTemplate.isNotEmpty) _buildTemplateBanner(),
        
        // Main content
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCalendar(context, state),
                SizedBox(height: 16.h),
                if (_selectedDay != null) ...[
                  _buildDayEditor(context, state),
                  SizedBox(height: 32.h),
                ] else
                  _buildSelectDayPrompt(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateBanner() {
    final totalSlots = _weeklyTemplate.values
        .fold<int>(0, (sum, slots) => sum + slots.length);
    
    return Container(
      margin: EdgeInsets.all(16.r),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.view_week, color: AppColors.primary, size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppBodyText(
                  text: 'Weekly Template Active',
                  fontWeight: FontWeight.w600,
                ),
                AppSmallText(
                  text: '$totalSlots total slots across ${_weeklyTemplate.length} days',
                  color: AppColors.grey500,
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: _applyTemplate,
            icon: Icon(Icons.copy_all, size: 16.sp),
            label: const Text('Apply'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(BuildContext context, DoctorScheduleLoaded state) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Row(
              children: [
                Icon(Icons.calendar_month, color: AppColors.primary, size: 20.sp),
                SizedBox(width: 8.w),
                const AppSubtitle(text: 'Select Date'),
                const Spacer(),
                // Legend
                _buildLegendItem(AppColors.success, 'Available'),
                SizedBox(width: 12.w),
                _buildLegendItem(AppColors.warning, 'Booked'),
              ],
            ),
          ),
          TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 90)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                final normalizedDate = DateTime(date.year, date.month, date.day);
                final availability = state.availabilityMap[normalizedDate];
                if (availability != null) {
                  final hasBookings = availability.slots.any((s) => s.isBooked);
                  return Positioned(
                    bottom: 1,
                    child: Container(
                      width: 6.w,
                      height: 6.h,
                      decoration: BoxDecoration(
                        color: hasBookings ? AppColors.warning : AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _selectedSlots.clear();

                final normalizedDate = DateTime(
                  selectedDay.year, selectedDay.month, selectedDay.day);
                final existing = state.availabilityMap[normalizedDate];
                if (existing != null) {
                  for (final slot in existing.slots) {
                    _selectedSlots.add(slot.time);
                  }
                  _notesController.text = existing.specialNotes ?? '';
                } else {
                  _notesController.clear();
                }
              });
            },
            calendarStyle: CalendarStyle(
              selectedDecoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8.w,
          height: 8.h,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 4.w),
        AppSmallText(text: label, color: AppColors.grey500),
      ],
    );
  }

  Widget _buildDayEditor(BuildContext context, DoctorScheduleLoaded state) {
    final dayName = _dayNames[_selectedDay!.weekday - 1];
    final templateSlots = _weeklyTemplate[dayName] ?? [];
    final normalizedDate = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    final existingAvailability = state.availabilityMap[normalizedDate];
    final hasBookings = existingAvailability?.slots.any((s) => s.isBooked) ?? false;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with date and quick actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTitle(text: dayName),
                  AppBodyText(
                    text: '${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
                    color: AppColors.grey500,
                  ),
                ],
              ),
              Row(
                children: [
                  if (templateSlots.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedSlots.clear();
                          _selectedSlots.addAll(templateSlots);
                        });
                      },
                      icon: Icon(Icons.restore, size: 18.sp),
                      label: const Text('Use Template'),
                    ),
                  TextButton.icon(
                    onPressed: _selectedSlots.isEmpty ? null : () {
                      setState(() => _selectedSlots.clear());
                    },
                    icon: Icon(Icons.clear, size: 18.sp, 
                      color: _selectedSlots.isEmpty ? AppColors.grey400 : AppColors.error),
                    label: Text('Clear',
                      style: TextStyle(
                        color: _selectedSlots.isEmpty ? AppColors.grey400 : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          if (hasBookings) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: AppColors.warning, size: 20.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'This day has booked appointments. You can only add new slots.',
                      style: TextStyle(fontSize: 13.sp, color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          SizedBox(height: 16.h),
          
          // Quick actions
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _buildQuickAction('Morning', ['08:00', '08:30', '09:00', '09:30', '10:00', '10:30', '11:00', '11:30']),
              _buildQuickAction('Afternoon', ['14:00', '14:30', '15:00', '15:30', '16:00', '16:30', '17:00', '17:30']),
              _buildQuickAction('All Day', _allTimeSlots),
            ],
          ),
          
          SizedBox(height: 16.h),
          
          // Time slots grid
          _buildTimeSlotsGrid(existingAvailability),
          
          SizedBox(height: 16.h),
          
          // Notes
          CustomTextField(
            controller: _notesController,
            label: 'Special Notes (Optional)',
            hintText: 'e.g., "Urgent cases only"',
            prefixIcon: Icons.note_outlined,
            maxLines: 2,
          ),
          
          SizedBox(height: 24.h),
          
          // Save button
          CustomButton(
            text: 'Save Availability',
            icon: Icons.save,
            onPressed: _selectedSlots.isNotEmpty
                ? () {
                    context.read<DoctorAppointmentBloc>().add(
                      SetDoctorAvailability(
                        date: _selectedDay!,
                        timeSlots: _selectedSlots.toList()..sort(),
                        specialNotes: _notesController.text.isNotEmpty
                            ? _notesController.text
                            : null,
                      ),
                    );
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String label, List<String> slots) {
    final allSelected = slots.every((s) => _selectedSlots.contains(s));
    
    return OutlinedButton(
      onPressed: () {
        setState(() {
          if (allSelected) {
            for (final s in slots) {
              _selectedSlots.remove(s);
            }
          } else {
            _selectedSlots.addAll(slots);
          }
        });
      },
      style: OutlinedButton.styleFrom(
        backgroundColor: allSelected ? AppColors.primary.withValues(alpha: 0.1) : null,
        side: BorderSide(
          color: allSelected ? AppColors.primary : AppColors.grey300,
        ),
      ),
      child: Text(label, style: TextStyle(fontSize: 12.sp)),
    );
  }

  Widget _buildTimeSlotsGrid(dynamic existingAvailability) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppBodyText(
              text: 'Time Slots',
              fontWeight: FontWeight.w600,
            ),
            AppSmallText(
              text: '${_selectedSlots.length} selected',
              color: AppColors.grey500,
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: _allTimeSlots.map((time) {
            final isSelected = _selectedSlots.contains(time);
            final isBooked = existingAvailability?.slots
                .any((s) => s.time == time && s.isBooked) ?? false;

            return GestureDetector(
              onTap: isBooked ? null : () {
                setState(() {
                  if (isSelected) {
                    _selectedSlots.remove(time);
                  } else {
                    _selectedSlots.add(time);
                  }
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: isBooked
                      ? AppColors.warning.withValues(alpha: 0.2)
                      : isSelected
                          ? AppColors.primary
                          : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: isBooked
                        ? AppColors.warning
                        : isSelected
                            ? AppColors.primary
                            : AppColors.grey300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        color: isBooked
                            ? AppColors.warning
                            : isSelected
                                ? Colors.white
                                : null,
                        fontWeight: isSelected || isBooked ? FontWeight.w600 : null,
                        fontSize: 14.sp,
                      ),
                    ),
                    if (isBooked) ...[
                      SizedBox(width: 4.w),
                      Icon(Icons.lock, size: 14.sp, color: AppColors.warning),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSelectDayPrompt() {
    return Container(
      margin: EdgeInsets.all(16.r),
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Icon(Icons.touch_app, size: 48.sp, color: AppColors.primary),
          SizedBox(height: 16.h),
          const AppSubtitle(text: 'Select a date'),
          SizedBox(height: 8.h),
          AppBodyText(
            text: 'Tap a date on the calendar to set or edit availability',
            color: AppColors.grey400,
            textAlign: TextAlign.center,
          ),
          if (_weeklyTemplate.isEmpty) ...[
            SizedBox(height: 24.h),
            OutlinedButton.icon(
              onPressed: _openTemplateScreen,
              icon: const Icon(Icons.add),
              label: const Text('Create Weekly Template'),
            ),
          ],
        ],
      ),
    );
  }
}
