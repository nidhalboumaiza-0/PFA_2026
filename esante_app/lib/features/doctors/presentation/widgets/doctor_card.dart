import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/doctor_entity.dart';

class DoctorCard extends StatelessWidget {
  final DoctorEntity doctor;
  final VoidCallback? onTap;

  const DoctorCard({
    super.key,
    required this.doctor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Row(
            children: [
              // Profile Image
              _buildProfileImage(),
              SizedBox(width: 16.w),
              
              // Doctor Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and Verified Badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Dr. ${doctor.fullName}',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (doctor.isVerified)
                          Icon(
                            Icons.verified,
                            color: AppColors.primary,
                            size: 18.sp,
                          ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    
                    // Specialty
                    Text(
                      doctor.displaySpecialty,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.grey400,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    
                    // Bottom Row: Rating, Distance, Fee
                    Row(
                      children: [
                        // Rating
                        if (doctor.rating != null) ...[
                          Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 16.sp,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            doctor.rating!.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 12.w),
                        ],
                        
                        // Distance
                        if (doctor.distance != null) ...[
                          Icon(
                            Icons.location_on_outlined,
                            color: AppColors.grey400,
                            size: 16.sp,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            doctor.displayDistance,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: AppColors.grey400,
                            ),
                          ),
                          SizedBox(width: 12.w),
                        ],
                        
                        // Consultation Fee
                        if (doctor.consultationFee != null) ...[
                          Icon(
                            Icons.payments_outlined,
                            color: AppColors.success,
                            size: 16.sp,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            '${doctor.consultationFee} TND',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Arrow
              Icon(
                Icons.chevron_right,
                color: AppColors.grey400,
                size: 24.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Container(
      width: 70.w,
      height: 70.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        color: AppColors.primary.withValues(alpha: 0.1),
      ),
      child: doctor.profilePhoto != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: Image.network(
                doctor.profilePhoto!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder(),
              ),
            )
          : _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        Icons.person,
        color: AppColors.primary,
        size: 36.sp,
      ),
    );
  }
}
