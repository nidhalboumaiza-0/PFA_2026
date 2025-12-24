import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/core/widgets/common/common_widgets.dart';
import 'package:medical_app/features/medical_records/domain/entities/consultation_entity.dart';
import 'package:medical_app/features/medical_records/presentation/bloc/medical_records_bloc.dart';
import 'package:medical_app/injection_container.dart';
import 'package:intl/intl.dart';

class ConsultationDetailsPage extends StatefulWidget {
  final String consultationId;

  const ConsultationDetailsPage({
    super.key,
    required this.consultationId,
  });

  @override
  State<ConsultationDetailsPage> createState() =>
      _ConsultationDetailsPageState();
}

class _ConsultationDetailsPageState extends State<ConsultationDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MedicalRecordsBloc>()
        ..add(GetConsultationFullDetailsEvent(
            consultationId: widget.consultationId)),
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('medical_records.consultation_details')),
        ),
        body: BlocBuilder<MedicalRecordsBloc, MedicalRecordsState>(
          builder: (context, state) {
            if (state is ConsultationLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ConsultationError) {
              return _buildErrorWidget(context, state.message);
            }

            if (state is ConsultationFullDetailsLoaded) {
              return _buildConsultationDetails(context, state.consultation);
            }

            if (state is ConsultationLoaded) {
              return _buildConsultationDetails(context, state.consultation);
            }

            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, String message) {
    return ErrorStateWidget(
      message: message,
      onRetry: () {
        context.read<MedicalRecordsBloc>().add(
          GetConsultationFullDetailsEvent(
            consultationId: widget.consultationId,
          ),
        );
      },
    );
  }

  Widget _buildConsultationDetails(
      BuildContext context, ConsultationEntity consultation) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(context, consultation),
          const SizedBox(height: 16),
          _buildChiefComplaintCard(context, consultation),
          if (consultation.medicalNote != null) ...[
            const SizedBox(height: 16),
            _buildMedicalNoteCard(context, consultation.medicalNote!),
          ],
          if (consultation.medicalNote?.vitalSigns != null) ...[
            const SizedBox(height: 16),
            _buildVitalSignsCard(context, consultation.medicalNote!.vitalSigns!),
          ],
          if (consultation.requiresFollowUp) ...[
            const SizedBox(height: 16),
            _buildFollowUpCard(context, consultation),
          ],
          if (consultation.documentIds != null &&
              consultation.documentIds!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildDocumentsCard(context, consultation.documentIds!),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, ConsultationEntity consultation) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('medical_records.consultation'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusChip(context, consultation.status),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.calendar_today,
              context.tr('medical_records.date'),
              DateFormat('dd/MM/yyyy HH:mm')
                  .format(consultation.consultationDate),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.medical_services,
              context.tr('medical_records.type'),
              consultation.consultationType,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChiefComplaintCard(BuildContext context, ConsultationEntity consultation) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.report_problem_outlined, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  context.tr('medical_records.chief_complaint'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Text(
              consultation.chiefComplaint,
              style: const TextStyle(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalNoteCard(BuildContext context, MedicalNoteEntity medicalNote) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.note_alt_outlined, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  context.tr('medical_records.medical_note'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            if (medicalNote.symptoms != null &&
                medicalNote.symptoms!.isNotEmpty) ...[
              _buildNoteSection(
                context.tr('medical_records.symptoms'),
                medicalNote.symptoms!.join(', '),
              ),
              const SizedBox(height: 12),
            ],
            if (medicalNote.diagnosis != null) ...[
              _buildNoteSection(
                context.tr('medical_records.diagnosis'),
                medicalNote.diagnosis!,
              ),
              const SizedBox(height: 12),
            ],
            if (medicalNote.physicalExamination != null) ...[
              _buildNoteSection(
                context.tr('medical_records.physical_examination'),
                medicalNote.physicalExamination!,
              ),
              const SizedBox(height: 12),
            ],
            if (medicalNote.labResults != null) ...[
              _buildNoteSection(
                context.tr('medical_records.lab_results'),
                medicalNote.labResults!,
              ),
              const SizedBox(height: 12),
            ],
            if (medicalNote.additionalNotes != null) ...[
              _buildNoteSection(
                context.tr('medical_records.additional_notes'),
                medicalNote.additionalNotes!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVitalSignsCard(BuildContext context, VitalSignsEntity vitalSigns) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.monitor_heart_outlined, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  context.tr('medical_records.vital_signs'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                if (vitalSigns.temperature != null)
                  _buildVitalSignItem(
                    Icons.thermostat,
                    context.tr('medical_records.temperature'),
                    '${vitalSigns.temperature}°C',
                  ),
                if (vitalSigns.bloodPressure != null)
                  _buildVitalSignItem(
                    Icons.speed,
                    context.tr('medical_records.blood_pressure'),
                    vitalSigns.bloodPressure!,
                  ),
                if (vitalSigns.heartRate != null)
                  _buildVitalSignItem(
                    Icons.favorite,
                    context.tr('medical_records.heart_rate'),
                    '${vitalSigns.heartRate} bpm',
                  ),
                if (vitalSigns.respiratoryRate != null)
                  _buildVitalSignItem(
                    Icons.air,
                    context.tr('medical_records.respiratory_rate'),
                    '${vitalSigns.respiratoryRate}/min',
                  ),
                if (vitalSigns.oxygenSaturation != null)
                  _buildVitalSignItem(
                    Icons.bubble_chart,
                    context.tr('medical_records.oxygen_saturation'),
                    '${vitalSigns.oxygenSaturation}%',
                  ),
                if (vitalSigns.weight != null)
                  _buildVitalSignItem(
                    Icons.monitor_weight,
                    context.tr('medical_records.weight'),
                    '${vitalSigns.weight} kg',
                  ),
                if (vitalSigns.height != null)
                  _buildVitalSignItem(
                    Icons.height,
                    context.tr('medical_records.height'),
                    '${vitalSigns.height} cm',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowUpCard(BuildContext context, ConsultationEntity consultation) {
    return Card(
      color: Colors.orange.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event_repeat, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Text(
                  context.tr('medical_records.follow_up'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (consultation.followUpDate != null)
              Text(
                '${context.tr('medical_records.follow_up_date')}: ${DateFormat('dd/MM/yyyy').format(consultation.followUpDate!)}',
                style: const TextStyle(fontSize: 14),
              ),
            if (consultation.followUpNotes != null) ...[
              const SizedBox(height: 8),
              Text(
                consultation.followUpNotes!,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsCard(BuildContext context, List<String> documentIds) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.attach_file, color: Colors.teal),
                const SizedBox(width: 8),
                Text(
                  context.tr('medical_records.documents'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Text(
              '${documentIds.length} ${context.tr('medical_records.documents_attached')}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to documents list
              },
              icon: const Icon(Icons.visibility),
              label: Text(context.tr('medical_records.view_documents')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildNoteSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildVitalSignItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: AppColors.primaryColor),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
