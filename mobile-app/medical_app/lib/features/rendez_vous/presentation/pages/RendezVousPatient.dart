import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/core/utils/navigation_with_transition.dart';
import 'package:medical_app/injection_container.dart' as di;
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../../core/specialties.dart';
import 'available_doctor_screen.dart';

class RendezVousPatient extends StatefulWidget {
  final String? selectedSpecialty;
  final bool
  showAppBar; // Whether to show the app bar (true when navigating directly, false from bottom nav)

  const RendezVousPatient({
    super.key,
    this.selectedSpecialty,
    this.showAppBar = true,
  });

  @override
  State<RendezVousPatient> createState() => _RendezVousPatientState();
}

class _RendezVousPatientState extends State<RendezVousPatient> {
  final TextEditingController dateTimeController = TextEditingController();
  String? selectedSpecialty;
  DateTime? selectedDateTime;
  final _formKey = GlobalKey<FormState>();

  // Calendar variables
  bool isCalendarVisible = false;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
    // Specialty initialization moved to didChangeDependencies for context access
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.selectedSpecialty != null && selectedSpecialty == null) {
      // Check if the selected specialty exists in any language
      List<String> translatedSpecialties = getTranslatedSpecialties(context);
      if (translatedSpecialties.contains(widget.selectedSpecialty)) {
        selectedSpecialty = widget.selectedSpecialty;
      }
    }
  }

  @override
  void dispose() {
    dateTimeController.dispose();
    super.dispose();
  }

  void _toggleCalendar() {
    setState(() {
      isCalendarVisible = !isCalendarVisible;
    });
  }

  Future<void> _selectDateTime(BuildContext context) async {
    _toggleCalendar();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
      // Show time picker after selecting a date
      _showTimePicker(selectedDay);
    });
  }

  void _showTimePicker(DateTime date) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: AppColors.whiteColor,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      setState(() {
        selectedDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        dateTimeController.text = DateFormat(
          'dd/MM/yyyy à HH:mm',
        ).format(selectedDateTime!);
        isCalendarVisible = false; // Hide calendar after selection
      });
    }
  }

  void selectDoctor(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      navigateWithTransition(
        context,
        AvailableDoctorScreen(
          specialty: selectedSpecialty!,
          selectedDateTime: selectedDateTime!,
        ),
        TransitionType.rightToLeft,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            context.tr('medilink'),
            style: GoogleFonts.raleway(
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppColors.primaryColor,
          elevation: 2,
          leading:
              widget.showAppBar
                  ? IconButton(
                    icon: const Icon(
                      Icons.chevron_left,
                      size: 28,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  )
                  : null,
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_today, color: Colors.white),
              onPressed: _toggleCalendar,
              tooltip: context.tr('select_date'),
            ),
          ],
        ),
        body: Stack(
          children: [
            // Main content
            SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 16.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header image
                      Center(
                        child: Image.asset(
                          'assets/images/Consultation.png',
                          height: 180.h,
                          width: 180.w,
                        ),
                      ),

                      SizedBox(height: 24.h),

                      // Title
                      Text(
                        context.tr('find_your_doctor'),
                        style: GoogleFonts.raleway(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.headlineMedium?.color,
                        ),
                      ),

                      SizedBox(height: 8.h),

                      // Subtitle
                      Text(
                        context.tr('select_specialty_date'),
                        style: GoogleFonts.raleway(
                          fontSize: 14.sp,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),

                      SizedBox(height: 28.h),

                      // Specialty selection
                      Text(
                        context.tr('medical_specialty'),
                        style: GoogleFonts.raleway(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.titleMedium?.color,
                        ),
                      ),

                      SizedBox(height: 8.h),

                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.r),
                          color: isDarkMode ? theme.cardColor : Colors.white,
                          border: Border.all(
                            color:
                                isDarkMode
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade200,
                            width: 1,
                          ),
                          boxShadow:
                              isDarkMode
                                  ? []
                                  : [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                        ),
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor:
                                isDarkMode ? theme.cardColor : Colors.white,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20.w,
                              vertical: 16.h,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16.r),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16.r),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16.r),
                              borderSide: BorderSide(
                                color: AppColors.primaryColor,
                                width: 1,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16.r),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 1,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16.r),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 1,
                              ),
                            ),
                            hintText: context.tr('choose_specialty'),
                            hintStyle: GoogleFonts.raleway(
                              color:
                                  isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[400],
                              fontSize: 15.sp,
                            ),
                            prefixIcon: Icon(
                              Icons.medical_services_outlined,
                              color: AppColors.primaryColor,
                              size: 22.sp,
                            ),
                          ),
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: AppColors.primaryColor,
                          ),
                          dropdownColor:
                              isDarkMode ? theme.cardColor : Colors.white,
                          style: GoogleFonts.raleway(
                            fontSize: 15.sp,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                          value: selectedSpecialty,
                          items:
                              getTranslatedSpecialties(context)
                                  .map(
                                    (specialty) => DropdownMenuItem(
                                      value: specialty,
                                      child: Text(
                                        specialty,
                                        style: GoogleFonts.raleway(
                                          fontSize: 15.sp,
                                          color:
                                              theme.textTheme.bodyMedium?.color,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedSpecialty = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return context.tr('please_select_specialty');
                            }
                            return null;
                          },
                        ),
                      ),

                      SizedBox(height: 24.h),

                      // Date and time selection
                      Text(
                        context.tr('desired_date_time'),
                        style: GoogleFonts.raleway(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.titleMedium?.color,
                        ),
                      ),

                      SizedBox(height: 8.h),

                      GestureDetector(
                        onTap: () => _selectDateTime(context),
                        child: AbsorbPointer(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16.r),
                              color:
                                  isDarkMode ? theme.cardColor : Colors.white,
                              border: Border.all(
                                color:
                                    isDarkMode
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade200,
                                width: 1,
                              ),
                              boxShadow:
                                  isDarkMode
                                      ? []
                                      : [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.1),
                                          spreadRadius: 1,
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                            ),
                            child: TextFormField(
                              controller: dateTimeController,
                              style: GoogleFonts.raleway(
                                fontSize: 15.sp,
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor:
                                    isDarkMode ? theme.cardColor : Colors.white,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20.w,
                                  vertical: 16.h,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16.r),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16.r),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16.r),
                                  borderSide: BorderSide(
                                    color: AppColors.primaryColor,
                                    width: 1,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16.r),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                    width: 1,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16.r),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                    width: 1,
                                  ),
                                ),
                                hintText: context.tr('select_date_time'),
                                hintStyle: GoogleFonts.raleway(
                                  color:
                                      isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[400],
                                  fontSize: 15.sp,
                                ),
                                prefixIcon: Icon(
                                  Icons.calendar_today,
                                  color: AppColors.primaryColor,
                                  size: 22.sp,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return context.tr('please_select_date_time');
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 40.h),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              selectedSpecialty != null &&
                                      selectedDateTime != null
                                  ? () => selectDoctor(context)
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            disabledBackgroundColor: Colors.grey,
                          ),
                          child: Text(
                            context.tr('next'),
                            style: GoogleFonts.raleway(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Calendar overlay
            if (isCalendarVisible)
              Container(
                color:
                    isDarkMode
                        ? Colors.black.withOpacity(0.8)
                        : Colors.white.withOpacity(0.9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(Icons.close, color: theme.iconTheme.color),
                      onPressed: _toggleCalendar,
                    ),
                    Expanded(
                      child: TableCalendar(
                        firstDay: DateTime.now(),
                        lastDay: DateTime.now().add(const Duration(days: 365)),
                        focusedDay: _focusedDay,
                        calendarFormat: _calendarFormat,
                        onFormatChanged: (format) {
                          setState(() {
                            _calendarFormat = format;
                          });
                        },
                        selectedDayPredicate: (day) {
                          return selectedDateTime != null &&
                              day.year == selectedDateTime!.year &&
                              day.month == selectedDateTime!.month &&
                              day.day == selectedDateTime!.day;
                        },
                        onDaySelected: _onDaySelected,
                        calendarStyle: CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: const BoxDecoration(
                            color: AppColors.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          markersMaxCount: 3,
                          weekendTextStyle: TextStyle(
                            color: Colors.red.shade300,
                          ),
                          outsideDaysVisible: false,
                        ),
                        headerStyle: HeaderStyle(
                          titleTextStyle: GoogleFonts.raleway(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.titleLarge?.color,
                          ),
                          formatButtonTextStyle: GoogleFonts.raleway(
                            fontSize: 14.sp,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                          titleCentered: true,
                        ),
                        availableCalendarFormats: const {
                          CalendarFormat.month: 'Mois',
                          CalendarFormat.twoWeeks: '2 Semaines',
                          CalendarFormat.week: 'Semaine',
                        },
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                            fontWeight: FontWeight.bold,
                          ),
                          weekendStyle: TextStyle(
                            color: Colors.red.shade300,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
