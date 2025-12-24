import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/core/widgets/common/common_widgets.dart';
import 'package:medical_app/features/medical_records/domain/entities/consultation_entity.dart';
import 'package:medical_app/features/medical_records/presentation/bloc/medical_records_bloc.dart';
import 'package:medical_app/features/medical_records/presentation/pages/consultation_details_page.dart';
import 'package:medical_app/injection_container.dart';
import 'package:intl/intl.dart';

class PatientMedicalHistoryPage extends StatefulWidget {
  const PatientMedicalHistoryPage({super.key});

  @override
  State<PatientMedicalHistoryPage> createState() =>
      _PatientMedicalHistoryPageState();
}

class _PatientMedicalHistoryPageState extends State<PatientMedicalHistoryPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<MedicalRecordsBloc>()..add(const GetMyMedicalHistoryEvent()),
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('medical_records.my_medical_history')),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => _showSearchDialog(),
            ),
          ],
        ),
        body: BlocBuilder<MedicalRecordsBloc, MedicalRecordsState>(
          builder: (context, state) {
            if (state is MedicalRecordsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is MedicalRecordsError) {
              return _buildErrorWidget(context, state.message);
            }

            if (state is MyMedicalHistoryLoaded) {
              if (state.consultations.isEmpty) {
                return _buildEmptyWidget(context);
              }
              return _buildMedicalHistoryList(context, state.consultations);
            }

            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  void _showSearchDialog() {
    // TODO: Implement search dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${context.tr('medical_records.search')}: ${context.tr('medical_records.search_coming_soon')}')),
    );
  }

  Widget _buildErrorWidget(BuildContext context, String message) {
    return ErrorStateWidget(
      message: message,
      onRetry: () {
        context.read<MedicalRecordsBloc>().add(const GetMyMedicalHistoryEvent());
      },
      retryText: context.tr('medical_records.retry'),
      useResponsiveSizing: false,
    );
  }

  Widget _buildEmptyWidget(BuildContext context) {
    return EmptyStateWidget(
      message: context.tr('medical_records.no_medical_history'),
      description: context.tr('medical_records.no_medical_history_desc'),
      useResponsiveSizing: false,
    );
  }

  Widget _buildMedicalHistoryList(
      BuildContext context, List<ConsultationEntity> consultations) {
    // Group consultations by date
    final groupedConsultations = <String, List<ConsultationEntity>>{};
    for (final consultation in consultations) {
      final dateKey =
          DateFormat('MMMM yyyy').format(consultation.consultationDate);
      groupedConsultations.putIfAbsent(dateKey, () => []).add(consultation);
    }

    return RefreshIndicator(
      onRefresh: () async {
        context
            .read<MedicalRecordsBloc>()
            .add(const GetMyMedicalHistoryEvent());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: groupedConsultations.length,
        itemBuilder: (context, index) {
          final dateKey = groupedConsultations.keys.elementAt(index);
          final consultationsForDate = groupedConsultations[dateKey]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  dateKey,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              ...consultationsForDate
                  .map((consultation) => _HistoryCard(
                        consultation: consultation,
                        onTap: () => _openConsultationDetails(consultation),
                      ))
                  ,
            ],
          );
        },
      ),
    );
  }

  void _openConsultationDetails(ConsultationEntity consultation) {
    if (consultation.id == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConsultationDetailsPage(
          consultationId: consultation.id!,
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final ConsultationEntity consultation;
  final VoidCallback onTap;

  const _HistoryCard({
    required this.consultation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline indicator
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 60,
                    color: Colors.grey[300],
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('dd MMM yyyy')
                              .format(consultation.consultationDate),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        _buildStatusChip(context, consultation.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      consultation.chiefComplaint,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (consultation.medicalNote?.diagnosis != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${context.tr('medical_records.diagnosis')}: ${consultation.medicalNote!.diagnosis}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _getConsultationTypeIcon(
                              consultation.consultationType),
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          consultation.consultationType,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (consultation.documentIds != null &&
                            consultation.documentIds!.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.attach_file,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${consultation.documentIds!.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getConsultationTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'follow-up':
        return Icons.event_repeat;
      case 'referral':
        return Icons.swap_horiz;
      default:
        return Icons.person;
    }
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    Color color;
    String displayText;
    switch (status.toLowerCase()) {
      case 'draft':
      case 'brouillon':
        color = Colors.orange;
        displayText = context.tr('medical_records.draft');
        break;
      case 'completed':
      case 'terminée':
        color = Colors.green;
        displayText = context.tr('medical_records.completed');
        break;
      case 'archived':
      case 'archivée':
        color = Colors.grey;
        displayText = context.tr('medical_records.archived');
        break;
      default:
        color = Colors.grey;
        displayText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
