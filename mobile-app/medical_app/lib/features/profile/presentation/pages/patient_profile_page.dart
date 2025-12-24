import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:medical_app/core/widgets/common/common_widgets.dart';
import 'package:medical_app/features/profile/presentation/widgets/profile_widgets.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../authentication/domain/entities/patient_entity.dart';
import '../../../rendez_vous/domain/entities/rendez_vous_entity.dart';

class PatientProfilePage extends StatefulWidget {
  final PatientEntity patient;
  final List<RendezVousEntity>? pastAppointments;

  const PatientProfilePage({
    Key? key,
    required this.patient,
    this.pastAppointments,
  }) : super(key: key);

  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
  bool _isLoading = true;
  List<RendezVousEntity> _pastAppointments = [];

  @override
  void initState() {
    super.initState();
    if (widget.pastAppointments != null) {
      setState(() {
        _pastAppointments = widget.pastAppointments!;
        _isLoading = false;
      });
    } else if (widget.patient.id != null) {
      _loadPatientAppointments();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPatientAppointments() async {
    // TODO: Implement using rdv-service API when endpoint is available
    // The backend would need an endpoint like:
    // GET /appointments/patient/:patientId/history (for doctors to view patient history)
    // For now, just set loading to false - appointments should be passed via widget.pastAppointments
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('profile.patient_profile'),
          style: GoogleFonts.raleway(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient header card with basic info
            _buildPatientHeaderCard(),

            // Medical History section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Text(
                context.tr('profile.antecedent'),
                style: GoogleFonts.raleway(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),

            _buildMedicalHistoryCard(),

            // Past Appointments
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
              child: Text(
                context.tr('profile.previous_consultations'),
                style: GoogleFonts.raleway(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),

            // Appointments list
            _isLoading
                ? Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    child: CircularProgressIndicator(
                      color: AppColors.primaryColor,
                    ),
                  ),
                )
                : _buildPastAppointmentsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientHeaderCard() {
    return Card(
      margin: EdgeInsets.all(16.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 70.h,
                  width: 70.w,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(Icons.person, color: Colors.white, size: 40.sp),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${widget.patient.name} ${widget.patient.lastName}",
                        style: GoogleFonts.raleway(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        widget.patient.dateOfBirth != null
                            ? "${_calculateAge(widget.patient.dateOfBirth!)} ans"
                            : "Âge non spécifié",
                        style: GoogleFonts.raleway(
                          fontSize: 16.sp,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Divider(height: 30.h, thickness: 1),

            // Contact info
            Row(
              children: [
                Icon(Icons.email_outlined, color: Colors.orange, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  widget.patient.email,
                  style: GoogleFonts.raleway(
                    fontSize: 14.sp,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(Icons.phone_outlined, color: Colors.orange, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  widget.patient.phoneNumber,
                  style: GoogleFonts.raleway(
                    fontSize: 14.sp,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: Colors.orange,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  widget.patient.dateOfBirth != null
                      ? DateFormat(
                        'dd/MM/yyyy',
                      ).format(widget.patient.dateOfBirth!)
                      : context.tr('profile.birth_date_not_specified'),
                  style: GoogleFonts.raleway(
                    fontSize: 14.sp,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(Icons.person_outline, color: Colors.orange, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  widget.patient.gender,
                  style: GoogleFonts.raleway(
                    fontSize: 14.sp,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalHistoryCard() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.medical_information_outlined,
                  color: Colors.red,
                  size: 24.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    context.tr('profile.medical_information'),
                    style: GoogleFonts.raleway(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            Divider(height: 24.h),

            // Medical history
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.history, size: 18.sp, color: Colors.grey.shade600),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('profile.medical_history'),
                        style: GoogleFonts.raleway(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        (widget.patient.antecedent?.isNotEmpty ?? false)
                            ? widget.patient.antecedent!
                            : context.tr("no_medical_history"),
                        style: GoogleFonts.raleway(
                          fontSize: 14.sp,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 12.h),

            // Blood Type
            Row(
              children: [
                Icon(Icons.bloodtype, size: 18.sp, color: Colors.grey.shade600),
                SizedBox(width: 8.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr("blood_type"),
                      style: GoogleFonts.raleway(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      widget.patient.bloodType ?? context.tr("not_specified"),
                      style: GoogleFonts.raleway(
                        fontSize: 14.sp,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 12.h),

            // Height and Weight
            Row(
              children: [
                // Height
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.height,
                        size: 18.sp,
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(width: 8.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr("height"),
                            style: GoogleFonts.raleway(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            widget.patient.height != null
                                ? "${widget.patient.height} cm"
                                : context.tr("not_specified"),
                            style: GoogleFonts.raleway(
                              fontSize: 14.sp,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Weight
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.monitor_weight,
                        size: 18.sp,
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(width: 8.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr("weight"),
                            style: GoogleFonts.raleway(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            widget.patient.weight != null
                                ? "${widget.patient.weight} kg"
                                : context.tr("not_specified"),
                            style: GoogleFonts.raleway(
                              fontSize: 14.sp,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 12.h),

            // Allergies
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber,
                  size: 18.sp,
                  color: Colors.grey.shade600,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr("allergies"),
                        style: GoogleFonts.raleway(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      if (widget.patient.allergies != null &&
                          widget.patient.allergies!.isNotEmpty)
                        Wrap(
                          spacing: 6.w,
                          runSpacing: 6.h,
                          children:
                              widget.patient.allergies!
                                  .map(
                                    (allergy) => Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                        border: Border.all(
                                          color: Colors.red.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Text(
                                        allergy,
                                        style: GoogleFonts.raleway(
                                          fontSize: 12.sp,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        )
                      else
                        Text(
                          context.tr("not_specified"),
                          style: GoogleFonts.raleway(
                            fontSize: 14.sp,
                            color: Colors.grey.shade700,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 12.h),

            // Chronic Diseases
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.medical_services,
                  size: 18.sp,
                  color: Colors.grey.shade600,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr("chronic_diseases"),
                        style: GoogleFonts.raleway(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      if (widget.patient.chronicDiseases != null &&
                          widget.patient.chronicDiseases!.isNotEmpty)
                        Wrap(
                          spacing: 6.w,
                          runSpacing: 6.h,
                          children:
                              widget.patient.chronicDiseases!
                                  .map(
                                    (disease) => Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                        border: Border.all(
                                          color: Colors.orange.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Text(
                                        disease,
                                        style: GoogleFonts.raleway(
                                          fontSize: 12.sp,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        )
                      else
                        Text(
                          context.tr("not_specified"),
                          style: GoogleFonts.raleway(
                            fontSize: 14.sp,
                            color: Colors.grey.shade700,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // Emergency Contact
            if (widget.patient.emergencyContact != null &&
                (widget.patient.emergencyContact!['name'] != null ||
                    widget.patient.emergencyContact!['phoneNumber'] != null))
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16.h),
                  Divider(height: 8.h),
                  SizedBox(height: 8.h),

                  // Emergency Contact Title
                  Row(
                    children: [
                      Icon(Icons.emergency, size: 20.sp, color: Colors.red),
                      SizedBox(width: 8.w),
                      Text(
                        context.tr("emergency_contact"),
                        style: GoogleFonts.raleway(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12.h),

                  // Emergency Contact Details
                  if (widget.patient.emergencyContact!['name'] != null)
                    Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 18.sp,
                            color: Colors.grey.shade600,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            widget.patient.emergencyContact!['name']!,
                            style: GoogleFonts.raleway(
                              fontSize: 14.sp,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (widget.patient.emergencyContact!['relationship'] != null)
                    Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Row(
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 18.sp,
                            color: Colors.grey.shade600,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            widget.patient.emergencyContact!['relationship']!,
                            style: GoogleFonts.raleway(
                              fontSize: 14.sp,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (widget.patient.emergencyContact!['phoneNumber'] != null)
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 18.sp,
                          color: Colors.grey.shade600,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          widget.patient.emergencyContact!['phoneNumber']!,
                          style: GoogleFonts.raleway(
                            fontSize: 14.sp,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPastAppointmentsList() {
    if (_pastAppointments.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          child: Column(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 40.sp,
                color: Colors.grey.withOpacity(0.7),
              ),
              SizedBox(height: 16.h),
              Text(
                context.tr("no_previous_consultations"),
                style: GoogleFonts.raleway(fontSize: 16.sp, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(16.w),
      itemCount: _pastAppointments.length,
      itemBuilder: (context, index) {
        final appointment = _pastAppointments[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Dr. ${appointment.medecinName ?? context.tr('doctor_not_assigned')}",
                            style: GoogleFonts.raleway(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            appointment.medecinSpeciality ??
                                context.tr("specialty_not_specified"),
                            style: GoogleFonts.raleway(
                              fontSize: 14.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          appointment.status,
                        ).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        _getStatusText(appointment.status, context),
                        style: GoogleFonts.raleway(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(appointment.status),
                        ),
                      ),
                    ),
                  ],
                ),
                Divider(height: 24.h),
                Row(
                  children: [
                    Icon(Icons.event, size: 18.sp, color: Colors.grey.shade600),
                    SizedBox(width: 6.w),
                    Text(
                      DateFormat('dd/MM/yyyy').format(appointment.startDate),
                      style: GoogleFonts.raleway(
                        fontSize: 14.sp,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Icon(
                      Icons.access_time,
                      size: 18.sp,
                      color: Colors.grey.shade600,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      DateFormat('HH:mm').format(appointment.startDate),
                      style: GoogleFonts.raleway(
                        fontSize: 14.sp,
                        color: Colors.grey.shade700,
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

  int _calculateAge(DateTime birthDate) {
    final currentDate = DateTime.now();
    int age = currentDate.year - birthDate.year;
    final monthDiff = currentDate.month - birthDate.month;

    if (monthDiff < 0 || (monthDiff == 0 && currentDate.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "completed":
        return Colors.green;
      case "accepted":
        return Colors.blue;
      case "pending":
        return Colors.orange;
      case "cancelled":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status, BuildContext context) {
    switch (status) {
      case "completed":
        return context.tr("status_completed");
      case "accepted":
        return context.tr("status_confirmed");
      case "pending":
        return context.tr("status_pending");
      case "cancelled":
        return context.tr("status_cancelled");
      default:
        return context.tr("status_unknown");
    }
  }
}
