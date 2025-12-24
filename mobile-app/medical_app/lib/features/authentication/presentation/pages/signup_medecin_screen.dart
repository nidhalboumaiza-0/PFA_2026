import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medical_app/core/widgets/common/common_widgets.dart';
import '../../../../core/utils/app_colors.dart';
import '../../domain/entities/medecin_entity.dart';
import '../../../../core/specialties.dart';
import 'package:medical_app/core/utils/navigation_with_transition.dart';
import 'password_screen.dart';

class SignupMedecinScreen extends StatefulWidget {
  final MedecinEntity medecinEntity;

  const SignupMedecinScreen({super.key, required this.medecinEntity});

  @override
  State<SignupMedecinScreen> createState() => _SignupMedecinScreenState();
}

class _SignupMedecinScreenState extends State<SignupMedecinScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // Controllers
  final TextEditingController licenseNumberController = TextEditingController();
  final TextEditingController consultationFeeController = TextEditingController();
  final TextEditingController clinicNameController = TextEditingController();
  final TextEditingController clinicCityController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();
  
  String? selectedSpecialty;
  int selectedDuration = 30;
  
  // Duration options
  final List<int> durationOptions = [15, 20, 30, 45, 60];

  @override
  void dispose() {
    licenseNumberController.dispose();
    consultationFeeController.dispose();
    clinicNameController.dispose();
    clinicCityController.dispose();
    aboutController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Build clinic address if provided
      Map<String, dynamic>? clinicAddress;
      if (clinicCityController.text.isNotEmpty) {
        clinicAddress = {
          'city': clinicCityController.text,
          'country': 'Tunisia', // Default country
        };
      }

      final updatedMedecinEntity = MedecinEntity(
        name: widget.medecinEntity.name,
        lastName: widget.medecinEntity.lastName,
        email: widget.medecinEntity.email,
        role: widget.medecinEntity.role,
        gender: widget.medecinEntity.gender,
        phoneNumber: widget.medecinEntity.phoneNumber,
        dateOfBirth: widget.medecinEntity.dateOfBirth,
        speciality: selectedSpecialty!,
        numLicence: licenseNumberController.text,
        appointmentDuration: selectedDuration,
        consultationFee: double.tryParse(consultationFeeController.text),
        clinicName: clinicNameController.text.isEmpty ? null : clinicNameController.text,
        clinicAddress: clinicAddress,
        about: aboutController.text.isEmpty ? null : aboutController.text,
      );

      navigateToAnotherScreenWithSlideTransitionFromRightToLeft(
        context,
        PasswordScreen(entity: updatedMedecinEntity),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(isDark),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10.h),
                      
                      // Doctor illustration
                      Center(
                        child: Container(
                          padding: EdgeInsets.all(24.r),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryColor.withOpacity(0.1),
                                AppColors.primaryColor.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.medical_services,
                            size: 50.sp,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 24.h),
                      
                      // Specialty Selection
                      _buildSectionCard(
                        isDark: isDark,
                        icon: Icons.local_hospital_outlined,
                        title: context.tr("specialty_label"),
                        isRequired: true,
                        child: _buildSpecialtyDropdown(isDark),
                      ),
                      
                      SizedBox(height: 16.h),
                      
                      // License Number
                      _buildSectionCard(
                        isDark: isDark,
                        icon: Icons.badge_outlined,
                        title: context.tr("license_number_label"),
                        isRequired: true,
                        child: _buildTextField(
                          controller: licenseNumberController,
                          hint: context.tr("license_number_hint"),
                          isDark: isDark,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return context.tr("license_number_required");
                            }
                            return null;
                          },
                        ),
                      ),
                      
                      SizedBox(height: 16.h),
                      
                      // Consultation Duration
                      _buildSectionCard(
                        isDark: isDark,
                        icon: Icons.schedule_outlined,
                        title: context.tr("consultation_duration_label"),
                        child: _buildDurationSelector(isDark),
                      ),
                      
                      SizedBox(height: 16.h),
                      
                      // Consultation Fee
                      _buildSectionCard(
                        isDark: isDark,
                        icon: Icons.payments_outlined,
                        title: context.tr("consultation_fee_label"),
                        child: _buildTextField(
                          controller: consultationFeeController,
                          hint: context.tr("consultation_fee_hint"),
                          isDark: isDark,
                          keyboardType: TextInputType.number,
                          prefix: Text(
                            "TND ",
                            style: GoogleFonts.raleway(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 16.h),
                      
                      // Clinic Information Section
                      _buildSectionTitle(context.tr("clinic_info"), isDark),
                      
                      SizedBox(height: 12.h),
                      
                      // Clinic Name
                      _buildSectionCard(
                        isDark: isDark,
                        icon: Icons.business_outlined,
                        title: context.tr("clinic_name"),
                        child: _buildTextField(
                          controller: clinicNameController,
                          hint: context.tr("enter_clinic_name"),
                          isDark: isDark,
                        ),
                      ),
                      
                      SizedBox(height: 16.h),
                      
                      // Clinic City
                      _buildSectionCard(
                        isDark: isDark,
                        icon: Icons.location_city_outlined,
                        title: context.tr("clinic_city"),
                        child: _buildTextField(
                          controller: clinicCityController,
                          hint: context.tr("enter_clinic_city"),
                          isDark: isDark,
                        ),
                      ),
                      
                      SizedBox(height: 16.h),
                      
                      // About
                      _buildSectionCard(
                        isDark: isDark,
                        icon: Icons.info_outline,
                        title: context.tr("about"),
                        child: _buildTextField(
                          controller: aboutController,
                          hint: context.tr("about_hint"),
                          isDark: isDark,
                          maxLines: 3,
                        ),
                      ),
                      
                      SizedBox(height: 24.h),
                      
                      // Info note
                      Container(
                        padding: EdgeInsets.all(16.r),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.verified_outlined, color: Colors.green, size: 20.sp),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                context.tr("doctor_verification_note"),
                                style: GoogleFonts.raleway(
                                  fontSize: 13.sp,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 30.h),
                    ],
                  ),
                ),
              ),
            ),
            
            // Submit Button
            _buildSubmitButton(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Row(
        children: [
          const AppBackButton(showAnimation: false),
          Expanded(
            child: Text(
              context.tr("professional_information"),
              textAlign: TextAlign.center,
              style: GoogleFonts.raleway(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ),
          SizedBox(width: 40.w),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: GoogleFonts.raleway(
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : const Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildSectionCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required Widget child,
    bool isRequired = false,
  }) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, color: AppColors.primaryColor, size: 18.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.raleway(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    if (isRequired)
                      Text(
                        " *",
                        style: GoogleFonts.raleway(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          child,
        ],
      ),
    );
  }

  Widget _buildSpecialtyDropdown(bool isDark) {
    return DropdownButtonFormField<String>(
      value: selectedSpecialty,
      isExpanded: true,
      decoration: InputDecoration(
        hintText: context.tr("specialty_hint"),
        hintStyle: GoogleFonts.raleway(
          fontSize: 14.sp,
          color: isDark ? Colors.white38 : Colors.grey.shade400,
        ),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade50,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
      ),
      dropdownColor: isDark ? const Color(0xFF2D2D44) : Colors.white,
      items: getTranslatedSpecialties(context).map((specialty) {
        return DropdownMenuItem(
          value: specialty,
          child: Text(
            specialty,
            style: GoogleFonts.raleway(
              fontSize: 14.sp,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedSpecialty = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return context.tr("specialty_required");
        }
        return null;
      },
    );
  }

  Widget _buildDurationSelector(bool isDark) {
    return Wrap(
      spacing: 10.w,
      runSpacing: 10.h,
      children: durationOptions.map((duration) {
        final isSelected = selectedDuration == duration;
        return GestureDetector(
          onTap: () {
            setState(() {
              selectedDuration = duration;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryColor
                  : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryColor
                    : (isDark ? Colors.white24 : Colors.grey.shade300),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(
              "$duration ${context.tr("min")}",
              style: GoogleFonts.raleway(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    Widget? prefix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.raleway(
        fontSize: 14.sp,
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.raleway(
          fontSize: 14.sp,
          color: isDark ? Colors.white38 : Colors.grey.shade400,
        ),
        prefixIcon: prefix != null
            ? Padding(
                padding: EdgeInsets.only(left: 16.w, right: 4.w),
                child: prefix,
              )
            : null,
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade50,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildSubmitButton(bool isDark) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cancel button
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                side: BorderSide(color: AppColors.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: Text(
                context.tr("cancel"),
                style: GoogleFonts.raleway(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          ),
          
          SizedBox(width: 12.w),
          
          // Continue button
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.tr("continue"),
                    style: GoogleFonts.raleway(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 18.sp,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
