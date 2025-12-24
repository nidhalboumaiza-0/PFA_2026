import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:medical_app/core/l10n/translator.dart';

import '../../../../core/utils/app_colors.dart';
import '../../domain/entities/prescription_entity.dart';
import '../bloc/prescription_bloc.dart';
import 'prescription_details_page.dart';

class PrescriptionsListPage extends StatefulWidget {
  final bool isDoctor;
  final String userId;
  final String userName;

  const PrescriptionsListPage({
    super.key,
    required this.isDoctor,
    required this.userId,
    required this.userName,
  });

  @override
  State<PrescriptionsListPage> createState() => _PrescriptionsListPageState();
}

class _PrescriptionsListPageState extends State<PrescriptionsListPage> {
  late PrescriptionBloc _prescriptionBloc;

  @override
  void initState() {
    super.initState();
    _prescriptionBloc = BlocProvider.of<PrescriptionBloc>(context);
    _loadPrescriptions();
  }

  void _loadPrescriptions() {
    if (widget.isDoctor) {
      _prescriptionBloc.add(GetDoctorPrescriptions(doctorId: widget.userId));
    } else {
      _prescriptionBloc.add(GetPatientPrescriptions(patientId: widget.userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.isDoctor ? 'Mes Ordonnances' : 'Mes Ordonnances',
          style: GoogleFonts.raleway(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
      ),
      body: BlocBuilder<PrescriptionBloc, PrescriptionState>(
        builder: (context, state) {
          if (state is PrescriptionLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor),
            );
          } else if (state is DoctorPrescriptionsLoaded && widget.isDoctor) {
            return _buildPrescriptionsList(state.prescriptions);
          } else if (state is PatientPrescriptionsLoaded && !widget.isDoctor) {
            return _buildPrescriptionsList(state.prescriptions);
          } else if (state is PrescriptionError) {
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
                    style: GoogleFonts.raleway(
                      fontSize: 16.sp,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),
                  ElevatedButton.icon(
                    onPressed: _loadPrescriptions,
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      context.tr('common.retry'),
                      style: GoogleFonts.raleway(),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    color: isDarkMode ? theme.iconTheme.color?.withValues(alpha: 0.4) : Colors.grey,
                    size: 60.sp,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    context.tr('prescription.loading_prescriptions'),
                    style: GoogleFonts.raleway(
                      fontSize: 16.sp,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildPrescriptionsList(List<PrescriptionEntity> prescriptions) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    if (prescriptions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_services_outlined,
              color: isDarkMode ? theme.iconTheme.color?.withValues(alpha: 0.4) : Colors.grey,
              size: 60.sp,
            ),
            SizedBox(height: 16.h),
            Text(
              context.tr('prescription.no_prescription'),
              style: GoogleFonts.raleway(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleMedium?.color,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              widget.isDoctor
                  ? 'Vous n\'avez pas encore créé d\'ordonnance'
                  : 'Vous n\'avez pas encore reçu d\'ordonnance',
              style: GoogleFonts.raleway(
                fontSize: 14.sp,
                color: theme.textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadPrescriptions();
      },
      color: AppColors.primaryColor,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: prescriptions.length,
        itemBuilder: (context, index) {
          final prescription = prescriptions[index];
          return _buildPrescriptionCard(prescription);
        },
      ),
    );
  }

  Widget _buildPrescriptionCard(PrescriptionEntity prescription) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final medicationCount = prescription.medications.length;
    
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      color: theme.cardColor,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider<PrescriptionBloc>.value(
                value: _prescriptionBloc,
                child: PrescriptionDetailsPage(
                  prescription: prescription,
                  isDoctor: widget.isDoctor,
                ),
              ),
            ),
          ).then((_) {
            // Refresh list when returning
            _loadPrescriptions();
          });
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.medical_services,
                    color: AppColors.primaryColor,
                    size: 24.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      '${context.tr('prescription.prescription_from')} ${DateFormat('dd/MM/yyyy').format(prescription.prescriptionDate)}',
                      style: GoogleFonts.raleway(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.titleMedium?.color,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                widget.isDoctor
                    ? '${context.tr('appointments.patient')}: ${prescription.patientName ?? 'N/A'}'
                    : '${context.tr('appointments.doctor')}: Dr. ${prescription.doctorName ?? 'N/A'}',
                style: GoogleFonts.raleway(
                  fontSize: 14.sp,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
              Divider(height: 20.h, color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$medicationCount ${context.tr('medical_records.medications')}',
                    style: GoogleFonts.raleway(
                      fontSize: 14.sp,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        context.tr('medical_records.view_details'),
                        style: GoogleFonts.raleway(
                          fontSize: 14.sp,
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.primaryColor,
                        size: 20.sp,
                      ),
                    ],
                  ),
                ],
              ),
              
              // Show edit status if doctor
              if (widget.isDoctor) 
                Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit,
                        size: 16.sp,
                        color: Colors.green,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Modifiable',
                        style: GoogleFonts.raleway(
                          fontSize: 12.sp,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 