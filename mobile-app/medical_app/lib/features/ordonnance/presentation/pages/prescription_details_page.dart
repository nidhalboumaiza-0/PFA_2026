import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/app_colors.dart';
import '../../domain/entities/prescription_entity.dart';
import '../bloc/prescription_bloc.dart';

class PrescriptionDetailsPage extends StatefulWidget {
  final PrescriptionEntity prescription;
  final bool isDoctor;

  const PrescriptionDetailsPage({
    super.key,
    required this.prescription,
    this.isDoctor = false,
  });

  @override
  State<PrescriptionDetailsPage> createState() =>
      _PrescriptionDetailsPageState();
}

class _PrescriptionDetailsPageState extends State<PrescriptionDetailsPage> {
  late PrescriptionBloc _prescriptionBloc;
  bool _isEditing = false;
  final _noteController = TextEditingController();
  final List<MedicationEntity> _medications = [];

  // Controllers for adding new medications
  final _medicationNameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _instructionsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _prescriptionBloc = BlocProvider.of<PrescriptionBloc>(context);
    _noteController.text = widget.prescription.generalInstructions ?? '';
    _medications.addAll(widget.prescription.medications);
  }

  @override
  void dispose() {
    _noteController.dispose();
    _medicationNameController.dispose();
    _dosageController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _addMedication() {
    if (_medicationNameController.text.isNotEmpty &&
        _dosageController.text.isNotEmpty &&
        _instructionsController.text.isNotEmpty) {
      setState(() {
        _medications.add(
          MedicationEntity(
            medicationName: _medicationNameController.text,
            dosage: _dosageController.text,
            frequency: '',
            duration: '',
            instructions: _instructionsController.text,
          ),
        );
        _medicationNameController.clear();
        _dosageController.clear();
        _instructionsController.clear();
      });
    }
  }

  void _removeMedication(int index) {
    setState(() {
      _medications.removeAt(index);
    });
  }

  void _savePrescription() {
    final editedPrescription = PrescriptionEntity(
      id: widget.prescription.id,
      consultationId: widget.prescription.consultationId,
      patientId: widget.prescription.patientId,
      patientName: widget.prescription.patientName,
      doctorId: widget.prescription.doctorId,
      doctorName: widget.prescription.doctorName,
      prescriptionDate: widget.prescription.prescriptionDate, // Keep original date
      medications: _medications,
      generalInstructions: _noteController.text.isNotEmpty ? _noteController.text : null,
      specialWarnings: widget.prescription.specialWarnings,
      isLocked: widget.prescription.isLocked,
      lockedAt: widget.prescription.lockedAt,
      canEditUntil: widget.prescription.canEditUntil,
      modificationHistory: widget.prescription.modificationHistory,
      status: widget.prescription.status,
      pharmacyName: widget.prescription.pharmacyName,
      pharmacyAddress: widget.prescription.pharmacyAddress,
      createdBy: widget.prescription.createdBy,
      createdAt: widget.prescription.createdAt,
      updatedAt: DateTime.now(),
    );

    _prescriptionBloc.add(EditPrescription(prescription: editedPrescription));
  }

  @override
  Widget build(BuildContext context) {
    final bool canEdit = widget.isDoctor;

    return BlocListener<PrescriptionBloc, PrescriptionState>(
      listener: (context, state) {
        if (state is PrescriptionEdited) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.tr('prescription_edited_success'),
                style: GoogleFonts.raleway(),
              ),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {
            _isEditing = false;
          });
        } else if (state is PrescriptionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.tr('prescription_error').replaceAll('{0}', state.message),
                style: GoogleFonts.raleway(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            context.tr('prescription_title'),
            style: GoogleFonts.raleway(
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppColors.primaryColor,
          actions: [
            if (canEdit && !_isEditing)
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
              ),
          ],
        ),
        body: BlocBuilder<PrescriptionBloc, PrescriptionState>(
          builder: (context, state) {
            if (state is PrescriptionLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Prescription info card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.medical_services,
                                color: AppColors.primaryColor,
                                size: 24.sp,
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.tr('prescription_date'),
                                      style: GoogleFonts.raleway(
                                        fontSize: 14.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      DateFormat(
                                        'dd MMMM yyyy, HH:mm',
                                      ).format(widget.prescription.prescriptionDate),
                                      style: GoogleFonts.raleway(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Patient',
                                      style: GoogleFonts.raleway(
                                        fontSize: 14.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      widget.prescription.patientName ?? 'N/A',
                                      style: GoogleFonts.raleway(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Médecin',
                                      style: GoogleFonts.raleway(
                                        fontSize: 14.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      widget.prescription.doctorName ?? 'N/A',
                                      style: GoogleFonts.raleway(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Medications section
                  Text(
                    context.tr('medications'),
                    style: GoogleFonts.raleway(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // List of medications
                  ...List.generate(
                    _medications.length,
                    (index) => _buildMedicationCard(
                      _medications[index],
                      index: index,
                      canRemove: _isEditing,
                    ),
                  ),

                  // Add medication form (only in edit mode)
                  if (_isEditing) _buildAddMedicationForm(),

                  SizedBox(height: 20.h),

                  // Notes section
                  Text(
                    context.tr('notes'),
                    style: GoogleFonts.raleway(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),

                  if (_isEditing)
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
                            hintText:
                                context.tr('prescription.notes_hint'),
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
                    )
                  else
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Text(
                          widget.prescription.generalInstructions?.isNotEmpty == true
                              ? widget.prescription.generalInstructions!
                              : context.tr('prescription.no_notes'),
                          style: GoogleFonts.raleway(
                            fontSize: 14.sp,
                            color:
                                widget.prescription.generalInstructions?.isNotEmpty == true
                                    ? Colors.black87
                                    : Colors.grey,
                            fontStyle:
                                widget.prescription.generalInstructions?.isNotEmpty == true
                                    ? FontStyle.normal
                                    : FontStyle.italic,
                          ),
                        ),
                      ),
                    ),

                  // Edit mode save button
                  if (_isEditing)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _isEditing = false;
                                // Reset to original data
                                _medications.clear();
                                _medications.addAll(
                                  widget.prescription.medications,
                                );
                                _noteController.text =
                                    widget.prescription.generalInstructions ?? '';
                              });
                            },
                            icon: Icon(Icons.cancel, color: Colors.white),
                            label: Text(
                              context.tr('common.cancel'),
                              style: GoogleFonts.raleway(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              padding: EdgeInsets.symmetric(
                                horizontal: 24.w,
                                vertical: 12.h,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _savePrescription,
                            icon: Icon(Icons.save, color: Colors.white),
                            label: Text(
                              context.tr('common.save'),
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
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMedicationCard(
    MedicationEntity medication, {
    required int index,
    bool canRemove = false,
  }) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    medication.medicationName,
                    style: GoogleFonts.raleway(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (canRemove)
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red, size: 20.sp),
                    onPressed: () => _removeMedication(index),
                  ),
              ],
            ),
            Divider(height: 20.h),
            Row(
              children: [
                Icon(Icons.medication, size: 18.sp, color: Colors.grey[600]),
                SizedBox(width: 8.w),
                Text(
                  'Dosage: ',
                  style: GoogleFonts.raleway(
                    fontSize: 14.sp,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  medication.dosage,
                  style: GoogleFonts.raleway(fontSize: 14.sp),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.description, size: 18.sp, color: Colors.grey[600]),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${context.tr('prescription.instructions')}: ',
                        style: GoogleFonts.raleway(
                          fontSize: 14.sp,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        medication.instructions ?? 'N/A',
                        style: GoogleFonts.raleway(fontSize: 14.sp),
                      ),
                    ],
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
      margin: EdgeInsets.only(top: 12.h, bottom: 12.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('prescription.add_medication'),
              style: GoogleFonts.raleway(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
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
              ),
              maxLines: 2,
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
    );
  }
}
