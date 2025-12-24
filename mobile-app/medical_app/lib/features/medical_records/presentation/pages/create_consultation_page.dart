import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/features/medical_records/domain/entities/consultation_entity.dart';
import 'package:medical_app/features/medical_records/presentation/bloc/medical_records_bloc.dart';
import 'package:medical_app/injection_container.dart';

class CreateConsultationPage extends StatefulWidget {
  final String appointmentId;
  final String? patientName;

  const CreateConsultationPage({
    super.key,
    required this.appointmentId,
    this.patientName,
  });

  @override
  State<CreateConsultationPage> createState() => _CreateConsultationPageState();
}

class _CreateConsultationPageState extends State<CreateConsultationPage> {
  final _formKey = GlobalKey<FormState>();
  final _chiefComplaintController = TextEditingController();
  final _symptomsController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _physicalExamController = TextEditingController();
  final _labResultsController = TextEditingController();
  final _additionalNotesController = TextEditingController();
  final _followUpNotesController = TextEditingController();

  // Vital Signs Controllers
  final _temperatureController = TextEditingController();
  final _bloodPressureController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _respiratoryRateController = TextEditingController();
  final _oxygenSaturationController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  String _consultationType = 'in-person';
  bool _requiresFollowUp = false;
  DateTime? _followUpDate;

  @override
  void dispose() {
    _chiefComplaintController.dispose();
    _symptomsController.dispose();
    _diagnosisController.dispose();
    _physicalExamController.dispose();
    _labResultsController.dispose();
    _additionalNotesController.dispose();
    _followUpNotesController.dispose();
    _temperatureController.dispose();
    _bloodPressureController.dispose();
    _heartRateController.dispose();
    _respiratoryRateController.dispose();
    _oxygenSaturationController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MedicalRecordsBloc>(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('medical_records.create_consultation')),
        ),
        body: BlocConsumer<MedicalRecordsBloc, MedicalRecordsState>(
          listener: (context, state) {
            if (state is ConsultationCreated) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.tr('medical_records.consultation_created')),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context, state.consultation);
            } else if (state is ConsultationError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${context.tr('medical_records.error')}: ${state.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.patientName != null) ...[
                          _buildPatientHeader(),
                          const SizedBox(height: 16),
                        ],
                        _buildConsultationTypeSection(),
                        const SizedBox(height: 24),
                        _buildChiefComplaintSection(),
                        const SizedBox(height: 24),
                        _buildVitalSignsSection(),
                        const SizedBox(height: 24),
                        _buildMedicalNoteSection(),
                        const SizedBox(height: 24),
                        _buildFollowUpSection(),
                        const SizedBox(height: 32),
                        _buildSubmitButton(context, state),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                if (state is ConsultationLoading)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPatientHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primaryColor.withOpacity(0.1),
              child: Icon(Icons.person, color: AppColors.primaryColor),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('medical_records.patient'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  widget.patientName!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsultationTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('medical_records.consultation_type'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(
              value: 'in-person',
              label: Text(context.tr('medical_records.in_person')),
              icon: const Icon(Icons.person),
            ),
            ButtonSegment(
              value: 'follow-up',
              label: Text(context.tr('medical_records.follow_up_type')),
              icon: const Icon(Icons.event_repeat),
            ),
            ButtonSegment(
              value: 'referral',
              label: Text(context.tr('medical_records.referral_type')),
              icon: const Icon(Icons.swap_horiz),
            ),
          ],
          selected: {_consultationType},
          onSelectionChanged: (Set<String> selection) {
            setState(() => _consultationType = selection.first);
          },
        ),
      ],
    );
  }

  Widget _buildChiefComplaintSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('medical_records.chief_complaint'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _chiefComplaintController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: context.tr('medical_records.chief_complaint_hint'),
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return context.tr('medical_records.chief_complaint_required');
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildVitalSignsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.monitor_heart, color: Colors.red),
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _temperatureController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: context.tr('medical_records.temperature'),
                      suffixText: '°C',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _bloodPressureController,
                    decoration: InputDecoration(
                      labelText: context.tr('medical_records.blood_pressure'),
                      hintText: '120/80',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _heartRateController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: context.tr('medical_records.heart_rate'),
                      suffixText: 'bpm',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _respiratoryRateController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: context.tr('medical_records.respiratory_rate'),
                      suffixText: '/min',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _oxygenSaturationController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: context.tr('medical_records.oxygen_saturation'),
                      suffixText: '%',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: context.tr('medical_records.weight'),
                      suffixText: 'kg',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: MediaQuery.of(context).size.width / 2 - 40,
              child: TextFormField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.tr('medical_records.height'),
                  suffixText: 'cm',
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalNoteSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.note_alt, color: Colors.blue),
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _symptomsController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: context.tr('medical_records.symptoms'),
                hintText: context.tr('medical_records.symptoms_hint'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _diagnosisController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: context.tr('medical_records.diagnosis'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _physicalExamController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: context.tr('medical_records.physical_examination'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _labResultsController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: context.tr('medical_records.lab_results'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _additionalNotesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: context.tr('medical_records.additional_notes'),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowUpSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_repeat, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  context.tr('medical_records.follow_up'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: Text(context.tr('medical_records.requires_follow_up')),
              value: _requiresFollowUp,
              onChanged: (value) {
                setState(() => _requiresFollowUp = value);
              },
            ),
            if (_requiresFollowUp) ...[
              const SizedBox(height: 12),
              ListTile(
                title: Text(context.tr('medical_records.follow_up_date')),
                subtitle: Text(
                  _followUpDate != null
                      ? '${_followUpDate!.day}/${_followUpDate!.month}/${_followUpDate!.year}'
                      : context.tr('medical_records.select_date'),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectFollowUpDate,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _followUpNotesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: context.tr('medical_records.follow_up_notes'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context, MedicalRecordsState state) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: state is ConsultationLoading
            ? null
            : () => _submitConsultation(context),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: AppColors.primaryColor,
        ),
        child: Text(
          context.tr('medical_records.save_consultation'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _selectFollowUpDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _followUpDate = picked);
    }
  }

  void _submitConsultation(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Parse symptoms from comma-separated string
    final symptoms = _symptomsController.text.isNotEmpty
        ? _symptomsController.text.split(',').map((s) => s.trim()).toList()
        : <String>[];

    // Build vital signs entity
    VitalSignsEntity? vitalSigns;
    if (_temperatureController.text.isNotEmpty ||
        _bloodPressureController.text.isNotEmpty ||
        _heartRateController.text.isNotEmpty) {
      vitalSigns = VitalSignsEntity(
        temperature: _temperatureController.text.isNotEmpty
            ? double.tryParse(_temperatureController.text)
            : null,
        bloodPressure: _bloodPressureController.text.isNotEmpty
            ? _bloodPressureController.text
            : null,
        heartRate: _heartRateController.text.isNotEmpty
            ? int.tryParse(_heartRateController.text)
            : null,
        respiratoryRate: _respiratoryRateController.text.isNotEmpty
            ? int.tryParse(_respiratoryRateController.text)
            : null,
        oxygenSaturation: _oxygenSaturationController.text.isNotEmpty
            ? int.tryParse(_oxygenSaturationController.text)
            : null,
        weight: _weightController.text.isNotEmpty
            ? double.tryParse(_weightController.text)
            : null,
        height: _heightController.text.isNotEmpty
            ? double.tryParse(_heightController.text)
            : null,
      );
    }

    // Build medical note entity
    final medicalNote = MedicalNoteEntity(
      symptoms: symptoms.isNotEmpty ? symptoms : null,
      diagnosis: _diagnosisController.text.isNotEmpty
          ? _diagnosisController.text
          : null,
      physicalExamination: _physicalExamController.text.isNotEmpty
          ? _physicalExamController.text
          : null,
      vitalSigns: vitalSigns,
      labResults: _labResultsController.text.isNotEmpty
          ? _labResultsController.text
          : null,
      additionalNotes: _additionalNotesController.text.isNotEmpty
          ? _additionalNotesController.text
          : null,
    );

    context.read<MedicalRecordsBloc>().add(
          CreateConsultationEvent(
            appointmentId: widget.appointmentId,
            chiefComplaint: _chiefComplaintController.text,
            medicalNote: medicalNote,
            consultationType: _consultationType,
            requiresFollowUp: _requiresFollowUp,
            followUpDate: _followUpDate,
            followUpNotes: _followUpNotesController.text.isNotEmpty
                ? _followUpNotesController.text
                : null,
          ),
        );
  }
}
