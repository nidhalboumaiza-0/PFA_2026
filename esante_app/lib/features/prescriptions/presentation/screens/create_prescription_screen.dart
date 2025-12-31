import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/models/prescription_model.dart';
import '../../domain/usecases/create_prescription.dart';
import '../bloc/prescription_bloc.dart';

class CreatePrescriptionScreen extends StatefulWidget {
  final String consultationId;
  final String patientId;
  final String doctorId;
  final String patientName;

  const CreatePrescriptionScreen({
    super.key,
    required this.consultationId,
    required this.patientId,
    required this.doctorId,
    required this.patientName,
  });

  @override
  State<CreatePrescriptionScreen> createState() => _CreatePrescriptionScreenState();
}

class _CreatePrescriptionScreenState extends State<CreatePrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<MedicationModel> _medications = [];

  // Current Medication Controllers
  final _medNameController = TextEditingController();
  final _medFormController = TextEditingController();
  final _medDosageController = TextEditingController();
  final _medFreqController = TextEditingController();
  final _medDurationController = TextEditingController();
  final _medInstructionsController = TextEditingController();

  // General Prescription Controllers
  final _generalInstructionsController = TextEditingController();
  final _warningsController = TextEditingController();

  @override
  void dispose() {
    _medNameController.dispose();
    _medFormController.dispose();
    _medDosageController.dispose();
    _medFreqController.dispose();
    _medDurationController.dispose();
    _medInstructionsController.dispose();
    _generalInstructionsController.dispose();
    _warningsController.dispose();
    super.dispose();
  }

  void _addMedication() {
    if (_medNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medication name is required')),
      );
      return;
    }

    setState(() {
      _medications.add(MedicationModel(
        name: _medNameController.text,
        form: _medFormController.text,
        dosage: _medDosageController.text,
        frequency: _medFreqController.text,
        duration: _medDurationController.text,
        instructions: _medInstructionsController.text.isNotEmpty
            ? _medInstructionsController.text
            : null,
      ));

      // Clear medication inputs
      _medNameController.clear();
      _medFormController.clear();
      _medDosageController.clear();
      _medFreqController.clear();
      _medDurationController.clear();
      _medInstructionsController.clear();
    });
  }

  void _removeMedication(int index) {
    setState(() {
      _medications.removeAt(index);
    });
  }

  void _submitPrescription() {
    if (_medications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one medication')),
      );
      return;
    }

    final params = CreatePrescriptionParams(
      consultationId: widget.consultationId,
      patientId: widget.patientId,
      doctorId: widget.doctorId,
      medications: _medications,
      generalInstructions: _generalInstructionsController.text.isNotEmpty
          ? _generalInstructionsController.text
          : null,
      specialWarnings: _warningsController.text.isNotEmpty
          ? _warningsController.text
          : null,
    );

    context.read<PrescriptionBloc>().add(CreatePrescription(params: params));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PrescriptionBloc>(),
      child: BlocListener<PrescriptionBloc, PrescriptionState>(
        listener: (context, state) {
          if (state is PrescriptionCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Prescription created successfully'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pop(context); // Go back to appointment details
          } else if (state is PrescriptionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: Scaffold(
          appBar: CustomAppBar(
            title: 'New Prescription',
            showBackButton: true,
            onBackPressed: () => Navigator.pop(context),
          ),
          body: Builder(
            builder: (context) {
              return SingleChildScrollView(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
              // Header Info
              InfoCard(
                title: 'Patient Information',
                icon: Icons.person_outline,
                items: [
                  InfoItem(
                    label: 'Name',
                    value: widget.patientName,
                    icon: Icons.person,
                  ),
                ],
              ),
              SizedBox(height: 24.h),

              // Add Medication Form
              Text(
                'Add Medication',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              SizedBox(height: 16.h),
              _buildMedicationForm(),
              SizedBox(height: 16.h),
              CustomButton(
                text: 'Add Medication',
                onPressed: _addMedication,
                isOutlined: true,
                icon: Icons.add,
              ),

              if (_medications.isNotEmpty) ...[
                SizedBox(height: 24.h),
                Text(
                  'Prescribed Medications (${_medications.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: 12.h),
                ..._medications.asMap().entries.map((entry) {
                  final index = entry.key;
                  final med = entry.value;
                  return _buildMedicationCard(index, med);
                }),
              ],

              SizedBox(height: 24.h),
              
              // General Instructions
              CustomTextField(
                label: 'General Instructions',
                controller: _generalInstructionsController,
                hintText: 'e.g. Take with food, drink plenty of water',
                maxLines: 3,
              ),
              SizedBox(height: 16.h),
               CustomTextField(
                label: 'Special Warnings',
                controller: _warningsController,
                hintText: 'e.g. May cause drowsiness',
                maxLines: 2,
              ),

              SizedBox(height: 32.h),
              
              // Submit Button
              BlocBuilder<PrescriptionBloc, PrescriptionState>(
                builder: (context, state) {
                  return CustomButton(
                    text: 'Create Prescription',
                    onPressed: state is PrescriptionCreating ? null : _submitPrescription,
                    isLoading: state is PrescriptionCreating,
                  );
                },
              ),
              SizedBox(height: 32.h),
            ],
          ),
        );
      }),
    ),
      ),
    );
  }

  Widget _buildMedicationForm() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          CustomTextField(
            label: 'Medication Name *',
            controller: _medNameController,
            hintText: 'e.g. Amoxicillin',
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Form',
                  controller: _medFormController,
                  hintText: 'e.g. Tablet',
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: CustomTextField(
                  label: 'Dosage',
                  controller: _medDosageController,
                  hintText: 'e.g. 500mg',
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Frequency',
                  controller: _medFreqController,
                  hintText: 'e.g. 3x daily',
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: CustomTextField(
                  label: 'Duration',
                  controller: _medDurationController,
                  hintText: 'e.g. 7 days',
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          CustomTextField(
            label: 'Instructions',
            controller: _medInstructionsController,
            hintText: 'Specific instructions for this medication',
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationCard(int index, MedicationModel med) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(Icons.medication, color: AppColors.primary, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${med.dosage} • ${med.frequency} • ${med.duration}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12.sp,
                  ),
                ),
                if (med.instructions != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    med.instructions!,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12.sp,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () => _removeMedication(index),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: 20.sp,
          ),
        ],
      ),
    );
  }
}
