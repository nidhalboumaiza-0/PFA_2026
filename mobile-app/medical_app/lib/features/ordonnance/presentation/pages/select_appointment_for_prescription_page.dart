import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/features/authentication/data/models/user_model.dart';
import 'package:medical_app/features/rendez_vous/domain/entities/rendez_vous_entity.dart';
import 'package:medical_app/features/rendez_vous/presentation/blocs/rendez-vous BLoC/rendez_vous_bloc.dart';
import 'create_prescription_page.dart';

class SelectAppointmentForPrescriptionPage extends StatefulWidget {
  const SelectAppointmentForPrescriptionPage({super.key});

  @override
  State<SelectAppointmentForPrescriptionPage> createState() =>
      _SelectAppointmentForPrescriptionPageState();
}

class _SelectAppointmentForPrescriptionPageState
    extends State<SelectAppointmentForPrescriptionPage> {
  late RendezVousBloc _rendezVousBloc;
  UserModel? currentUser;
  bool isLoading = true;
  List<RendezVousEntity> eligibleAppointments = [];
  String selectedFilter = 'completed';

  @override
  void initState() {
    super.initState();
    _rendezVousBloc = BlocProvider.of<RendezVousBloc>(context);
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('CACHED_USER');

    if (userJson != null) {
      try {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        setState(() {
          currentUser = UserModel.fromJson(userMap);
          isLoading = false;
        });

        if (currentUser?.id != null) {
          // First check and update past appointments to ensure they're marked as completed
          _rendezVousBloc.add(
            CheckAndUpdatePastAppointments(
              userId: currentUser!.id!,
              userRole: 'doctor',
            ),
          );

          // Then fetch appointments
          _rendezVousBloc.add(FetchRendezVous(doctorId: currentUser!.id));
        }
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        debugPrint('Error loading user: $e');
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'accepted':
        return 'Accepté';
      case 'pending':
        return 'En attente';
      case 'cancelled':
        return 'Annulé';
      case 'completed':
        return 'Terminé';
      default:
        return 'Inconnu';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  bool _isAppointmentPast(RendezVousEntity appointment) {
    DateTime appointmentEndTime = appointment.endDate;
    return DateTime.now().isAfter(appointmentEndTime);
  }

  bool _isEligibleForPrescription(RendezVousEntity appointment) {
    return appointment.status == 'completed' ||
        (appointment.status == 'accepted' && _isAppointmentPast(appointment));
  }

  void _navigateToCreatePrescription(RendezVousEntity appointment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePrescriptionPage(appointment: appointment),
      ),
    ).then((_) {
      // Refresh appointments when returning
      if (currentUser?.id != null) {
        _rendezVousBloc.add(FetchRendezVous(doctorId: currentUser!.id));
      }
    });
  }

  List<RendezVousEntity> _filterAppointments(
    List<RendezVousEntity> appointments,
  ) {
    // First filter to only eligible appointments
    var filtered = appointments.where(_isEligibleForPrescription).toList();

    // Then apply additional status filter if needed
    if (selectedFilter == 'completed') {
      return filtered.where((a) => a.status == 'completed').toList();
    } else if (selectedFilter == 'accepted') {
      return filtered
          .where((a) => a.status == 'accepted' && _isAppointmentPast(a))
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('appointments.select_appointment'),
          style: GoogleFonts.raleway(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : BlocConsumer<RendezVousBloc, RendezVousState>(
                listener: (context, state) {
                  if (state is RendezVousLoaded) {
                    setState(() {
                      eligibleAppointments = _filterAppointments(
                        state.rendezVous,
                      );
                    });
                  }
                },
                builder: (context, state) {
                  if (state is RendezVousLoading) {
                    return Center(child: CircularProgressIndicator());
                  } else if (state is RendezVousError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 60.sp,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            '${context.tr('common.error')}: ${state.message}',
                            style: GoogleFonts.raleway(fontSize: 16.sp),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 24.h),
                          ElevatedButton.icon(
                            onPressed: () {
                              if (currentUser?.id != null) {
                                _rendezVousBloc.add(
                                  FetchRendezVous(doctorId: currentUser!.id),
                                );
                              }
                            },
                            icon: Icon(Icons.refresh),
                            label: Text(
                              'Réessayer',
                              style: GoogleFonts.raleway(),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 8.h,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (eligibleAppointments.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            color: Colors.grey,
                            size: 60.sp,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            context.tr('appointments.no_eligible_appointments'),
                            style: GoogleFonts.raleway(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            context.tr('appointments.no_completed_or_past_appointments_found'),
                            style: GoogleFonts.raleway(
                              fontSize: 14.sp,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                context.tr('medical_records.filter_by'),
                                style: GoogleFonts.raleway(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            FilterChip(
                              label: Text(context.tr('appointments.status_completed')),
                              selected: selectedFilter == 'completed',
                              onSelected: (selected) {
                                setState(() {
                                  selectedFilter = 'completed';
                                  if (state is RendezVousLoaded) {
                                    eligibleAppointments = _filterAppointments(
                                      state.rendezVous,
                                    );
                                  }
                                });
                              },
                              selectedColor: AppColors.primaryColor.withValues(
                                alpha: 0.2,
                              ),
                              checkmarkColor: AppColors.primaryColor,
                            ),
                            SizedBox(width: 8.w),
                            FilterChip(
                              label: Text(context.tr('medical_records.past')),
                              selected: selectedFilter == 'accepted',
                              onSelected: (selected) {
                                setState(() {
                                  selectedFilter = 'accepted';
                                  if (state is RendezVousLoaded) {
                                    eligibleAppointments = _filterAppointments(
                                      state.rendezVous,
                                    );
                                  }
                                });
                              },
                              selectedColor: AppColors.primaryColor.withValues(
                                alpha: 0.2,
                              ),
                              checkmarkColor: AppColors.primaryColor,
                            ),
                            SizedBox(width: 8.w),
                            FilterChip(
                              label: Text(context.tr('common.all')),
                              selected: selectedFilter == 'all',
                              onSelected: (selected) {
                                setState(() {
                                  selectedFilter = 'all';
                                  if (state is RendezVousLoaded) {
                                    eligibleAppointments = _filterAppointments(
                                      state.rendezVous,
                                    );
                                  }
                                });
                              },
                              selectedColor: AppColors.primaryColor.withValues(
                                alpha: 0.2,
                              ),
                              checkmarkColor: AppColors.primaryColor,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.all(16.w),
                          itemCount: eligibleAppointments.length,
                          itemBuilder: (context, index) {
                            final appointment = eligibleAppointments[index];
                            return _buildAppointmentCard(appointment);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
    );
  }

  Widget _buildAppointmentCard(RendezVousEntity appointment) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: InkWell(
        onTap: () => _navigateToCreatePrescription(appointment),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat(
                      'dd/MM/yyyy à HH:mm',
                    ).format(appointment.startDate),
                    style: GoogleFonts.raleway(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(appointment.status),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      _getStatusText(appointment.status),
                      style: GoogleFonts.raleway(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Icon(Icons.person, size: 20.sp, color: Colors.grey[600]),
                  SizedBox(width: 8.w),
                  Text(
                    '${context.tr('appointments.patient')}: ${appointment.patientName ?? context.tr('common.unknown')}',
                    style: GoogleFonts.raleway(
                      fontSize: 14.sp,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    size: 20.sp,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    appointment.medecinSpeciality ?? 'Consultation générale',
                    style: GoogleFonts.raleway(
                      fontSize: 14.sp,
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _navigateToCreatePrescription(appointment),
                    icon: Icon(
                      Icons.medical_services,
                      size: 18.sp,
                      color: Colors.white,
                    ),
                    label: Text(
                      context.tr('prescription.create_prescription'),
                      style: GoogleFonts.raleway(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
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
}
