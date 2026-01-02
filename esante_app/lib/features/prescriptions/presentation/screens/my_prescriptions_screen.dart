import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/prescription_entity.dart';
import '../bloc/prescription_bloc.dart';
import 'prescription_details_screen.dart';

/// Screen to display patient's prescriptions list
class MyPrescriptionsScreen extends StatelessWidget {
  const MyPrescriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PrescriptionBloc>()..add(const LoadMyPrescriptions()),
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'My Prescriptions',
          showBackButton: true,
        ),
        body: BlocBuilder<PrescriptionBloc, PrescriptionState>(
          builder: (context, state) {
            if (state is PrescriptionsLoading) {
              return const _PrescriptionsShimmer();
            }

            if (state is PrescriptionError) {
              // Show beautiful no-connection widget for network errors
              if (state.isNetworkError) {
                return NoConnectionWidget(
                  onRetry: () => context.read<PrescriptionBloc>().add(
                        const LoadMyPrescriptions(),
                      ),
                );
              }
              return _ErrorView(
                message: state.message,
                onRetry: () => context.read<PrescriptionBloc>().add(
                      const LoadMyPrescriptions(),
                    ),
              );
            }

            if (state is PrescriptionsLoaded) {
              if (state.prescriptions.isEmpty) {
                return const _EmptyView();
              }

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<PrescriptionBloc>().add(
                        const LoadMyPrescriptions(),
                      );
                },
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  itemCount: state.prescriptions.length,
                  itemBuilder: (context, index) {
                    final prescription = state.prescriptions[index];
                    return _PrescriptionCard(prescription: prescription);
                  },
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  final PrescriptionEntity prescription;

  const _PrescriptionCard({required this.prescription});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: GestureDetector(
        onTap: () => context.pushPage(
          PrescriptionDetailsScreen(prescriptionId: prescription.id),
          transition: NavTransition.slideLeft,
        ),
        child: InfoCard(
          title: dateFormat.format(prescription.date),
          icon: Icons.receipt_long_rounded,
          trailing: _StatusChip(status: prescription.status),
          children: [
          // Doctor info
          InfoRow(
            label: 'Doctor',
            value: prescription.doctor.name,
            icon: Icons.person_outline,
          ),
          if (prescription.doctor.specialty != null)
            InfoRow(
              label: 'Specialty',
              value: prescription.doctor.specialty!,
              icon: Icons.medical_services_outlined,
            ),

          // Appointment context
          if (prescription.appointment != null) ...[
            SizedBox(height: 8.h),
            Divider(color: AppColors.divider(context)),
            SizedBox(height: 8.h),
            if (prescription.appointment!.chiefComplaint != null)
              InfoRow(
                label: 'Reason',
                value: prescription.appointment!.chiefComplaint!,
                icon: Icons.sick_outlined,
              ),
            if (prescription.appointment!.diagnosis != null)
              InfoRow(
                label: 'Diagnosis',
                value: prescription.appointment!.diagnosis!,
                icon: Icons.medical_information_outlined,
              ),
          ],

          // Medications count
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.medication, size: 18.sp, color: AppColors.primary),
                SizedBox(width: 8.w),
                Text(
                  '${prescription.medicationCount} medication${prescription.medicationCount > 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),

          // Warning indicator
          if (prescription.hasWarnings) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(Icons.warning_amber, size: 16.sp, color: Colors.orange[700]),
                SizedBox(width: 4.w),
                Text(
                  'Special warnings',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange[700],
                      ),
                ),
              ],
            ),
          ],

          // View details button
          SizedBox(height: 12.h),
          CustomButton(
            text: 'View Details',
            onPressed: () => context.pushPage(
              PrescriptionDetailsScreen(prescriptionId: prescription.id),
              transition: NavTransition.slideLeft,
            ),
            isOutlined: true,
          ),
        ],
      ),
    ));
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

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_services_outlined,
            size: 80.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'No prescriptions yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Your prescriptions will appear here',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: Colors.red[300]),
            SizedBox(height: 16.h),
            Text(
              'Error loading prescriptions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8.h),
            Text(message, textAlign: TextAlign.center),
            SizedBox(height: 16.h),
            CustomButton(
              text: 'Retry',
              onPressed: onRetry,
              icon: Icons.refresh,
            ),
          ],
        ),
      ),
    );
  }
}

class _PrescriptionsShimmer extends StatelessWidget {
  const _PrescriptionsShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(bottom: 16.h),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40.w,
                      height: 40.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 100.w,
                          height: 14.h,
                          color: Colors.white,
                        ),
                        SizedBox(height: 4.h),
                        Container(
                          width: 150.w,
                          height: 12.h,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Container(width: 200.w, height: 12.h, color: Colors.white),
                SizedBox(height: 8.h),
                Container(width: 180.w, height: 12.h, color: Colors.white),
                SizedBox(height: 12.h),
                Container(
                  width: 120.w,
                  height: 30.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
