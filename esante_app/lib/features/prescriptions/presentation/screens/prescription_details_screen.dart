import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/prescription_entity.dart';
import '../bloc/prescription_bloc.dart';

/// Screen to display prescription details
class PrescriptionDetailsScreen extends StatelessWidget {
  final String prescriptionId;

  const PrescriptionDetailsScreen({
    super.key,
    required this.prescriptionId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PrescriptionBloc>()
        ..add(LoadPrescriptionDetails(prescriptionId: prescriptionId)),
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Prescription Details',
          showBackButton: true,
        ),
        body: BlocBuilder<PrescriptionBloc, PrescriptionState>(
          builder: (context, state) {
            if (state is PrescriptionDetailsLoading) {
              return const _DetailsShimmer();
            }

            if (state is PrescriptionError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64.sp, color: Colors.red[300]),
                    SizedBox(height: 16.h),
                    Text(state.message),
                    SizedBox(height: 16.h),
                    CustomButton(
                      text: 'Retry',
                      onPressed: () => context.read<PrescriptionBloc>().add(
                            LoadPrescriptionDetails(prescriptionId: prescriptionId),
                          ),
                      icon: Icons.refresh,
                    ),
                  ],
                ),
              );
            }

            if (state is PrescriptionDetailsLoaded) {
              return _PrescriptionDetails(prescription: state.prescription);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _PrescriptionDetails extends StatelessWidget {
  final PrescriptionEntity prescription;

  const _PrescriptionDetails({required this.prescription});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Prescription header info
          InfoCard(
            title: 'Prescription',
            icon: Icons.receipt_long_rounded,
            trailing: _StatusChip(status: prescription.status),
            items: [
              InfoItem(
                label: 'Date',
                value: dateFormat.format(prescription.date),
                icon: Icons.calendar_today_outlined,
              ),
              InfoItem(
                label: 'Doctor',
                value: prescription.doctor.name,
                icon: Icons.person_outline,
              ),
              if (prescription.doctor.specialty != null)
                InfoItem(
                  label: 'Specialty',
                  value: prescription.doctor.specialty,
                  icon: Icons.medical_services_outlined,
                ),
            ],
          ),
          SizedBox(height: 16.h),

          // Consultation context
          if (prescription.appointment != null) ...[
            InfoCard(
              title: 'Consultation',
              icon: Icons.local_hospital_outlined,
              items: [
                if (prescription.appointment!.consultationDate != null)
                  InfoItem(
                    label: 'Consultation Date',
                    value: dateFormat.format(prescription.appointment!.consultationDate!),
                    icon: Icons.event_outlined,
                  ),
                if (prescription.appointment!.consultationType != null)
                  InfoItem(
                    label: 'Type',
                    value: _formatConsultationType(prescription.appointment!.consultationType!),
                    icon: Icons.category_outlined,
                  ),
                if (prescription.appointment!.chiefComplaint != null)
                  InfoItem(
                    label: 'Reason for Visit',
                    value: prescription.appointment!.chiefComplaint,
                    icon: Icons.sick_outlined,
                  ),
                if (prescription.appointment!.diagnosis != null)
                  InfoItem(
                    label: 'Diagnosis',
                    value: prescription.appointment!.diagnosis,
                    icon: Icons.medical_information_outlined,
                  ),
              ],
            ),
            SizedBox(height: 16.h),
          ],

          // Medications
          InfoCard(
            title: 'Medications (${prescription.medicationCount})',
            icon: Icons.medication_rounded,
            children: [
              ...prescription.medications.asMap().entries.map((entry) {
                final index = entry.key;
                final medication = entry.value;
                return Column(
                  children: [
                    if (index > 0) Divider(color: AppColors.divider(context)),
                    _MedicationItem(medication: medication),
                  ],
                );
              }),
            ],
          ),
          SizedBox(height: 16.h),

          // Instructions & Warnings
          if (prescription.generalInstructions != null ||
              prescription.specialWarnings != null ||
              prescription.pharmacyName != null)
            InfoCard(
              title: 'Additional Info',
              icon: Icons.info_outline,
              items: [
                if (prescription.generalInstructions != null)
                  InfoItem(
                    label: 'General Instructions',
                    value: prescription.generalInstructions,
                    icon: Icons.notes_outlined,
                  ),
                if (prescription.specialWarnings != null)
                  InfoItem(
                    label: 'Special Warnings',
                    value: prescription.specialWarnings,
                    icon: Icons.warning_amber_rounded,
                  ),
                if (prescription.pharmacyName != null)
                  InfoItem(
                    label: 'Pharmacy',
                    value: prescription.pharmacyName,
                    icon: Icons.local_pharmacy_outlined,
                  ),
              ],
            ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  String _formatConsultationType(String type) {
    switch (type.toLowerCase()) {
      case 'in-person':
        return 'In Person';
      case 'follow-up':
        return 'Follow-up';
      case 'referral':
        return 'Referral';
      default:
        return type;
    }
  }
}

class _MedicationItem extends StatelessWidget {
  final MedicationEntity medication;

  const _MedicationItem({required this.medication});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Medication name
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.medication,
                  size: 20.sp,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medication.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (medication.form != null)
                      Text(
                        medication.form!.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary(context),
                            ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Medication details grid
          Wrap(
            spacing: 16.w,
            runSpacing: 8.h,
            children: [
              _DetailChip(
                icon: Icons.straighten,
                label: 'Dosage',
                value: medication.dosage,
              ),
              _DetailChip(
                icon: Icons.schedule,
                label: 'Frequency',
                value: medication.frequency,
              ),
              _DetailChip(
                icon: Icons.timelapse,
                label: 'Duration',
                value: medication.duration,
              ),
            ],
          ),

          // Instructions
          if (medication.instructions != null) ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline, size: 18.sp, color: Colors.amber[700]),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      medication.instructions!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.amber[800],
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.divider(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: AppColors.textHint(context)),
          SizedBox(width: 6.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textHint(context),
                      fontSize: 10.sp,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status.toLowerCase()) {
      case 'active':
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green[700]!;
        label = 'Active';
        break;
      case 'completed':
        backgroundColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey[700]!;
        label = 'Completed';
        break;
      case 'cancelled':
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red[700]!;
        label = 'Cancelled';
        break;
      default:
        backgroundColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey[700]!;
        label = status;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _DetailsShimmer extends StatelessWidget {
  const _DetailsShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: List.generate(3, (index) {
            return Container(
              margin: EdgeInsets.only(bottom: 16.h),
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 150.w, height: 16.h, color: Colors.white),
                  SizedBox(height: 16.h),
                  ...List.generate(3, (i) => Column(
                    children: [
                      Row(
                        children: [
                          Container(width: 36.w, height: 36.h, color: Colors.white),
                          SizedBox(width: 12.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(width: 80.w, height: 12.h, color: Colors.white),
                              SizedBox(height: 4.h),
                              Container(width: 120.w, height: 14.h, color: Colors.white),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                    ],
                  )),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
