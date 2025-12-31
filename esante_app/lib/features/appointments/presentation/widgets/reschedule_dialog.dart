import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/appointment_entity.dart';
import '../../domain/entities/time_slot_entity.dart';
import '../bloc/patient/patient_appointment_bloc.dart';

/// Dialog for rescheduling an appointment
/// Shows date picker and available time slots
class RescheduleDialog extends StatefulWidget {
  final AppointmentEntity appointment;
  final String doctorId;

  const RescheduleDialog({
    super.key,
    required this.appointment,
    required this.doctorId,
  });

  /// Show the reschedule dialog
  static Future<void> show(
    BuildContext context, {
    required AppointmentEntity appointment,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<PatientAppointmentBloc>(),
        child: RescheduleDialog(
          appointment: appointment,
          doctorId: appointment.doctorId,
        ),
      ),
    );
  }

  @override
  State<RescheduleDialog> createState() => _RescheduleDialogState();
}

class _RescheduleDialogState extends State<RescheduleDialog> {
  DateTime? _selectedDate;
  String? _selectedTime;
  final _reasonController = TextEditingController();
  List<TimeSlotEntity> _availability = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load doctor availability for next 30 days
    _loadAvailability();
  }

  void _loadAvailability() {
    final now = DateTime.now();
    context.read<PatientAppointmentBloc>().add(
          LoadDoctorAvailability(
            doctorId: widget.doctorId,
            startDate: now,
            endDate: now.add(const Duration(days: 30)),
          ),
        );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  List<String> get _availableTimesForSelectedDate {
    if (_selectedDate == null) return [];

    final matchingSlots = _availability.where(
      (s) =>
          s.date.year == _selectedDate!.year &&
          s.date.month == _selectedDate!.month &&
          s.date.day == _selectedDate!.day,
    );

    if (matchingSlots.isEmpty) return [];

    return matchingSlots.first.availableSlots.map((s) => s.time).toList();
  }

  bool _isDateAvailable(DateTime date) {
    return _availability.any(
      (s) =>
          s.date.year == date.year &&
          s.date.month == date.month &&
          s.date.day == date.day &&
          s.availableSlots.isNotEmpty,
    );
  }

  void _onSubmit() {
    if (_selectedDate == null || _selectedTime == null) {
      AppSnackBar.warning(context, 'Please select a date and time');
      return;
    }

    Navigator.pop(context);

    context.read<PatientAppointmentBloc>().add(
          RequestPatientReschedule(
            appointmentId: widget.appointment.id,
            newDate: _selectedDate!,
            newTime: _selectedTime!,
            reason: _reasonController.text.trim().isEmpty
                ? null
                : _reasonController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PatientAppointmentBloc, PatientAppointmentState>(
      listener: (context, state) {
        if (state is DoctorAvailabilityLoaded) {
          setState(() {
            _availability = state.availability;
            _isLoading = false;
          });
        } else if (state is DoctorAvailabilityLoading) {
          setState(() => _isLoading = true);
        } else if (state is PatientAppointmentError) {
          setState(() => _isLoading = false);
          AppSnackBar.error(context, state.message);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 12.h,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              // Title
              Row(
                children: [
                  Icon(Icons.schedule, color: AppColors.primary, size: 24.sp),
                  SizedBox(width: 12.w),
                  AppTitle(
                    text: 'Reschedule Appointment',
                    fontSize: 20.sp,
                  ),
                ],
              ),
              SizedBox(height: 8.h),

              // Current appointment info
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: AppColors.grey200,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.grey400, size: 20.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: AppSmallText(
                        text:
                            'Current: ${DateFormat('MMM dd, yyyy').format(widget.appointment.appointmentDate)} at ${widget.appointment.appointmentTime}',
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              // Date selection
              AppSubtitle(
                text: 'Select New Date',
                fontSize: 16.sp,
              ),
              SizedBox(height: 12.h),

              if (_isLoading)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.h),
                    child: const CircularProgressIndicator(),
                  ),
                )
              else
                _buildDateSelector(),

              SizedBox(height: 20.h),

              // Time selection
              if (_selectedDate != null) ...[
                AppSubtitle(
                  text: 'Select Time',
                  fontSize: 16.sp,
                ),
                SizedBox(height: 12.h),
                _buildTimeSelector(),
                SizedBox(height: 20.h),
              ],

              // Reason (optional)
              AppSubtitle(
                text: 'Reason (Optional)',
                fontSize: 16.sp,
              ),
              SizedBox(height: 8.h),
              CustomTextField(
                controller: _reasonController,
                hintText: 'Why do you want to reschedule?',
                maxLines: 2,
                prefixIcon: Icons.notes,
              ),
              SizedBox(height: 24.h),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          _selectedDate != null && _selectedTime != null
                              ? _onSubmit
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        disabledBackgroundColor: AppColors.grey300,
                      ),
                      child: const Text('Request Reschedule'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    final now = DateTime.now();
    final dates = List.generate(
      14,
      (i) => now.add(Duration(days: i + 1)),
    );

    return SizedBox(
      height: 80.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = _selectedDate != null &&
              _selectedDate!.year == date.year &&
              _selectedDate!.month == date.month &&
              _selectedDate!.day == date.day;
          final isAvailable = _isDateAvailable(date);

          return Padding(
            padding: EdgeInsets.only(right: 12.w),
            child: _DateChip(
              date: date,
              isSelected: isSelected,
              isAvailable: isAvailable,
              onTap: isAvailable
                  ? () {
                      setState(() {
                        _selectedDate = date;
                        _selectedTime = null;
                      });
                    }
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeSelector() {
    final times = _availableTimesForSelectedDate;

    if (times.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: AppColors.grey200,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, color: AppColors.grey400, size: 20.sp),
            SizedBox(width: 8.w),
            AppBodyText(
              text: 'No available slots for this date',
              color: AppColors.grey500,
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: times.map((time) {
        final isSelected = _selectedTime == time;
        return _TimeChip(
          time: time,
          isSelected: isSelected,
          onTap: () {
            setState(() => _selectedTime = time);
          },
        );
      }).toList(),
    );
  }
}

class _DateChip extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final bool isAvailable;
  final VoidCallback? onTap;

  const _DateChip({
    required this.date,
    required this.isSelected,
    required this.isAvailable,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60.w,
        padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 4.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : isAvailable
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.grey200,
          borderRadius: BorderRadius.circular(12.r),
          border: isSelected
              ? null
              : Border.all(
                  color: isAvailable ? AppColors.primary : AppColors.grey200,
                  width: 1,
                ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat('EEE').format(date),
                style: TextStyle(
                  fontSize: 11.sp,
                  color: isSelected
                      ? Colors.white
                      : isAvailable
                          ? AppColors.primary
                          : AppColors.grey400,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                DateFormat('dd').format(date),
                style: TextStyle(
                  fontSize: 16.sp,
                  color: isSelected
                      ? Colors.white
                      : isAvailable
                          ? AppColors.textPrimaryStatic
                          : AppColors.grey400,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String time;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeChip({
    required this.time,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.grey300,
            width: 1.5,
          ),
        ),
        child: Text(
          time,
          style: TextStyle(
            fontSize: 14.sp,
            color: isSelected ? Colors.white : AppColors.textPrimaryStatic,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
