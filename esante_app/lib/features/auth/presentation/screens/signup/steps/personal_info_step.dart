import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../../core/widgets/widgets.dart';
import '../signup_controller.dart';

class PersonalInfoStep extends StatefulWidget {
  final SignupController controller;
  final VoidCallback onContinue;

  const PersonalInfoStep({
    super.key,
    required this.controller,
    required this.onContinue,
  });

  @override
  State<PersonalInfoStep> createState() => _PersonalInfoStepState();
}

class _PersonalInfoStepState extends State<PersonalInfoStep> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;

  String? _dobError;
  String? _genderError;

  @override
  void initState() {
    super.initState();
    final data = widget.controller.data;
    _firstNameController = TextEditingController(text: data.firstName);
    _lastNameController = TextEditingController(text: data.lastName);
    _phoneController = TextEditingController(text: data.phone);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveData() {
    final data = widget.controller.data;
    data.firstName = _firstNameController.text;
    data.lastName = _lastNameController.text;
    data.phone = _phoneController.text;
  }

  bool _validate() {
    _saveData();
    
    if (!(_formKey.currentState?.validate() ?? false)) {
      return false;
    }

    final data = widget.controller.data;
    bool isValid = true;

    // Patient-specific validation
    if (data.role == UserRoleOption.patient) {
      if (data.dateOfBirth == null) {
        setState(() => _dobError = 'Please select your date of birth');
        isValid = false;
      } else {
        setState(() => _dobError = null);
      }

      if (data.gender == null) {
        setState(() => _genderError = 'Please select your gender');
        isValid = false;
      } else {
        setState(() => _genderError = null);
      }
    }

    return isValid;
  }

  void _onContinue() {
    if (_validate()) {
      widget.onContinue();
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.controller.data;
    final isPatient = data.role == UserRoleOption.patient;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              controller: _firstNameController,
              label: 'First Name',
              hintText: 'Enter your first name',
              prefixIcon: Icons.person_outline,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your first name';
                }
                if (value.length < 2) {
                  return 'First name must be at least 2 characters';
                }
                return null;
              },
            ),
            SizedBox(height: 20.h),
            CustomTextField(
              controller: _lastNameController,
              label: 'Last Name',
              hintText: 'Enter your last name',
              prefixIcon: Icons.person_outline,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your last name';
                }
                if (value.length < 2) {
                  return 'Last name must be at least 2 characters';
                }
                return null;
              },
            ),
            SizedBox(height: 20.h),
            CustomTextField(
              controller: _phoneController,
              label: 'Phone Number',
              hintText: 'Enter your phone number',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                if (value.length < 8) {
                  return 'Please enter a valid phone number';
                }
                return null;
              },
            ),
            // Patient-specific fields
            if (isPatient) ...[
              SizedBox(height: 20.h),
              DateOfBirthPicker(
                selectedDate: data.dateOfBirth,
                onDateSelected: (date) {
                  setState(() {
                    data.dateOfBirth = date;
                    _dobError = null;
                  });
                },
                errorText: _dobError,
              ),
              SizedBox(height: 20.h),
              GenderDropdown(
                value: data.gender,
                onChanged: (value) {
                  setState(() {
                    data.gender = value;
                    _genderError = null;
                  });
                },
                errorText: _genderError,
              ),
            ],
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
