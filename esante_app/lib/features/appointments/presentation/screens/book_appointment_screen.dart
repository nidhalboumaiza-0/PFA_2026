import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../injection_container.dart';
import '../../../doctors/domain/entities/doctor_entity.dart';
import '../bloc/patient/patient_appointment_bloc.dart';

class BookAppointmentScreen extends StatelessWidget {
  final DoctorEntity doctor;

  const BookAppointmentScreen({
    super.key,
    required this.doctor,
  });

  @override
  Widget build(BuildContext context) {
    // Use singleton BLoC from DI for real-time WebSocket updates
    final bloc = sl<PatientAppointmentBloc>();
    bloc.add(LoadDoctorAvailability(
      doctorId: doctor.id,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 30)),
    ));
    
    return BlocProvider.value(
      value: bloc,
      child: _BookAppointmentView(doctor: doctor),
    );
  }
}

class _BookAppointmentView extends StatefulWidget {
  final DoctorEntity doctor;

  const _BookAppointmentView({required this.doctor});

  @override
  State<_BookAppointmentView> createState() => _BookAppointmentViewState();
}

class _BookAppointmentViewState extends State<_BookAppointmentView> {
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Book Appointment',
        showBackButton: true,
      ),
      body: BlocConsumer<PatientAppointmentBloc, PatientAppointmentState>(
        listener: (context, state) {
          if (state is AppointmentRequestSuccess) {
            AppSnackBar.success(context, 'Appointment requested successfully!');
            Navigator.pop(context, true);
          } else if (state is PatientAppointmentError) {
            AppSnackBar.error(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is DoctorAvailabilityLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is DoctorAvailabilityLoaded) {
            return _buildContent(context, state);
          }

          if (state is AppointmentRequestLoading) {
            return  Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  AppBodyText(text: 'Requesting appointment...'),
                ],
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64.sp, color: AppColors.error),
                SizedBox(height: 16.h),
                const AppSubtitle(text: 'Failed to load availability'),
                SizedBox(height: 16.h),
                CustomButton(
                  text: 'Retry',
                  onPressed: () {
                    context.read<PatientAppointmentBloc>().add(
                          LoadDoctorAvailability(
                            doctorId: widget.doctor.id,
                            startDate: DateTime.now(),
                            endDate: DateTime.now().add(const Duration(days: 30)),
                          ),
                        );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, DoctorAvailabilityLoaded state) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doctor Info Header
          _buildDoctorHeader(),
          SizedBox(height: 16.h),

          // Calendar Section
          _buildCalendarSection(context, state),
          SizedBox(height: 16.h),

          // Time Slots Section
          if (state.selectedDate != null) ...[
            _buildTimeSlotsSection(context, state),
            SizedBox(height: 16.h),
          ],

          // Reason and Notes
          if (state.canBook) ...[
            _buildReasonSection(),
            SizedBox(height: 24.h),
          ],

          // Book Button
          _buildBookButton(context, state),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  Widget _buildDoctorHeader() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30.r,
            backgroundColor: AppColors.primary,
            child: widget.doctor.profilePhoto != null
                ? ClipOval(
                    child: Image.network(
                      widget.doctor.profilePhoto!,
                      fit: BoxFit.cover,
                      width: 60.r,
                      height: 60.r,
                    ),
                  )
                : Icon(Icons.person, size: 30.sp, color: Colors.white),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.doctor.fullName,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  widget.doctor.displaySpecialty,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.primary,
                  ),
                ),
                if (widget.doctor.consultationFee != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    'Consultation: ${widget.doctor.consultationFee} TND',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.grey400,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarSection(
      BuildContext context, DoctorAvailabilityLoaded state) {
    // Create a set of available dates for quick lookup
    final availableDateSet = <DateTime>{};
    for (final slot in state.availability) {
      if (slot.isAvailable && slot.availableSlots.isNotEmpty) {
        availableDateSet.add(DateTime(
          slot.date.year,
          slot.date.month,
          slot.date.day,
        ));
      }
    }

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
                Icon(Icons.calendar_today, color: AppColors.primary, size: 20.sp),
                SizedBox(width: 8.w),
                const AppSubtitle(text: 'Select Date'),
              ],
            ),
          ),
          TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 60)),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              if (state.selectedDate == null) return false;
              return day.year == state.selectedDate!.year &&
                  day.month == state.selectedDate!.month &&
                  day.day == state.selectedDate!.day;
            },
            enabledDayPredicate: (day) {
              final normalizedDay = DateTime(day.year, day.month, day.day);
              return availableDateSet.contains(normalizedDay);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
              context.read<PatientAppointmentBloc>().add(
                    SelectDate(date: selectedDay),
                  );
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
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
              disabledTextStyle: TextStyle(
                color: AppColors.grey300,
                fontSize: 14.sp,
              ),
              defaultTextStyle: TextStyle(fontSize: 14.sp),
              weekendTextStyle: TextStyle(fontSize: 14.sp),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonDecoration: BoxDecoration(
                border: Border.all(color: AppColors.primary),
                borderRadius: BorderRadius.circular(8.r),
              ),
              formatButtonTextStyle: TextStyle(
                color: AppColors.primary,
                fontSize: 12.sp,
              ),
            ),
          ),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }

  Widget _buildTimeSlotsSection(
      BuildContext context, DoctorAvailabilityLoaded state) {
    final slots = state.slotsForSelectedDate;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, color: AppColors.primary, size: 20.sp),
              SizedBox(width: 8.w),
              const AppSubtitle(text: 'Available Times'),
            ],
          ),
          SizedBox(height: 12.h),
          if (slots.isEmpty)
            Container(
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: AppColors.grey300.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: AppBodyText(
                  text: 'No available slots for this date',
                  color: AppColors.grey400,
                ),
              ),
            )
          else
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: slots.map((slot) {
                final isSelected = state.selectedTime == slot.time;
                return GestureDetector(
                  onTap: () {
                    context.read<PatientAppointmentBloc>().add(
                          SelectTimeSlot(time: slot.time),
                        );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.grey300,
                      ),
                    ),
                    child: Text(
                      slot.time,
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
      ),
    );
  }

  Widget _buildReasonSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.note_alt_outlined, color: AppColors.primary, size: 20.sp),
              SizedBox(width: 8.w),
              const AppSubtitle(text: 'Appointment Details'),
            ],
          ),
          SizedBox(height: 12.h),
          CustomTextField(
            controller: _reasonController,
            hintText: 'Reason for visit (optional)',
            label: 'Reason',
            prefixIcon: Icons.medical_information_outlined,
            maxLines: 2,
          ),
          SizedBox(height: 12.h),
          CustomTextField(
            controller: _notesController,
            hintText: 'Any additional notes (optional)',
            label: 'Notes',
            prefixIcon: Icons.edit_note,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildBookButton(
      BuildContext context, DoctorAvailabilityLoaded state) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: CustomButton(
        text: 'Book Appointment',
        icon: Icons.calendar_month,
        onPressed: state.canBook
            ? () {
                context.read<PatientAppointmentBloc>().add(
                      RequestAppointment(
                        doctorId: widget.doctor.id,
                        appointmentDate: state.selectedDate!,
                        appointmentTime: state.selectedTime!,
                        reason: _reasonController.text.isNotEmpty
                            ? _reasonController.text
                            : null,
                        notes: _notesController.text.isNotEmpty
                            ? _notesController.text
                            : null,
                      ),
                    );
              }
            : null,
      ),
    );
  }
}
