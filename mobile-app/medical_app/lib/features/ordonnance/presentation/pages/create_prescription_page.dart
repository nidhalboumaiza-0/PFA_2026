import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/l10n/translator.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/custom_snack_bar.dart';
import '../../../../core/services/api_service.dart';
import '../../../authentication/domain/entities/patient_entity.dart';
import '../../../rendez_vous/domain/entities/rendez_vous_entity.dart';
import '../../domain/entities/prescription_entity.dart';
import '../../data/models/medication_model.dart';

class CreatePrescriptionPage extends StatefulWidget {
  final RendezVousEntity appointment;
  final PatientEntity? patient;
  final PrescriptionEntity? existingPrescription;

  const CreatePrescriptionPage({
    super.key,
    required this.appointment,
    this.patient,
    this.existingPrescription,
  });

  @override
  State<CreatePrescriptionPage> createState() => _CreatePrescriptionPageState();
}

class _CreatePrescriptionPageState extends State<CreatePrescriptionPage> {
  final _formKey = GlobalKey<FormState>();
  final _medicationNameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _durationController = TextEditingController();
  final _noteController = TextEditingController();
  final List<MedicationModel> _medications = [];
  bool _isSaving = false;
  bool _isEditing = false;
  String? _prescriptionId;
  DateTime _expiresAt = DateTime.now().add(
    const Duration(days: 30),
  ); // Default 30 days

  @override
  void initState() {
    super.initState();
    _loadExistingPrescription();
  }

  void _loadExistingPrescription() {
    if (widget.existingPrescription != null) {
      setState(() {
        _isEditing = true;
        _prescriptionId = widget.existingPrescription!.id;
        _noteController.text = widget.existingPrescription!.generalInstructions ?? '';
        if (widget.existingPrescription!.canEditUntil != null) {
          _expiresAt = widget.existingPrescription!.canEditUntil!;
        }

        // Load medications from existing prescription
        for (var med in widget.existingPrescription!.medications) {
          _medications.add(MedicationModel.fromEntity(med));
        }
      });
    }
  }

  @override
  void dispose() {
    _medicationNameController.dispose();
    _dosageController.dispose();
    _instructionsController.dispose();
    _frequencyController.dispose();
    _durationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _addMedication() {
    if (_medicationNameController.text.isEmpty ||
        _dosageController.text.isEmpty ||
        _instructionsController.text.isEmpty) {
      showWarningSnackBar(
        context,
        context.tr('prescription.fill_all_medication_fields'),
      );
      return;
    }

    setState(() {
      _medications.add(
        MedicationModel(
          medicationName: _medicationNameController.text,
          dosage: _dosageController.text,
          instructions: _instructionsController.text,
          frequency: _frequencyController.text.isNotEmpty
              ? _frequencyController.text
              : '',
          duration: _durationController.text.isNotEmpty
              ? _durationController.text
              : '',
        ),
      );
      _medicationNameController.clear();
      _dosageController.clear();
      _instructionsController.clear();
      _frequencyController.clear();
      _durationController.clear();
    });
  }

  void _removeMedication(int index) {
    setState(() {
      _medications.removeAt(index);
    });
  }

  void _editMedication(MedicationModel medication, int index) {
    _medicationNameController.text = medication.medicationName;
    _dosageController.text = medication.dosage;
    _instructionsController.text = medication.instructions ?? '';
    _frequencyController.text = medication.frequency;
    _durationController.text = medication.duration;

    _removeMedication(index);

    // Scroll to medication form
    Future.delayed(Duration(milliseconds: 100), () {
      Scrollable.ensureVisible(
        _formKey.currentContext!,
        duration: Duration(milliseconds: 300),
      );
    });
  }

  Future<void> _savePrescription() async {
    if (_medications.isEmpty) {
      showWarningSnackBar(context, context.tr('prescription.add_at_least_one'));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Generate ID if it's a new prescription, otherwise use existing
      final prescriptionId = _isEditing ? _prescriptionId! : const Uuid().v4();
      
      // Use the Express API instead of directly updating Firestore
      if (_isEditing) {
        await ApiService.patchRequest(
          '${ApiService.baseUrl}/prescriptions/$prescriptionId',
          {
            'medications': _medications.map((m) => m.toJson()).toList(),
            'note': _noteController.text,
            'expiresAt': _expiresAt.toIso8601String(),
          },
        );
      } else {
        await ApiService.postRequest(
          '${ApiService.baseUrl}/prescriptions',
          {
            'appointmentId': widget.appointment.id,
            'medications': _medications.map((m) => m.toJson()).toList(),
            'note': _noteController.text,
            'expiresAt': _expiresAt.toIso8601String(),
          },
        );
      }

      if (mounted) {
        showSuccessSnackBar(
          context,
          _isEditing
              ? context.tr('prescription.updated_successfully')
              : context.tr('prescription.saved_successfully'),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error saving prescription: $e');
      if (mounted) {
        showErrorSnackBar(context, '${context.tr('prescription.error_saving')}: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? context.tr('prescription.edit_prescription') : context.tr('prescription.new_prescription'),
          style: GoogleFonts.raleway(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _savePrescription,
            child:
                _isSaving
                    ? SizedBox(
                      width: 24.w,
                      height: 24.h,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : Text(
                      context.tr('common.save'),
                      style: GoogleFonts.raleway(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient information card
              _buildPatientInfoCard(),
              SizedBox(height: 20.h),

              // Medication list
              Text(
                context.tr('prescription.medications'),
                style: GoogleFonts.raleway(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8.h),

              // Existing medications
              ...List.generate(
                _medications.length,
                (index) => _buildMedicationItem(_medications[index], index),
              ),

              // Add medication form
              _buildAddMedicationForm(),
              SizedBox(height: 20.h),

              // Additional notes
              Text(
                context.tr('prescription.additional_notes'),
                style: GoogleFonts.raleway(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8.h),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: TextFormField(
                    controller: _noteController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: context.tr('prescription.notes_hint'),
                      border: InputBorder.none,
                      hintStyle: GoogleFonts.raleway(
                        fontSize: 14.sp,
                        color: Colors.grey,
                      ),
                    ),
                    style: GoogleFonts.raleway(
                      fontSize: 14.sp,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 100.h), // Extra space at bottom for keyboard
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _savePrescription,
        icon: Icon(Icons.save, color: Colors.white),
        label: Text(
          context.tr('common.save'),
          style: GoogleFonts.raleway(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildPatientInfoCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 50.h,
                  width: 50.w,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(Icons.person, color: Colors.white, size: 30.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.appointment.patientName ?? context.tr('common.unknown_patient'),
                        style: GoogleFonts.raleway(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        DateFormat(
                          'dd/MM/yyyy à HH:mm',
                        ).format(widget.appointment.startDate),
                        style: GoogleFonts.raleway(
                          fontSize: 14.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.patient != null &&
                widget.patient!.antecedent != null &&
                widget.patient!.antecedent!.isNotEmpty) ...[
              Divider(height: 24.h),
              Text(
                context.tr('prescription.medical_history'),
                style: GoogleFonts.raleway(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                widget.patient!.antecedent!,
                style: GoogleFonts.raleway(
                  fontSize: 13.sp,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationItem(MedicationModel medication, int index) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    medication.medicationName,
                    style: GoogleFonts.raleway(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    color: AppColors.primaryColor,
                    size: 22.sp,
                  ),
                  tooltip: context.tr('common.edit'),
                  onPressed: () => _editMedication(medication, index),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 22.sp,
                  ),
                  tooltip: context.tr('common.delete'),
                  onPressed: () => _removeMedication(index),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(
                  Icons.medical_services_outlined,
                  size: 16.sp,
                  color: Colors.blueGrey,
                ),
                SizedBox(width: 6.w),
                Text(
                  "${context.tr('prescription.dosage')}: ${medication.dosage}",
                  style: GoogleFonts.raleway(
                    fontSize: 14.sp,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 16.sp,
                  color: Colors.blueGrey,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    "${context.tr('prescription.instructions')}: ${medication.instructions}",
                    style: GoogleFonts.raleway(
                      fontSize: 14.sp,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMedicationForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('prescription.add_medication'),
                style: GoogleFonts.raleway(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _medicationNameController,
                decoration: InputDecoration(
                  labelText: context.tr('prescription.medication_name'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 12.h,
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _dosageController,
                decoration: InputDecoration(
                  labelText: context.tr('prescription.dosage'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 12.h,
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _instructionsController,
                decoration: InputDecoration(
                  labelText: context.tr('prescription.instructions'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 12.h,
                  ),
                ),
                maxLines: 2,
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _frequencyController,
                decoration: InputDecoration(
                  labelText: context.tr('prescription.frequency'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 12.h,
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _durationController,
                decoration: InputDecoration(
                  labelText: context.tr('prescription.duration'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 12.h,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _addMedication,
                  icon: Icon(Icons.add, color: Colors.white),
                  label: Text(
                    context.tr('prescription.add'),
                    style: GoogleFonts.raleway(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 12.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
