import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/appointment_entity.dart';

/// Widget for selecting a patient from the doctor's patient list
/// For referral booking purposes
class PatientSelectionWidget extends StatefulWidget {
  final PatientInfo? selectedPatient;
  final Function(PatientInfo) onPatientSelected;

  const PatientSelectionWidget({
    super.key,
    this.selectedPatient,
    required this.onPatientSelected,
  });

  @override
  State<PatientSelectionWidget> createState() => _PatientSelectionWidgetState();
}

class _PatientSelectionWidgetState extends State<PatientSelectionWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<PatientInfo> _filteredPatients = [];
  final bool _isLoading = false;
  String _searchQuery = '';

  // Mock data for demonstration - in real app, fetch from API
  final List<PatientInfo> _mockPatients = [
    const PatientInfo(
      id: '1',
      firstName: 'Mohamed',
      lastName: 'Ben Ahmed',
      profilePhoto: null,
    ),
    const PatientInfo(
      id: '2',
      firstName: 'Fatma',
      lastName: 'Trabelsi',
      profilePhoto: null,
    ),
    const PatientInfo(
      id: '3',
      firstName: 'Karim',
      lastName: 'Bouazizi',
      profilePhoto: null,
    ),
    const PatientInfo(
      id: '4',
      firstName: 'Sara',
      lastName: 'Khemiri',
      profilePhoto: null,
    ),
    const PatientInfo(
      id: '5',
      firstName: 'Ahmed',
      lastName: 'Gharbi',
      profilePhoto: null,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _filteredPatients = _mockPatients;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterPatients(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredPatients = _mockPatients;
      } else {
        _filteredPatients = _mockPatients.where((patient) {
          final fullName = patient.fullName.toLowerCase();
          return fullName.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Field
        CustomTextField(
          controller: _searchController,
          hintText: 'Search patient by name...',
          prefixIcon: Icons.search,
          onChanged: _filterPatients,
        ),
        SizedBox(height: 16.h),

        // Selected Patient Card (if any)
        if (widget.selectedPatient != null) ...[
          _buildSelectedPatientCard(widget.selectedPatient!),
          SizedBox(height: 16.h),
          const Divider(),
          SizedBox(height: 8.h),
          Text(
            'Or select another patient:',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.grey500,
            ),
          ),
          SizedBox(height: 8.h),
        ],

        // Patient List
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_filteredPatients.isEmpty)
          _buildEmptyState()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredPatients.length,
            separatorBuilder: (_, __) => SizedBox(height: 8.h),
            itemBuilder: (context, index) {
              final patient = _filteredPatients[index];
              final isSelected = widget.selectedPatient?.id == patient.id;
              return _buildPatientCard(patient, isSelected);
            },
          ),
      ],
    );
  }

  Widget _buildSelectedPatientCard(PatientInfo patient) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withValues(alpha: 0.15),
            AppColors.success.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.success,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success.withValues(alpha: 0.2),
              border: Border.all(
                color: AppColors.success,
                width: 2,
              ),
            ),
            child: patient.profilePhoto != null
                ? ClipOval(
                    child: Image.network(
                      patient.profilePhoto!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Center(
                    child: Text(
                      _getInitials(patient.fullName),
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ),
          ),
          SizedBox(width: 16.w),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 18.sp,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'Selected Patient',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  patient.fullName,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Change button
          TextButton(
            onPressed: () {
              // Clear selection to show list
              widget.onPatientSelected(const PatientInfo(
                id: '',
                firstName: '',
                lastName: '',
              ));
            },
            child: Text(
              'Change',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 13.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(PatientInfo patient, bool isSelected) {
    return GestureDetector(
      onTap: () => widget.onPatientSelected(patient),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.grey300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getAvatarColor(patient.firstName).withValues(alpha: 0.2),
              ),
              child: patient.profilePhoto != null
                  ? ClipOval(
                      child: Image.network(
                        patient.profilePhoto!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: Text(
                        _getInitials(patient.fullName),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: _getAvatarColor(patient.firstName),
                        ),
                      ),
                    ),
            ),
            SizedBox(width: 12.w),
            
            // Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient.fullName,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Patient',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.grey500,
                    ),
                  ),
                ],
              ),
            ),
            
            // Selection indicator
            if (isSelected)
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16.sp,
                ),
              )
            else
              Container(
                width: 24.w,
                height: 24.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.grey400,
                    width: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(32.w),
      child: Column(
        children: [
          Icon(
            Icons.person_search,
            size: 64.sp,
            color: AppColors.grey400,
          ),
          SizedBox(height: 16.h),
          Text(
            _searchQuery.isEmpty
                ? 'No patients found'
                : 'No patients matching "$_searchQuery"',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.grey500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Color _getAvatarColor(String name) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.info,
      AppColors.success,
      Colors.purple,
      Colors.orange,
      Colors.teal,
    ];
    return colors[name.hashCode % colors.length];
  }
}
