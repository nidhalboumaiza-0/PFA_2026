import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../../../core/widgets/widgets.dart';
import '../../../../../profile/presentation/widgets/location_picker_card.dart';
import '../../../../domain/entities/doctor_profile_entity.dart';
import '../signup_controller.dart';

class DoctorProfessionalStep extends StatefulWidget {
  final SignupController controller;
  final VoidCallback onContinue;

  const DoctorProfessionalStep({
    super.key,
    required this.controller,
    required this.onContinue,
  });

  @override
  State<DoctorProfessionalStep> createState() => _DoctorProfessionalStepState();
}

class _DoctorProfessionalStepState extends State<DoctorProfessionalStep> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _licenseController;
  late final TextEditingController _yearsController;
  late final TextEditingController _clinicController;
  late final TextEditingController _cityController;
  late final TextEditingController _countryController;
  late final TextEditingController _consultationFeeController;
  late final TextEditingController _languagesController;
  late final TextEditingController _aboutController;

  String? _specialtyError;
  bool _acceptsInsurance = false;

  @override
  void initState() {
    super.initState();
    final data = widget.controller.data;
    _licenseController = TextEditingController(text: data.licenseNumber);
    _yearsController = TextEditingController(
      text: data.yearsOfExperience?.toString() ?? '',
    );
    _clinicController = TextEditingController(text: data.clinicName);
    _cityController = TextEditingController(text: data.city);
    _countryController = TextEditingController(text: data.country);
    _consultationFeeController = TextEditingController(
      text: data.consultationFee?.toStringAsFixed(0) ?? '',
    );
    _languagesController = TextEditingController(text: data.languages);
    _aboutController = TextEditingController(text: data.about);
    _acceptsInsurance = data.acceptsInsurance;
  }

  @override
  void dispose() {
    _licenseController.dispose();
    _yearsController.dispose();
    _clinicController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _consultationFeeController.dispose();
    _languagesController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  void _saveData() {
    final data = widget.controller.data;
    data.licenseNumber = _licenseController.text;
    data.yearsOfExperience = int.tryParse(_yearsController.text);
    data.clinicName = _clinicController.text;
    data.city = _cityController.text;
    data.country = _countryController.text;
    data.consultationFee = double.tryParse(_consultationFeeController.text);
    data.acceptsInsurance = _acceptsInsurance;
    data.languages = _languagesController.text;
    data.about = _aboutController.text;
  }

  bool _validate() {
    _saveData();
    
    if (!(_formKey.currentState?.validate() ?? false)) {
      return false;
    }

    if (widget.controller.data.specialty == null) {
      setState(() => _specialtyError = 'Please select your specialty');
      return false;
    }
    
    setState(() => _specialtyError = null);
    return true;
  }

  void _onContinue() {
    if (_validate()) {
      widget.onContinue();
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.controller.data;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomDropdown<String>(
              label: 'Medical Specialty',
              value: data.specialty,
              items: MedicalSpecialties.list,
              onChanged: (value) {
                setState(() {
                  data.specialty = value;
                  _specialtyError = null;
                });
              },
              itemLabelBuilder: (item) => item,
              hintText: 'Select your specialty',
              errorText: _specialtyError,
              isRequired: true,
              prefixIcon: Icons.medical_services_outlined,
              isSearchable: true,
            ),
            SizedBox(height: 20.h),
            CustomTextField(
              controller: _licenseController,
              label: 'License Number',
              hintText: 'Enter your medical license number',
              prefixIcon: Icons.badge_outlined,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your license number';
                }
                return null;
              },
            ),
            SizedBox(height: 20.h),
            CustomTextField(
              controller: _yearsController,
              label: 'Years of Experience',
              hintText: 'Enter years of experience (optional)',
              prefixIcon: Icons.work_outline,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: 20.h),
            CustomTextField(
              controller: _clinicController,
              label: 'Clinic/Hospital Name',
              hintText: 'Enter clinic or hospital name (optional)',
              prefixIcon: Icons.local_hospital_outlined,
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: 20.h),
            CustomTextField(
              controller: _cityController,
              label: 'City',
              hintText: 'Enter your city',
              prefixIcon: Icons.location_city_outlined,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your city';
                }
                return null;
              },
            ),
            SizedBox(height: 20.h),
            CustomTextField(
              controller: _countryController,
              label: 'Country',
              hintText: 'Enter your country',
              prefixIcon: Icons.public_outlined,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your country';
                }
                return null;
              },
            ),
            SizedBox(height: 24.h),
            
            // Consultation & Services Section
            AppTitle(
              text: 'Consultation & Services',
              fontSize: 14.sp,
              textAlign: TextAlign.left,
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _consultationFeeController,
                    label: 'Consultation Fee *',
                    hintText: 'Fee in TND',
                    prefixIcon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Fee is required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Enter valid amount';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.health_and_safety_outlined, color: Colors.grey, size: 20.sp),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Accepts Insurance',
                                style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                              ),
                              Switch(
                                value: _acceptsInsurance,
                                onChanged: (value) {
                                  setState(() => _acceptsInsurance = value);
                                },
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            CustomTextField(
              controller: _languagesController,
              label: 'Languages',
              hintText: 'French, Arabic, English...',
              prefixIcon: Icons.language,
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: 20.h),
            CustomTextField(
              controller: _aboutController,
              label: 'About You (Optional)',
              hintText: 'Brief description of your experience and services...',
              prefixIcon: Icons.info_outline,
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),
            SizedBox(height: 24.h),
            // Clinic Location Map Picker
            AppTitle(
              text: 'Clinic Location',
              fontSize: 14.sp,
              textAlign: TextAlign.left,
            ),
            SizedBox(height: 8.h),
            AppSubtitle(
              text: 'Tap to select your clinic or hospital location on the map',
              fontSize: 12.sp,
              textAlign: TextAlign.left,
            ),
            SizedBox(height: 12.h),
            LocationPickerCard(
              latitude: widget.controller.data.clinicLatitude,
              longitude: widget.controller.data.clinicLongitude,
              onLocationSelected: (LatLng location) {
                setState(() {
                  widget.controller.data.clinicLatitude = location.latitude;
                  widget.controller.data.clinicLongitude = location.longitude;
                });
              },
            ),
            SizedBox(height: 40.h),
            CustomButton(
              text: 'Continue',
              onPressed: _onContinue,
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}
