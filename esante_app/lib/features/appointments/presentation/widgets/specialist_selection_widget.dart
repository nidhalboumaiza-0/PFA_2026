import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../doctors/domain/entities/doctor_entity.dart';

/// A widget for selecting a specialist doctor for referral appointments.
/// 
/// Displays a searchable list of specialist doctors with their specialties,
/// ratings, and availability information.
class SpecialistSelectionWidget extends StatefulWidget {
  final DoctorEntity? selectedSpecialist;
  final Function(DoctorEntity) onSpecialistSelected;
  final String? filterSpecialty;

  const SpecialistSelectionWidget({
    super.key,
    this.selectedSpecialist,
    required this.onSpecialistSelected,
    this.filterSpecialty,
  });

  @override
  State<SpecialistSelectionWidget> createState() => _SpecialistSelectionWidgetState();
}

class _SpecialistSelectionWidgetState extends State<SpecialistSelectionWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedSpecialty = 'All';
  
  // Mock specialist data - In production, fetch from API
  final List<DoctorEntity> _mockSpecialists = const [
    DoctorEntity(
      id: 'doc_spec_1',
      firstName: 'Sarah',
      lastName: 'Chen',
      specialty: 'Cardiology',
      clinicName: 'City Heart Center',
      rating: 4.9,
      reviewCount: 234,
      yearsOfExperience: 15,
      isVerified: true,
      isActive: true,
      consultationFee: 150,
    ),
    DoctorEntity(
      id: 'doc_spec_2',
      firstName: 'Michael',
      lastName: 'Brown',
      specialty: 'Neurology',
      clinicName: 'Metro Neuroscience Institute',
      rating: 4.8,
      reviewCount: 189,
      yearsOfExperience: 12,
      isVerified: true,
      isActive: true,
      consultationFee: 180,
    ),
    DoctorEntity(
      id: 'doc_spec_3',
      firstName: 'Emily',
      lastName: 'Rodriguez',
      specialty: 'Orthopedics',
      clinicName: 'Sports Medicine Center',
      rating: 4.7,
      reviewCount: 156,
      yearsOfExperience: 10,
      isVerified: true,
      isActive: true,
      consultationFee: 140,
    ),
    DoctorEntity(
      id: 'doc_spec_4',
      firstName: 'James',
      lastName: 'Wilson',
      specialty: 'Dermatology',
      clinicName: 'Skin Care Clinic',
      rating: 4.6,
      reviewCount: 98,
      yearsOfExperience: 8,
      isVerified: true,
      isActive: true,
      consultationFee: 120,
    ),
    DoctorEntity(
      id: 'doc_spec_5',
      firstName: 'Lisa',
      lastName: 'Thompson',
      specialty: 'Cardiology',
      clinicName: 'Heart & Vascular Institute',
      rating: 4.9,
      reviewCount: 312,
      yearsOfExperience: 18,
      isVerified: true,
      isActive: false,
      consultationFee: 200,
    ),
    DoctorEntity(
      id: 'doc_spec_6',
      firstName: 'Ahmed',
      lastName: 'Hassan',
      specialty: 'Gastroenterology',
      clinicName: 'Digestive Health Center',
      rating: 4.8,
      reviewCount: 145,
      yearsOfExperience: 11,
      isVerified: true,
      isActive: true,
      consultationFee: 160,
    ),
  ];

  List<String> get _specialties {
    final specialties = _mockSpecialists.map((s) => s.specialty).toSet().toList();
    specialties.sort();
    return ['All', ...specialties];
  }

  List<DoctorEntity> get _filteredSpecialists {
    return _mockSpecialists.where((specialist) {
      final matchesSearch = specialist.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          specialist.specialty.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (specialist.clinicName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      
      final matchesSpecialty = _selectedSpecialty == 'All' || 
          specialist.specialty == _selectedSpecialty;
      
      return matchesSearch && matchesSpecialty;
    }).toList();
  }

  Color _getSpecialtyColor(String specialty) {
    final colors = {
      'Cardiology': const Color(0xFFE53935),
      'Neurology': const Color(0xFF8E24AA),
      'Orthopedics': const Color(0xFF1E88E5),
      'Dermatology': const Color(0xFFFF8F00),
      'Gastroenterology': const Color(0xFF43A047),
    };
    return colors[specialty] ?? const Color(0xFF757575);
  }

  IconData _getSpecialtyIcon(String specialty) {
    final icons = {
      'Cardiology': Icons.favorite_rounded,
      'Neurology': Icons.psychology_rounded,
      'Orthopedics': Icons.accessibility_new_rounded,
      'Dermatology': Icons.face_rounded,
      'Gastroenterology': Icons.medical_services_rounded,
    };
    return icons[specialty] ?? Icons.local_hospital_rounded;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected specialist card
        if (widget.selectedSpecialist != null)
          _buildSelectedSpecialistCard(widget.selectedSpecialist!, theme),
        
        if (widget.selectedSpecialist != null)
          SizedBox(height: 16.h),

        // Search bar
        _buildSearchBar(theme),
        SizedBox(height: 12.h),

        // Specialty filter chips
        _buildSpecialtyFilter(theme),
        SizedBox(height: 16.h),

        // Results count
        Text(
          '${_filteredSpecialists.length} specialists found',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        SizedBox(height: 12.h),

        // Specialists list
        SizedBox(
          height: 380.h,
          child: _filteredSpecialists.isEmpty
              ? _buildEmptyState(theme)
              : ListView.builder(
                  itemCount: _filteredSpecialists.length,
                  itemBuilder: (context, index) {
                    final specialist = _filteredSpecialists[index];
                    final isSelected = specialist.id == widget.selectedSpecialist?.id;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: _buildSpecialistCard(specialist, isSelected, theme),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search by name, specialty, or clinic...',
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.primary,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        ),
      ),
    );
  }

  Widget _buildSpecialtyFilter(ThemeData theme) {
    return SizedBox(
      height: 40.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _specialties.length,
        itemBuilder: (context, index) {
          final specialty = _specialties[index];
          final isSelected = specialty == _selectedSpecialty;
          
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: FilterChip(
              label: Text(specialty),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedSpecialty = specialty);
              },
              backgroundColor: theme.colorScheme.surface,
              selectedColor: AppColors.primaryLight,
              labelStyle: theme.textTheme.labelMedium?.copyWith(
                color: isSelected 
                    ? AppColors.primary 
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
                side: BorderSide(
                  color: isSelected 
                      ? AppColors.primary 
                      : theme.colorScheme.outline.withOpacity(0.3),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedSpecialistCard(DoctorEntity specialist, ThemeData theme) {
    final specialtyColor = _getSpecialtyColor(specialist.specialty);
    
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Center(
              child: Icon(
                _getSpecialtyIcon(specialist.specialty),
                color: specialtyColor,
                size: 28.sp,
              ),
            ),
          ),
          SizedBox(width: 16.w),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 16.sp,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'Selected Specialist',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  'Dr. ${specialist.fullName}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '${specialist.specialty} • ${specialist.clinicName ?? 'Private Practice'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.85),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialistCard(DoctorEntity specialist, bool isSelected, ThemeData theme) {
    final specialtyColor = _getSpecialtyColor(specialist.specialty);
    final isAvailable = specialist.isActive;
    
    return GestureDetector(
      onTap: () => widget.onSpecialistSelected(specialist),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primaryLight.withOpacity(0.3)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected 
                ? AppColors.primary 
                : theme.colorScheme.outline.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.black.withOpacity(0.03),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row with avatar and basic info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with specialty icon
                Container(
                  width: 56.w,
                  height: 56.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        specialtyColor.withOpacity(0.15),
                        specialtyColor.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Center(
                    child: Icon(
                      _getSpecialtyIcon(specialist.specialty),
                      color: specialtyColor,
                      size: 26.sp,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                // Name and specialty
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Dr. ${specialist.fullName}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (specialist.isVerified)
                            Icon(
                              Icons.verified,
                              color: AppColors.primary,
                              size: 18.sp,
                            ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: specialtyColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          specialist.specialty,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: specialtyColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Availability indicator
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: isAvailable 
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.grey300.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6.w,
                        height: 6.w,
                        decoration: BoxDecoration(
                          color: isAvailable ? AppColors.success : AppColors.grey500,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        isAvailable ? 'Available' : 'Busy',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isAvailable ? AppColors.success : AppColors.grey500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            
            // Clinic
            if (specialist.clinicName != null)
              Row(
                children: [
                  Icon(
                    Icons.local_hospital_outlined,
                    size: 16.sp,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      specialist.clinicName!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            if (specialist.clinicName != null) SizedBox(height: 12.h),
            
            // Stats row
            Row(
              children: [
                // Rating
                if (specialist.rating != null)
                  _buildStatChip(
                    icon: Icons.star_rounded,
                    value: '${specialist.rating}',
                    label: specialist.reviewCount != null ? '(${specialist.reviewCount})' : null,
                    iconColor: Colors.amber,
                    theme: theme,
                  ),
                if (specialist.rating != null) SizedBox(width: 16.w),
                // Experience
                if (specialist.yearsOfExperience != null)
                  _buildStatChip(
                    icon: Icons.work_history_rounded,
                    value: '${specialist.yearsOfExperience} yrs',
                    iconColor: AppColors.primary,
                    theme: theme,
                  ),
                const Spacer(),
                // Consultation fee
                if (specialist.consultationFee != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      '\$${specialist.consultationFee}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12.h),
            
            // Select indicator
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.primary.withOpacity(0.1)
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: isSelected 
                      ? AppColors.primary 
                      : theme.colorScheme.outline.withOpacity(0.1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isSelected ? Icons.check_circle : Icons.add_circle_outline,
                    size: 18.sp,
                    color: isSelected ? AppColors.primary : AppColors.grey500,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    isSelected ? 'Selected' : 'Tap to select',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isSelected ? AppColors.primary : AppColors.grey500,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String value,
    String? label,
    required Color iconColor,
    required ThemeData theme,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16.sp, color: iconColor),
        SizedBox(width: 4.w),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        if (label != null) ...[
          SizedBox(width: 2.w),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_search_rounded,
              size: 48.sp,
              color: AppColors.primary.withOpacity(0.5),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'No specialists found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Try adjusting your search or filters',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
