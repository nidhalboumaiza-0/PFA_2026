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
import '../../domain/entities/appointment_entity.dart';
import '../../domain/entities/time_slot_entity.dart';
import '../bloc/doctor/doctor_appointment_bloc.dart';
import '../bloc/patient/patient_appointment_bloc.dart';
import '../widgets/patient_selection_widget.dart';
import '../widgets/specialist_selection_widget.dart';

/// Screen for doctors to book referral appointments for their patients
class ReferralBookingScreen extends StatelessWidget {
  /// Optional pre-selected patient (from patient details screen)
  final PatientInfo? preselectedPatient;
  
  /// Optional referral ID if coming from referral service
  final String? referralId;

  const ReferralBookingScreen({
    super.key,
    this.preselectedPatient,
    this.referralId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<DoctorAppointmentBloc>(),
      child: _ReferralBookingView(
        preselectedPatient: preselectedPatient,
        referralId: referralId,
      ),
    );
  }
}

class _ReferralBookingView extends StatefulWidget {
  final PatientInfo? preselectedPatient;
  final String? referralId;

  const _ReferralBookingView({
    this.preselectedPatient,
    this.referralId,
  });

  @override
  State<_ReferralBookingView> createState() => _ReferralBookingViewState();
}

class _ReferralBookingViewState extends State<_ReferralBookingView> {
  int _currentStep = 0;
  
  // Step 1: Patient Selection
  PatientInfo? _selectedPatient;
  
  // Step 2: Specialist Selection  
  DoctorEntity? _selectedSpecialist;
  
  // Step 3: Date & Time Selection
  DateTime? _selectedDate;
  String? _selectedTime;
  List<TimeSlotEntity> _specialistAvailability = [];
  bool _isLoadingAvailability = false;
  
  // Step 4: Reason & Notes
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  final EasyInfiniteDateTimelineController _dateController = EasyInfiniteDateTimelineController();

  @override
  void initState() {
    super.initState();
    if (widget.preselectedPatient != null) {
      _selectedPatient = widget.preselectedPatient;
      // Skip to specialist selection if patient is preselected
      _currentStep = 1;
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedPatient != null;
      case 1:
        return _selectedSpecialist != null;
      case 2:
        return _selectedDate != null && _selectedTime != null;
      case 3:
        return _reasonController.text.trim().isNotEmpty;
      default:
        return false;
    }
  }

  void _loadSpecialistAvailability() async {
    if (_selectedSpecialist == null) return;
    
    setState(() => _isLoadingAvailability = true);
    
    // Use patient bloc to get doctor availability
    final bloc = sl<PatientAppointmentBloc>();
    bloc.add(LoadDoctorAvailability(
      doctorId: _selectedSpecialist!.id,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 30)),
    ));
  }

  void _submitReferral() {
    if (!_canProceed()) return;
    
    context.read<DoctorAppointmentBloc>().add(
      BookReferralAppointment(
        patientId: _selectedPatient!.id,
        specialistDoctorId: _selectedSpecialist!.id,
        appointmentDate: _selectedDate!,
        appointmentTime: _selectedTime!,
        reason: _reasonController.text.trim(),
        referralId: widget.referralId,
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Book Referral Appointment',
        showBackButton: true,
      ),
      body: BlocConsumer<DoctorAppointmentBloc, DoctorAppointmentState>(
        listener: (context, state) {
          if (state is ReferralBookingSuccess) {
            AppSnackBar.success(
              context, 
              'Referral appointment booked successfully!',
            );
            Navigator.pop(context, state.appointment);
          } else if (state is DoctorAppointmentError) {
            AppSnackBar.error(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is ReferralBookingLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    AppAssets.loadingHealthLottie,
                    width: 150.w,
                    height: 150.h,
                  ),
                  SizedBox(height: 16.h),
                  const AppSubtitle(text: 'Booking referral appointment...'),
                ],
              ),
            );
          }
          
          return Column(
            children: [
              // Step Indicator
              _buildStepIndicator(),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: _buildCurrentStep(),
                  ),
                ),
              ),
              
              // Navigation Buttons
              _buildNavigationButtons(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStepCircle(0, 'Patient', Icons.person_outline),
          _buildStepLine(0),
          _buildStepCircle(1, 'Specialist', Icons.medical_services_outlined),
          _buildStepLine(1),
          _buildStepCircle(2, 'Schedule', Icons.calendar_today_outlined),
          _buildStepLine(2),
          _buildStepCircle(3, 'Details', Icons.description_outlined),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label, IconData icon) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;
    
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? AppColors.primary : AppColors.grey300,
              border: isCurrent
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : AppColors.grey500,
              size: 20.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
              color: isActive ? AppColors.primary : AppColors.grey500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int afterStep) {
    final isActive = _currentStep > afterStep;
    return Container(
      height: 2.h,
      width: 20.w,
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.grey300,
        borderRadius: BorderRadius.circular(1.r),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildPatientSelectionStep();
      case 1:
        return _buildSpecialistSelectionStep();
      case 2:
        return _buildScheduleStep();
      case 3:
        return _buildDetailsStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPatientSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.person_search,
                color: AppColors.primary,
                size: 28.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Patient',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Choose a patient to refer to a specialist',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.grey500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 24.h),
        
        // Patient Selection Widget
        PatientSelectionWidget(
          selectedPatient: _selectedPatient,
          onPatientSelected: (patient) {
            setState(() => _selectedPatient = patient);
          },
        ),
      ],
    );
  }

  Widget _buildSpecialistSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with patient info
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Patient: ${_selectedPatient?.fullName ?? 'Selected'}',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        
        // Header
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.medical_services,
                color: AppColors.secondary,
                size: 28.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Specialist',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Search for a specialist doctor',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.grey500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 24.h),
        
        // Specialist Selection Widget
        SpecialistSelectionWidget(
          selectedSpecialist: _selectedSpecialist,
          onSpecialistSelected: (doctor) {
            setState(() {
              _selectedSpecialist = doctor;
              _selectedDate = null;
              _selectedTime = null;
              _specialistAvailability = [];
            });
          },
        ),
      ],
    );
  }

  Widget _buildScheduleStep() {
    return BlocProvider.value(
      value: sl<PatientAppointmentBloc>(),
      child: BlocConsumer<PatientAppointmentBloc, PatientAppointmentState>(
        listener: (context, state) {
          if (state is DoctorAvailabilityLoaded) {
            setState(() {
              _specialistAvailability = state.availability;
              _isLoadingAvailability = false;
            });
          }
        },
        builder: (context, state) {
          // Load availability if not loaded
          if (_specialistAvailability.isEmpty && 
              _selectedSpecialist != null && 
              !_isLoadingAvailability &&
              state is! DoctorAvailabilityLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadSpecialistAvailability();
            });
          }
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Previous selections summary
              _buildSelectionsSummary(),
              SizedBox(height: 16.h),
              
              // Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.calendar_month,
                      color: AppColors.info,
                      size: 28.sp,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Date & Time',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Choose available slot for the appointment',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: AppColors.grey500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              
              // Date Picker
              if (state is DoctorAvailabilityLoading || _isLoadingAvailability)
                Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      SizedBox(height: 16.h),
                      const AppBodyText(text: 'Loading availability...'),
                    ],
                  ),
                )
              else ...[
                Text(
                  'Select Date',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8.h),
                _buildDateTimeline(),
                SizedBox(height: 24.h),
                
                // Time Slots
                if (_selectedDate != null) ...[
                  Text(
                    'Available Times',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  _buildTimeSlots(),
                ],
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSelectionsSummary() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.person, size: 16.sp, color: AppColors.success),
              SizedBox(width: 8.w),
              Text(
                'Patient: ${_selectedPatient?.fullName ?? '-'}',
                style: TextStyle(fontSize: 12.sp),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(Icons.medical_services, size: 16.sp, color: AppColors.secondary),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Specialist: ${_selectedSpecialist?.fullName ?? '-'} (${_selectedSpecialist?.specialty ?? ''})',
                  style: TextStyle(fontSize: 12.sp),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeline() {
    // Get dates with availability
    final availableDates = _specialistAvailability
        .where((ts) => ts.availableSlots.isNotEmpty)
        .map((ts) => DateTime(ts.date.year, ts.date.month, ts.date.day))
        .toSet();

    return EasyInfiniteDateTimeLine(
      controller: _dateController,
      firstDate: DateTime.now(),
      focusDate: _selectedDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      onDateChange: (date) {
        setState(() {
          _selectedDate = date;
          _selectedTime = null;
        });
      },
      dayProps: EasyDayProps(
        height: 80.h,
        width: 60.w,
        dayStructure: DayStructure.dayStrDayNum,
        borderColor: AppColors.grey300,
        activeDayStyle: DayStyle(
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12.r),
          ),
          dayNumStyle: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
          dayStrStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12.sp,
          ),
        ),
        inactiveDayStyle: DayStyle(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.grey300),
          ),
          dayNumStyle: TextStyle(
            color: AppColors.grey600,
            fontSize: 16.sp,
          ),
          dayStrStyle: TextStyle(
            color: AppColors.grey500,
            fontSize: 11.sp,
          ),
        ),
        todayStyle: DayStyle(
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.primary),
          ),
          dayNumStyle: TextStyle(
            color: AppColors.primary,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
          dayStrStyle: TextStyle(
            color: AppColors.primary,
            fontSize: 11.sp,
          ),
        ),
        disabledDayStyle: DayStyle(
          decoration: BoxDecoration(
            color: AppColors.grey200,
            borderRadius: BorderRadius.circular(12.r),
          ),
          dayNumStyle: TextStyle(
            color: AppColors.grey400,
            fontSize: 16.sp,
          ),
          dayStrStyle: TextStyle(
            color: AppColors.grey400,
            fontSize: 11.sp,
          ),
        ),
      ),
      itemBuilder: (context, date, isSelected, onTap) {
        final dateOnly = DateTime(date.year, date.month, date.day);
        final hasAvailability = availableDates.contains(dateOnly);
        
        return GestureDetector(
          onTap: hasAvailability ? onTap : null,
          child: Opacity(
            opacity: hasAvailability ? 1.0 : 0.4,
            child: Container(
              width: 60.w,
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : hasAvailability
                        ? Theme.of(context).cardColor
                        : AppColors.grey200,
                borderRadius: BorderRadius.circular(12.r),
                border: isSelected
                    ? null
                    : Border.all(
                        color: hasAvailability
                            ? AppColors.primary.withValues(alpha: 0.3)
                            : AppColors.grey300,
                      ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getDayName(date.weekday),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: isSelected ? Colors.white70 : AppColors.grey500,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.textPrimaryStatic,
                    ),
                  ),
                  if (hasAvailability && !isSelected)
                    Container(
                      margin: EdgeInsets.only(top: 4.h),
                      width: 6.w,
                      height: 6.w,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  Widget _buildTimeSlots() {
    if (_selectedDate == null) return const SizedBox.shrink();
    
    final dateOnly = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
    final daySlot = _specialistAvailability.firstWhere(
      (ts) => DateTime(ts.date.year, ts.date.month, ts.date.day) == dateOnly,
      orElse: () => TimeSlotEntity(
        id: '',
        doctorId: '',
        date: _selectedDate!,
        slots: [],
      ),
    );
    
    final availableSlots = daySlot.availableSlots;
    
    if (availableSlots.isEmpty) {
      return Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_busy,
              size: 48.sp,
              color: AppColors.warning,
            ),
            SizedBox(height: 8.h),
            const AppSubtitle(text: 'No available slots'),
            const AppBodyText(text: 'Please select another date'),
          ],
        ),
      );
    }
    
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: availableSlots.map((slot) {
        final isSelected = _selectedTime == slot.time;
        return GestureDetector(
          onTap: () => setState(() => _selectedTime = slot.time),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.grey300,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              slot.time,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : AppColors.textPrimaryStatic,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Card
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.1),
                AppColors.secondary.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Text(
                'Referral Summary',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 12.h),
              _buildSummaryRow(
                Icons.person,
                'Patient',
                _selectedPatient?.fullName ?? '-',
              ),
              _buildSummaryRow(
                Icons.medical_services,
                'Specialist',
                '${_selectedSpecialist?.fullName ?? '-'}\n${_selectedSpecialist?.specialty ?? ''}',
              ),
              _buildSummaryRow(
                Icons.calendar_today,
                'Date',
                _selectedDate != null
                    ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                    : '-',
              ),
              _buildSummaryRow(
                Icons.access_time,
                'Time',
                _selectedTime ?? '-',
              ),
            ],
          ),
        ),
        SizedBox(height: 24.h),
        
        // Reason Input
        Text(
          'Reason for Referral *',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        CustomTextField(
          controller: _reasonController,
          hintText: 'e.g., Cardiac evaluation for chest pain',
          maxLines: 3,
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: 16.h),
        
        // Notes Input
        Text(
          'Additional Notes (Optional)',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        CustomTextField(
          controller: _notesController,
          hintText: 'Any additional information for the specialist...',
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18.sp, color: AppColors.grey500),
          SizedBox(width: 12.w),
          SizedBox(
            width: 70.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.grey500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: CustomButton(
                text: 'Back',
                onPressed: _previousStep,
                isOutlined: true,
              ),
            ),
          if (_currentStep > 0) SizedBox(width: 12.w),
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: CustomButton(
              text: _currentStep == 3 ? 'Book Referral' : 'Continue',
              onPressed: _canProceed()
                  ? (_currentStep == 3 ? _submitReferral : _nextStep)
                  : null,
              icon: _currentStep == 3 ? Icons.check : Icons.arrow_forward,
            ),
          ),
        ],
      ),
    );
  }
}
