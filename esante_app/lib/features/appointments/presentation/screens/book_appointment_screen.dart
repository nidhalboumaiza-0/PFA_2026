import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../injection_container.dart';
import '../../../doctors/domain/entities/doctor_entity.dart';
import '../../domain/entities/document_entity.dart';
import '../bloc/patient/patient_appointment_bloc.dart';
import '../widgets/document_attachment_widget.dart';

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
  final EasyInfiniteDateTimelineController _dateController = EasyInfiniteDateTimelineController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _reasonError;
  
  // Document attachments
  List<PendingDocumentAttachment> _attachments = [];

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
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
          // Booking illustration
          Center(
            child: Lottie.asset(
              AppAssets.waitingAppointmentLottie,
              width: 160.w,
              height: 120.h,
              fit: BoxFit.contain,
            ),
          ),
          
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
            SizedBox(height: 16.h),
            
            // Document Attachments Section
            _buildDocumentSection(),
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
          EasyInfiniteDateTimeLine(
            controller: _dateController,
            firstDate: DateTime.now(),
            focusDate: state.selectedDate ?? DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 60)),
            onDateChange: (date) {
              // Check if this date has available slots
              final normalizedDate = DateTime(date.year, date.month, date.day);
              if (availableDateSet.contains(normalizedDate)) {
                context.read<PatientAppointmentBloc>().add(
                      SelectDate(date: date),
                    );
              } else {
                // Show message that no slots available for this date
                AppSnackBar.warning(
                  context,
                  'No available slots on this date',
                );
              }
            },
            showTimelineHeader: false,
            itemBuilder: (context, date, isSelected, onTap) {
              final normalizedDate = DateTime(date.year, date.month, date.day);
              final isAvailable = availableDateSet.contains(normalizedDate);
              final isToday = DateTime.now().day == date.day &&
                  DateTime.now().month == date.month &&
                  DateTime.now().year == date.year;

              return GestureDetector(
                onTap: () => onTap(),
                child: Container(
                  width: 64.w,
                  height: 80.h,
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : isAvailable
                            ? AppColors.success.withValues(alpha: 0.12)
                            : AppColors.grey200.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12.r),
                    border: isToday && !isSelected
                        ? Border.all(color: AppColors.primary, width: 2)
                        : isAvailable && !isSelected
                            ? Border.all(color: AppColors.success.withValues(alpha: 0.4), width: 1.5)
                            : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _getDayName(date.weekday),
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : isAvailable
                                      ? AppColors.success
                                      : AppColors.grey400,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : isToday
                                      ? AppColors.primary
                                      : isAvailable
                                          ? AppColors.success
                                          : AppColors.grey400,
                            ),
                          ),
                        ],
                      ),
                      // Available indicator dot at bottom
                      if (isAvailable && !isSelected)
                        Positioned(
                          bottom: 6.h,
                          child: Container(
                            width: 6.w,
                            height: 6.h,
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
            dayProps: EasyDayProps(
              height: 80.h,
              width: 64.w,
              dayStructure: DayStructure.dayStrDayNum,
              activeDayStyle: DayStyle(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                dayStrStyle: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                dayNumStyle: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              inactiveDayStyle: DayStyle(
                decoration: BoxDecoration(
                  color: AppColors.grey200.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                dayStrStyle: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.grey400,
                ),
                dayNumStyle: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.grey400,
                ),
              ),
              todayStyle: DayStyle(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                dayStrStyle: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
                dayNumStyle: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          // Show availability legend
          Padding(
            padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 12.h),
            child: Row(
              children: [
                // Available indicator
                Container(
                  width: 12.w,
                  height: 12.h,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(3.r),
                    border: Border.all(color: AppColors.success, width: 1),
                  ),
                ),
                SizedBox(width: 6.w),
                Text(
                  'Available',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 16.w),
                // Unavailable indicator
                Container(
                  width: 12.w,
                  height: 12.h,
                  decoration: BoxDecoration(
                    color: AppColors.grey200,
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),
                SizedBox(width: 6.w),
                Text(
                  'Unavailable',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.grey400,
                  ),
                ),
                const Spacer(),
                Text(
                  '${availableDateSet.length} days',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.grey400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
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
            hintText: 'Reason for visit *',
            label: 'Reason (Required)',
            prefixIcon: Icons.medical_information_outlined,
            maxLines: 2,
            errorText: _reasonError,
            onChanged: (value) {
              if (_reasonError != null && value.isNotEmpty) {
                setState(() => _reasonError = null);
              }
            },
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

  Widget _buildDocumentSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DocumentAttachmentWidget(
        attachments: _attachments,
        onAttachmentsChanged: (newAttachments) {
          setState(() {
            _attachments = newAttachments;
          });
        },
        maxFiles: 5,
        maxFileSizeMB: 10,
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
                // Validate required fields
                if (_reasonController.text.trim().isEmpty) {
                  setState(() {
                    _reasonError = 'Please provide a reason for your visit';
                  });
                  AppSnackBar.warning(context, 'Please provide a reason for your appointment');
                  return;
                }
                
                if (_reasonController.text.trim().length > 500) {
                  setState(() {
                    _reasonError = 'Reason must be less than 500 characters';
                  });
                  return;
                }
                
                if (_notesController.text.length > 1000) {
                  AppSnackBar.warning(context, 'Notes must be less than 1000 characters');
                  return;
                }

                context.read<PatientAppointmentBloc>().add(
                      RequestAppointment(
                        doctorId: widget.doctor.id,
                        appointmentDate: state.selectedDate!,
                        appointmentTime: state.selectedTime!,
                        reason: _reasonController.text.trim(),
                        notes: _notesController.text.trim().isNotEmpty
                            ? _notesController.text.trim()
                            : null,
                        attachments: _attachments,
                      ),
                    );
              }
            : null,
      ),
    );
  }
}
