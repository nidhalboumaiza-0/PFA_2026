import 'package:flutter/material.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/specialties.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../authentication/domain/entities/medecin_entity.dart';
import '../../../specialite/presentation/pages/AllSpecialtiesPage.dart';
import '../../domain/entities/rendez_vous_entity.dart';
import '../blocs/rendez-vous BLoC/rendez_vous_bloc.dart';
import '../../../../features/authentication/data/models/user_model.dart';
import '../../../../injection_container.dart' as di;
import 'appointment_details_page.dart';
import '../../../profile/presentation/pages/doctor_profile_page.dart'
    as doctor_profile_page;
import 'package:medical_app/features/dossier_medical/presentation/bloc/dossier_medical_bloc.dart';
import 'package:medical_app/features/dossier_medical/presentation/bloc/dossier_medical_event.dart';
import 'package:medical_app/features/dossier_medical/presentation/bloc/dossier_medical_state.dart';
import 'package:medical_app/features/dossier_medical/presentation/pages/dossier_medical_screen.dart';
import 'package:medical_app/core/util/snackbar_message.dart';

class AppointmentsPatients extends StatefulWidget {
  final bool showAppBar;

  const AppointmentsPatients({Key? key, this.showAppBar = true})
    : super(key: key);

  @override
  _AppointmentsPatientsState createState() => _AppointmentsPatientsState();
}

class _AppointmentsPatientsState extends State<AppointmentsPatients> {
  late RendezVousBloc _rendezVousBloc;
  List<RendezVousEntity> appointments = [];
  List<RendezVousEntity> filteredAppointments = [];
  UserModel? currentUser;
  bool isLoading = true;
  String? cancellingAppointmentId; // Track ID of appointment being cancelled
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Calendar related variables
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isCalendarVisible = false;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _rendezVousBloc = di.sl<RendezVousBloc>();
    _loadUser();

    // Reset selected day to null to show all appointments initially
    _selectedDay = null;
    _focusedDay = DateTime.now();

    debugPrint(
      'AppointmentsPatients: initState called, _isCalendarVisible = $_isCalendarVisible',
    );
  }

  // Make setState more verbose with logging
  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    // Add a small delay to ensure the state is updated before logging
    Future.microtask(() {
      debugPrint(
        'AppointmentsPatients: setState called, _isCalendarVisible = $_isCalendarVisible',
      );
    });
  }

  Future<void> _loadUser() async {
    debugPrint('AppointmentsPatients: Loading user data...');
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('CACHED_USER');

    if (userJson != null) {
      try {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        debugPrint('AppointmentsPatients: User JSON loaded: ${userMap['id']}');
        currentUser = UserModel.fromJson(userMap);

        // Fetch appointments using the patient ID
        if (currentUser != null && currentUser!.id != null) {
          debugPrint(
            'AppointmentsPatients: Fetching appointments for patient ID: ${currentUser!.id}',
          );

          // Check for past appointments that need to be updated to completed
          _rendezVousBloc.add(
            CheckAndUpdatePastAppointments(
              userId: currentUser!.id!,
              userRole: 'patient',
            ),
          );

          // Then fetch the appointments (which will now have updated statuses)
          _rendezVousBloc.add(FetchRendezVous(patientId: currentUser!.id));
        } else {
          debugPrint('AppointmentsPatients: Current user or ID is null');
          setState(() {
            isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('AppointmentsPatients: Error loading user data: $e');
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr('error_loading_user_data'),
              style: GoogleFonts.raleway(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } else {
      debugPrint('AppointmentsPatients: No user data found in SharedPreferences');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Filter appointments by selected date
  void _filterAppointmentsByDate(DateTime? selectedDay) {
    if (selectedDay == null) {
      setState(() {
        filteredAppointments = List.from(appointments);
      });
      return;
    }

    final filtered =
        appointments.where((appointment) {
          final appointmentDate = DateTime(
            appointment.startDate.year,
            appointment.startDate.month,
            appointment.startDate.day,
          );

          final selectedDate = DateTime(
            selectedDay.year,
            selectedDay.month,
            selectedDay.day,
          );

          return appointmentDate.isAtSameMomentAs(selectedDate);
        }).toList();

    setState(() {
      filteredAppointments = filtered;
    });
  }

  // Toggle calendar visibility
  void _toggleCalendar() {
    debugPrint('Toggling calendar visibility');
    setState(() {
      _isCalendarVisible = !_isCalendarVisible;
    });
  }

  // Clear date filter
  void _clearDateFilter() {
    setState(() {
      _selectedDay = null;
      filteredAppointments = List.from(appointments);
    });
  }

  // Fonction pour annuler un rendez-vous
  void _cancelAppointment(RendezVousEntity appointment) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              context.tr("confirm_cancellation"),
              style: GoogleFonts.raleway(
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
            content: Text(
              context.tr("want_to_cancel_appointment"),
              style: GoogleFonts.raleway(fontSize: 14.sp),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  context.tr("no"),
                  style: GoogleFonts.raleway(
                    fontSize: 14.sp,
                    color: Colors.grey,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (appointment.id != null &&
                      appointment.patient != null &&
                      appointment.medecin != null &&
                      appointment.patientName != null &&
                      appointment.medecinName != null) {
                    setState(() {
                      cancellingAppointmentId = appointment.id;
                    });

                    // Send the status update request to the backend
                    _rendezVousBloc.add(
                      UpdateRendezVousStatus(
                        rendezVousId: appointment.id!,
                        status: "cancelled",
                      ),
                    );
                  }
                  Navigator.pop(context);
                },
                child: Text(
                  context.tr("yes"),
                  style: GoogleFonts.raleway(
                    fontSize: 14.sp,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // Navigate to appointment details
  void _navigateToAppointmentDetails(RendezVousEntity appointment) async {
    // Navigate to appointment details page
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AppointmentDetailsPage(
              appointment: appointment,
              isDoctor:
                  false, // Pass parameter to indicate this is a patient view
            ),
      ),
    );

    // If the appointment was cancelled or modified from the details page, refresh the list
    if (result == true && currentUser != null && currentUser!.id != null) {
      _rendezVousBloc.add(FetchRendezVous(patientId: currentUser!.id));
    }
  }

  // Fetch doctor info from Firestore
  Future<MedecinEntity?> _fetchDoctorInfo(String doctorId) async {
    try {
      final doctorDoc =
          await _firestore.collection('medecins').doc(doctorId).get();

      if (doctorDoc.exists) {
        Map<String, dynamic> doctorData =
            doctorDoc.data() as Map<String, dynamic>;
        return MedecinEntity(
          id: doctorId,
          name: doctorData['name'] ?? '',
          lastName: doctorData['lastName'] ?? '',
          email: doctorData['email'] ?? '',
          speciality: doctorData['speciality'],
          role: doctorData['role'] ?? 'doctor',
          gender: doctorData['gender'] ?? 'unknown',
          phoneNumber: doctorData['phoneNumber'] ?? '',
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching doctor info: $e');
      return null;
    }
  }

  void _navigateToDoctorProfile(
    String? doctorId,
    String doctorName,
    String? speciality,
  ) async {
    if (doctorId == null) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor),
          ),
    );

    // Try to fetch doctor from Firestore
    MedecinEntity? doctorEntity = await _fetchDoctorInfo(doctorId);

    // Dismiss loading indicator
    Navigator.pop(context);

    // If fetch failed, create a basic doctor entity with available info
    if (doctorEntity == null) {
      final nameArray = doctorName.split(' ');
      final firstName = nameArray.isNotEmpty ? nameArray[0] : '';
      final lastName = nameArray.length > 1 ? nameArray[1] : '';

      doctorEntity = MedecinEntity(
        id: doctorId,
        name: firstName,
        lastName: lastName,
        email: "docteur@medical-app.com",
        speciality: speciality,
        role: 'doctor',
        gender: 'unknown',
        phoneNumber: "+212 600000000",
      );
    }

    // Now doctorEntity is guaranteed to be non-null
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => doctor_profile_page.DoctorProfilePage(
              doctor: doctorEntity!,
              canBookAppointment: false,
            ),
      ),
    );
  }

  // Fonction pour ajouter un nouveau rendez-vous (à implémenter)
  void _addAppointment() {
    if (currentUser == null || currentUser!.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('appointments.must_be_logged_in')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // For now, skip dossier medical check and go directly to specialties
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                AllSpecialtiesPage(specialties: getSpecialtiesWithImages(context)),
      ),
    );

    // Original code with DossierMedicalBloc (temporarily commented out)
    /*
    // Check if the patient has a medical dossier
    final dossierMedicalBloc = di.sl<DossierMedicalBloc>();

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    dossierMedicalBloc.add(
      CheckDossierMedicalExists(patientId: currentUser!.id!),
    );

    // Listen for the result
    dossierMedicalBloc.stream.listen((state) {
      // Close loading dialog
      if (state is DossierMedicalExists || state is DossierMedicalError) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (state is DossierMedicalExists) {
        if (state.exists) {
          // Patient has a dossier, proceed to specialties page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      AllSpecialtiesPage(specialties: getSpecialtiesWithImages(context)),
            ),
          );
        } else {
          // Show warning about missing medical dossier
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: Text(context.tr('appointments.medical_record_required')),
                  content: Text(
                    context.tr('appointments.create_medical_record_first'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(context.tr('common.cancel')),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Navigate to dossier medical screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => DossierMedicalScreen(
                                  patientId: currentUser!.id!,
                                ),
                          ),
                        );
                      },
                      child: Text(context.tr('appointments.create_my_record')),
                    ),
                  ],
                ),
          );
        }
      } else if (state is DossierMedicalError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de la vérification du dossier médical: ${state.message}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
    */
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      'Building AppointmentsPatients, filtered appointments: ${filteredAppointments.length}',
    );

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _addAppointment,
        backgroundColor: const Color(0xFFFF3B3B),
        child: const Icon(Icons.add, color: Colors.white, size: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBar:
          widget.showAppBar
              ? AppBar(
                title: Text(
                  context.tr("my_appointments"),
                  style: GoogleFonts.poppins(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: AppColors.primaryColor,
                elevation: 2,
                actions: [
                  IconButton(
                    icon: Icon(Icons.calendar_today, color: Colors.white),
                    tooltip: context.tr("filter_by_date"),
                    onPressed: _toggleCalendar,
                  ),
                  IconButton(
                    icon: Icon(Icons.add, color: Colors.white),
                    tooltip: context.tr("add_appointment"),
                    onPressed: _addAppointment,
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh, color: Colors.white),
                    tooltip: context.tr("refresh"),
                    onPressed: () {
                      if (currentUser != null && currentUser!.id != null) {
                        _rendezVousBloc.add(
                          FetchRendezVous(patientId: currentUser!.id),
                        );
                      }
                    },
                  ),
                ],
              )
              : null,
      body: BlocProvider.value(
        value: _rendezVousBloc,
        child: BlocListener<RendezVousBloc, RendezVousState>(
          listener: (context, state) {
            debugPrint(
              'AppointmentsPatients: BlocListener received state: ${state.runtimeType}',
            );

            if (state is RendezVousLoaded) {
              debugPrint(
                'AppointmentsPatients: RendezVousLoaded state with ${state.rendezVous.length} appointments',
              );

              // Debug each appointment
              for (var appt in state.rendezVous) {
                debugPrint(
                  'Appointment: id=${appt.id}, status=${appt.status}, doctor=${appt.medecinName}, time=${appt.startDate}',
                );
              }

              setState(() {
                appointments = state.rendezVous;
                filteredAppointments =
                    state
                        .rendezVous; // Initialize filtered list with all appointments
                isLoading = false;

                // Apply date filter if a date is selected
                if (_selectedDay != null) {
                  _filterAppointmentsByDate(_selectedDay);
                }
              });
            } else if (state is RendezVousError) {
              debugPrint(
                'AppointmentsPatients: RendezVousError state: ${state.message}',
              );
              setState(() {
                isLoading = false;
                cancellingAppointmentId = null; // Reset on error
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message, style: GoogleFonts.raleway()),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            } else if (state is RendezVousLoading) {
              debugPrint('AppointmentsPatients: RendezVousLoading state');
              setState(() {
                isLoading = true;
              });
            } else if (state is RendezVousStatusUpdatedState) {
              debugPrint(
                'AppointmentsPatients: RendezVousStatusUpdatedState state for appointment ${state.id} with status ${state.status}',
              );
              setState(() {
                cancellingAppointmentId =
                    null; // Reset after successful status update

                // Update the appointment status in the local list if needed
                final index = appointments.indexWhere(
                  (appt) => appt.id == state.id,
                );
                if (index != -1) {
                  // Update the appointment in the list with the new status
                  final updatedAppointment = RendezVousEntity(
                    id: appointments[index].id,
                    startDate: appointments[index].startDate,
                    endDate: appointments[index].endDate,
                    serviceName: appointments[index].serviceName,
                    patient: appointments[index].patient,
                    medecin: appointments[index].medecin,
                    patientName: appointments[index].patientName,
                    medecinName: appointments[index].medecinName,
                    medecinSpeciality: appointments[index].medecinSpeciality,
                    status: state.status,
                  );
                  appointments[index] = updatedAppointment;

                  // Apply filters to update the UI
                  _filterAppointmentsByDate(_selectedDay);
                }
              });

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.status == "cancelled"
                        ? context.tr("appointment_cancelled")
                        : context.tr("appointment_status_updated"),
                    style: GoogleFonts.raleway(),
                  ),
                  backgroundColor: AppColors.primaryColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
          },
          child: SafeArea(
            child:
                isLoading
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: AppColors.primaryColor,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            context.tr("loading_appointments"),
                            style: GoogleFonts.raleway(
                              fontSize: 16.sp,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    )
                    : Column(
                      children: [
                        // Slide down calendar
                        AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          height: _isCalendarVisible ? 350.h : 0,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            boxShadow:
                                _isCalendarVisible
                                    ? [
                                      BoxShadow(
                                        color: Colors.black,
                                        spreadRadius: 2,
                                        blurRadius: 8,
                                        offset: Offset(0, 6),
                                      ),
                                    ]
                                    : [],
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isCalendarVisible)
                                  Container(
                                    margin: EdgeInsets.all(8.h),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 12.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          spreadRadius: 2,
                                          blurRadius: 8,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        // Calendar header
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 8.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border(
                                              bottom: BorderSide(
                                                color: Colors.grey.shade200,
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                context.tr("select_date"),
                                                style: GoogleFonts.raleway(
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primaryColor,
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  if (_selectedDay != null)
                                                    TextButton(
                                                      onPressed: () {
                                                        setState(() {
                                                          _selectedDay = null;
                                                          _isCalendarVisible =
                                                              false;
                                                        });
                                                        _filterAppointmentsByDate(
                                                          null,
                                                        );
                                                      },
                                                      child: Text(
                                                        context.tr("clear"),
                                                        style:
                                                            GoogleFonts.raleway(
                                                              color: Colors.red,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                      ),
                                                    ),
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.close,
                                                      color:
                                                          Colors.grey.shade700,
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        _isCalendarVisible =
                                                            false;
                                                      });
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Table Calendar
                                        TableCalendar(
                                          firstDay: DateTime.now().subtract(
                                            Duration(days: 365),
                                          ),
                                          lastDay: DateTime.now().add(
                                            Duration(days: 365),
                                          ),
                                          focusedDay:
                                              _selectedDay ?? _focusedDay,
                                          calendarFormat: _calendarFormat,
                                          onFormatChanged: (format) {
                                            setState(() {
                                              _calendarFormat = format;
                                            });
                                          },
                                          selectedDayPredicate: (day) {
                                            return _selectedDay != null &&
                                                isSameDay(_selectedDay!, day);
                                          },
                                          onDaySelected: (
                                            selectedDay,
                                            focusedDay,
                                          ) {
                                            setState(() {
                                              _selectedDay = selectedDay;
                                              _focusedDay = focusedDay;
                                              _isCalendarVisible = false;
                                            });
                                            _filterAppointmentsByDate(
                                              _selectedDay,
                                            );
                                          },
                                          // Custom marker builder to show appointment count
                                          calendarBuilders: CalendarBuilders(
                                            markerBuilder: (
                                              context,
                                              date,
                                              events,
                                            ) {
                                              // Count appointments on this day
                                              final appointmentsOnDay =
                                                  appointments.where((
                                                    appointment,
                                                  ) {
                                                    return isSameDay(
                                                      appointment.startDate,
                                                      date,
                                                    );
                                                  }).toList();

                                              if (appointmentsOnDay.isEmpty) {
                                                return null;
                                              }

                                              return Positioned(
                                                bottom: 1,
                                                right: 1,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color:
                                                        AppColors.primaryColor,
                                                  ),
                                                  width: 16.w,
                                                  height: 16.h,
                                                  child: Center(
                                                    child: Text(
                                                      '${appointmentsOnDay.length}',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10.sp,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          calendarStyle: CalendarStyle(
                                            todayDecoration: BoxDecoration(
                                              color: AppColors.primaryColor
                                                  .withOpacity(0.5),
                                              shape: BoxShape.circle,
                                            ),
                                            selectedDecoration: BoxDecoration(
                                              color: AppColors.primaryColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          headerStyle: HeaderStyle(
                                            formatButtonTextStyle:
                                                GoogleFonts.raleway(
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.primaryColor,
                                                ),
                                            titleTextStyle: GoogleFonts.raleway(
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                            leftChevronIcon: Icon(
                                              Icons.chevron_left,
                                              color: AppColors.primaryColor,
                                            ),
                                            rightChevronIcon: Icon(
                                              Icons.chevron_right,
                                              color: AppColors.primaryColor,
                                            ),
                                            formatButtonVisible: true,
                                            titleCentered: true,
                                          ),
                                          availableCalendarFormats: {
                                            CalendarFormat.month: context.tr("month"),
                                            CalendarFormat.twoWeeks:
                                                context.tr("two_weeks"),
                                            CalendarFormat.week: context.tr("week"),
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // Dark overlay behind calendar when visible
                        if (_isCalendarVisible)
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isCalendarVisible = false;
                                });
                              },
                              child: Container(
                                color: Colors.black.withOpacity(0.7),
                              ),
                            ),
                          ),

                        // Date filter indicator and clear button
                        if (_selectedDay != null)
                          Container(
                            color: Colors.grey[50],
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 12.h,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.filter_list,
                                  color: AppColors.primaryColor,
                                  size: 20.sp,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  context.tr("filtered_by_date").replaceAll(
                                    "{0}",
                                    DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(_selectedDay!),
                                  ),
                                  style: GoogleFonts.raleway(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                Spacer(),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedDay = null;
                                    });
                                    _filterAppointmentsByDate(null);
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.close,
                                        size: 18.sp,
                                        color: AppColors.primaryColor,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        context.tr("clear"),
                                        style: GoogleFonts.raleway(
                                          fontSize: 14.sp,
                                          color: AppColors.primaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Display filteredAppointments instead of appointments
                        Expanded(
                          child:
                              filteredAppointments.isEmpty
                                  ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 64.sp,
                                          color: Colors.grey.withOpacity(0.5),
                                        ),
                                        SizedBox(height: 24.h),
                                        Text(
                                          _selectedDay != null
                                              ? context.tr("no_appointments_for_date")
                                                  .replaceAll(
                                                    "{0}",
                                                    DateFormat(
                                                      'dd/MM/yyyy',
                                                    ).format(_selectedDay!),
                                                  )
                                              : context.tr("no_appointments_found"),
                                          style: GoogleFonts.raleway(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[700],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: 8.h),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 32.w,
                                          ),
                                          child: Text(
                                            context.tr("tap_to_add_appointment"),
                                            style: GoogleFonts.raleway(
                                              fontSize: 14.sp,
                                              color: Colors.grey[600],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        SizedBox(height: 24.h),
                                        ElevatedButton.icon(
                                          onPressed: _addAppointment,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppColors.primaryColor,
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 20.w,
                                              vertical: 12.h,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          icon: Icon(Icons.add, size: 20.sp),
                                          label: Text(
                                            context.tr("add_appointment"),
                                            style: GoogleFonts.raleway(
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  : RefreshIndicator(
                                    onRefresh: () async {
                                      if (currentUser != null &&
                                          currentUser!.id != null) {
                                        _rendezVousBloc.add(
                                          FetchRendezVous(
                                            patientId: currentUser!.id,
                                          ),
                                        );
                                      }
                                    },
                                    color: AppColors.primaryColor,
                                    child: ListView.builder(
                                      padding: EdgeInsets.all(16.w),
                                      itemCount: filteredAppointments.length,
                                      itemBuilder: (context, index) {
                                        final appointment =
                                            filteredAppointments[index];
                                        final formattedDate = DateFormat(
                                          'dd/MM/yyyy',
                                        ).format(appointment.startDate);
                                        final formattedTime = DateFormat(
                                          'HH:mm',
                                        ).format(appointment.startDate);

                                        // Check if this appointment is currently being cancelled
                                        final isCancelling =
                                            appointment.id != null &&
                                            cancellingAppointmentId ==
                                                appointment.id;

                                        return Card(
                                          margin: EdgeInsets.only(bottom: 16.h),
                                          elevation: 2,
                                          color: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: EdgeInsets.all(16.w),
                                            child: Column(
                                              children: [
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      height: 40.h,
                                                      width: 40.w,
                                                      decoration: BoxDecoration(
                                                        color:
                                                            AppColors
                                                                .primaryColor,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: InkWell(
                                                        onTap:
                                                            () => _navigateToDoctorProfile(
                                                              appointment
                                                                  .medecin,
                                                              appointment
                                                                      .medecinName ??
                                                                  "Médecin",
                                                              appointment
                                                                  .medecinSpeciality,
                                                            ),
                                                        child: Icon(
                                                          Icons.person,
                                                          color: Colors.white,
                                                          size: 24.sp,
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 12.w),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          InkWell(
                                                            onTap:
                                                                () => _navigateToDoctorProfile(
                                                                  appointment
                                                                      .medecin,
                                                                  appointment
                                                                          .medecinName ??
                                                                      "Médecin",
                                                                  appointment
                                                                      .medecinSpeciality,
                                                                ),
                                                            child: Text(
                                                              appointment.medecinName !=
                                                                      null
                                                                  ? "Dr. ${appointment.medecinName?.split(" ").last ?? ''}"
                                                                  : context.tr("doctor_to_assign"),
                                                              style: GoogleFonts.raleway(
                                                                fontSize: 15.sp,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color:
                                                                    Colors
                                                                        .black87,
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(height: 4.h),
                                                          Text(
                                                            appointment
                                                                    .medecinSpeciality ??
                                                                '',
                                                            style: GoogleFonts.raleway(
                                                              fontSize: 13.sp,
                                                              color:
                                                                  Colors
                                                                      .grey
                                                                      .shade600,
                                                            ),
                                                          ),
                                                          SizedBox(height: 4.h),
                                                          Container(
                                                            padding:
                                                                EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      8.w,
                                                                  vertical: 4.h,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  _getStatusColor(
                                                                    appointment
                                                                        .status,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    12,
                                                                  ),
                                                            ),
                                                            child: Text(
                                                              _getStatusText(
                                                                appointment
                                                                    .status,
                                                              ),
                                                              style: GoogleFonts.raleway(
                                                                fontSize: 12.sp,
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .end,
                                                      children: [
                                                        Text(
                                                          formattedDate,
                                                          style:
                                                              GoogleFonts.raleway(
                                                                fontSize: 13.sp,
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                        ),
                                                        SizedBox(height: 4.h),
                                                        Text(
                                                          formattedTime,
                                                          style:
                                                              GoogleFonts.raleway(
                                                                fontSize: 13.sp,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color:
                                                                    Colors
                                                                        .grey
                                                                        .shade700,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 16.h),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    TextButton.icon(
                                                      onPressed:
                                                          () =>
                                                              _navigateToAppointmentDetails(
                                                                appointment,
                                                              ),
                                                      icon: Icon(
                                                        Icons
                                                            .calendar_today_outlined,
                                                        color:
                                                            AppColors
                                                                .primaryColor,
                                                        size: 16.sp,
                                                      ),
                                                      label: Text(
                                                        context.tr("view_details"),
                                                        style: GoogleFonts.raleway(
                                                          color:
                                                              AppColors
                                                                  .primaryColor,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 14.sp,
                                                        ),
                                                      ),
                                                      style: TextButton.styleFrom(
                                                        minimumSize: Size.zero,
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 12.w,
                                                              vertical: 6.h,
                                                            ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 8.w),
                                                    if (appointment.status !=
                                                        "cancelled")
                                                      appointment.id != null &&
                                                              isCancelling
                                                          ? Container(
                                                            padding:
                                                                EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      12.w,
                                                                  vertical: 6.h,
                                                                ),
                                                            child: SizedBox(
                                                              height: 16.sp,
                                                              width: 16.sp,
                                                              child:
                                                                  CircularProgressIndicator(
                                                                    color:
                                                                        Colors
                                                                            .red,
                                                                    strokeWidth:
                                                                        2.w,
                                                                  ),
                                                            ),
                                                          )
                                                          : TextButton.icon(
                                                            onPressed:
                                                                () => _cancelAppointment(
                                                                  appointment,
                                                                ),
                                                            icon: Icon(
                                                              Icons
                                                                  .cancel_outlined,
                                                              color: Colors.red,
                                                              size: 16.sp,
                                                            ),
                                                            label: Text(
                                                              context.tr("cancel_appointment"),
                                                              style: GoogleFonts.raleway(
                                                                color:
                                                                    Colors.red,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                fontSize: 14.sp,
                                                              ),
                                                            ),
                                                            style: TextButton.styleFrom(
                                                              minimumSize:
                                                                  Size.zero,
                                                              padding:
                                                                  EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        12.w,
                                                                    vertical:
                                                                        6.h,
                                                                  ),
                                                            ),
                                                          ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                        ),
                      ],
                    ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "accepted":
        return Colors.green;
      case "pending":
        return Colors.orange;
      case "cancelled":
        return Colors.red;
      case "completed":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case "accepted":
        return context.tr("status_confirmed");
      case "pending":
        return context.tr("status_pending");
      case "cancelled":
        return context.tr("status_cancelled");
      case "completed":
        return context.tr("status_completed");
      default:
        return context.tr("status_unknown");
    }
  }

  @override
  void dispose() {
    // Don't close bloc here as it might be used elsewhere and is being provided by dependency injection
    super.dispose();
  }
}
