import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/features/rendez_vous/domain/entities/rendez_vous_entity.dart';
import 'package:medical_app/features/rendez_vous/presentation/blocs/rendez-vous%20BLoC/rendez_vous_bloc.dart';

class AppointmentDetailsPage extends StatefulWidget {
  final String id;

  const AppointmentDetailsPage({Key? key, required this.id}) : super(key: key);

  @override
  State<AppointmentDetailsPage> createState() => _AppointmentDetailsPageState();
}

class _AppointmentDetailsPageState extends State<AppointmentDetailsPage> {
  @override
  void initState() {
    super.initState();
    _loadAppointmentDetails();
  }

  void _loadAppointmentDetails() {
    // Use FetchRendezVous event with an ID filter
    context.read<RendezVousBloc>().add(
      FetchRendezVous(appointmentId: widget.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          context.tr('appointment_details'),
          style: GoogleFonts.raleway(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<RendezVousBloc, RendezVousState>(
        builder: (context, state) {
          if (state is RendezVousLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor),
            );
          } else if (state is RendezVousLoaded) {
            // Find appointment by ID
            final appointment = state.rendezVous.firstWhere(
              (a) => a.id == widget.id,
              orElse:
                  () => RendezVousEntity(
                    startDate: DateTime.now(),
                    endDate: DateTime.now().add(const Duration(minutes: 30)),
                    serviceName: '',
                    patient: '',
                    medecin: '',
                    status: 'not_found',
                  ),
            );

            if (appointment.status == 'not_found') {
              return Center(
                child: Text(
                  context.tr('appointment_not_found'),
                  style: GoogleFonts.raleway(fontSize: 16.sp),
                ),
              );
            }

            return _buildAppointmentDetailsView(appointment);
          } else if (state is RendezVousError) {
            return Center(
              child: Text(
                '${context.tr('common.error')}: ${state.message}',
                style: GoogleFonts.raleway(color: Colors.red),
              ),
            );
          }
          return Center(
            child: Text(
              context.tr('appointment_not_found'),
              style: GoogleFonts.raleway(fontSize: 16.sp),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppointmentDetailsView(RendezVousEntity appointment) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(appointment),
          SizedBox(height: 16.h),
          _buildStatusCard(appointment),
          SizedBox(height: 16.h),
          _buildActionButtons(appointment),
        ],
      ),
    );
  }

  Widget _buildInfoCard(RendezVousEntity appointment) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('appointment_info'),
              style: GoogleFonts.raleway(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
            Divider(height: 24.h, thickness: 1),
            _buildInfoRow(context.tr('patient'), appointment.patientName ?? 'Unknown'),
            _buildInfoRow(context.tr('doctor'), appointment.medecinName ?? 'Unknown'),
            _buildInfoRow(
              context.tr('date'),
              appointment.startDate.toString().substring(0, 10),
            ),
            _buildInfoRow(context.tr('time'), _formatTime(appointment.startDate)),
            _buildInfoRow(context.tr('service'), appointment.serviceName),
            if (appointment.motif != null && appointment.motif!.isNotEmpty)
              _buildInfoRow(context.tr('motif'), appointment.motif!),
            if (appointment.symptoms != null &&
                appointment.symptoms!.isNotEmpty)
              _buildInfoRow(context.tr('symptoms'), appointment.symptoms!.join(', ')),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildStatusCard(RendezVousEntity appointment) {
    Color statusColor;
    String statusText = appointment.status;

    switch (appointment.status) {
      case 'En attente':
        statusColor = Colors.orange;
        break;
      case 'Accepté':
        statusColor = Colors.green;
        break;
      case 'Refusé':
        statusColor = Colors.red;
        break;
      case 'Annulé':
        statusColor = Colors.red;
        break;
      case 'Terminé':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Row(
          children: [
            Text(
              context.tr('status'),
              style: GoogleFonts.raleway(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                statusText,
                style: GoogleFonts.raleway(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(RendezVousEntity appointment) {
    // Only show accept/reject buttons if the appointment is pending
    if (appointment.status == 'En attente') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                context.read<RendezVousBloc>().add(
                  AcceptAppointment(appointment.id!),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                context.tr('accept'),
                style: GoogleFonts.raleway(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                context.read<RendezVousBloc>().add(
                  RefuseAppointment(appointment.id!),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                context.tr('reject'),
                style: GoogleFonts.raleway(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // For patients, add cancel button if not yet completed
    if (appointment.status == 'Accepté') {
      return ElevatedButton(
        onPressed: () {
          context.read<RendezVousBloc>().add(
            CancelAppointment(appointment.id!),
          );
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          minimumSize: Size(double.infinity, 48.h),
        ),
        child: Text(
          context.tr('cancel'),
          style: GoogleFonts.raleway(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // For completed appointments, add rating button
    if (appointment.status == 'Terminé' && !appointment.isRated) {
      return ElevatedButton(
        onPressed: () {
          _showRatingDialog(appointment);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          minimumSize: Size(double.infinity, 48.h),
        ),
        child: Text(
          context.tr('rate_doctor'),
          style: GoogleFonts.raleway(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110.w,
            child: Text(
              label,
              style: GoogleFonts.raleway(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(child: Text(value, style: GoogleFonts.raleway())),
        ],
      ),
    );
  }

  void _showRatingDialog(RendezVousEntity appointment) {
    double selectedRating = 3.0;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(context.tr('rate_your_doctor')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.tr('how_was_your_experience')),
                SizedBox(height: 20.h),
                StatefulBuilder(
                  builder:
                      (context, setState) => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          5,
                          (index) => IconButton(
                            icon: Icon(
                              index < selectedRating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: AppColors.primaryColor,
                              size: 36,
                            ),
                            onPressed: () {
                              setState(() {
                                selectedRating = index + 1.0;
                              });
                            },
                          ),
                        ),
                      ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.tr('cancel')),
              ),
              ElevatedButton(
                onPressed: () {
                  context.read<RendezVousBloc>().add(
                    RateDoctor(
                      appointmentId: appointment.id!,
                      rating: selectedRating,
                    ),
                  );
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                ),
                child: Text(context.tr('submit')),
              ),
            ],
          ),
    );
  }
}
