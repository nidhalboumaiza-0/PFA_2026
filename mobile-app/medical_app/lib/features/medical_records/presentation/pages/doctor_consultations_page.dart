import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:medical_app/core/widgets/common/common_widgets.dart';
import 'package:medical_app/features/medical_records/domain/entities/consultation_entity.dart';
import 'package:medical_app/features/medical_records/presentation/bloc/medical_records_bloc.dart';
import 'package:medical_app/features/medical_records/presentation/pages/consultation_details_page.dart';
import 'package:medical_app/injection_container.dart';
import 'package:intl/intl.dart';

class DoctorConsultationsPage extends StatefulWidget {
  const DoctorConsultationsPage({super.key});

  @override
  State<DoctorConsultationsPage> createState() =>
      _DoctorConsultationsPageState();
}

class _DoctorConsultationsPageState extends State<DoctorConsultationsPage> {
  String? _selectedStatus;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<MedicalRecordsBloc>()..add(const GetDoctorConsultationsEvent()),
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('medical_records.consultations')),
          actions: [
            IconButton(
              icon: const Icon(Icons.date_range),
              tooltip: context.tr('medical_records.filter_by_date'),
              onPressed: _showDateRangeFilter,
            ),
            PopupMenuButton<String?>(
              icon: const Icon(Icons.filter_list),
              tooltip: context.tr('medical_records.filter_by_status'),
              onSelected: (value) {
                setState(() => _selectedStatus = value);
                _loadConsultations();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: null,
                  child: Text(context.tr('medical_records.all')),
                ),
                PopupMenuItem(
                  value: 'draft',
                  child: Text(context.tr('medical_records.draft')),
                ),
                PopupMenuItem(
                  value: 'completed',
                  child: Text(context.tr('medical_records.completed')),
                ),
                PopupMenuItem(
                  value: 'archived',
                  child: Text(context.tr('medical_records.archived')),
                ),
              ],
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

            if (state is DoctorConsultationsLoaded) {
              if (state.consultations.isEmpty) {
                return _buildEmptyWidget();
              }
              return _buildConsultationsList(context, state.consultations);
            }

            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  void _loadConsultations() {
    context.read<MedicalRecordsBloc>().add(
          GetDoctorConsultationsEvent(
            status: _selectedStatus,
            startDate: _startDate,
            endDate: _endDate,
          ),
        );
  }

  void _showDateRangeFilter() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadConsultations();
    }
  }

  Widget _buildErrorWidget(BuildContext context, String message) {
    return ErrorStateWidget(
      message: message,
      onRetry: _loadConsultations,
      retryText: context.tr('medical_records.retry'),
      useResponsiveSizing: false,
    );
  }

  Widget _buildEmptyWidget() {
    return EmptyStateWidget(
      message: context.tr('medical_records.no_consultations'),
      useResponsiveSizing: false,
    );
  }

  Widget _buildConsultationsList(
      BuildContext context, List<ConsultationEntity> consultations) {
    return RefreshIndicator(
      onRefresh: () async {
        _loadConsultations();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: consultations.length,
        itemBuilder: (context, index) {
          final consultation = consultations[index];
          return _ConsultationCard(
            consultation: consultation,
            onTap: () => _openConsultationDetails(consultation),
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

class _ConsultationCard extends StatelessWidget {
  final ConsultationEntity consultation;
  final VoidCallback onTap;

  const _ConsultationCard({
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      consultation.chiefComplaint,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusChip(context, consultation.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm')
                        .format(consultation.consultationDate),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.medical_services,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    consultation.consultationType,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              if (consultation.medicalNote?.diagnosis != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${context.tr('medical_records.diagnosis')}: ${consultation.medicalNote!.diagnosis}',
                  style: const TextStyle(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (consultation.requiresFollowUp) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.event_repeat,
                        size: 16,
                        color: Colors.orange[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        context.tr('medical_records.follow_up_required'),
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 12,
                        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
