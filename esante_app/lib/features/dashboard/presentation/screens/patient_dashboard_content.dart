import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../injection_container.dart';
import '../../../messaging/presentation/bloc/messaging_bloc.dart';
import '../../../messaging/presentation/bloc/messaging_event.dart';
import '../../../messaging/presentation/bloc/messaging_state.dart';
import '../../../messaging/presentation/screens/conversations_screen.dart';
import '../../../notifications/presentation/bloc/notification_bloc.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../profile/domain/entities/patient_profile_entity.dart';
import '../../../profile/domain/usecases/check_profile_completion_usecase.dart';
import '../../../profile/presentation/blocs/patient_profile/patient_profile_bloc.dart';
import '../../../prescriptions/presentation/screens/my_prescriptions_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

/// Dashboard content for patient users (without bottom navigation)
/// This is used inside PatientMainNavigation
class PatientDashboardContent extends StatefulWidget {
  final bool showProfileCompletionDialog;
  final int profileCompletionPercentage;
  final ValueChanged<int>? onNavigateToTab;
  
  const PatientDashboardContent({
    super.key,
    this.showProfileCompletionDialog = false,
    this.profileCompletionPercentage = 0,
    this.onNavigateToTab,
  });

  @override
  State<PatientDashboardContent> createState() => _PatientDashboardContentState();
}

class _PatientDashboardContentState extends State<PatientDashboardContent> {
  late final PatientProfileBloc _profileBloc;
  late final MessagingBloc _messagingBloc;
  
  @override
  void initState() {
    super.initState();
    _profileBloc = sl<PatientProfileBloc>();
    _profileBloc.add(LoadPatientProfile());
    
    // Get messaging bloc and fetch unread count
    _messagingBloc = sl<MessagingBloc>();
    _messagingBloc.add(const GetUnreadCount());
    
    if (widget.showProfileCompletionDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showProfileCompletionDialog();
      });
    }
  }

  void _showProfileCompletionDialog() {
    if (!mounted) return;
    
    ProfileCompletionDialog.show(
      context,
      completionPercentage: widget.profileCompletionPercentage,
      onCompleteNow: () {
        // Navigate to profile tab
        widget.onNavigateToTab?.call(3);
      },
      onLater: () async {
        final markShownUseCase = sl<MarkProfileCompletionShownUseCase>();
        await markShownUseCase();
        print('[PatientDashboard] User chose to complete profile later');
      },
    );
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
                  'Dashboard',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                centerTitle: true,
              ),
              actions: [
                // Messages icon with unread badge
                BlocBuilder<MessagingBloc, MessagingState>(
                  bloc: _messagingBloc,
                  buildWhen: (previous, current) => 
                    current is UnreadCountLoaded || current is ConversationsLoaded,
                  builder: (context, state) {
                    final unreadCount = _messagingBloc.unreadCount;
                    return IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ConversationsScreen(),
                          ),
                        );
                      },
                      icon: unreadCount > 0
                          ? Badge(
                              label: unreadCount > 99 
                                  ? const Text('99+') 
                                  : Text(unreadCount.toString()),
                              child: Icon(
                                Icons.chat_bubble_outline,
                                size: 24.sp,
                              ),
                            )
                          : Icon(
                              Icons.chat_bubble_outline,
                              size: 24.sp,
                            ),
                      tooltip: 'Messages',
                    );
                  },
                ),
                // Notifications icon with real unread count
                BlocProvider(
                  create: (_) => sl<NotificationBloc>()..add(const RefreshUnreadCount()),
                  child: BlocBuilder<NotificationBloc, NotificationState>(
                    builder: (context, state) {
                      final unreadCount = state is NotificationsLoaded 
                          ? state.unreadCount 
                          : 0;
                      return IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          );
                        },
                        icon: unreadCount > 0
                            ? Badge(
                                label: unreadCount > 99
                                    ? const Text('99+')
                                    : Text(unreadCount.toString()),
                                child: Icon(
                                  Icons.notifications_outlined,
                                  size: 24.sp,
                                ),
                              )
                            : Icon(
                                Icons.notifications_outlined,
                                size: 24.sp,
                              ),
                        tooltip: 'Notifications',
                      );
                    },
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
                    _buildQuickActions(context),
                    SizedBox(height: 24.h),
                    _buildSectionTitle(context, 'Upcoming Appointments'),
                    SizedBox(height: 12.h),
                    _buildEmptyState(
                      context,
                      icon: Icons.calendar_today_outlined,
                      title: 'No appointments scheduled',
                      subtitle: 'Book an appointment with a doctor',
                    ),
                    SizedBox(height: 24.h),
                    _buildSectionTitle(context, 'Recent Activity'),
                    SizedBox(height: 12.h),
                    _buildEmptyState(
                      context,
                      icon: Icons.history_outlined,
                      title: 'No recent activity',
                      subtitle: 'Your medical history will appear here',
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
    return BlocBuilder<PatientProfileBloc, PatientProfileState>(
      builder: (context, state) {
        String userName = 'Patient';
        String? profilePhoto;
        
        if (state is PatientProfileLoaded) {
          userName = state.profile.fullName.isNotEmpty 
              ? state.profile.fullName 
              : 'Patient';
          profilePhoto = state.profile.profilePhoto;
        } else if (state is PatientProfileUpdated) {
          userName = state.profile.fullName.isNotEmpty 
              ? state.profile.fullName 
              : 'Patient';
          profilePhoto = state.profile.profilePhoto;
        }
        
        return GestureDetector(
          onTap: () {
            // Navigate to profile tab
            widget.onNavigateToTab?.call(3);
          },
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
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
                          Icons.person_rounded,
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
                        userName,
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

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.search_rounded,
        label: 'Find Doctor',
        color: AppColors.primary,
        onTap: () => widget.onNavigateToTab?.call(1),
      ),
      _QuickAction(
        icon: Icons.calendar_month_rounded,
        label: 'Appointments',
        color: AppColors.success,
        onTap: () => widget.onNavigateToTab?.call(2),
      ),
      _QuickAction(
        icon: Icons.receipt_long_rounded,
        label: 'Prescriptions',
        color: AppColors.error,
        onTap: () => context.pushPage(
          const MyPrescriptionsScreen(),
          transition: NavTransition.slideUp,
        ),
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
