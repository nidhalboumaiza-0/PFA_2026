import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/core/widgets/common/common_widgets.dart';
import 'package:medical_app/features/authentication/data/data%20sources/auth_local_data_source.dart';
import 'package:medical_app/features/authentication/domain/entities/user_entity.dart';
import 'package:medical_app/features/notifications/domain/entities/notification_entity.dart';
import 'package:medical_app/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:medical_app/features/notifications/presentation/bloc/notification_event.dart';
import 'package:medical_app/features/notifications/presentation/bloc/notification_state.dart';
import 'package:medical_app/features/rendez_vous/presentation/blocs/rendez-vous%20BLoC/rendez_vous_bloc.dart';
import 'package:medical_app/features/rendez_vous/presentation/pages/appointment_details.dart';
import 'package:medical_app/injection_container.dart' as di;

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late UserEntity _currentUser;
  bool _isLoading = true;
  String _selectedFilter = 'all';
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isLoading && _currentUser.id != null) {
      _refreshNotifications(showLoading: false);
    }
  }

  Future<void> _loadUserData() async {
    try {
      final authLocalDataSource = di.sl<AuthLocalDataSource>();
      final user = await authLocalDataSource.getUser();

      setState(() {
        _currentUser = user;
      });

      if (user.id != null) {
        print('Setting up notifications stream for user: ${user.id}');
        context.read<NotificationBloc>().add(
          GetNotificationsStreamEvent(userId: user.id!),
        );

        print('Loading notifications for user: ${user.id}');
        context.read<NotificationBloc>().add(
          const GetNotificationsEvent(),
        );

        context.read<NotificationBloc>().add(
          MarkAllNotificationsAsReadEvent(userId: user.id!),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('error_loading_user_data'))));
    }
  }

  Future<void> _refreshNotifications({bool showLoading = true}) async {
    if (_currentUser.id == null) return;

    if (showLoading) {
      setState(() {
        _isLoading = true;
      });

      Future.delayed(Duration(seconds: 5), () {
        if (mounted && _isLoading) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(context.tr('loading_timeout'))));
        }
      });
    }

    try {
      context.read<NotificationBloc>().add(
        const GetNotificationsEvent(),
      );

      context.read<NotificationBloc>().add(
        MarkAllNotificationsAsReadEvent(userId: _currentUser.id!),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.tr('error_refreshing'))));
      }
    }

    return Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('notifications'),
          style: GoogleFonts.raleway(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.done_all, color: Colors.white),
            tooltip: context.tr('mark_all_read'),
            onPressed: () {
              if (_currentUser.id != null) {
                context.read<NotificationBloc>().add(
                  MarkAllNotificationsAsReadEvent(userId: _currentUser.id!),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.tr('all_notifications_marked_as_read')),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.primaryColor,
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            tooltip: context.tr('refresh'),
            onPressed: () => _refreshNotifications(),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryColor.withOpacity(0.05), Colors.white],
          ),
        ),
        child: BlocConsumer<NotificationBloc, NotificationState>(
          listener: (context, state) {
            if (state is NotificationError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is NotificationsLoaded) {
              if (_isLoading) {
                setState(() {
                  _isLoading = false;
                });
              }
            }
          },
          builder: (context, state) {
            if (state is NotificationLoading && _isLoading) {
              return LoadingStateWidget(
                message: context.tr('loading_notifications'),
              );
            }

            if (state is NotificationsLoaded) {
              final notifications = state.notifications;
              print('Loaded ${notifications.length} notifications');

              if (notifications.isEmpty) {
                return EmptyStateWidget(
                  message: context.tr('no_notifications'),
                  description: context.tr('you_have_no_notifications_yet'),
                  actionText: context.tr('refresh'),
                  onAction: () => _refreshNotifications(),
                );
              }

              return Column(
                children: [
                  _buildFilterChips(),
                  Expanded(
                    child: RefreshIndicator(
                      key: _refreshIndicatorKey,
                      onRefresh: _refreshNotifications,
                      color: AppColors.primaryColor,
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          return AnimatedOpacity(
                            duration: Duration(milliseconds: 500),
                            opacity: 1.0,
                            curve: Curves.easeInOut,
                            child: AnimatedPadding(
                              duration: Duration(milliseconds: 300),
                              padding: EdgeInsets.only(
                                top: index == 0 ? 8.h : 0,
                                bottom: 12.h,
                              ),
                              child: _buildNotificationCard(
                                notifications[index],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            }

            return EmptyStateWidget(
              message: context.tr('no_notifications'),
              description: context.tr('you_have_no_notifications_yet'),
              actionText: context.tr('refresh'),
              onAction: () => _refreshNotifications(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          _buildFilterChip('all', context.tr('all')),
          SizedBox(width: 10.w),
          _buildFilterChip('appointment', context.tr('appointments')),
          SizedBox(width: 10.w),
          _buildFilterChip('prescription', context.tr('prescriptions')),
          if (_currentUser.role == 'patient') ...[
            SizedBox(width: 10.w),
            _buildFilterChip('rating', context.tr('ratings')),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.raleway(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
          color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
        ),
      ),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _selectedFilter = value;
          });
        }
      },
      selectedColor: AppColors.primaryColor,
      backgroundColor:
          isDarkMode ? theme.cardColor.withOpacity(0.3) : Colors.grey.shade100,
      checkmarkColor: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      elevation: 0,
      shadowColor: Colors.transparent,
    );
  }

  Widget _buildNotificationCard(NotificationEntity notification) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    String senderName = '';
    if (notification.data != null) {
      senderName =
          notification.data!['senderName'] ??
          notification.data!['doctorName'] ??
          notification.data!['patientName'] ??
          '';
    }

    return Dismissible(
      key: Key(notification.id),
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12.r),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(context.tr('delete_notification')),
                content: Text(context.tr('confirm_delete_notification')),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(context.tr('cancel')),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(
                      context.tr('delete'),
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
        );
      },
      onDismissed: (direction) {
        context.read<NotificationBloc>().add(
          DeleteNotificationEvent(notificationId: notification.id),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('notification_deleted')),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.zero,
        elevation: notification.isRead ? 1 : 3,
        shadowColor: AppColors.primaryColor.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side:
              notification.isRead
                  ? BorderSide.none
                  : BorderSide(
                    color: AppColors.primaryColor.withOpacity(0.5),
                    width: 1.5,
                  ),
        ),
        child: InkWell(
          onTap: () {
            context.read<NotificationBloc>().add(
              MarkNotificationAsReadEvent(notificationId: notification.id),
            );
            _navigateToDetails(notification);
          },
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _getNotificationIcon(notification.type),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 4.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification.title,
                              style: GoogleFonts.raleway(
                                fontSize: 16.sp,
                                fontWeight:
                                    notification.isRead
                                        ? FontWeight.w600
                                        : FontWeight.bold,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              notification.body,
                              style: GoogleFonts.raleway(
                                fontSize: 14.sp,
                                color:
                                    isDarkMode
                                        ? Colors.grey[300]
                                        : Colors.black54,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 12.h),
                            Wrap(
                              spacing: 8.w,
                              runSpacing: 8.h,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (senderName.isNotEmpty)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                      vertical: 4.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isDarkMode
                                              ? Colors.blue.withOpacity(0.2)
                                              : Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20.r),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.person,
                                          size: 12.sp,
                                          color: Colors.blue,
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          senderName,
                                          style: GoogleFonts.raleway(
                                            fontSize: 12.sp,
                                            color: Colors.blue,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                    vertical: 4.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isDarkMode
                                            ? Colors.grey.withOpacity(0.2)
                                            : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 12.sp,
                                        color:
                                            isDarkMode
                                                ? Colors.grey[400]
                                                : Colors.grey[700],
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        _getFormattedTime(
                                          notification.createdAt,
                                        ),
                                        style: GoogleFonts.raleway(
                                          fontSize: 12.sp,
                                          color:
                                              isDarkMode
                                                  ? Colors.grey[400]
                                                  : Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!notification.isRead)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                      vertical: 4.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryColor.withOpacity(
                                        0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(20.r),
                                    ),
                                    child: Text(
                                      context.tr('new'),
                                      style: GoogleFonts.raleway(
                                        fontSize: 12.sp,
                                        color: AppColors.primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (notification.type == NotificationType.newAppointment &&
                    _currentUser.role == 'medecin' &&
                    !notification.isRead)
                  _buildActionButtons(notification),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _getNotificationIcon(NotificationType type) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    IconData icon;
    Color color;
    String label = '';

    switch (type) {
      case NotificationType.appointmentRejected:
        icon = Icons.cancel_rounded;
        color = Colors.red;
        label = context.tr('rejected');
        break;
      case NotificationType.rating:
        icon = Icons.star_rounded;
        color = Colors.amber;
        label = context.tr('rating');
        break;
      case NotificationType.newPrescription:
        icon = Icons.medical_services_rounded;
        color = AppColors.primaryColor;
        label = context.tr('prescription');
        break;
      case NotificationType.prescription:
        icon = Icons.medical_services_rounded;
        color = AppColors.primaryColor;
        label = context.tr('prescription');
        break;
      case NotificationType.message:
      case NotificationType.newMessage:
        icon = Icons.message_rounded;
        color = Colors.blue;
        label = context.tr('message');
        break;
      case NotificationType.medicalRecord:
        icon = Icons.folder_rounded;
        color = Colors.green;
        label = context.tr('medical_record');
        break;
      case NotificationType.general:
      case NotificationType.systemAlert:
        icon = Icons.notifications_rounded;
        color = Colors.grey;
        label = context.tr('notification');
        break;
      case NotificationType.appointment:
        icon = Icons.calendar_today_rounded;
        color = Colors.blue;
        label = context.tr('appointment');
        break;
      case NotificationType.newAppointment:
        icon = Icons.calendar_today_rounded;
        color = Colors.blue;
        label = context.tr('new_appointment');
        break;
      case NotificationType.appointmentAccepted:
      case NotificationType.appointmentConfirmed:
        icon = Icons.check_circle_rounded;
        color = Colors.green;
        label = context.tr('accepted');
        break;
      case NotificationType.appointmentReminder:
        icon = Icons.alarm_rounded;
        color = Colors.orange;
        label = context.tr('reminder');
        break;
      case NotificationType.appointmentCancelled:
        icon = Icons.event_busy_rounded;
        color = Colors.red;
        label = context.tr('cancelled');
        break;
      case NotificationType.referralReceived:
      case NotificationType.referralScheduled:
        icon = Icons.swap_horiz_rounded;
        color = Colors.purple;
        label = context.tr('referral');
        break;
      case NotificationType.consultationCreated:
        icon = Icons.medical_information_rounded;
        color = Colors.teal;
        label = context.tr('consultation');
        break;
      case NotificationType.prescriptionCreated:
        icon = Icons.medication_rounded;
        color = AppColors.primaryColor;
        label = context.tr('prescription');
        break;
      case NotificationType.documentUploaded:
        icon = Icons.upload_file_rounded;
        color = Colors.indigo;
        label = context.tr('document');
        break;
    }

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: isDarkMode ? color.withOpacity(0.2) : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: Icon(icon, color: color, size: 26.sp),
        ),
        if (label.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: Text(
              label,
              style: GoogleFonts.raleway(
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? color.withOpacity(0.8) : color,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons(NotificationEntity notification) {
    return Padding(
      padding: EdgeInsets.only(top: 16.h),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 18.sp,
              ),
              label: Text(
                context.tr('accept'),
                style: GoogleFonts.raleway(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                ),
              ),
              onPressed: () => _acceptAppointment(notification),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 2,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: ElevatedButton.icon(
              icon: Icon(
                Icons.cancel_outlined,
                color: Colors.white,
                size: 18.sp,
              ),
              label: Text(
                context.tr('reject'),
                style: GoogleFonts.raleway(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                ),
              ),
              onPressed: () => _rejectAppointment(notification),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _acceptAppointment(NotificationEntity notification) {
    if (notification.appointmentId != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primaryColor),
                  SizedBox(width: 20),
                  Text(context.tr('common.processing'), style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          );
        },
      );

      String patientId = notification.senderId ?? '';
      String patientName = notification.data?['patientName'] ?? '';

      final blocListener = BlocListener<RendezVousBloc, RendezVousState>(
        listener: (context, state) {
          if (state is RendezVousStatusUpdatedState ||
              state is RendezVousError ||
              state is RendezVousErrorState) {
            Navigator.of(context, rootNavigator: true).pop();

            if (state is RendezVousErrorState || state is RendezVousError) {
              String errorMessage =
                  state is RendezVousErrorState
                      ? state.message
                      : (state as RendezVousError).message;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${context.tr('common.error')}: $errorMessage'),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is RendezVousStatusUpdatedState) {
              context.read<NotificationBloc>().add(
                MarkNotificationAsReadEvent(notificationId: notification.id),
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.tr('appointment_accepted')),
                  backgroundColor: Colors.green,
                ),
              );

              if (_currentUser.id != null) {
                context.read<NotificationBloc>().add(
                  const GetNotificationsEvent(),
                );
              }
            }
          }
        },
        child: Container(),
      );

      Navigator.of(
        context,
      ).overlay?.insert(OverlayEntry(builder: (context) => blocListener));

      context.read<RendezVousBloc>().add(
        UpdateRendezVousStatus(
          rendezVousId: notification.appointmentId!,
          status: 'accepted',
        ),
      );
    }
  }

  void _rejectAppointment(NotificationEntity notification) {
    if (notification.appointmentId != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primaryColor),
                  SizedBox(width: 20),
                  Text(context.tr('common.processing'), style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          );
        },
      );

      String patientId = notification.senderId ?? '';
      String patientName = notification.data?['patientName'] ?? '';

      final blocListener = BlocListener<RendezVousBloc, RendezVousState>(
        listener: (context, state) {
          if (state is RendezVousStatusUpdatedState ||
              state is RendezVousError ||
              state is RendezVousErrorState) {
            Navigator.of(context, rootNavigator: true).pop();

            if (state is RendezVousErrorState || state is RendezVousError) {
              String errorMessage =
                  state is RendezVousErrorState
                      ? state.message
                      : (state as RendezVousError).message;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${context.tr('common.error')}: $errorMessage'),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is RendezVousStatusUpdatedState) {
              context.read<NotificationBloc>().add(
                MarkNotificationAsReadEvent(notificationId: notification.id),
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.tr('appointment_rejected')),
                  backgroundColor: Colors.red,
                ),
              );

              if (_currentUser.id != null) {
                context.read<NotificationBloc>().add(
                  const GetNotificationsEvent(),
                );
              }
            }
          }
        },
        child: Container(),
      );

      Navigator.of(
        context,
      ).overlay?.insert(OverlayEntry(builder: (context) => blocListener));

      context.read<RendezVousBloc>().add(
        UpdateRendezVousStatus(
          rendezVousId: notification.appointmentId!,
          status: 'cancelled',
        ),
      );
    }
  }

  void _navigateToDetails(NotificationEntity notification) {
    if (notification.appointmentId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  AppointmentDetailsPage(id: notification.appointmentId!),
        ),
      );
    } else if (notification.prescriptionId != null) {
      // TODO: Implement prescription details navigation
    } else if (notification.type == NotificationType.rating) {
      // TODO: Implement rating details navigation
    }
  }

  String _getFormattedTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('MMM d, yyyy').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}
