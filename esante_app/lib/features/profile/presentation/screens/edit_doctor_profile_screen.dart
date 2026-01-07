import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../widgets/location_picker_card.dart';
import '../widgets/education_editor.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/doctor_profile_entity.dart';
import '../../domain/usecases/update_doctor_profile_usecase.dart';
import '../blocs/doctor_profile/doctor_profile_bloc.dart';

class EditDoctorProfileScreen extends StatefulWidget {
  final DoctorProfileEntity profile;

  const EditDoctorProfileScreen({
    super.key,
    required this.profile,
  });

  @override
  State<EditDoctorProfileScreen> createState() => _EditDoctorProfileScreenState();
}

class _EditDoctorProfileScreenState extends State<EditDoctorProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _licenseNumberController;
  late TextEditingController _yearsOfExperienceController;
  late TextEditingController _clinicNameController;
  late TextEditingController _clinicStreetController;
  late TextEditingController _clinicCityController;
  late TextEditingController _clinicStateController;
  late TextEditingController _clinicZipCodeController;
  late TextEditingController _clinicCountryController;
  late TextEditingController _aboutController;
  late TextEditingController _consultationFeeController;
  late TextEditingController _languagesController;
  late TextEditingController _subSpecialtyController;

  String? _selectedSpecialty;
  bool _acceptsInsurance = false;
  bool _hasChanges = false;
  
  // Education list for the editor
  List<Map<String, dynamic>> _educationList = [];
  
  // Location coordinates for clinic
  double? _clinicLatitude;
  double? _clinicLongitude;

  final List<String> _specialties = [
    'General Practice',
    'Internal Medicine',
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
    'Radiology',
    'Rheumatology',
    'Surgery',
    'Urology',
    'Gynecology',
    'ENT (Otolaryngology)',
    'Emergency Medicine',
    'Family Medicine',
    'Nephrology',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final profile = widget.profile;

    _firstNameController = TextEditingController(text: profile.firstName);
    _lastNameController = TextEditingController(text: profile.lastName);
    _phoneController = TextEditingController(text: profile.phone);
    _licenseNumberController = TextEditingController(text: profile.licenseNumber);
    _yearsOfExperienceController = TextEditingController(
      text: profile.yearsOfExperience > 0 ? profile.yearsOfExperience.toString() : '',
    );
    _clinicNameController = TextEditingController(text: profile.clinicName ?? '');
    _clinicStreetController = TextEditingController(text: profile.clinicAddress?.street ?? '');
    _clinicCityController = TextEditingController(text: profile.clinicAddress?.city ?? '');
    _clinicStateController = TextEditingController(text: profile.clinicAddress?.state ?? '');
    _clinicZipCodeController = TextEditingController(text: profile.clinicAddress?.zipCode ?? '');
    _clinicCountryController = TextEditingController(text: profile.clinicAddress?.country ?? '');
    _aboutController = TextEditingController(text: profile.about ?? '');
    _consultationFeeController = TextEditingController(
      text: profile.consultationFee > 0 ? profile.consultationFee.toStringAsFixed(0) : '',
    );
    _languagesController = TextEditingController(text: profile.languages.join(', '));
    _subSpecialtyController = TextEditingController(text: profile.subSpecialty ?? '');

    _selectedSpecialty = _specialties.contains(profile.specialty) ? profile.specialty : null;
    _acceptsInsurance = profile.acceptsInsurance;
    
    // Initialize clinic coordinates
    _clinicLatitude = profile.clinicAddress?.latitude;
    _clinicLongitude = profile.clinicAddress?.longitude;
    
    // Initialize education list from profile
    _educationList = profile.education
        .map((e) => {
              'degree': e.degree,
              'institution': e.institution,
              if (e.year != null) 'year': e.year,
            })
        .toList();

    _addChangeListeners();
  }

  void _addChangeListeners() {
    final controllers = [
      _firstNameController,
      _lastNameController,
      _phoneController,
      _licenseNumberController,
      _yearsOfExperienceController,
      _clinicNameController,
      _clinicStreetController,
      _clinicCityController,
      _clinicStateController,
      _clinicZipCodeController,
      _clinicCountryController,
      _aboutController,
      _consultationFeeController,
      _languagesController,
      _subSpecialtyController,
    ];

    for (var controller in controllers) {
      controller.addListener(_onFieldChanged);
    }
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _licenseNumberController.dispose();
    _yearsOfExperienceController.dispose();
    _clinicNameController.dispose();
    _clinicStreetController.dispose();
    _clinicCityController.dispose();
    _clinicStateController.dispose();
    _clinicZipCodeController.dispose();
    _clinicCountryController.dispose();
    _aboutController.dispose();
    _consultationFeeController.dispose();
    _languagesController.dispose();
    _subSpecialtyController.dispose();
    super.dispose();
  }

  List<String>? _parseListField(String text) {
    if (text.trim().isEmpty) return null;
    return text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  void _saveProfile(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    Map<String, dynamic>? clinicAddress;
    if (_clinicCityController.text.isNotEmpty || _clinicCountryController.text.isNotEmpty) {
      // Use selected coordinates or existing ones or default to [0,0]
      final lat = _clinicLatitude ?? widget.profile.clinicAddress?.latitude ?? 0.0;
      final lng = _clinicLongitude ?? widget.profile.clinicAddress?.longitude ?? 0.0;

      clinicAddress = {
        if (_clinicStreetController.text.isNotEmpty) 'street': _clinicStreetController.text,
        'city': _clinicCityController.text,
        if (_clinicStateController.text.isNotEmpty) 'state': _clinicStateController.text,
        if (_clinicZipCodeController.text.isNotEmpty) 'zipCode': _clinicZipCodeController.text,
        'country': _clinicCountryController.text,
        'coordinates': {
          'type': 'Point',
          'coordinates': [lng, lat],
        },
      };
    }

    final params = UpdateDoctorProfileParams(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      phone: _phoneController.text,
      specialty: _selectedSpecialty,
      subSpecialty: _subSpecialtyController.text.isNotEmpty ? _subSpecialtyController.text : null,
      licenseNumber: _licenseNumberController.text,
      yearsOfExperience: int.tryParse(_yearsOfExperienceController.text),
      education: _educationList.isNotEmpty ? _educationList : null,
      clinicName: _clinicNameController.text.isNotEmpty ? _clinicNameController.text : null,
      clinicAddress: clinicAddress,
      about: _aboutController.text.isNotEmpty ? _aboutController.text : null,
      consultationFee: double.tryParse(_consultationFeeController.text),
      acceptsInsurance: _acceptsInsurance,
      languages: _parseListField(_languagesController.text),
    );

    context.read<DoctorProfileBloc>().add(UpdateDoctorProfile(params: params));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DoctorProfileBloc>(),
      child: Builder(
        builder: (blocContext) => Scaffold(
          appBar: _buildAppBar(blocContext),
          body: BlocConsumer<DoctorProfileBloc, DoctorProfileState>(
            listener: (context, state) {
              if (state is DoctorProfileUpdated) {
                AppSnackBar.success(context, 'Profile updated successfully!');
                Navigator.pop(context, true);
              } else if (state is DoctorProfileError) {
                AppSnackBar.error(context, state.failure.message);
              }
            },
            builder: (context, state) {
              final isLoading = state is DoctorProfileUpdating;

              return Stack(
                children: [
                  Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(20.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Personal Information'),
                          SizedBox(height: 16.h),
                          _buildPersonalInfoSection(),

                          SizedBox(height: 32.h),
                          _buildSectionTitle('Professional Information'),
                          SizedBox(height: 16.h),
                          _buildProfessionalSection(),

                          SizedBox(height: 32.h),
                          _buildEducationSection(),

                          SizedBox(height: 32.h),
                          _buildSectionTitle('Clinic Information'),
                          SizedBox(height: 16.h),
                          _buildClinicSection(),

                          SizedBox(height: 32.h),
                          _buildSectionTitle('About & Services'),
                          SizedBox(height: 16.h),
                          _buildAboutSection(),

                          SizedBox(height: 40.h),
                          CustomButton(
                            text: 'Save Changes',
                            icon: Icons.save_rounded,
                            onPressed: _hasChanges ? () => _saveProfile(context) : null,
                            isLoading: isLoading,
                          ),
                          SizedBox(height: 32.h),
                        ],
                      ),
                    ),
                  ),
                  if (isLoading)
                    Container(
                      color: Colors.black.withOpacity(0.1),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      title: Text(
        'Edit Profile',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
      centerTitle: true,
      backgroundColor: isDark ? AppColors.surface(context) : Colors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: () async {
          if (_hasChanges) {
            final shouldDiscard = await _showDiscardDialog();
            if (shouldDiscard != true) return;
          }
          Navigator.pop(context);
        },
        icon: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18.sp,
            color: AppColors.textPrimary(context),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDiscardDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _firstNameController,
                hintText: 'Enter first name',
                label: 'First Name',
                prefixIcon: Icons.person_outline_rounded,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: CustomTextField(
                controller: _lastNameController,
                hintText: 'Enter last name',
                label: 'Last Name',
                prefixIcon: Icons.person_outline_rounded,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        CustomTextField(
          controller: _phoneController,
          hintText: 'Enter phone number',
          label: 'Phone Number',
          prefixIcon: Icons.phone_rounded,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildProfessionalSection() {
    return Column(
      children: [
        CustomDropdown<String>(
          label: 'Specialty',
          value: _selectedSpecialty,
          items: _specialties,
          itemLabelBuilder: (s) => s,
          onChanged: (value) {
            setState(() {
              _selectedSpecialty = value;
              _hasChanges = true;
            });
          },
        ),
        SizedBox(height: 16.h),
        CustomTextField(
          controller: _subSpecialtyController,
          hintText: 'e.g., Echocardiography, Sports Medicine',
          label: 'Sub-Specialty (Optional)',
          prefixIcon: Icons.medical_services_outlined,
        ),
        SizedBox(height: 16.h),
        CustomTextField(
          controller: _licenseNumberController,
          hintText: 'Enter license number',
          label: 'License Number',
          prefixIcon: Icons.badge_outlined,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Required';
            }
            return null;
          },
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _yearsOfExperienceController,
                hintText: 'Years',
                label: 'Experience',
                prefixIcon: Icons.work_outline,
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: CustomTextField(
                controller: _consultationFeeController,
                hintText: 'Fee (\$)',
                label: 'Consultation Fee',
                prefixIcon: Icons.attach_money,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        SwitchListTile(
          title: const Text('Accepts Insurance'),
          subtitle: const Text('Toggle if you accept insurance payments'),
          value: _acceptsInsurance,
          onChanged: (value) {
            setState(() {
              _acceptsInsurance = value;
              _hasChanges = true;
            });
          },
          activeColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildClinicSection() {
    return Column(
      children: [
        CustomTextField(
          controller: _clinicNameController,
          hintText: 'Enter clinic name',
          label: 'Clinic Name',
          prefixIcon: Icons.business_outlined,
        ),
        SizedBox(height: 16.h),
        CustomTextField(
          controller: _clinicStreetController,
          hintText: 'Enter street address',
          label: 'Street Address',
          prefixIcon: Icons.location_on_outlined,
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _clinicCityController,
                hintText: 'City',
                label: 'City',
                prefixIcon: Icons.location_city_outlined,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: CustomTextField(
                controller: _clinicStateController,
                hintText: 'State',
                label: 'State',
                prefixIcon: Icons.map_outlined,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _clinicZipCodeController,
                hintText: 'Zip Code',
                label: 'Zip Code',
                prefixIcon: Icons.pin_drop_outlined,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: CustomTextField(
                controller: _clinicCountryController,
                hintText: 'Country',
                label: 'Country',
                prefixIcon: Icons.flag_outlined,
              ),
            ),
          ],
        ),
        SizedBox(height: 20.h),
        LocationPickerCard(
          latitude: _clinicLatitude,
          longitude: _clinicLongitude,
          onLocationSelected: (latLng) {
            setState(() {
              _clinicLatitude = latLng.latitude;
              _clinicLongitude = latLng.longitude;
              _hasChanges = true;
            });
          },
        ),
      ],
    );
  }

  Widget _buildEducationSection() {
    return EducationEditor(
      initialEducation: widget.profile.education,
      onChanged: (educationList) {
        setState(() {
          _educationList = educationList;
          _hasChanges = true;
        });
      },
    );
  }

  Widget _buildAboutSection() {
    return Column(
      children: [
        CustomTextField(
          controller: _aboutController,
          hintText: 'Tell patients about yourself...',
          label: 'About',
          prefixIcon: Icons.info_outline,
          maxLines: 4,
        ),
        SizedBox(height: 16.h),
        CustomTextField(
          controller: _languagesController,
          hintText: 'English, French, Arabic...',
          label: 'Languages (comma separated)',
          prefixIcon: Icons.language,
        ),
      ],
    );
  }
}
