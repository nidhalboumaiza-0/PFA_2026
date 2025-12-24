import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/core/widgets/common/common_widgets.dart';
import 'package:medical_app/features/referral/domain/entities/referral_entity.dart';
import 'package:medical_app/features/referral/presentation/bloc/referral_bloc.dart';
import 'package:medical_app/injection_container.dart';
import 'package:intl/intl.dart';

class PatientReferralsPage extends StatefulWidget {
  const PatientReferralsPage({super.key});

  @override
  State<PatientReferralsPage> createState() => _PatientReferralsPageState();
}

class _PatientReferralsPageState extends State<PatientReferralsPage> {
  String? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ReferralBloc>()..add(const LoadMyReferralsEvent()),
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('referral.my_referrals')),
          actions: [
            PopupMenuButton<String?>(
              icon: const Icon(Icons.filter_list),
              tooltip: context.tr('referral.filter_by_status'),
              onSelected: (value) {
                setState(() => _selectedStatus = value);
                context.read<ReferralBloc>().add(
                      LoadMyReferralsEvent(status: value),
                    );
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: null,
                  child: Text(context.tr('referral.all')),
                ),
                PopupMenuItem(
                  value: 'En attente',
                  child: Text(context.tr('referral.pending')),
                ),
                PopupMenuItem(
                  value: 'Accepté',
                  child: Text(context.tr('referral.accepted')),
                ),
                PopupMenuItem(
                  value: 'En cours',
                  child: Text(context.tr('referral.in_progress')),
                ),
                PopupMenuItem(
                  value: 'Terminé',
                  child: Text(context.tr('referral.completed')),
                ),
                PopupMenuItem(
                  value: 'Annulé',
                  child: Text(context.tr('referral.cancelled')),
                ),
              ],
            ),
          ],
        ),
        body: BlocBuilder<ReferralBloc, ReferralState>(
          builder: (context, state) {
            if (state is ReferralLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ReferralError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context
                          .read<ReferralBloc>()
                          .add(LoadMyReferralsEvent(status: _selectedStatus)),
                      child: Text(context.tr('common.retry')),
                    ),
                  ],
                ),
              );
            }

            if (state is MyReferralsLoaded) {
              if (state.referrals.isEmpty) {
                return EmptyStateWidget(
                  message: context.tr('referral.no_patient_referrals'),
                  useResponsiveSizing: false,
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  context
                      .read<ReferralBloc>()
                      .add(LoadMyReferralsEvent(status: _selectedStatus));
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.referrals.length,
                  itemBuilder: (context, index) {
                    return _PatientReferralCard(referral: state.referrals[index]);
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

class _PatientReferralCard extends StatelessWidget {
  final ReferralEntity referral;

  const _PatientReferralCard({required this.referral});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showReferralDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('referral.referring_doctor'),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          referral.referringDoctorName ?? '-',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(status: referral.status),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('referral.target_doctor'),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          referral.targetDoctorName ?? '-',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (referral.targetDoctorSpecialty != null)
                          Text(
                            referral.targetDoctorSpecialty!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (referral.specialty != null) ...[
                Row(
                  children: [
                    Icon(Icons.medical_services_outlined,
                        size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      referral.specialty!,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Icon(Icons.description_outlined,
                      size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      referral.reason,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    referral.referralDate != null
                        ? DateFormat('dd/MM/yyyy').format(referral.referralDate!)
                        : '-',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  if (referral.urgency != 'routine') ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: referral.urgency == 'emergency'
                            ? Colors.red[100]
                            : Colors.orange[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        referral.urgency == 'emergency'
                            ? context.tr('referral.emergency')
                            : context.tr('referral.urgent'),
                        style: TextStyle(
                          color: referral.urgency == 'emergency'
                              ? Colors.red[700]
                              : Colors.orange[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (referral.appointmentDate != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.event, color: AppColors.primaryColor),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('referral.appointment_date'),
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${DateFormat('dd/MM/yyyy').format(referral.appointmentDate!)} ${referral.appointmentTime ?? ''}',
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showReferralDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                context.tr('referral.referral_details'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildDetailItem(
                context.tr('referral.referring_doctor'),
                referral.referringDoctorName ?? '-',
                referral.referringDoctorSpecialty,
              ),
              _buildDetailItem(
                context.tr('referral.target_doctor'),
                referral.targetDoctorName ?? '-',
                referral.targetDoctorSpecialty,
              ),
              _buildDetailItem(
                context.tr('referral.specialty'),
                referral.specialty ?? '-',
                null,
              ),
              _buildDetailItem(
                context.tr('referral.reason'),
                referral.reason,
                null,
              ),
              if (referral.diagnosis != null)
                _buildDetailItem(
                  context.tr('referral.diagnosis'),
                  referral.diagnosis!,
                  null,
                ),
              if (referral.symptoms?.isNotEmpty == true)
                _buildDetailItem(
                  context.tr('referral.symptoms'),
                  referral.symptoms!.join(', '),
                  null,
                ),
              _buildDetailItem(
                context.tr('referral.referral_date'),
                referral.referralDate != null
                    ? DateFormat('dd/MM/yyyy').format(referral.referralDate!)
                    : '-',
                null,
              ),
              if (referral.appointmentDate != null)
                _buildDetailItem(
                  context.tr('referral.appointment_date'),
                  '${DateFormat('dd/MM/yyyy').format(referral.appointmentDate!)} ${referral.appointmentTime ?? ''}',
                  null,
                ),
              if (referral.referralNotes != null)
                _buildDetailItem(
                  context.tr('referral.referral_notes'),
                  referral.referralNotes!,
                  null,
                ),
              if (referral.responseNotes != null)
                _buildDetailItem(
                  context.tr('referral.response_notes'),
                  referral.responseNotes!,
                  null,
                ),
              if (referral.completionNotes != null)
                _buildDetailItem(
                  context.tr('referral.completion_notes'),
                  referral.completionNotes!,
                  null,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, String? subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
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

    switch (status.toLowerCase()) {
      case 'en attente':
      case 'pending':
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[700]!;
        break;
      case 'accepté':
      case 'accepted':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[700]!;
        break;
      case 'refusé':
      case 'rejected':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[700]!;
        break;
      case 'en cours':
      case 'in_progress':
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[700]!;
        break;
      case 'terminé':
      case 'completed':
        backgroundColor = AppColors.primaryColor.withOpacity(0.1);
        textColor = AppColors.primaryColor;
        break;
      case 'annulé':
      case 'cancelled':
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[700]!;
        break;
      default:
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
