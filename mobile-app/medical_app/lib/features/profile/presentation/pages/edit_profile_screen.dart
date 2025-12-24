import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/core/widgets/common/common_widgets.dart';
import 'package:medical_app/features/authentication/domain/entities/medecin_entity.dart';
import 'package:medical_app/features/authentication/domain/entities/patient_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medical_app/features/profile/presentation/pages/blocs/BLoC%20update%20profile/update_user_bloc.dart';
import 'package:medical_app/features/authentication/domain/entities/user_entity.dart';
import 'package:intl/intl.dart';

class EditProfileScreen extends StatefulWidget {
  final UserEntity user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _genderController;
  late TextEditingController _dateOfBirthController;
  late TextEditingController _antecedentController;
  late TextEditingController _specialityController;
  late TextEditingController _numLicenceController;
  late TextEditingController _appointmentDurationController;
  // New patient fields controllers
  late TextEditingController _bloodTypeController;
  late TextEditingController _allergiesController;
  late TextEditingController _chronicDiseasesController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyRelationshipController;
  late TextEditingController _emergencyPhoneController;
  // New doctor fields controllers (from backend schema)
  late TextEditingController _consultationFeeController;
  late TextEditingController _yearsOfExperienceController;
  late TextEditingController _aboutController;
  late TextEditingController _clinicNameController;
  late TextEditingController _clinicCityController;
  late TextEditingController _clinicCountryController;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneNumberController = TextEditingController(
      text: widget.user.phoneNumber,
    );
    _genderController = TextEditingController(text: widget.user.gender);
    _dateOfBirthController = TextEditingController(
      text:
          widget.user.dateOfBirth != null
              ? DateFormat('yyyy-MM-dd').format(widget.user.dateOfBirth!)
              : '',
    );

    // Initialize patient-specific controllers
    if (widget.user is PatientEntity) {
      final patient = widget.user as PatientEntity;
      _antecedentController = TextEditingController(
        text: patient.antecedent ?? '',
      );
      // Initialize new patient fields controllers
      _bloodTypeController = TextEditingController(
        text: patient.bloodType ?? '',
      );
      _allergiesController = TextEditingController(
        text: patient.allergies?.join(', ') ?? '',
      );
      _chronicDiseasesController = TextEditingController(
        text: patient.chronicDiseases?.join(', ') ?? '',
      );
      _emergencyNameController = TextEditingController(
        text: patient.emergencyContact?['name'] ?? '',
      );
      _emergencyRelationshipController = TextEditingController(
        text: patient.emergencyContact?['relationship'] ?? '',
      );
      _emergencyPhoneController = TextEditingController(
        text: patient.emergencyContact?['phoneNumber'] ?? '',
      );
      // Initialize empty doctor-specific controllers
      _consultationFeeController = TextEditingController();
      _yearsOfExperienceController = TextEditingController();
      _aboutController = TextEditingController();
      _clinicNameController = TextEditingController();
      _clinicCityController = TextEditingController();
      _clinicCountryController = TextEditingController();
    } else {
      _antecedentController = TextEditingController();
      // Initialize empty controllers for patient fields even if not used
      _bloodTypeController = TextEditingController();
      _allergiesController = TextEditingController();
      _chronicDiseasesController = TextEditingController();
      _emergencyNameController = TextEditingController();
      _emergencyRelationshipController = TextEditingController();
      _emergencyPhoneController = TextEditingController();
    }

    // Initialize doctor-specific controllers
    if (widget.user is MedecinEntity) {
      final doctor = widget.user as MedecinEntity;
      _specialityController = TextEditingController(
        text: doctor.speciality ?? '',
      );
      _numLicenceController = TextEditingController(
        text: doctor.numLicence ?? '',
      );
      _appointmentDurationController = TextEditingController(
        text: doctor.appointmentDuration?.toString() ?? '30',
      );
      _consultationFeeController = TextEditingController(
        text: doctor.consultationFee?.toString() ?? '',
      );
      _yearsOfExperienceController = TextEditingController(
        text: doctor.yearsOfExperience?.toString() ?? '',
      );
      _aboutController = TextEditingController(
        text: doctor.about ?? '',
      );
      _clinicNameController = TextEditingController(
        text: doctor.clinicName ?? '',
      );
      _clinicCityController = TextEditingController(
        text: doctor.clinicAddress?['city'] ?? '',
      );
      _clinicCountryController = TextEditingController(
        text: doctor.clinicAddress?['country'] ?? '',
      );
    } else {
      _specialityController = TextEditingController();
      _numLicenceController = TextEditingController();
      _appointmentDurationController = TextEditingController();
      _consultationFeeController = TextEditingController();
      _yearsOfExperienceController = TextEditingController();
      _aboutController = TextEditingController();
      _clinicNameController = TextEditingController();
      _clinicCityController = TextEditingController();
      _clinicCountryController = TextEditingController();
    }

    // Add listeners to detect changes
    _nameController.addListener(_onFieldChanged);
    _lastNameController.addListener(_onFieldChanged);
    _phoneNumberController.addListener(_onFieldChanged);
    _genderController.addListener(_onFieldChanged);
    _dateOfBirthController.addListener(_onFieldChanged);
    _antecedentController.addListener(_onFieldChanged);
    _specialityController.addListener(_onFieldChanged);
    _numLicenceController.addListener(_onFieldChanged);
    _appointmentDurationController.addListener(_onFieldChanged);
    _consultationFeeController.addListener(_onFieldChanged);
    _yearsOfExperienceController.addListener(_onFieldChanged);
    _aboutController.addListener(_onFieldChanged);
    _clinicNameController.addListener(_onFieldChanged);
    _clinicCityController.addListener(_onFieldChanged);
    _clinicCountryController.addListener(_onFieldChanged);
    // Add listeners for new patient fields
    _bloodTypeController.addListener(_onFieldChanged);
    _allergiesController.addListener(_onFieldChanged);
    _chronicDiseasesController.addListener(_onFieldChanged);
    _emergencyNameController.addListener(_onFieldChanged);
    _emergencyRelationshipController.addListener(_onFieldChanged);
    _emergencyPhoneController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    setState(() {
      _hasChanges = true;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _genderController.dispose();
    _dateOfBirthController.dispose();
    _antecedentController.dispose();
    _specialityController.dispose();
    _numLicenceController.dispose();
    _appointmentDurationController.dispose();
    // Dispose new patient fields controllers
    _bloodTypeController.dispose();
    _allergiesController.dispose();
    _chronicDiseasesController.dispose();
    _emergencyNameController.dispose();
    _emergencyRelationshipController.dispose();
    _emergencyPhoneController.dispose();
    // Dispose new doctor fields controllers
    _consultationFeeController.dispose();
    _yearsOfExperienceController.dispose();
    _aboutController.dispose();
    _clinicNameController.dispose();
    _clinicCityController.dispose();
    _clinicCountryController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      UserEntity updatedUser;
      if (widget.user is PatientEntity) {
        // Parse allergies into a list
        List<String>? allergies;
        if (_allergiesController.text.isNotEmpty) {
          allergies =
              _allergiesController.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
        }

        // Parse chronic diseases into a list
        List<String>? chronicDiseases;
        if (_chronicDiseasesController.text.isNotEmpty) {
          chronicDiseases =
              _chronicDiseasesController.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
        }

        // Create emergency contact map if any field is filled
        Map<String, String?>? emergencyContact;
        if (_emergencyNameController.text.isNotEmpty ||
            _emergencyRelationshipController.text.isNotEmpty ||
            _emergencyPhoneController.text.isNotEmpty) {
          emergencyContact = {
            'name':
                _emergencyNameController.text.isEmpty
                    ? null
                    : _emergencyNameController.text,
            'relationship':
                _emergencyRelationshipController.text.isEmpty
                    ? null
                    : _emergencyRelationshipController.text,
            'phoneNumber':
                _emergencyPhoneController.text.isEmpty
                    ? null
                    : _emergencyPhoneController.text,
          };
        }

        updatedUser = PatientEntity(
          id: widget.user.id,
          name: _nameController.text,
          lastName: _lastNameController.text,
          email: _emailController.text,
          role: widget.user.role,
          gender: _genderController.text,
          phoneNumber: _phoneNumberController.text,
          dateOfBirth:
              _dateOfBirthController.text.isNotEmpty
                  ? DateTime.tryParse(_dateOfBirthController.text)
                  : null,
          antecedent: _antecedentController.text,
          bloodType:
              _bloodTypeController.text.isEmpty
                  ? null
                  : _bloodTypeController.text,
          allergies: allergies,
          chronicDiseases: chronicDiseases,
          emergencyContact: emergencyContact,
        );
      } else {
        // Build clinic address if any fields are filled
        Map<String, dynamic>? clinicAddress;
        if (_clinicCityController.text.isNotEmpty ||
            _clinicCountryController.text.isNotEmpty ||
            _clinicNameController.text.isNotEmpty) {
          clinicAddress = {};
          if (_clinicCityController.text.isNotEmpty) {
            clinicAddress['city'] = _clinicCityController.text;
          }
          if (_clinicCountryController.text.isNotEmpty) {
            clinicAddress['country'] = _clinicCountryController.text;
          }
        }

        updatedUser = MedecinEntity(
          id: widget.user.id,
          name: _nameController.text,
          lastName: _lastNameController.text,
          email: _emailController.text,
          role: widget.user.role,
          gender: _genderController.text,
          phoneNumber: _phoneNumberController.text,
          dateOfBirth:
              _dateOfBirthController.text.isNotEmpty
                  ? DateTime.tryParse(_dateOfBirthController.text)
                  : null,
          speciality: _specialityController.text,
          numLicence: _numLicenceController.text,
          appointmentDuration:
              _appointmentDurationController.text.isNotEmpty
                  ? int.parse(_appointmentDurationController.text)
                  : 30,
          consultationFee:
              _consultationFeeController.text.isNotEmpty
                  ? double.tryParse(_consultationFeeController.text)
                  : null,
          yearsOfExperience:
              _yearsOfExperienceController.text.isNotEmpty
                  ? int.tryParse(_yearsOfExperienceController.text)
                  : null,
          about: _aboutController.text.isNotEmpty ? _aboutController.text : null,
          clinicName: _clinicNameController.text.isNotEmpty ? _clinicNameController.text : null,
          clinicAddress: clinicAddress,
        );
      }
      
      // Dispatch update event
      context.read<UpdateUserBloc>().add(UpdateUserEvent(updatedUser));
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _dateOfBirthController.text.isNotEmpty
              ? DateTime.parse(_dateOfBirthController.text)
              : DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: AppColors.whiteColor,
              surface: Colors.white,
              onSurface: AppColors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateOfBirthController.text = DateFormat('yyyy-MM-dd').format(picked);
        _hasChanges = true;
      });
    }
  }

  // Show a confirmation dialog when user tries to go back with unsaved changes
  Future<bool> _onWillPop() async {
    if (!_hasChanges) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              context.tr('profile.discard_changes'),
              style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
            ),
            content: Text(
              context.tr('profile.unsaved_changes_warning'),
              style: GoogleFonts.raleway(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  context.tr('common.cancel'),
                  style: GoogleFonts.raleway(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text(
                  context.tr('common.discard'),
                  style: GoogleFonts.raleway(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            context.tr('edit_profile'),
            style: GoogleFonts.raleway(
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppColors.primaryColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            if (_hasChanges)
              IconButton(
                icon: const Icon(Icons.save, color: Colors.white),
                onPressed: _saveChanges,
                tooltip: context.tr('save'),
              ),
          ],
          elevation: 0,
        ),
        body: BlocConsumer<UpdateUserBloc, UpdateUserState>(
          listener: (context, state) {
            if (state is UpdateUserSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.tr('profile_updated_success'))),
              );
              Navigator.pop(context, state.user);
            } else if (state is UpdateUserFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            return Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primaryColor,
                        AppColors.primaryColor.withOpacity(0.8),
                        AppColors.primaryColor.withOpacity(0.1),
                        Colors.white,
                      ],
                      stops: const [0.0, 0.1, 0.3, 0.5],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        // Profile picture & header
                        SizedBox(
                          height: 120.h,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 40.r,
                                  backgroundColor: Colors.white,
                                  child: Icon(
                                    Icons.person,
                                    size: 40.sp,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                                SizedBox(height: 10.h),
                                Text(
                                  '${widget.user.name} ${widget.user.lastName}',
                                  style: GoogleFonts.raleway(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Form fields in scrollable area
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(30.r),
                                topRight: Radius.circular(30.r),
                              ),
                            ),
                            child: SingleChildScrollView(
                              padding: EdgeInsets.all(20.w),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 10.h),

                                    Text(
                                      context.tr('personal_information'),
                                      style: GoogleFonts.raleway(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                    SizedBox(height: 20.h),

                                    // First Name field
                                    _buildTextField(
                                      controller: _nameController,
                                      label: context.tr('first_name_label'),
                                      icon: Icons.person,
                                      validator:
                                          (value) =>
                                              value!.isEmpty
                                                  ? context.tr('name_required')
                                                  : null,
                                    ),
                                    SizedBox(height: 16.h),

                                    // Last Name field
                                    _buildTextField(
                                      controller: _lastNameController,
                                      label: context.tr('last_name_label'),
                                      icon: Icons.person,
                                      validator:
                                          (value) =>
                                              value!.isEmpty
                                                  ? context.tr('last_name_required')
                                                  : null,
                                    ),
                                    SizedBox(height: 16.h),

                                    // Email field (disabled)
                                    _buildTextField(
                                      enabled: false,
                                      controller: _emailController,
                                      label: context.tr('email'),
                                      icon: Icons.email,
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                    SizedBox(height: 16.h),

                                    // Phone Number field
                                    _buildTextField(
                                      controller: _phoneNumberController,
                                      label: context.tr('phone_number_label'),
                                      icon: Icons.phone,
                                      keyboardType: TextInputType.phone,
                                      validator:
                                          (value) =>
                                              value!.isEmpty
                                                  ? context.tr('phone_number_required')
                                                  : null,
                                    ),
                                    SizedBox(height: 16.h),

                                    // Gender field
                                    _buildDropdownField(
                                      controller: _genderController,
                                      label: context.tr('gender'),
                                      icon: Icons.people,
                                      options: ['Male', 'Female', 'Other'],
                                      validator:
                                          (value) =>
                                              value!.isEmpty
                                                  ? context.tr('gender_required')
                                                  : null,
                                    ),
                                    SizedBox(height: 16.h),

                                    // Date of Birth field
                                    _buildTextField(
                                      controller: _dateOfBirthController,
                                      label: context.tr('date_of_birth_label'),
                                      icon: Icons.calendar_today,
                                      readOnly: true,
                                      onTap: () => _selectDate(context),
                                      hintText: 'YYYY-MM-DD',
                                    ),

                                    // Patient specific fields
                                    if (widget.user is PatientEntity) ...[
                                      SizedBox(height: 30.h),
                                      Text(
                                        context.tr('medical_information'),
                                        style: GoogleFonts.raleway(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryColor,
                                        ),
                                      ),
                                      SizedBox(height: 20.h),
                                      _buildTextField(
                                        controller: _antecedentController,
                                        label: context.tr('medical_history_label'),
                                        icon: Icons.medical_services,
                                        maxLines: 3,
                                        hintText: context.tr('medical_history_hint'),
                                      ),
                                      SizedBox(height: 16.h),

                                      // Blood Type - Dropdown with backend values
                                      _buildDropdownField(
                                        controller: _bloodTypeController,
                                        label: context.tr('blood_type'),
                                        icon: Icons.bloodtype,
                                        options: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
                                      ),
                                      SizedBox(height: 16.h),

                                      // Allergies
                                      _buildTextField(
                                        controller: _allergiesController,
                                        label: context.tr('allergies'),
                                        icon: Icons.warning_amber,
                                        hintText: context.tr('enter_allergies'),
                                        maxLines: 2,
                                      ),
                                      SizedBox(height: 16.h),

                                      // Chronic Diseases
                                      _buildTextField(
                                        controller: _chronicDiseasesController,
                                        label: context.tr('chronic_diseases'),
                                        icon: Icons.local_hospital,
                                        hintText: context.tr('enter_chronic_diseases'),
                                        maxLines: 2,
                                      ),

                                      // Emergency Contact Section
                                      SizedBox(height: 30.h),
                                      Text(
                                        context.tr('emergency_contact'),
                                        style: GoogleFonts.raleway(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryColor,
                                        ),
                                      ),
                                      SizedBox(height: 20.h),

                                      // Emergency Contact Name
                                      _buildTextField(
                                        controller: _emergencyNameController,
                                        label: context.tr('emergency_contact_name'),
                                        icon: Icons.person,
                                        hintText: context.tr('enter_emergency_name'),
                                      ),
                                      SizedBox(height: 16.h),

                                      // Emergency Contact Relationship
                                      _buildTextField(
                                        controller: _emergencyRelationshipController,
                                        label: context.tr('emergency_relationship'),
                                        icon: Icons.people,
                                        hintText: context.tr('enter_emergency_relationship'),
                                      ),
                                      SizedBox(height: 16.h),

                                      // Emergency Contact Phone
                                      _buildTextField(
                                        controller: _emergencyPhoneController,
                                        label: context.tr('emergency_phone'),
                                        icon: Icons.phone,
                                        keyboardType: TextInputType.phone,
                                        hintText: context.tr('enter_emergency_phone'),
                                      ),
                                    ],

                                    // Doctor specific fields
                                    if (widget.user is MedecinEntity) ...[
                                      SizedBox(height: 30.h),
                                      Text(
                                        context.tr('professional_information'),
                                        style: GoogleFonts.raleway(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryColor,
                                        ),
                                      ),
                                      SizedBox(height: 20.h),
                                      _buildTextField(
                                        controller: _specialityController,
                                        label: context.tr('specialty_label'),
                                        icon: Icons.medical_services,
                                        validator:
                                            (value) =>
                                                value!.isEmpty
                                                    ? context.tr('specialty_required')
                                                    : null,
                                      ),
                                      SizedBox(height: 16.h),
                                      _buildTextField(
                                        controller: _numLicenceController,
                                        label: context.tr('license_number_label'),
                                        icon: Icons.badge,
                                        validator:
                                            (value) =>
                                                value!.isEmpty
                                                    ? context.tr('license_number_required')
                                                    : null,
                                      ),
                                      SizedBox(height: 16.h),
                                      _buildTextField(
                                        controller: _appointmentDurationController,
                                        label: context.tr('appointment_duration'),
                                        icon: Icons.timer,
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (value!.isEmpty)
                                            return context.tr('appointment_duration_required');
                                          final duration = int.tryParse(value);
                                          if (duration == null || duration <= 0) {
                                            return context.tr('invalid_duration');
                                          }
                                          return null;
                                        },
                                        suffix: Text(
                                          context.tr('minutes'),
                                          style: GoogleFonts.raleway(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 16.h),
                                      
                                      // Consultation Fee
                                      _buildTextField(
                                        controller: _consultationFeeController,
                                        label: context.tr('consultation_fee'),
                                        icon: Icons.attach_money,
                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                        hintText: context.tr('enter_consultation_fee'),
                                        suffix: Text(
                                          'TND',
                                          style: GoogleFonts.raleway(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 16.h),
                                      
                                      // Years of Experience
                                      _buildTextField(
                                        controller: _yearsOfExperienceController,
                                        label: context.tr('years_of_experience'),
                                        icon: Icons.work_history,
                                        keyboardType: TextInputType.number,
                                        hintText: context.tr('enter_years_experience'),
                                        suffix: Text(
                                          context.tr('years'),
                                          style: GoogleFonts.raleway(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 16.h),
                                      
                                      // About / Bio
                                      _buildTextField(
                                        controller: _aboutController,
                                        label: context.tr('about'),
                                        icon: Icons.info_outline,
                                        hintText: context.tr('enter_about'),
                                        maxLines: 4,
                                      ),
                                      
                                      // Clinic Information Section
                                      SizedBox(height: 30.h),
                                      Text(
                                        context.tr('clinic_information'),
                                        style: GoogleFonts.raleway(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryColor,
                                        ),
                                      ),
                                      SizedBox(height: 20.h),
                                      
                                      // Clinic Name
                                      _buildTextField(
                                        controller: _clinicNameController,
                                        label: context.tr('clinic_name'),
                                        icon: Icons.local_hospital,
                                        hintText: context.tr('enter_clinic_name'),
                                      ),
                                      SizedBox(height: 16.h),
                                      
                                      // Clinic City
                                      _buildTextField(
                                        controller: _clinicCityController,
                                        label: context.tr('clinic_city'),
                                        icon: Icons.location_city,
                                        hintText: context.tr('enter_clinic_city'),
                                      ),
                                      SizedBox(height: 16.h),
                                      
                                      // Clinic Country
                                      _buildTextField(
                                        controller: _clinicCountryController,
                                        label: context.tr('clinic_country'),
                                        icon: Icons.flag,
                                        hintText: context.tr('enter_clinic_country'),
                                      ),
                                    ],

                                    SizedBox(height: 40.h),

                                    // Save button
                                    Container(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: _hasChanges ? _saveChanges : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primaryColor,
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor: Colors.grey[300],
                                          padding: EdgeInsets.symmetric(vertical: 15.h),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16.r),
                                          ),
                                          elevation: 2,
                                        ),
                                        child: Text(
                                          context.tr('save'),
                                          style: GoogleFonts.raleway(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 20.h),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (state is UpdateUserLoading)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    String? hintText,
    int maxLines = 1,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        style: GoogleFonts.raleway(fontSize: 14.sp),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          labelStyle: GoogleFonts.raleway(color: AppColors.primaryColor),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          contentPadding: EdgeInsets.symmetric(
            vertical: 16.h,
            horizontal: 16.w,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide(color: AppColors.primaryColor, width: 1),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide(color: Colors.red, width: 1),
          ),
          prefixIcon: Icon(icon, color: AppColors.primaryColor),
          suffixIcon: suffix,
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey[100],
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdownField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required List<String> options,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: options.contains(controller.text) ? controller.text : null,
        items:
            options.map((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              );
            }).toList(),
        onChanged: (value) {
          if (value != null) {
            controller.text = value;
            _hasChanges = true;
          }
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.raleway(color: AppColors.primaryColor),
          contentPadding: EdgeInsets.symmetric(
            vertical: 16.h,
            horizontal: 16.w,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide(color: AppColors.primaryColor, width: 1),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide(color: Colors.red, width: 1),
          ),
          prefixIcon: Icon(icon, color: AppColors.primaryColor),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: validator,
        style: GoogleFonts.raleway(fontSize: 14.sp),
        dropdownColor: Colors.white,
        icon: Icon(Icons.arrow_drop_down, color: AppColors.primaryColor),
      ),
    );
  }
}
