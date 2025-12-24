import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medical_app/core/widgets/common/common_widgets.dart';
import '../../../../core/utils/app_colors.dart';
import '../../domain/entities/patient_entity.dart';
import 'password_screen.dart';
import 'package:medical_app/core/utils/navigation_with_transition.dart';

class SignupPatientScreen extends StatefulWidget {
  final PatientEntity patientEntity;

  const SignupPatientScreen({super.key, required this.patientEntity});

  @override
  State<SignupPatientScreen> createState() => _SignupPatientScreenState();
}

class _SignupPatientScreenState extends State<SignupPatientScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late PageController _pageController;
  int _currentPage = 0;

  // Controllers for medical info
  final TextEditingController chronicDiseasesController = TextEditingController();
  final TextEditingController allergiesController = TextEditingController();

  // Controllers for emergency contact
  final TextEditingController emergencyNameController = TextEditingController();
  final TextEditingController emergencyRelationController = TextEditingController();
  final TextEditingController emergencyPhoneController = TextEditingController();

  String? selectedBloodType;

  // List of blood types matching backend enum
  final List<String> bloodTypes = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    chronicDiseasesController.dispose();
    allergiesController.dispose();
    emergencyNameController.dispose();
    emergencyRelationController.dispose();
    emergencyPhoneController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitForm();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _submitForm() {
    // Parse allergies into a list (comma-separated)
    List<String>? allergies;
    if (allergiesController.text.isNotEmpty) {
      allergies = allergiesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    // Parse chronic diseases into a list (comma-separated)
    List<String>? chronicDiseases;
    if (chronicDiseasesController.text.isNotEmpty) {
      chronicDiseases = chronicDiseasesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    // Create emergency contact map if any field is filled
    Map<String, String?>? emergencyContact;
    if (emergencyNameController.text.isNotEmpty ||
        emergencyRelationController.text.isNotEmpty ||
        emergencyPhoneController.text.isNotEmpty) {
      emergencyContact = {
        'name': emergencyNameController.text.isEmpty
            ? null
            : emergencyNameController.text,
        'relationship': emergencyRelationController.text.isEmpty
            ? null
            : emergencyRelationController.text,
        'phone': emergencyPhoneController.text.isEmpty
            ? null
            : emergencyPhoneController.text,
      };
    }

    final updatedPatientEntity = PatientEntity(
      name: widget.patientEntity.name,
      lastName: widget.patientEntity.lastName,
      email: widget.patientEntity.email,
      role: widget.patientEntity.role,
      gender: widget.patientEntity.gender,
      phoneNumber: widget.patientEntity.phoneNumber,
      dateOfBirth: widget.patientEntity.dateOfBirth,
      bloodType: selectedBloodType,
      allergies: allergies,
      chronicDiseases: chronicDiseases,
      emergencyContact: emergencyContact,
    );

    navigateToAnotherScreenWithSlideTransitionFromRightToLeft(
      context,
      PasswordScreen(entity: updatedPatientEntity),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and progress
            _buildHeader(isDark),
            
            // Page content
            Expanded(
              child: Form(
                key: _formKey,
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: [
                    _buildMedicalInfoPage(isDark),
                    _buildEmergencyContactPage(isDark),
                  ],
                ),
              ),
            ),
            
            // Navigation buttons
            _buildNavigationButtons(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        children: [
          // Back button and title
          Row(
            children: [
            AppBackButton(
                onPressed: _previousPage,
                showAnimation: false,
              ),
              Expanded(
                child: Text(
                  context.tr("medical_info"),
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
          
          SizedBox(height: 20.h),
          
          // Progress indicator
          _buildProgressIndicator(isDark),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(bool isDark) {
    return Row(
      children: [
        _buildStepIndicator(0, context.tr("health_info"), isDark),
        Expanded(
          child: Container(
            height: 2,
            color: _currentPage >= 1
                ? AppColors.primaryColor
                : (isDark ? Colors.white24 : Colors.grey.shade300),
          ),
        ),
        _buildStepIndicator(1, context.tr("emergency"), isDark),
      ],
    );
  }

  Widget _buildStepIndicator(int step, String label, bool isDark) {
    final isActive = _currentPage >= step;
    final isCurrent = _currentPage == step;
    
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 36.w,
          height: 36.h,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryColor : (isDark ? Colors.white24 : Colors.grey.shade300),
            shape: BoxShape.circle,
            border: isCurrent
                ? Border.all(color: AppColors.primaryColor.withOpacity(0.3), width: 3)
                : null,
          ),
          child: Center(
            child: isActive && !isCurrent
                ? Icon(Icons.check, color: Colors.white, size: 18.sp)
                : Text(
                    '${step + 1}',
                    style: GoogleFonts.raleway(
                      color: isActive ? Colors.white : (isDark ? Colors.white54 : Colors.grey),
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          label,
          style: GoogleFonts.raleway(
            fontSize: 11.sp,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
            color: isActive
                ? AppColors.primaryColor
                : (isDark ? Colors.white54 : Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildMedicalInfoPage(bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 10.h),
          
          // Illustration
          Center(
            child: Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_outline,
                size: 60.sp,
                color: AppColors.primaryColor,
              ),
            ),
          ),
          
          SizedBox(height: 24.h),
          
          // Blood Type Card
          _buildSectionCard(
            isDark: isDark,
            icon: Icons.bloodtype_outlined,
            title: context.tr("blood_type"),
            child: Wrap(
              spacing: 10.w,
              runSpacing: 10.h,
              children: bloodTypes.map((type) {
                final isSelected = selectedBloodType == type;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedBloodType = isSelected ? null : type;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryColor
                          : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryColor
                            : (isDark ? Colors.white24 : Colors.grey.shade300),
                      ),
                    ),
                    child: Text(
                      type,
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
            ),
          ),
          
          SizedBox(height: 16.h),
          
          // Allergies Card
          _buildSectionCard(
            isDark: isDark,
            icon: Icons.warning_amber_outlined,
            title: context.tr("allergies"),
            child: _buildTextField(
              controller: allergiesController,
              hint: context.tr("allergies_hint"),
              maxLines: 2,
              isDark: isDark,
            ),
          ),
          
          SizedBox(height: 16.h),
          
          // Chronic Diseases Card
          _buildSectionCard(
            isDark: isDark,
            icon: Icons.medical_information_outlined,
            title: context.tr("chronic_diseases"),
            child: _buildTextField(
              controller: chronicDiseasesController,
              hint: context.tr("chronic_diseases_hint"),
              maxLines: 3,
              isDark: isDark,
            ),
          ),
          
          SizedBox(height: 24.h),
          
          // Info note
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 20.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    context.tr("optional_fields_note"),
                    style: GoogleFonts.raleway(
                      fontSize: 13.sp,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 30.h),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactPage(bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 10.h),
          
          // Illustration
          Center(
            child: Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emergency_outlined,
                size: 60.sp,
                color: Colors.red,
              ),
            ),
          ),
          
          SizedBox(height: 16.h),
          
          // Emergency contact description
          Center(
            child: Text(
              context.tr("emergency_contact_desc"),
              textAlign: TextAlign.center,
              style: GoogleFonts.raleway(
                fontSize: 14.sp,
                color: isDark ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
          ),
          
          SizedBox(height: 24.h),
          
          // Contact Name
          _buildSectionCard(
            isDark: isDark,
            icon: Icons.person_outline,
            title: context.tr("emergency_contact_name"),
            child: _buildTextField(
              controller: emergencyNameController,
              hint: context.tr("enter_emergency_name"),
              isDark: isDark,
            ),
          ),
          
          SizedBox(height: 16.h),
          
          // Relationship
          _buildSectionCard(
            isDark: isDark,
            icon: Icons.people_outline,
            title: context.tr("emergency_relationship"),
            child: _buildTextField(
              controller: emergencyRelationController,
              hint: context.tr("enter_emergency_relationship"),
              isDark: isDark,
            ),
          ),
          
          SizedBox(height: 16.h),
          
          // Phone
          _buildSectionCard(
            isDark: isDark,
            icon: Icons.phone_outlined,
            title: context.tr("emergency_phone"),
            child: _buildTextField(
              controller: emergencyPhoneController,
              hint: context.tr("enter_emergency_phone"),
              keyboardType: TextInputType.phone,
              isDark: isDark,
            ),
          ),
          
          SizedBox(height: 24.h),
          
          // Skip note
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.skip_next_outlined, color: Colors.orange, size: 20.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    context.tr("skip_emergency_note"),
                    style: GoogleFonts.raleway(
                      fontSize: 13.sp,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 30.h),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required Widget child,
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
              Text(
                title,
                style: GoogleFonts.raleway(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    required bool isDark,
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
      ),
    );
  }

  Widget _buildNavigationButtons(bool isDark) {
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
          // Skip button (only on first page)
          if (_currentPage == 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  side: BorderSide(color: AppColors.primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: Text(
                  context.tr("skip"),
                  style: GoogleFonts.raleway(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ),
          
          if (_currentPage == 0) SizedBox(width: 12.w),
          
          // Continue/Finish button
          Expanded(
            flex: _currentPage == 0 ? 2 : 1,
            child: ElevatedButton(
              onPressed: _nextPage,
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
                    _currentPage == 1 ? context.tr("finish") : context.tr("continue"),
                    style: GoogleFonts.raleway(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(
                    _currentPage == 1 ? Icons.check : Icons.arrow_forward,
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
