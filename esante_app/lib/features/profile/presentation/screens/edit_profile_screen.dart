import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/patient_profile_entity.dart';
import '../../domain/usecases/update_patient_profile_usecase.dart';
import '../blocs/patient_profile/profile_bloc.dart';

class EditProfileScreen extends StatefulWidget {
  final PatientProfileEntity profile;

  const EditProfileScreen({
    super.key,
    required this.profile,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipCodeController;
  late TextEditingController _countryController;
  late TextEditingController _allergiesController;
  late TextEditingController _chronicDiseasesController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyRelationshipController;
  late TextEditingController _emergencyPhoneController;
  late TextEditingController _insuranceProviderController;
  late TextEditingController _insurancePolicyController;

  String? _selectedGender;
  String? _selectedBloodType;
  DateTime? _selectedDateOfBirth;
  DateTime? _insuranceExpiryDate;

  bool _hasChanges = false;

  final List<String> _genderOptions = ['male', 'female', 'other'];
  final List<String> _bloodTypeOptions = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

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
    _streetController = TextEditingController(text: profile.address?.street ?? '');
    _cityController = TextEditingController(text: profile.address?.city ?? '');
    _stateController = TextEditingController(text: profile.address?.state ?? '');
    _zipCodeController = TextEditingController(text: profile.address?.zipCode ?? '');
    _countryController = TextEditingController(text: profile.address?.country ?? '');
    _allergiesController = TextEditingController(text: profile.allergies.join(', '));
    _chronicDiseasesController = TextEditingController(text: profile.chronicDiseases.join(', '));
    _emergencyNameController = TextEditingController(text: profile.emergencyContact?.name ?? '');
    _emergencyRelationshipController = TextEditingController(text: profile.emergencyContact?.relationship ?? '');
    _emergencyPhoneController = TextEditingController(text: profile.emergencyContact?.phone ?? '');
    _insuranceProviderController = TextEditingController(text: profile.insuranceInfo?.provider ?? '');
    _insurancePolicyController = TextEditingController(text: profile.insuranceInfo?.policyNumber ?? '');

    _selectedGender = profile.gender;
    _selectedBloodType = profile.bloodType;
    _selectedDateOfBirth = profile.dateOfBirth;
    _insuranceExpiryDate = profile.insuranceInfo?.expiryDate;

    // Add listeners to track changes
    _addChangeListeners();
  }

  void _addChangeListeners() {
    final controllers = [
      _firstNameController, _lastNameController, _phoneController,
      _streetController, _cityController, _stateController, 
      _zipCodeController, _countryController, _allergiesController, 
      _chronicDiseasesController, _emergencyNameController,
      _emergencyRelationshipController, _emergencyPhoneController,
      _insuranceProviderController, _insurancePolicyController,
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
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _countryController.dispose();
    _allergiesController.dispose();
    _chronicDiseasesController.dispose();
    _emergencyNameController.dispose();
    _emergencyRelationshipController.dispose();
    _emergencyPhoneController.dispose();
    _insuranceProviderController.dispose();
    _insurancePolicyController.dispose();
    super.dispose();
  }

  List<String>? _parseListField(String text) {
    if (text.trim().isEmpty) return null;
    return text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  void _saveProfile(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    // Build address map
    Map<String, dynamic>? address;
    if (_streetController.text.isNotEmpty || _cityController.text.isNotEmpty ||
        _stateController.text.isNotEmpty || _zipCodeController.text.isNotEmpty ||
        _countryController.text.isNotEmpty) {
      address = {
        if (_streetController.text.isNotEmpty) 'street': _streetController.text,
        if (_cityController.text.isNotEmpty) 'city': _cityController.text,
        if (_stateController.text.isNotEmpty) 'state': _stateController.text,
        if (_zipCodeController.text.isNotEmpty) 'zipCode': _zipCodeController.text,
        if (_countryController.text.isNotEmpty) 'country': _countryController.text,
      };
    }

    // Build emergency contact map
    Map<String, dynamic>? emergencyContact;
    if (_emergencyNameController.text.isNotEmpty || 
        _emergencyRelationshipController.text.isNotEmpty ||
        _emergencyPhoneController.text.isNotEmpty) {
      emergencyContact = {
        if (_emergencyNameController.text.isNotEmpty) 'name': _emergencyNameController.text,
        if (_emergencyRelationshipController.text.isNotEmpty) 'relationship': _emergencyRelationshipController.text,
        if (_emergencyPhoneController.text.isNotEmpty) 'phone': _emergencyPhoneController.text,
      };
    }

    // Build insurance info map
    Map<String, dynamic>? insuranceInfo;
    if (_insuranceProviderController.text.isNotEmpty || 
        _insurancePolicyController.text.isNotEmpty ||
        _insuranceExpiryDate != null) {
      insuranceInfo = {
        if (_insuranceProviderController.text.isNotEmpty) 'provider': _insuranceProviderController.text,
        if (_insurancePolicyController.text.isNotEmpty) 'policyNumber': _insurancePolicyController.text,
        if (_insuranceExpiryDate != null) 'expiryDate': _insuranceExpiryDate!.toIso8601String(),
      };
    }

    final params = UpdatePatientProfileParams(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      phone: _phoneController.text,
      gender: _selectedGender,
      dateOfBirth: _selectedDateOfBirth,
      bloodType: _selectedBloodType,
      address: address,
      allergies: _parseListField(_allergiesController.text),
      chronicDiseases: _parseListField(_chronicDiseasesController.text),
      emergencyContact: emergencyContact,
      insuranceInfo: insuranceInfo,
    );

    context.read<ProfileBloc>().add(UpdateProfile(params: params));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProfileBloc>(),
      child: Builder(
        builder: (blocContext) => Scaffold(
          appBar: _buildAppBar(blocContext),
          body: BlocConsumer<ProfileBloc, ProfileState>(
            listener: (context, state) {
              if (state is ProfileUpdated) {
                AppSnackBar.success(context, 'Profile updated successfully!');
                Navigator.pop(context, true);
              } else if (state is ProfileError) {
                AppSnackBar.error(context, state.failure.message);
              }
            },
            builder: (context, state) {
              final isLoading = state is ProfileUpdating;
              
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
                          _buildSectionTitle('Address'),
                          SizedBox(height: 16.h),
                          _buildAddressSection(),
                          
                          SizedBox(height: 32.h),
                          _buildSectionTitle('Medical Information'),
                          SizedBox(height: 16.h),
                          _buildMedicalSection(),
                          
                          SizedBox(height: 32.h),
                          _buildSectionTitle('Emergency Contact'),
                          SizedBox(height: 16.h),
                          _buildEmergencyContactSection(),
                          
                          SizedBox(height: 32.h),
                          _buildSectionTitle('Insurance Information'),
                          SizedBox(height: 16.h),
                          _buildInsuranceSection(),
                          
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
                    return 'First name is required';
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
                    return 'Last name is required';
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
              return 'Phone number is required';
            }
            return null;
          },
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: CustomDropdown<String>(
                label: 'Gender',
                value: _selectedGender,
                items: _genderOptions,
                itemLabelBuilder: (g) => g.substring(0, 1).toUpperCase() + g.substring(1),
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                    _hasChanges = true;
                  });
                },
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: CustomDatePicker(
                label: 'Date of Birth',
                selectedDate: _selectedDateOfBirth,
                onDateSelected: (date) {
                  setState(() {
                    _selectedDateOfBirth = date;
                    _hasChanges = true;
                  });
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        CustomDropdown<String>(
          label: 'Blood Type',
          value: _selectedBloodType,
          items: _bloodTypeOptions,
          itemLabelBuilder: (b) => b,
          onChanged: (value) {
            setState(() {
              _selectedBloodType = value;
              _hasChanges = true;
            });
          },
        ),
      ],
    );
  }

  Widget _buildAddressSection() {
    return Column(
      children: [
        CustomTextField(
          controller: _streetController,
          hintText: 'Enter street address',
          label: 'Street Address',
          prefixIcon: Icons.home_outlined,
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _cityController,
                hintText: 'Enter city',
                label: 'City',
                prefixIcon: Icons.location_city_outlined,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: CustomTextField(
                controller: _stateController,
                hintText: 'Enter state',
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
                controller: _zipCodeController,
                hintText: 'Enter zip code',
                label: 'Zip Code',
                prefixIcon: Icons.pin_drop_outlined,
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: CustomTextField(
                controller: _countryController,
                hintText: 'Enter country',
                label: 'Country',
                prefixIcon: Icons.flag_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMedicalSection() {
    return Column(
      children: [
        CustomTextField(
          controller: _allergiesController,
          hintText: 'Enter allergies separated by commas',
          label: 'Allergies',
          prefixIcon: Icons.warning_amber_rounded,
          maxLines: 2,
        ),
        SizedBox(height: 16.h),
        CustomTextField(
          controller: _chronicDiseasesController,
          hintText: 'Enter conditions separated by commas',
          label: 'Chronic Diseases',
          prefixIcon: Icons.healing_outlined,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildEmergencyContactSection() {
    return Column(
      children: [
        CustomTextField(
          controller: _emergencyNameController,
          hintText: 'Enter contact name',
          label: 'Contact Name',
          prefixIcon: Icons.person_outline_rounded,
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _emergencyRelationshipController,
                hintText: 'e.g. Spouse, Parent',
                label: 'Relationship',
                prefixIcon: Icons.family_restroom_outlined,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: CustomTextField(
                controller: _emergencyPhoneController,
                hintText: 'Contact phone',
                label: 'Phone',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInsuranceSection() {
    return Column(
      children: [
        CustomTextField(
          controller: _insuranceProviderController,
          hintText: 'Enter insurance provider',
          label: 'Insurance Provider',
          prefixIcon: Icons.business_outlined,
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _insurancePolicyController,
                hintText: 'Enter policy number',
                label: 'Policy Number',
                prefixIcon: Icons.numbers_outlined,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: CustomDatePicker(
                label: 'Expiry Date',
                selectedDate: _insuranceExpiryDate,
                onDateSelected: (date) {
                  setState(() {
                    _insuranceExpiryDate = date;
                    _hasChanges = true;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
