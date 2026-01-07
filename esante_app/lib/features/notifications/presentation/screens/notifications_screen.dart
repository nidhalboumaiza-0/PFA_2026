import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/notification_entity.dart';
import '../bloc/notification_bloc.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NotificationBloc>()..add(const LoadNotifications()),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              if (state is NotificationsLoaded && state.unreadCount > 0) {
                return TextButton(
                  onPressed: () {
                    context.read<NotificationBloc>().add(
                          const MarkAllNotificationsAsRead(),
                        );
                  },
                  child: Text(
                    'Mark all read',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14.sp,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NotificationError) {
            return ErrorStateWidget(
              title: 'Unable to load notifications',
              message: state.message,
              imagePath: AppAssets.onlineDoctorPanaImage,
              onRetry: () {
                context.read<NotificationBloc>().add(const LoadNotifications());
              },
            );
          }

          if (state is NotificationsLoaded) {
            if (state.notifications.isEmpty) {
              return _buildEmptyState(context);
            }

            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<NotificationBloc>()
                    .add(const LoadNotifications(refresh: true));
              },
              child: ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                itemCount: state.notifications.length + (state.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= state.notifications.length) {
                    // Load more trigger
                    context
                        .read<NotificationBloc>()
                        .add(const LoadMoreNotifications());
                    return Padding(
                      padding: EdgeInsets.all(16.r),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }

                  final notification = state.notifications[index];
                  return _NotificationCard(
                    notification: notification,
                    isDark: isDark,
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              AppAssets.waitingAppointmentLottie,
              width: 200.w,
              height: 200.h,
            ),
            SizedBox(height: 24.h),
            Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'When you receive notifications about\nappointments, messages, and more,\nthey\'ll appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary(context),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationEntity notification;
  final bool isDark;

  const _NotificationCard({
    required this.notification,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        color: AppColors.error,
        child: Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: 28.sp,
        ),
      ),
      onDismissed: (_) {
        context.read<NotificationBloc>().add(
              DeleteNotification(notification.id),
            );
      },
      child: InkWell(
        onTap: () => _handleTap(context),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: notification.isRead
                ? (isDark ? AppColors.surface(context) : Colors.white)
                : AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16.r),
            border: !notification.isRead
                ? Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 1,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: 10.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIcon(),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8.w,
                            height: 8.h,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.textSecondary(context),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14.sp,
                          color: AppColors.grey400,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          timeago.format(notification.createdAt),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.grey400,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: _getTypeColor().withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            notification.type.displayName,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: _getTypeColor(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 48.w,
      height: 48.h,
      decoration: BoxDecoration(
        color: _getTypeColor().withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Icon(
        _getIcon(),
        color: _getTypeColor(),
        size: 24.sp,
      ),
    );
  }

  IconData _getIcon() {
    switch (notification.type) {
      case NotificationType.appointmentConfirmed:
        return Icons.check_circle_outline;
      case NotificationType.appointmentRejected:
        return Icons.cancel_outlined;
      case NotificationType.appointmentCancelled:
        return Icons.event_busy_outlined;
      case NotificationType.appointmentReminder:
        return Icons.alarm;
      case NotificationType.appointmentRescheduled:
      case NotificationType.rescheduleRequested:
        return Icons.schedule;
      case NotificationType.newMessage:
        return Icons.message_outlined;
      case NotificationType.referralReceived:
      case NotificationType.referralScheduled:
        return Icons.share_outlined;
      case NotificationType.prescriptionCreated:
        return Icons.medication_outlined;
      case NotificationType.consultationCreated:
        return Icons.description_outlined;
      case NotificationType.newAppointmentRequest:
        return Icons.calendar_today_outlined;
      case NotificationType.general:
        return Icons.notifications_outlined;
    }
  }

  Color _getTypeColor() {
    switch (notification.type) {
      case NotificationType.appointmentConfirmed:
        return AppColors.success;
      case NotificationType.appointmentRejected:
      case NotificationType.appointmentCancelled:
        return AppColors.error;
      case NotificationType.appointmentReminder:
        return AppColors.warning;
      case NotificationType.appointmentRescheduled:
      case NotificationType.rescheduleRequested:
        return AppColors.info;
      case NotificationType.newMessage:
        return AppColors.primary;
      case NotificationType.referralReceived:
      case NotificationType.referralScheduled:
        return Colors.purple;
      case NotificationType.prescriptionCreated:
        return Colors.teal;
      case NotificationType.consultationCreated:
        return Colors.indigo;
      case NotificationType.newAppointmentRequest:
        return AppColors.secondary;
      case NotificationType.general:
        return AppColors.grey500;
    }
  }

  void _handleTap(BuildContext context) {
    // Mark as read if not already
    if (!notification.isRead) {
      context.read<NotificationBloc>().add(
            MarkNotificationAsRead(notification.id),
          );
    }

    // Navigate based on type
    final navigator = Navigator.of(context);
    switch (notification.type) {
      case NotificationType.appointmentConfirmed:
      case NotificationType.appointmentRejected:
      case NotificationType.appointmentCancelled:
      case NotificationType.appointmentReminder:
      case NotificationType.appointmentRescheduled:
      case NotificationType.rescheduleRequested:
      case NotificationType.newAppointmentRequest:
        if (notification.resourceId != null) {
          navigator.pushNamed(
            '/appointment-details',
            arguments: {'appointmentId': notification.resourceId},
          );
        } else {
          navigator.pushNamed('/appointments');
        }
        break;
      case NotificationType.newMessage:
        if (notification.actionData?['conversationId'] != null) {
          navigator.pushNamed(
            '/chat',
            arguments: notification.actionData,
          );
        } else {
          navigator.pushNamed('/messages');
        }
        break;
      case NotificationType.prescriptionCreated:
      case NotificationType.consultationCreated:
        navigator.pushNamed('/medical-records');
        break;
      case NotificationType.referralReceived:
      case NotificationType.referralScheduled:
        navigator.pushNamed('/referrals');
        break;
      case NotificationType.general:
        break;
    }
  }
}
