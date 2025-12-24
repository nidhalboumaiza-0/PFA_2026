import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/features/authentication/domain/entities/medecin_entity.dart';
import 'package:medical_app/features/referral/presentation/bloc/referral_bloc.dart';
import 'package:medical_app/injection_container.dart';

class CreateReferralPage extends StatefulWidget {
  final String? preselectedPatientId;
  final String? preselectedPatientName;

  const CreateReferralPage({
    super.key,
    this.preselectedPatientId,
    this.preselectedPatientName,
  });

  @override
  State<CreateReferralPage> createState() => _CreateReferralPageState();
}

class _CreateReferralPageState extends State<CreateReferralPage> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _symptomsController = TextEditingController();
  final _relevantHistoryController = TextEditingController();
  final _currentMedicationsController = TextEditingController();
  final _specificConcernsController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedPatientId;
  String? _selectedPatientName;
  String? _selectedSpecialty;
  MedecinEntity? _selectedSpecialist;
  String _urgency = 'routine';
  bool _includeFullHistory = true;

  final List<String> _specialties = [
    'Cardiology',
    'Dermatology',
    'Endocrinology',
    'Gastroenterology',
    'Neurology',
    'Oncology',
    'Ophthalmology',
    'Orthopedics',
    'Pediatrics',
    'Psychiatry',
    'Pulmonology',
    'Rheumatology',
    'Urology',
    'General Medicine',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.preselectedPatientId != null) {
      _selectedPatientId = widget.preselectedPatientId;
      _selectedPatientName = widget.preselectedPatientName;
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _diagnosisController.dispose();
    _symptomsController.dispose();
    _relevantHistoryController.dispose();
    _currentMedicationsController.dispose();
    _specificConcernsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ReferralBloc>(),
      child: BlocListener<ReferralBloc, ReferralState>(
        listener: (context, state) {
          if (state is ReferralCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.tr('referral.referral_created'))),
            );
            Navigator.pop(context);
          } else if (state is ReferralError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is SpecialistsLoaded) {
            _showSpecialistSelectionDialog(context, state.specialists);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(context.tr('referral.create_referral')),
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Patient Selection
                  _buildSectionTitle(context.tr('referral.select_patient')),
                  _buildPatientSelector(),
                  const SizedBox(height: 24),

                  // Specialty Selection
                  _buildSectionTitle(context.tr('referral.specialty')),
                  _buildSpecialtyDropdown(),
                  const SizedBox(height: 24),

                  // Specialist Selection
                  _buildSectionTitle(context.tr('referral.select_specialist')),
                  _buildSpecialistSelector(),
                  const SizedBox(height: 24),

                  // Urgency
                  _buildSectionTitle(context.tr('referral.urgency')),
                  _buildUrgencySelector(),
                  const SizedBox(height: 24),

                  // Reason
                  _buildSectionTitle(context.tr('referral.reason')),
                  TextFormField(
                    controller: _reasonController,
                    decoration: InputDecoration(
                      hintText: context.tr('referral.reason_hint'),
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return context.tr('referral.field_required');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Diagnosis
                  _buildSectionTitle(context.tr('referral.diagnosis')),
                  TextFormField(
                    controller: _diagnosisController,
                    decoration: InputDecoration(
                      hintText: context.tr('referral.diagnosis_hint'),
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),

                  // Symptoms
                  _buildSectionTitle(context.tr('referral.symptoms')),
                  TextFormField(
                    controller: _symptomsController,
                    decoration: InputDecoration(
                      hintText: context.tr('referral.symptoms_hint'),
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),

                  // Relevant History
                  _buildSectionTitle(context.tr('referral.relevant_history')),
                  TextFormField(
                    controller: _relevantHistoryController,
                    decoration: InputDecoration(
                      hintText: context.tr('referral.relevant_history_hint'),
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // Current Medications
                  _buildSectionTitle(context.tr('referral.current_medications')),
                  TextFormField(
                    controller: _currentMedicationsController,
                    decoration: InputDecoration(
                      hintText: context.tr('referral.current_medications_hint'),
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),

                  // Specific Concerns
                  _buildSectionTitle(context.tr('referral.specific_concerns')),
                  TextFormField(
                    controller: _specificConcernsController,
                    decoration: InputDecoration(
                      hintText: context.tr('referral.specific_concerns_hint'),
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),

                  // Include Full History
                  CheckboxListTile(
                    value: _includeFullHistory,
                    onChanged: (value) {
                      setState(() => _includeFullHistory = value ?? true);
                    },
                    title: Text(context.tr('referral.include_full_history')),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 24),

                  // Notes
                  _buildSectionTitle(context.tr('referral.referral_notes')),
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      hintText: context.tr('referral.referral_notes_hint'),
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  BlocBuilder<ReferralBloc, ReferralState>(
                    builder: (context, state) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: state is ReferralLoading
                              ? null
                              : () => _submitReferral(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: state is ReferralLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  context.tr('referral.create_referral'),
                                  style: const TextStyle(fontSize: 16),
                                ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildPatientSelector() {
    // TODO: Implement patient selection from doctor's patients list
    // For now, using a text display or placeholder
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.person, color: Colors.grey[600]),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _selectedPatientName ?? context.tr('referral.select_patient'),
              style: TextStyle(
                color: _selectedPatientName != null
                    ? Colors.black
                    : Colors.grey[600],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Show patient search/selection dialog
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.tr('referral.patient_selection_coming_soon')),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialtyDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedSpecialty,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        hintText: context.tr('referral.select_specialty'),
      ),
      items: _specialties.map((specialty) {
        return DropdownMenuItem(
          value: specialty,
          child: Text(specialty),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedSpecialty = value;
          _selectedSpecialist = null; // Reset specialist when specialty changes
        });
      },
      validator: (value) {
        if (value == null) {
          return context.tr('referral.please_select_specialty');
        }
        return null;
      },
    );
  }

  Widget _buildSpecialistSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.medical_services, color: Colors.grey[600]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedSpecialist != null
                      ? '${_selectedSpecialist!.name} ${_selectedSpecialist!.lastName}'
                      : context.tr('referral.select_specialist'),
                  style: TextStyle(
                    color: _selectedSpecialist != null
                        ? Colors.black
                        : Colors.grey[600],
                  ),
                ),
                if (_selectedSpecialist?.speciality != null)
                  Text(
                    _selectedSpecialist!.speciality!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          BlocBuilder<ReferralBloc, ReferralState>(
            builder: (context, state) {
              return IconButton(
                icon: state is ReferralLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                onPressed: state is ReferralLoading || _selectedSpecialty == null
                    ? null
                    : () {
                        context.read<ReferralBloc>().add(
                              SearchSpecialistsEvent(
                                specialty: _selectedSpecialty!,
                              ),
                            );
                      },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUrgencySelector() {
    return Row(
      children: [
        Expanded(
          child: _UrgencyOption(
            label: context.tr('referral.routine'),
            value: 'routine',
            groupValue: _urgency,
            onChanged: (value) => setState(() => _urgency = value!),
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _UrgencyOption(
            label: context.tr('referral.urgent'),
            value: 'urgent',
            groupValue: _urgency,
            onChanged: (value) => setState(() => _urgency = value!),
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _UrgencyOption(
            label: context.tr('referral.emergency'),
            value: 'emergency',
            groupValue: _urgency,
            onChanged: (value) => setState(() => _urgency = value!),
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  void _showSpecialistSelectionDialog(
    BuildContext context,
    List<MedecinEntity> specialists,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('referral.select_specialist')),
        content: SizedBox(
          width: double.maxFinite,
          child: specialists.isEmpty
              ? Center(
                  child: Text('${context.tr('referral.no_specialists_found')} $_selectedSpecialty'),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: specialists.length,
                  itemBuilder: (context, index) {
                    final specialist = specialists[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          '${specialist.name.substring(0, 1)}${specialist.lastName.substring(0, 1)}',
                        ),
                      ),
                      title: Text(
                        '${specialist.name} ${specialist.lastName}',
                      ),
                      subtitle: Text(specialist.speciality ?? ''),
                      onTap: () {
                        setState(() => _selectedSpecialist = specialist);
                        Navigator.pop(dialogContext);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.tr('common.cancel')),
          ),
        ],
      ),
    );
  }

  void _submitReferral(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('referral.select_patient'))),
      );
      return;
    }

    if (_selectedSpecialist == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('referral.select_specialist'))),
      );
      return;
    }

    final symptoms = _symptomsController.text.isNotEmpty
        ? _symptomsController.text.split(',').map((s) => s.trim()).toList()
        : null;

    context.read<ReferralBloc>().add(
          CreateReferralEvent(
            targetDoctorId: _selectedSpecialist!.id!,
            patientId: _selectedPatientId!,
            reason: _reasonController.text,
            specialty: _selectedSpecialty!,
            urgency: _urgency,
            diagnosis: _diagnosisController.text.isNotEmpty
                ? _diagnosisController.text
                : null,
            symptoms: symptoms,
            relevantHistory: _relevantHistoryController.text.isNotEmpty
                ? _relevantHistoryController.text
                : null,
            currentMedications: _currentMedicationsController.text.isNotEmpty
                ? _currentMedicationsController.text
                : null,
            specificConcerns: _specificConcernsController.text.isNotEmpty
                ? _specificConcernsController.text
                : null,
            includeFullHistory: _includeFullHistory,
            referralNotes: _notesController.text.isNotEmpty
                ? _notesController.text
                : null,
          ),
        );
  }
}

class _UrgencyOption extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;
  final Color color;

  const _UrgencyOption({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;

    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? color : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
