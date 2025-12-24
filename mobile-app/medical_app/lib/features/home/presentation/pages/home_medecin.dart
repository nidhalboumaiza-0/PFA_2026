import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medical_app/core/l10n/translator.dart';
import 'package:medical_app/core/utils/app_colors.dart';
import 'package:medical_app/core/utils/navigation_with_transition.dart';
import 'package:medical_app/cubit/theme_cubit/theme_cubit.dart';
import 'package:medical_app/features/authentication/presentation/pages/login_screen.dart';
import 'package:medical_app/features/dashboard/presentation/pages/dashboard_medecin.dart';
import 'package:medical_app/features/notifications/presentation/pages/notifications_page.dart';
import 'package:medical_app/features/profile/presentation/pages/ProfilMedecin.dart';
import 'package:medical_app/features/rendez_vous/presentation/pages/appointments_medecins.dart';
import 'package:medical_app/features/settings/presentation/pages/SettingsPage.dart';
import 'package:medical_app/widgets/theme_cubit_switch.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../localisation/presentation/pages/pharmacie_page.dart';
import '../../../messagerie/presentation/pages/conversations_page.dart';
import '../../../profile/presentation/pages/blocs/BLoC%20update%20profile/update_user_bloc.dart';
import '../../../notifications/presentation/widgets/notification_badge.dart';
import '../../../messagerie/presentation/blocs/conversation/conversation_bloc.dart';
import '../../../secours/presentation/pages/secours_screen.dart';

class HomeMedecin extends StatefulWidget {
  const HomeMedecin({super.key});

  @override
  State<HomeMedecin> createState() => _HomeMedecinState();
}

class _HomeMedecinState extends State<HomeMedecin> {
  int selectedItem = 0;
  String userId = '';
  String doctorName = 'Dr. Unknown';
  String email = 'doctor@example.com';
  DateTime? selectedAppointmentDate;
  // Add a global key for the scaffold
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _printFCMToken(); // Print FCM token for testing
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('CACHED_USER');
    if (userJson != null) {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      setState(() {
        userId = userMap['id'] as String? ?? '';
        doctorName =
            '${userMap['name'] ?? ''} ${userMap['lastName'] ?? ''}'.trim();
        email = userMap['email'] as String? ?? 'doctor@example.com';
      });
    }
  }

  // Print FCM token for testing
  Future<void> _printFCMToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('FCM_TOKEN');
      print('==========================');
      print('FCM TOKEN for testing: $token');
      print('==========================');
    } catch (e) {
      print('Error getting FCM token: $e');
    }
  }

  List<BottomNavigationBarItem> getItems(BuildContext context) => [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined, size: 22.sp),
      activeIcon: Icon(Icons.home_filled, size: 24.sp),
      label: context.tr('home'),
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.calendar_today_outlined, size: 22.sp),
      activeIcon: Icon(Icons.calendar_today, size: 24.sp),
      label: context.tr('appointments'),
    ),
    BottomNavigationBarItem(
      icon: _buildMessageIcon(false),
      activeIcon: _buildMessageIcon(true),
      label: context.tr('messages'),
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline, size: 22.sp),
      activeIcon: Icon(Icons.person, size: 24.sp),
      label: context.tr('profile'),
    ),
  ];

  late List<Widget> pages = [
    const DashboardMedecin(),
    AppointmentsMedecins(
      initialSelectedDate: selectedAppointmentDate,
      showAppBar: false,
    ),
    const ConversationsPage(),
    const ProfilMedecin(),
  ];

  // Function to display date picker
  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedAppointmentDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(
        const Duration(days: 365),
      ), // Allow past year
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedAppointmentDate) {
      setState(() {
        selectedAppointmentDate = picked;
        _updatePages();
      });
    }
  }

  // Update pages with the new selected date
  void _updatePages() {
    setState(() {
      pages = [
        const DashboardMedecin(),
        AppointmentsMedecins(
          initialSelectedDate: selectedAppointmentDate,
          showAppBar: false,
        ),
        const ConversationsPage(),
        const ProfilMedecin(),
      ];
    });
  }

  // Reset the date filter
  void _resetDateFilter() {
    setState(() {
      selectedAppointmentDate = null;
      _updatePages();
    });
  }

  void _onNotificationTapped() {
    navigateToAnotherScreenWithSlideTransitionFromRightToLeft(
      context,
      const NotificationsPage(),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('logout')),
        content: Text(context.tr('confirm_logout')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(context.tr('cancel'))),
          TextButton(
            onPressed: () async {
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('CACHED_USER');
                await prefs.remove('TOKEN');

                // Replace the entire navigation stack to prevent going back
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                  (Route<dynamic> route) => false, // Remove all previous routes
                );

                // Optional: show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.tr('logout_success')),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                // Show error message if logout fails
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.tr('logout_error')),
                    backgroundColor: Colors.red,
                  ),
                );
                print("Logout error: $e");
              }
            },
            child: Text(context.tr('logout'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required Function() onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.white, size: 20),
      title: Text(
        title,
        style: GoogleFonts.raleway(fontSize: 16, color: color ?? Colors.white),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return BlocListener<UpdateUserBloc, UpdateUserState>(
      listener: (_, state) {
        if (state is UpdateUserSuccess) {
          setState(() {
            doctorName = '${state.user.name} ${state.user.lastName}'.trim();
            email = state.user.email;
            userId = state.user.id ?? '';
          });
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.menu, color: AppColors.whiteColor),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
          title:
              selectedItem == 0
                  ? Text(
                    context.tr('medilink'),
                    style: GoogleFonts.raleway(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                  : selectedItem == 1
                  ? Text(
                    context.tr('appointments'),
                    style: GoogleFonts.raleway(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                  : selectedItem == 2
                  ? Text(
                    context.tr('messages'),
                    style: GoogleFonts.raleway(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                  : Text(
                    context.tr('profile'),
                    style: GoogleFonts.raleway(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          actions: [
            if (selectedItem == 1) ...[
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () => _selectDate(context),
                tooltip: context.tr('filter_by_date'),
              ),
              if (selectedAppointmentDate != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _resetDateFilter,
                  tooltip: context.tr('reset_filter'),
                ),
            ],
            // Add the notification badge
            const NotificationBadge(
              iconColor: AppColors.whiteColor,
              iconSize: 24,
            ),
          ],
          backgroundColor: AppColors.primaryColor,
          elevation: 0,
          centerTitle: true,
        ),
        body: pages[selectedItem],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color:
                isDarkMode ? theme.colorScheme.surface : AppColors.whiteColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 0,
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: BottomNavigationBar(
              items: getItems(context),
              currentIndex: selectedItem,
              selectedItemColor: AppColors.primaryColor,
              unselectedItemColor:
                  isDarkMode ? Colors.grey.shade400 : const Color(0xFF757575),
              showUnselectedLabels: true,
              type: BottomNavigationBarType.fixed,
              backgroundColor:
                  isDarkMode ? theme.colorScheme.surface : AppColors.whiteColor,
              selectedLabelStyle: GoogleFonts.raleway(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: GoogleFonts.raleway(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
              onTap: (index) {
                setState(() {
                  selectedItem = index;
                });

                // When messages tab is selected, refresh conversations
                if (index == 2 && userId.isNotEmpty) {
                  context.read<ConversationBloc>().add(FetchConversationsEvent());
                }
              },
            ),
          ),
        ),
        drawer: _buildDrawer(isDarkMode, theme),
      ),
    );
  }

  // Widget to display message icon with badge for unread messages
  Widget _buildMessageIcon(bool isActive) {
    return BlocBuilder<ConversationBloc, ConversationState>(
      buildWhen: (previous, current) {
        // Only rebuild when unread count changes
        return current is ConversationsLoaded;
      },
      builder: (context, state) {
        int unreadCount = 0;

        if (state is ConversationsLoaded) {
          unreadCount =
              state.conversations
                  .where(
                    (conv) =>
                        conv.lastMessage != null &&
                        !(conv.lastMessage!.isRead) &&
                        conv.lastMessage!.content?.isNotEmpty == true,
                  )
                  .length;
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              isActive ? Icons.chat_bubble : Icons.chat_bubble_outline,
              size: isActive ? 24.sp : 22.sp,
            ),
            if (unreadCount > 0)
              Positioned(
                right: -5,
                top: -5,
                child: Container(
                  padding: EdgeInsets.all(4.r),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 1.5,
                    ),
                  ),
                  constraints: BoxConstraints(minWidth: 14.r, minHeight: 14.r),
                  child: Center(
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDrawer(bool isDarkMode, ThemeData theme) {
    // Get text direction to handle RTL languages like Arabic
    final TextDirection textDirection = Directionality.of(context);
    final bool isRTL = textDirection == TextDirection.rtl;

    return Drawer(
      width:
          MediaQuery.of(context).size.width *
          0.75, // Slightly narrower to avoid overflow
      shape: RoundedRectangleBorder(
        borderRadius:
            isRTL
                ? BorderRadius.horizontal(left: Radius.circular(20))
                : BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      backgroundColor: Colors.transparent, // Make drawer background transparent
      elevation: 0, // Remove default shadow
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? theme.colorScheme.surface : null,
          gradient:
              isDarkMode
                  ? null
                  : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF2fa7bb),
                      const Color(0xFF2fa7bb).withOpacity(0.9),
                    ],
                  ),
          borderRadius:
              isRTL
                  ? BorderRadius.horizontal(left: Radius.circular(20))
                  : BorderRadius.horizontal(right: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 30.h, bottom: 16.h),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40.r,
                      backgroundColor: Colors.white.withOpacity(0.9),
                      child: Icon(
                        Icons.person,
                        size: 40.sp,
                        color: const Color(0xFF2fa7bb),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      doctorName,
                      style: GoogleFonts.poppins(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      email,
                      style: GoogleFonts.raleway(
                        fontSize: 14.sp,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Divider(
                color: Colors.white.withOpacity(0.2),
                thickness: 1,
                height: 1,
              ),
              SizedBox(height: 15),

              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildDrawerItem(
                      icon: FontAwesomeIcons.hospital,
                      title: context.tr('hospitals'),
                      onTap: () {
                        Navigator.pop(context);
                        navigateToAnotherScreenWithSlideTransitionFromRightToLeft(
                          context,
                          const PharmaciePage(),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: FontAwesomeIcons.kitMedical,
                      title: context.tr('first_aid'),
                      onTap: () {
                        Navigator.pop(context);
                        navigateToAnotherScreenWithSlideTransitionFromRightToLeft(
                          context,
                          const SecoursScreen(),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: FontAwesomeIcons.gear,
                      title: context.tr('settings'),
                      onTap: () {
                        Navigator.pop(context);
                        navigateToAnotherScreenWithSlideTransitionFromRightToLeft(
                          context,
                          const SettingsPage(),
                        );
                      },
                    ),
                    // Theme toggle
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: BlocBuilder<ThemeCubit, ThemeState>(
                        builder: (context, state) {
                          final isDarkModeState =
                              state is ThemeLoaded
                                  ? state.themeMode == ThemeMode.dark
                                  : false;
                          return Row(
                            children: [
                              Icon(
                                isDarkModeState
                                    ? FontAwesomeIcons.moon
                                    : FontAwesomeIcons.sun,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 16),
                              Text(
                                isDarkModeState
                                    ? context.tr('dark_mode')
                                    : context.tr('light_mode'),
                                style: GoogleFonts.raleway(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Transform.scale(
                                scale: 0.8,
                                child: const ThemeCubitSwitch(compact: true),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                color: Colors.white.withOpacity(0.2),
                thickness: 1,
                height: 1,
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                child: _buildDrawerItem(
                  icon: FontAwesomeIcons.rightFromBracket,
                  title: context.tr('logout'),
                  onTap: _logout,
                  color: Colors.red[50],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
