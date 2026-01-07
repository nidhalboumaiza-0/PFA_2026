import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_list.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../injection_container.dart';
import '../../data/models/patient_profile_model.dart';
import '../../domain/entities/patient_profile_entity.dart';

/// Screen to view another patient's profile
class PatientDetailScreen extends StatefulWidget {
  final String patientId;

  const PatientDetailScreen({
    super.key,
    required this.patientId,
  });

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  PatientProfileEntity? _patient;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPatient();
  }

  Future<void> _loadPatient() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiClient = sl<ApiClient>();
      // Use generic profile endpoint which works with any profile ID
      final response = await apiClient.get(ApiList.profileById(widget.patientId));
      
      // Parse the response - the endpoint returns data with profile info
      final patientData = response['data'] ?? response;
      
      setState(() {
        _patient = PatientProfileModel.fromJson(patientData);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load patient profile';
        _isLoading = false;
      });
      print('[PatientDetailScreen] Error loading patient: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? _buildLoadingView()
          : _error != null
              ? _buildErrorView()
              : _buildContent(),
    );
  }

  Widget _buildLoadingView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Header placeholder
            Container(
              height: 280.h,
              color: Colors.white,
            ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: List.generate(
                  5,
                  (index) => Padding(
                    padding: EdgeInsets.only(bottom: 16.h),
                    child: Container(
                      height: 80.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: AppColors.primary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64.sp, color: Colors.grey),
                SizedBox(height: 16.h),
                AppBodyText(
                  text: _error ?? 'Something went wrong',
                  color: Colors.grey,
                ),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: _loadPatient,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final patient = _patient!;
    
    return CustomScrollView(
      slivers: [
        // App Bar with profile header
        SliverAppBar(
          expandedHeight: 280.h,
          pinned: true,
          backgroundColor: AppColors.primary,
          leading: IconButton(
            icon: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: _buildProfileHeader(patient),
          ),
        ),

        // Content
        SliverPadding(
          padding: EdgeInsets.all(16.w),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Basic Info Card
              _buildInfoCard(
                title: 'Basic Information',
                icon: Icons.person_outline,
                children: [
                  _buildInfoRow('Gender', patient.gender.isNotEmpty 
                      ? patient.gender[0].toUpperCase() + patient.gender.substring(1) 
                      : 'Not specified'),
                  _buildInfoRow('Age', '${patient.age} years old'),
                  if (patient.bloodType != null)
                    _buildInfoRow('Blood Type', patient.bloodType!),
                ],
              ),
              SizedBox(height: 16.h),

              // Contact Info Card
              _buildInfoCard(
                title: 'Contact Information',
                icon: Icons.contact_phone_outlined,
                children: [
                  _buildInfoRow('Phone', patient.phone.isNotEmpty 
                      ? patient.phone 
                      : 'Not provided'),
                  if (patient.email != null && patient.email!.isNotEmpty)
                    _buildInfoRow('Email', patient.email!),
                  if (patient.address != null && patient.address!.city != null)
                    _buildInfoRow('City', patient.address!.city!),
                ],
              ),
              SizedBox(height: 16.h),

              // Medical Info Card
              if (patient.allergies.isNotEmpty || patient.chronicDiseases.isNotEmpty)
                _buildInfoCard(
                  title: 'Medical Information',
                  icon: Icons.medical_information_outlined,
                  children: [
                    if (patient.allergies.isNotEmpty)
                      _buildInfoRow('Allergies', patient.allergies.join(', ')),
                    if (patient.chronicDiseases.isNotEmpty)
                      _buildInfoRow('Chronic Diseases', patient.chronicDiseases.join(', ')),
                  ],
                ),

              SizedBox(height: 80.h), // Bottom padding
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(PatientProfileEntity patient) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 40.h),
            // Profile Photo
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: CircleAvatar(
                radius: 50.r,
                backgroundColor: Colors.white,
                backgroundImage: patient.profilePhoto != null
                    ? NetworkImage(patient.profilePhoto!)
                    : null,
                child: patient.profilePhoto == null
                    ? Text(
                        _getInitials(patient.fullName),
                        style: TextStyle(
                          fontSize: 32.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
            ),
            SizedBox(height: 16.h),
            // Name
            Text(
              patient.fullName,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4.h),
            // Patient tag
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                'Patient',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
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
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20.sp),
              ),
              SizedBox(width: 12.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }
}
