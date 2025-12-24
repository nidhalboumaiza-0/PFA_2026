import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/core/utils/custom_snack_bar.dart';
import 'package:medical_app/features/authentication/data/data%20sources/auth_local_data_source.dart';
import 'package:medical_app/features/rendez_vous/domain/entities/rendez_vous_entity.dart';
import 'package:medical_app/features/rendez_vous/presentation/blocs/rendez-vous%20BLoC/rendez_vous_bloc.dart';
import 'package:medical_app/injection_container.dart';
import 'package:medical_app/widgets/reusable_text_widget.dart';

class RendezVousMedecin extends StatefulWidget {
  const RendezVousMedecin({super.key});

  @override
  State<RendezVousMedecin> createState() => _RendezVousMedecinState();
}

class _RendezVousMedecinState extends State<RendezVousMedecin> {
  String? doctorId;

  @override
  void initState() {
    super.initState();
    _loadDoctorId();
  }

  Future<void> _loadDoctorId() async {
    final authLocalDataSource = sl<AuthLocalDataSource>();
    final user = await authLocalDataSource.getUser();
    setState(() {
      doctorId = user.id;
    });
    if (doctorId != null) {
      context.read<RendezVousBloc>().add(FetchRendezVous(doctorId: doctorId));
    }
  }

  Future<bool?> _showConfirmationDialog(String action, String patientName) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action ' + context.tr('consultation.the_consultation')),
        content: Text(
          context.tr('consultation.confirm_action_for_patient', args: {'action': action, 'patient': patientName}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('common.confirm')),
          ),
        ],
      ),
    );
  }

  void _updateConsultationStatus(
      String id,
      String newStatus,
      String patientName,
      ) async {
    final action = newStatus == 'Accepté' ? 'accepter' : 'refuser';
    final confirmed = await _showConfirmationDialog(action, patientName);
    if (confirmed == true) {
      if (newStatus == 'Accepté') {
        context.read<RendezVousBloc>().add(AcceptAppointment(id));
      } else if (newStatus == 'Refusé') {
        context.read<RendezVousBloc>().add(RefuseAppointment(id));
      } else {
        context.read<RendezVousBloc>().add(UpdateRendezVousStatus(
          rendezVousId: id,
          status: newStatus,
        ));
      }
    }
  }

  String _translateStatus(String status) {
    switch (status) {
      case 'En attente':
        return 'En attente';
      case 'Accepté':
        return 'Accepté';
      case 'Refusé':
        return 'Refusé';
      case 'Annulé':
        return 'Annulé';
      case 'Terminé':
        return 'Terminé';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.whiteColor,
        appBar: AppBar(
          title: Text(context.tr('consultation.title')),
          backgroundColor: const Color(0xFF2FA7BB),
          leading: IconButton(
            icon: const Icon(
              Icons.chevron_left,
              size: 30,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: BlocListener<RendezVousBloc, RendezVousState>(
          listener: (context, state) {
            if (state is RendezVousError) {
              showErrorSnackBar(context, state.message);
            } else if (state is RendezVousStatusUpdated) {
              showSuccessSnackBar(
                context,
                context.tr('consultation.updated_successfully'),
              );
              if (doctorId != null) {
                context.read<RendezVousBloc>().add(FetchRendezVous(doctorId: doctorId));
              }
            }
          },
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Image responsive
                  Image.asset(
                    'assets/images/Consultation.png',
                    height:250.h,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 20.h),
                  // Liste des consultations
                  BlocBuilder<RendezVousBloc, RendezVousState>(
                    builder: (context, state) {
                      if (state is RendezVousLoading || doctorId == null) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is RendezVousLoaded) {
                        final pendingRendezVous = state.rendezVous
                            .where((rv) => rv.status == 'pending')
                            .toList();
                        if (pendingRendezVous.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: ReusableTextWidget(
                                text: context.tr('consultation.no_pending_consultations'),
                                textSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: pendingRendezVous.length,
                          itemBuilder: (context, index) {
                            final consultation = pendingRendezVous[index];
                            return Card(
                              elevation: 2,
                              margin: EdgeInsets.symmetric(vertical: 8.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(16.w),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ReusableTextWidget(
                                      text: context.tr('appointments.patient') + ": ${consultation.patientName ?? context.tr('common.unknown')}",
                                      textSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                    ),
                                    SizedBox(height: 8.h),
                                    ReusableTextWidget(
                                      text:
                                      context.tr('consultation.start_time') + ": ${consultation.startDate.toLocal().toString().substring(0, 16) ?? context.tr('common.not_defined')}",
                                      textSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                    SizedBox(height: 8.h),
                                    ReusableTextWidget(
                                      text: context.tr('consultation.service') + ": ${consultation.serviceName}",
                                      textSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                    SizedBox(height: 8.h),
                                    ReusableTextWidget(
                                      text: context.tr('appointments.status') + ": ${_translateStatus(consultation.status)}",
                                      textSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: consultation.status == 'En attente'
                                          ? Colors.orange
                                          : consultation.status == 'Accepté'
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    if (consultation.status == 'En attente') ...[
                                      SizedBox(height: 16.h),
                                      Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                  BorderRadius.circular(8.r),
                                                ),
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 12.h,
                                                ),
                                              ),
                                              onPressed: () {
                                                _updateConsultationStatus(
                                                  consultation.id ?? '',
                                                  'Accepté',
                                                  consultation.patientName ?? 'Inconnu',
                                                );
                                              },
                                              child: Text(
                                                context.tr('appointments.accept'),
                                                style: GoogleFonts.raleway(
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.whiteColor,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 8.w),
                                          Expanded(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                  BorderRadius.circular(8.r),
                                                ),
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 12.h,
                                                ),
                                              ),
                                              onPressed: () {
                                                _updateConsultationStatus(
                                                  consultation.id ?? '',
                                                  'Refusé',
                                                  consultation.patientName ?? 'Inconnu',
                                                );
                                              },
                                              child: Text(
                                                context.tr('appointments.reject'),
                                                style: GoogleFonts.raleway(
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.whiteColor,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      } else if (state is RendezVousError) {
                        return ReusableTextWidget(
                          text: state.message,
                          textSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}