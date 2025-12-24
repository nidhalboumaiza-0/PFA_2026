import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/core/utils/custom_snack_bar.dart';
import 'package:medical_app/features/authentication/data/data%20sources/auth_local_data_source.dart';
import 'package:medical_app/features/authentication/domain/entities/medecin_entity.dart';
import 'package:medical_app/features/dossier_medical/domain/repositories/dossier_medical_repository.dart';
import 'package:medical_app/features/messagerie/presentation/blocs/online_status/online_status_cubit.dart';
import 'package:medical_app/features/messagerie/presentation/blocs/online_status/online_status_state.dart';
import 'package:medical_app/features/rendez_vous/domain/entities/rendez_vous_entity.dart';
import 'package:medical_app/features/rendez_vous/presentation/blocs/rendez-vous%20BLoC/rendez_vous_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../injection_container.dart' as di;
import '../../../../features/authentication/domain/entities/user_entity.dart';

class AvailableDoctorScreen extends StatefulWidget {
  final String specialty;
  final DateTime selectedDateTime;

  const AvailableDoctorScreen({
    super.key,
    required this.specialty,
    required this.selectedDateTime,
  });

  @override
  State<AvailableDoctorScreen> createState() => _AvailableDoctorScreenState();
}

class _AvailableDoctorScreenState extends State<AvailableDoctorScreen> {
  final TextEditingController _motifController = TextEditingController();
  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;
  UserEntity? currentUser;
  final AuthLocalDataSource _authLocalDataSource = di.sl<AuthLocalDataSource>();

  late RendezVousBloc _rendezVousBloc;

  @override
  void initState() {
    super.initState();
    _rendezVousBloc = di.sl<RendezVousBloc>();
    _loadUser();
    _rendezVousBloc.add(
      FetchDoctorsBySpecialty(
        widget.specialty,
        startDate: widget.selectedDateTime,
        endDate: widget.selectedDateTime.add(const Duration(minutes: 30)),
      ),
    );
  }

  Future<void> _loadUser() async {
    final user = await _authLocalDataSource.getUser();
    setState(() {
      currentUser = user;
    });
  }

  @override
  void dispose() {
    _motifController.dispose();
    _symptomsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _showAppointmentDetailsDialog(MedecinEntity doctor) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              context.tr('appointment_details'),
              style: GoogleFonts.raleway(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('motif'),
                    style: GoogleFonts.raleway(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: _motifController,
                    decoration: InputDecoration(
                      hintText: context.tr('motif_hint'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    maxLines: 2,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    context.tr('symptoms'),
                    style: GoogleFonts.raleway(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: _symptomsController,
                    decoration: InputDecoration(
                      hintText: context.tr('symptoms_hint'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    maxLines: 2,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    context.tr('notes'),
                    style: GoogleFonts.raleway(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      hintText: context.tr('notes_optional'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  context.tr('cancel'),
                  style: GoogleFonts.raleway(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                ),
                child: Text(
                  context.tr('continue'),
                  style: GoogleFonts.raleway(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (result == true) {
      _confirmAppointment(doctor);
    }
  }

  Future<void> _confirmAppointment(MedecinEntity doctor) async {
    // First check if the patient has a medical record
    if (currentUser != null) {
      setState(() {
        _isLoading = true;
      });

      // Get the repository directly
      final dossierMedicalRepository = di.sl<DossierMedicalRepository>();
      final result = await dossierMedicalRepository.hasDossierMedical(
        currentUser!.id!,
      );

      setState(() {
        _isLoading = false;
      });

      bool hasMedicalRecord = false;
      result.fold(
        (failure) {
          print('Failed to check medical record: ${failure.message}');
          hasMedicalRecord = false;
        },
        (exists) {
          print('Patient has medical record: $exists');
          hasMedicalRecord = exists;
        },
      );

      if (!hasMedicalRecord) {
        // Show dialog that they need to create a medical record first
        final bool goToMedicalRecord =
            await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder:
                  (context) => AlertDialog(
                    title: Text(
                      context.tr('dossier_medical_required'),
                      style: GoogleFonts.raleway(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
                      ),
                    ),
                    content: Text(
                      context.tr('dossier_medical_required_explanation'),
                      style: GoogleFonts.raleway(fontSize: 14.sp),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(
                          context.tr('cancel'),
                          style: GoogleFonts.raleway(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                        ),
                        child: Text(
                          context.tr('create_dossier_medical'),
                          style: GoogleFonts.raleway(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
            ) ??
            false;

        if (goToMedicalRecord) {
          // Navigate to medical record creation page
          Navigator.of(context).pushNamed('/dossier-medical');
        }

        return; // Don't proceed with appointment booking
      }

      // Patient has a medical record, continue with appointment booking
      print(
        'Proceeding with appointment booking for patient with medical record',
      );
    }

    final formattedDate = DateFormat(
      'dd/MM/yyyy à HH:mm',
    ).format(widget.selectedDateTime);

    // Calculate the end time based on doctor's appointment duration
    final int appointmentDuration = doctor.appointmentDuration;
    final DateTime endDateTime = widget.selectedDateTime.add(
      Duration(minutes: appointmentDuration),
    );
    final formattedEndTime = DateFormat('HH:mm').format(endDateTime);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              context.tr('confirm_appointment'),
              style: GoogleFonts.raleway(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('confirm_appointment_with')
                      .replaceAll(
                        '{0}',
                        'Dr. ${doctor.name} ${doctor.lastName}',
                      )
                  .replaceAll('{1}', formattedDate),
                  style: GoogleFonts.raleway(fontSize: 16.sp),
                ),
                SizedBox(height: 12.h),
                Text(
                  '${context.tr('appointment_duration')}: $appointmentDuration ${context.tr('minutes')}',
                  style: GoogleFonts.raleway(
                    fontSize: 14.sp,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  '${context.tr('end_time')}: $formattedEndTime',
              style: GoogleFonts.raleway(
                    fontSize: 14.sp,
                    color: Colors.grey[700],
              ),
            ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  context.tr('cancel'),
                  style: GoogleFonts.raleway(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                ),
                child: Text(
                  context.tr('confirm'),
                  style: GoogleFonts.raleway(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true && currentUser != null) {
      // Create symptoms list from comma-separated string
      List<String>? symptoms;
      if (_symptomsController.text.isNotEmpty) {
        symptoms =
            _symptomsController.text.split(',').map((s) => s.trim()).toList();
      }

      // Calculate end date based on doctor's appointment duration setting
      // Instead of fixed 30 minutes, use the doctor's appointment duration from their profile
      final endDate = widget.selectedDateTime.add(
        Duration(minutes: appointmentDuration),
      );

      // Create the appointment entity
      final appointmentEntity = RendezVousEntity(
        startDate: widget.selectedDateTime,
        endDate: endDate,
        serviceName: widget.specialty,
        patient: currentUser!.id ?? '',
        medecin: doctor.id ?? '',
        status: 'En attente',
        motif: _motifController.text.isNotEmpty ? _motifController.text : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        symptoms: symptoms,
        // UI display fields
        patientName: '${currentUser!.name} ${currentUser!.lastName}',
        medecinName: '${doctor.name} ${doctor.lastName}',
        medecinSpeciality: doctor.speciality,
      );

      // Show loading dialog
      setState(() => _isLoading = true);

      // Create the appointment
      _rendezVousBloc.add(CreateRendezVous(appointmentEntity));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('available_doctors'),
          style: GoogleFonts.raleway(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocConsumer<RendezVousBloc, RendezVousState>(
        bloc: _rendezVousBloc,
              listener: (context, state) {
          if (state is RendezVousCreated) {
            setState(() => _isLoading = false);
            showSuccessSnackBar(context, context.tr('appointment_created_successfully'));
            // Close all screens and return to previous menu
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else if (state is RendezVousError) {
                    setState(() => _isLoading = false);
                  showErrorSnackBar(context, state.message);
                }
              },
              builder: (context, state) {
          if (state is RendezVousLoading || _isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor),
                  );
                } else if (state is DoctorsLoaded) {
                  final doctors = state.doctors;
                  if (doctors.isEmpty) {
                    return Center(
                        child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                    Icon(Icons.search_off, size: 64.sp, color: Colors.grey),
                            SizedBox(height: 16.h),
                            Text(
                      context.tr('no_doctors_available'),
                      style: GoogleFonts.raleway(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                      ),
                              textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      context.tr('try_another_date_or_specialty'),
                              style: GoogleFonts.raleway(
                        fontSize: 14.sp,
                        color: Colors.grey,
                              ),
                      textAlign: TextAlign.center,
                            ),
                          ],
                      ),
                    );
                  }
                  return ListView.builder(
              padding: EdgeInsets.all(16.w),
                    itemCount: doctors.length,
                    itemBuilder: (context, index) {
                      final doctor = doctors[index];
                      return _buildDoctorCard(doctor);
                    },
                  );
          } else if (state is RendezVousError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
                  SizedBox(height: 16.h),
                  Text(
                    state.message,
                    style: GoogleFonts.raleway(fontSize: 16.sp),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return Center(
            child: Text(
              context.tr('select_specialty_and_date'),
              style: GoogleFonts.raleway(fontSize: 16.sp),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDoctorCard(MedecinEntity doctor) {
    // Format doctor's name properly
    String formatDoctorName() {
      final name = doctor.name ?? '';
      final lastName = doctor.lastName ?? '';

      if (name.isEmpty && lastName.isEmpty) {
        return "Dr. Unknown";
      }
      return "Dr. $name $lastName".trim();
    }

    return BlocBuilder<OnlineStatusCubit, OnlineStatusState>(
      builder: (context, onlineState) {
        final doctorId = doctor.id ?? '';
        final isOnline = onlineState.isUserOnline(doctorId);
        
        return Card(
          margin: EdgeInsets.only(bottom: 16.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Doctor avatar with online indicator
                    Stack(
                      children: [
                        Container(
                          height: 64.h,
                          width: 64.w,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(Icons.person, color: Colors.white, size: 32.sp),
                        ),
                        // Online indicator
                        if (isOnline)
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              width: 14.w,
                              height: 14.h,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  formatDoctorName(),
                                  style: GoogleFonts.raleway(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              // Online badge text
                              if (isOnline)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6.w,
                                        height: 6.h,
                                        decoration: const BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        context.tr('online') ?? 'Online',
                                        style: GoogleFonts.raleway(
                                          fontSize: 10.sp,
                                          color: Colors.green,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                      SizedBox(height: 4.h),
                      Text(
                        doctor.speciality ?? "",
                        style: GoogleFonts.raleway(
                          fontSize: 14.sp,
                          color: Colors.grey,
                        ),
                      ),
                      if (doctor.experience != null &&
                          doctor.experience!.isNotEmpty) ...[
                        SizedBox(height: 4.h),
                        Text(
                          context.tr('experience'),
                          style: GoogleFonts.raleway(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 2.h),
                        ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: doctor.experience!.length,
                          itemBuilder: (context, index) {
                            final expItem = doctor.experience![index];
                            final position =
                                expItem.containsKey('position')
                                    ? expItem['position'].toString()
                                    : '';
                            final organization =
                                expItem.containsKey('organization')
                                    ? expItem['organization'].toString()
                                    : '';
                            final years =
                                expItem.containsKey('years')
                                    ? expItem['years'].toString()
                                    : '';

                            final List<String> parts = [];
                            if (position.isNotEmpty) parts.add(position);
                            if (organization.isNotEmpty)
                              parts.add(organization);
                            if (years.isNotEmpty) parts.add(years);

                            return Padding(
                              padding: EdgeInsets.only(bottom: 2.h),
                              child: Text(
                                parts.join(' - '),
                                style: GoogleFonts.raleway(
                                  fontSize: 13.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                      // Display appointment duration info
                      SizedBox(height: 6.h),
                      Row(
                            children: [
                              Icon(
                            Icons.timer_outlined,
                                size: 16.sp,
                            color: AppColors.primaryColor,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                            '${context.tr('appointments.consultation_duration')}: ${doctor.appointmentDuration} min',
                                style: GoogleFonts.raleway(
                              fontSize: 13.sp,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
            if (doctor.education != null && doctor.education!.isNotEmpty) ...[
              Text(
                context.tr('education'),
                style: GoogleFonts.raleway(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4.h),
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: doctor.education!.length,
                itemBuilder: (context, index) {
                  final eduItem = doctor.education![index];
                  String displayText = '';

                  // Extract values safely
                  final hasDegree = eduItem.containsKey('degree');
                  final hasInstitution = eduItem.containsKey('institution');

                  if (hasDegree && hasInstitution) {
                    final degree = eduItem['degree'].toString();
                    final institution = eduItem['institution'].toString();
                    displayText = '$degree - $institution';
                  } else if (hasDegree) {
                    displayText = eduItem['degree'].toString();
                  } else if (hasInstitution) {
                    displayText = eduItem['institution'].toString();
                  }

                  if (displayText.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Text(
                      displayText,
                      style: GoogleFonts.raleway(fontSize: 14.sp),
                    ),
                  );
                },
              ),
              SizedBox(height: 16.h),
            ],
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showAppointmentDetailsDialog(doctor),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      context.tr('book_appointment'),
                        style: GoogleFonts.raleway(
                        color: Colors.white,
                          fontWeight: FontWeight.w600,
                      ),
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
  );
  }
}
