import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../injection_container.dart';
import '../../../messaging/presentation/screens/conversations_screen.dart';
import '../../../profile/presentation/blocs/doctor_profile/doctor_profile_bloc.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

/// Dashboard content for doctor users (without bottom navigation)
/// This is used inside DoctorMainNavigation
class DoctorDashboardContent extends StatefulWidget {
  final ValueChanged<int>? onNavigateToTab;

  const DoctorDashboardContent({
    super.key,
    this.onNavigateToTab,
  });

  @override
  State<DoctorDashboardContent> createState() => _DoctorDashboardContentState();
}

class _DoctorDashboardContentState extends State<DoctorDashboardContent> {
  late final DoctorProfileBloc _profileBloc;
  
  @override
  void initState() {
    super.initState();
    _profileBloc = sl<DoctorProfileBloc>();
    _profileBloc.add(LoadDoctorProfile());
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider.value(
      value: _profileBloc,
      child: SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.h,
            floating: true,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: isDark ? AppColors.surface(context) : Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Doctor Dashboard',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              centerTitle: true,
            ),
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ConversationsScreen(),
                    ),
                  );
                },
                icon: Badge(
                  smallSize: 8.r,
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: 24.sp,
                  ),
                ),
                tooltip: 'Messages',
              ),
              IconButton(
                onPressed: () {
                  // TODO: Navigate to notifications
                },
                icon: Badge(
                  smallSize: 8.r,
                  child: Icon(
                    Icons.notifications_outlined,
                    size: 24.sp,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileCard(context),
                  SizedBox(height: 24.h),
                  _buildQuickStats(context),
                  SizedBox(height: 24.h),
                  _buildQuickActions(context),
                  SizedBox(height: 24.h),
                  _buildSectionTitle(context, 'Today\'s Appointments'),
                  SizedBox(height: 12.h),
                  _buildEmptyState(
                    context,
                    icon: Icons.calendar_today_outlined,
                    title: 'No appointments today',
                    subtitle: 'Your schedule is clear',
                  ),
                  SizedBox(height: 24.h),
                  _buildSectionTitle(context, 'Recent Patients'),
                  SizedBox(height: 12.h),
                  _buildEmptyState(
                    context,
                    icon: Icons.people_outline,
                    title: 'No recent patients',
                    subtitle: 'Patient consultations will appear here',
                  ),
                  SizedBox(height: 100.h), // Extra space for bottom nav
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return BlocBuilder<DoctorProfileBloc, DoctorProfileState>(
      builder: (context, state) {
        String doctorName = 'Doctor';
        String? profilePhoto;
        
        if (state is DoctorProfileLoaded) {
          doctorName = 'Dr. ${state.profile.fullName}'.trim();
          if (doctorName == 'Dr. ') doctorName = 'Doctor';
          profilePhoto = state.profile.profilePhoto;
        }
        
        return GestureDetector(
          onTap: () {
            widget.onNavigateToTab?.call(3);
          },
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20.r,
                  offset: Offset(0, 10.h),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 60.w,
                  height: 60.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2.w,
                    ),
                    image: profilePhoto != null && profilePhoto.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(profilePhoto),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: profilePhoto == null || profilePhoto.isEmpty
                      ? Icon(
                          Icons.medical_services_rounded,
                          size: 32.sp,
                          color: Colors.white,
                        )
                      : null,
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back!',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        doctorName,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 24.sp,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildStatCard(context, '0', 'Today', Icons.calendar_today, AppColors.primary)),
        SizedBox(width: 12.w),
        Expanded(child: _buildStatCard(context, '0', 'Pending', Icons.pending_actions, AppColors.warning)),
        SizedBox(width: 12.w),
        Expanded(child: _buildStatCard(context, '0', 'Completed', Icons.check_circle_outline, AppColors.success)),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String value, String label, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface(context) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 24.sp, color: color),
          SizedBox(height: 8.h),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary(context),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.calendar_month_rounded,
        label: 'Appointments',
        color: AppColors.primary,
        onTap: () => widget.onNavigateToTab?.call(1),
      ),
      _QuickAction(
        icon: Icons.schedule_rounded,
        label: 'Availability',
        color: AppColors.success,
        onTap: () => widget.onNavigateToTab?.call(2),
      ),
      _QuickAction(
        icon: Icons.message_rounded,
        label: 'Messages',
        color: AppColors.info,
        onTap: () {
          // TODO: Navigate to messages
        },
      ),
      _QuickAction(
        icon: Icons.settings_rounded,
        label: 'Settings',
        color: AppColors.warning,
        onTap: () {
          context.pushPage(const SettingsScreen());
        },
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.map((action) => _buildQuickActionItem(context, action)).toList(),
    );
  }

  Widget _buildQuickActionItem(BuildContext context, _QuickAction action) {
    return GestureDetector(
      onTap: action.onTap,
      child: Column(
        children: [
          Container(
            width: 64.w,
            height: 64.h,
            decoration: BoxDecoration(
              color: action.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: action.color.withValues(alpha: 0.2),
                width: 1.w,
              ),
            ),
            child: Icon(
              action.icon,
              size: 28.sp,
              color: action.color,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            action.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        TextButton(
          onPressed: () {},
          child: Text(
            'See all',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface(context) : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : AppColors.shadow(context).withValues(alpha: 0.08),
            blurRadius: 20.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64.w,
            height: 64.h,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 32.sp,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: 4.h),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary(context),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
