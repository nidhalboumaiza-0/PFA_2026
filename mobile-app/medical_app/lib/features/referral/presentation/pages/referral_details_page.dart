import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/features/referral/domain/entities/referral_entity.dart';
import 'package:medical_app/features/referral/presentation/bloc/referral_bloc.dart';
import 'package:intl/intl.dart';

class ReferralDetailsPage extends StatelessWidget {
  final ReferralEntity referral;
  final bool isSent;

  const ReferralDetailsPage({
    super.key,
    required this.referral,
    required this.isSent,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReferralBloc, ReferralState>(
      listener: (context, state) {
        if (state is ReferralAccepted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('referral.referral_accepted'))),
          );
          Navigator.pop(context);
        } else if (state is ReferralRejected) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('referral.referral_rejected'))),
          );
          Navigator.pop(context);
        } else if (state is ReferralCompleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('referral.referral_completed'))),
          );
          Navigator.pop(context);
        } else if (state is ReferralCancelled) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('referral.referral_cancelled'))),
          );
          Navigator.pop(context);
        } else if (state is ReferralError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('referral.referral_details')),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusSection(context),
              const SizedBox(height: 24),
              _buildInfoSection(
                title: context.tr('referral.patient'),
                icon: Icons.person,
                content: referral.patientName ?? '-',
                subtitle: referral.patientPhone,
              ),
              const SizedBox(height: 16),
              _buildInfoSection(
                title: isSent
                    ? context.tr('referral.target_doctor')
                    : context.tr('referral.referring_doctor'),
                icon: Icons.medical_services,
                content: isSent
                    ? referral.targetDoctorName ?? '-'
                    : referral.referringDoctorName ?? '-',
                subtitle: isSent
                    ? referral.targetDoctorSpecialty
                    : referral.referringDoctorSpecialty,
              ),
              const SizedBox(height: 24),
              _buildDetailCard(context),
              const SizedBox(height: 16),
              if (referral.diagnosis != null || referral.symptoms?.isNotEmpty == true)
                _buildMedicalInfoCard(context),
              const SizedBox(height: 16),
              if (referral.statusHistory?.isNotEmpty == true)
                _buildStatusHistoryCard(context),
              const SizedBox(height: 24),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (referral.status.toLowerCase()) {
      case 'en attente':
      case 'pending':
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[700]!;
        icon = Icons.hourglass_empty;
        break;
      case 'accepté':
      case 'accepted':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[700]!;
        icon = Icons.check_circle;
        break;
      case 'refusé':
      case 'rejected':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[700]!;
        icon = Icons.cancel;
        break;
      case 'en cours':
      case 'in_progress':
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[700]!;
        icon = Icons.pending_actions;
        break;
      case 'terminé':
      case 'completed':
        backgroundColor = AppColors.primaryColor.withOpacity(0.1);
        textColor = AppColors.primaryColor;
        icon = Icons.done_all;
        break;
      case 'annulé':
      case 'cancelled':
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[700]!;
        icon = Icons.block;
        break;
      default:
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[700]!;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('referral.status'),
                  style: TextStyle(
                    color: textColor.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
                Text(
                  referral.status,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (referral.urgency != 'routine')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: referral.urgency == 'emergency'
                    ? Colors.red[600]
                    : Colors.orange[600],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                referral.urgency == 'emergency'
                    ? context.tr('referral.emergency')
                    : context.tr('referral.urgent'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required String content,
    String? subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primaryColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              Text(
                content,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
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
        ),
      ],
    );
  }

  Widget _buildDetailCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('referral.referral_details'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              icon: Icons.calendar_today,
              label: context.tr('referral.referral_date'),
              value: referral.referralDate != null
                  ? DateFormat('dd/MM/yyyy').format(referral.referralDate!)
                  : '-',
            ),
            if (referral.specialty != null) ...[
              const Divider(),
              _buildDetailRow(
                icon: Icons.medical_services_outlined,
                label: context.tr('referral.specialty'),
                value: referral.specialty!,
              ),
            ],
            const Divider(),
            _buildDetailRow(
              icon: Icons.description,
              label: context.tr('referral.reason'),
              value: referral.reason,
              isMultiLine: true,
            ),
            if (referral.relevantHistory != null) ...[
              const Divider(),
              _buildDetailRow(
                icon: Icons.history,
                label: context.tr('referral.relevant_history'),
                value: referral.relevantHistory!,
                isMultiLine: true,
              ),
            ],
            if (referral.currentMedications != null) ...[
              const Divider(),
              _buildDetailRow(
                icon: Icons.medication,
                label: context.tr('referral.current_medications'),
                value: referral.currentMedications!,
                isMultiLine: true,
              ),
            ],
            if (referral.specificConcerns != null) ...[
              const Divider(),
              _buildDetailRow(
                icon: Icons.warning_amber,
                label: context.tr('referral.specific_concerns'),
                value: referral.specificConcerns!,
                isMultiLine: true,
              ),
            ],
            if (referral.referralNotes != null) ...[
              const Divider(),
              _buildDetailRow(
                icon: Icons.note,
                label: context.tr('referral.referral_notes'),
                value: referral.referralNotes!,
                isMultiLine: true,
              ),
            ],
            if (referral.responseNotes != null) ...[
              const Divider(),
              _buildDetailRow(
                icon: Icons.reply,
                label: context.tr('referral.response_notes'),
                value: referral.responseNotes!,
                isMultiLine: true,
              ),
            ],
            if (referral.completionNotes != null) ...[
              const Divider(),
              _buildDetailRow(
                icon: Icons.check_box,
                label: context.tr('referral.completion_notes'),
                value: referral.completionNotes!,
                isMultiLine: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalInfoCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_hospital, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                Text(
                  context.tr('referral.medical_information'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (referral.diagnosis != null) ...[
              _buildDetailRow(
                icon: Icons.healing,
                label: context.tr('referral.diagnosis'),
                value: referral.diagnosis!,
              ),
              const Divider(),
            ],
            if (referral.symptoms?.isNotEmpty == true)
              _buildDetailRow(
                icon: Icons.sick,
                label: context.tr('referral.symptoms'),
                value: referral.symptoms!.join(', '),
                isMultiLine: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHistoryCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timeline, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                Text(
                  context.tr('referral.status_history'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...referral.statusHistory!.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.status,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              DateFormat('dd/MM/yyyy HH:mm')
                                  .format(entry.changedAt),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            if (entry.reason != null)
                              Text(
                                entry.reason!,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
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

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isMultiLine = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment:
            isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
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
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final isPending = referral.status.toLowerCase() == 'en attente' ||
        referral.status.toLowerCase() == 'pending';
    final isAccepted = referral.status.toLowerCase() == 'accepté' ||
        referral.status.toLowerCase() == 'accepted';
    final isInProgress = referral.status.toLowerCase() == 'en cours' ||
        referral.status.toLowerCase() == 'in_progress';

    if (isSent) {
      // Sent referrals - can cancel if pending
      if (isPending) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showCancelDialog(context),
            icon: const Icon(Icons.cancel),
            label: Text(context.tr('referral.cancel_referral')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        );
      }
    } else {
      // Received referrals - can accept/reject if pending, complete if accepted
      if (isPending) {
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showRejectDialog(context),
                icon: const Icon(Icons.close),
                label: Text(context.tr('referral.reject')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showAcceptDialog(context),
                icon: const Icon(Icons.check),
                label: Text(context.tr('referral.accept')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        );
      } else if (isAccepted || isInProgress) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showCompleteDialog(context),
            icon: const Icon(Icons.done_all),
            label: Text(context.tr('referral.complete')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        );
      }
    }

    return const SizedBox.shrink();
  }

  void _showAcceptDialog(BuildContext context) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('referral.accept')),
        content: TextField(
          controller: notesController,
          decoration: InputDecoration(
            labelText: context.tr('referral.response_notes'),
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.tr('common.cancel')),
          ),
          BlocBuilder<ReferralBloc, ReferralState>(
            builder: (context, state) {
              return ElevatedButton(
                onPressed: state is ReferralLoading
                    ? null
                    : () {
                        context.read<ReferralBloc>().add(
                              AcceptReferralEvent(
                                referralId: referral.id!,
                                responseNotes: notesController.text.isNotEmpty
                                    ? notesController.text
                                    : null,
                              ),
                            );
                        Navigator.pop(dialogContext);
                      },
                child: state is ReferralLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(context.tr('referral.accept')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('referral.reject')),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(
            labelText: context.tr('referral.rejection_reason'),
            hintText: context.tr('referral.rejection_reason_hint'),
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.tr('common.cancel')),
          ),
          BlocBuilder<ReferralBloc, ReferralState>(
            builder: (context, state) {
              return ElevatedButton(
                onPressed: state is ReferralLoading
                    ? null
                    : () {
                        if (reasonController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(context.tr('referral.rejection_reason_hint')),
                            ),
                          );
                          return;
                        }
                        context.read<ReferralBloc>().add(
                              RejectReferralEvent(
                                referralId: referral.id!,
                                reason: reasonController.text,
                              ),
                            );
                        Navigator.pop(dialogContext);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: state is ReferralLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(context.tr('referral.reject')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showCompleteDialog(BuildContext context) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('referral.complete')),
        content: TextField(
          controller: notesController,
          decoration: InputDecoration(
            labelText: context.tr('referral.completion_notes'),
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.tr('common.cancel')),
          ),
          BlocBuilder<ReferralBloc, ReferralState>(
            builder: (context, state) {
              return ElevatedButton(
                onPressed: state is ReferralLoading
                    ? null
                    : () {
                        context.read<ReferralBloc>().add(
                              CompleteReferralEvent(
                                referralId: referral.id!,
                                completionNotes: notesController.text.isNotEmpty
                                    ? notesController.text
                                    : null,
                              ),
                            );
                        Navigator.pop(dialogContext);
                      },
                child: state is ReferralLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(context.tr('referral.complete')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('referral.cancel_referral')),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(
            labelText: context.tr('referral.cancellation_reason'),
            hintText: context.tr('referral.cancellation_reason_hint'),
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.tr('common.cancel')),
          ),
          BlocBuilder<ReferralBloc, ReferralState>(
            builder: (context, state) {
              return ElevatedButton(
                onPressed: state is ReferralLoading
                    ? null
                    : () {
                        if (reasonController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(context.tr('referral.cancellation_reason_hint')),
                            ),
                          );
                          return;
                        }
                        context.read<ReferralBloc>().add(
                              CancelReferralEvent(
                                referralId: referral.id!,
                                reason: reasonController.text,
                              ),
                            );
                        Navigator.pop(dialogContext);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: state is ReferralLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(context.tr('referral.cancel_referral')),
              );
            },
          ),
        ],
      ),
    );
  }
}
