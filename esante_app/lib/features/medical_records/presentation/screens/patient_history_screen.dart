import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/medical_history_entity.dart';
import '../bloc/patient_history_bloc.dart';
import '../bloc/patient_history_event.dart';
import '../bloc/patient_history_state.dart';

/// Screen to display a patient's medical history for doctors
class PatientHistoryScreen extends StatelessWidget {
  final String patientId;
  final String? patientName;

  const PatientHistoryScreen({
    super.key,
    required this.patientId,
    this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<PatientHistoryBloc>()
        ..add(LoadPatientHistoryEvent(
          patientId: patientId,
          patientName: patientName,
        )),
      child: _PatientHistoryView(patientName: patientName),
    );
  }
}

class _PatientHistoryView extends StatelessWidget {
  final String? patientName;

  const _PatientHistoryView({this.patientName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: AppBodyText(
          text: patientName != null ? "$patientName's History" : 'Patient History',
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: AppColors.background(context),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context
                .read<PatientHistoryBloc>()
                .add(const RefreshPatientHistoryEvent()),
          ),
        ],
      ),
      body: BlocBuilder<PatientHistoryBloc, PatientHistoryState>(
        builder: (context, state) {
          if (state is PatientHistoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PatientHistoryError) {
            return _buildErrorView(context, state);
          }

          if (state is PatientHistoryLoaded) {
            return _buildHistoryContent(context, state.history);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, PatientHistoryError state) {
    IconData icon;
    String title;

    if (state.code == 'NO_RELATIONSHIP') {
      icon = Icons.lock_outline;
      title = 'Access Restricted';
    } else {
      icon = Icons.error_outline;
      title = 'Error Loading History';
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64.sp, color: AppColors.error),
            SizedBox(height: 16.h),
            AppBodyText(
              text: title,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            AppBodyText(
              text: state.message,
              color: AppColors.grey600,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            CustomButton(
              text: 'Go Back',
              onPressed: () => Navigator.of(context).pop(),
              width: 150.w,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryContent(
      BuildContext context, MedicalHistoryEntity history) {
    return RefreshIndicator(
      onRefresh: () async {
        context
            .read<PatientHistoryBloc>()
            .add(const RefreshPatientHistoryEvent());
      },
      child: CustomScrollView(
        slivers: [
          // Summary Card
          SliverToBoxAdapter(
            child: _buildSummaryCard(history.summary),
          ),

          // Current Medications
          if (history.summary.currentMedications.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildSectionHeader('Current Medications', Icons.medication),
            ),
            SliverToBoxAdapter(
              child: _buildCurrentMedications(history.summary.currentMedications),
            ),
          ],

          // Diagnoses
          if (history.summary.diagnoses.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildSectionHeader('Previous Diagnoses', Icons.medical_information),
            ),
            SliverToBoxAdapter(
              child: _buildDiagnosesList(history.summary.diagnoses),
            ),
          ],

          // Consultations
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              'Consultations (${history.consultations.length})',
              Icons.calendar_month,
            ),
          ),
          if (history.consultations.isEmpty)
            SliverToBoxAdapter(
              child: _buildEmptySection('No consultations found'),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _buildConsultationCard(history.consultations[index]),
                childCount: history.consultations.length,
              ),
            ),

          // Prescriptions
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              'Prescriptions (${history.prescriptions.length})',
              Icons.receipt_long,
            ),
          ),
          if (history.prescriptions.isEmpty)
            SliverToBoxAdapter(
              child: _buildEmptySection('No prescriptions found'),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _buildPrescriptionCard(history.prescriptions[index]),
                childCount: history.prescriptions.length,
              ),
            ),

          // Documents
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              'Documents (${history.documents.length})',
              Icons.folder_open,
            ),
          ),
          if (history.documents.isEmpty)
            SliverToBoxAdapter(
              child: _buildEmptySection('No shared documents'),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _buildDocumentCard(history.documents[index]),
                childCount: history.documents.length,
              ),
            ),

          // Bottom padding
          SliverToBoxAdapter(child: SizedBox(height: 24.h)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(MedicalHistorySummaryEntity summary) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.summarize, color: Colors.white, size: 24.sp),
              SizedBox(width: 8.w),
              AppBodyText(
                text: 'Medical Summary',
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                '${summary.totalConsultations}',
                'Consultations',
                Icons.calendar_today,
              ),
              _buildSummaryItem(
                '${summary.totalPrescriptions}',
                'Prescriptions',
                Icons.receipt,
              ),
              _buildSummaryItem(
                '${summary.totalDocuments}',
                'Documents',
                Icons.folder,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String count, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20.sp),
        SizedBox(height: 4.h),
        AppBodyText(
          text: count,
          color: Colors.white,
          fontSize: 24.sp,
          fontWeight: FontWeight.bold,
        ),
        AppSmallText(
          text: label,
          color: Colors.white70,
          fontSize: 12.sp,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 8.h),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22.sp),
          SizedBox(width: 8.w),
          AppBodyText(
            text: title,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.grey600,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySection(String message) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.grey500, size: 20.sp),
            SizedBox(width: 12.w),
            AppBodyText(
              text: message,
              color: AppColors.grey600,
              fontSize: 14.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentMedications(List<CurrentMedicationEntity> medications) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: medications
            .map((med) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Row(
                    children: [
                      Icon(Icons.circle, color: AppColors.success, size: 8.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: AppBodyText(
                          text: '${med.name} - ${med.dosage}',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      AppSmallText(
                        text: med.frequency,
                        fontSize: 12.sp,
                        color: AppColors.grey600,
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildDiagnosesList(List<String> diagnoses) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: diagnoses
            .map((diagnosis) => Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: AppSmallText(
                    text: diagnosis,
                    fontSize: 13.sp,
                    color: AppColors.warning,
                    fontWeight: FontWeight.w500,
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildConsultationCard(ConsultationSummaryEntity consultation) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 16.sp, color: AppColors.primary),
                    SizedBox(width: 6.w),
                    AppBodyText(
                      text: dateFormat.format(consultation.consultationDate),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: AppSmallText(
                    text: consultation.consultationType.toUpperCase(),
                    fontSize: 10.sp,
                    color: AppColors.info,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (consultation.chiefComplaint != null) ...[
              SizedBox(height: 8.h),
              AppSmallText(
                text: 'Chief Complaint:',
                fontSize: 12.sp,
                color: AppColors.grey600,
              ),
              AppBodyText(
                text: consultation.chiefComplaint!,
                fontSize: 14.sp,
              ),
            ],
            if (consultation.diagnosis != null) ...[
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.medical_services,
                        size: 16.sp, color: AppColors.primary),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: AppBodyText(
                        text: consultation.diagnosis!,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (consultation.vitalSigns != null) ...[
              SizedBox(height: 8.h),
              _buildVitalSigns(consultation.vitalSigns!),
            ],
            if (consultation.followUpRequired) ...[
              SizedBox(height: 8.h),
              Row(
                children: [
                  Icon(Icons.event_repeat, size: 14.sp, color: AppColors.warning),
                  SizedBox(width: 4.w),
                  AppSmallText(
                    text: 'Follow-up: ${consultation.followUpDate != null ? dateFormat.format(consultation.followUpDate!) : 'Scheduled'}',
                    fontSize: 12.sp,
                    color: AppColors.warning,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVitalSigns(VitalSignsEntity vitals) {
    final items = <Widget>[];

    if (vitals.bloodPressure != null) {
      items.add(_buildVitalItem('BP', vitals.bloodPressure!));
    }
    if (vitals.heartRate != null) {
      items.add(_buildVitalItem('HR', '${vitals.heartRate} bpm'));
    }
    if (vitals.temperature != null) {
      items.add(_buildVitalItem('Temp', '${vitals.temperature}°C'));
    }
    if (vitals.oxygenSaturation != null) {
      items.add(_buildVitalItem('SpO2', '${vitals.oxygenSaturation}%'));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8.w,
      runSpacing: 4.h,
      children: items,
    );
  }

  Widget _buildVitalItem(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: AppSmallText(
        text: '$label: $value',
        fontSize: 11.sp,
        color: AppColors.grey600,
      ),
    );
  }

  Widget _buildPrescriptionCard(PrescriptionSummaryEntity prescription) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: prescription.isActive
              ? AppColors.success.withValues(alpha: 0.5)
              : AppColors.grey200,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt_long,
                        size: 16.sp, color: AppColors.success),
                    SizedBox(width: 6.w),
                    AppBodyText(
                      text: dateFormat.format(prescription.prescriptionDate),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: prescription.isActive
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.grey100,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: AppSmallText(
                    text: prescription.status.toUpperCase(),
                    fontSize: 10.sp,
                    color: prescription.isActive
                        ? AppColors.success
                        : AppColors.grey600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            ...prescription.medications.map((med) => Padding(
                  padding: EdgeInsets.only(bottom: 4.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.medication,
                          size: 14.sp, color: AppColors.grey500),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppSmallText(
                              text: med.medicationName,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                            ),
                            AppSmallText(
                              text: '${med.dosage} - ${med.frequency}',
                              fontSize: 12.sp,
                              color: AppColors.grey600,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard(MedicalDocumentEntity document) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final iconData = _getDocumentIcon(document.documentType);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.grey200),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(iconData, color: AppColors.info, size: 24.sp),
        ),
        title: AppBodyText(
          text: document.title,
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: AppSmallText(
          text: '${dateFormat.format(document.uploadDate)} • ${document.fileSizeFormatted}',
          fontSize: 12.sp,
          color: AppColors.grey600,
        ),
        trailing: document.downloadUrl != null
            ? Icon(Icons.download, color: AppColors.primary, size: 20.sp)
            : null,
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      ),
    );
  }

  IconData _getDocumentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'lab_report':
      case 'lab_result':
        return Icons.science;
      case 'imaging':
      case 'xray':
      case 'mri':
        return Icons.image;
      case 'prescription':
        return Icons.receipt;
      case 'medical_report':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }
}
