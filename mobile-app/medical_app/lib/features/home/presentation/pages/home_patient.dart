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
import 'package:medical_app/features/dashboard/presentation/pages/dashboard_patient.dart';
import 'package:medical_app/features/localisation/presentation/pages/pharmacie_page.dart';
import 'package:medical_app/features/profile/presentation/pages/ProfilPatient.dart';
import 'package:medical_app/features/secours/presentation/pages/secours_screen.dart';
import 'package:medical_app/features/settings/presentation/pages/settings_patient.dart';
import 'package:medical_app/widgets/theme_cubit_switch.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../authentication/presentation/pages/login_screen.dart';
import '../../../messagerie/presentation/pages/conversations_page.dart';
import '../../../profile/presentation/pages/blocs/BLoC update profile/update_user_bloc.dart';
import '../../../rendez_vous/presentation/pages/appointments_patients.dart';
import 'package:medical_app/features/notifications/presentation/widgets/notification_badge.dart';
import '../../../messagerie/presentation/blocs/conversation/conversation_bloc.dart';

class HomePatient extends StatefulWidget {
  const HomePatient({super.key});

  @override
  State<HomePatient> createState() => _HomePatientState();
}

class _HomePatientState extends State<HomePatient> {
  int _selectedIndex = 0;
  String userId = '';
  String patientName = 'John Doe';
  String email = 'johndoe@example.com';
  DateTime? _selectedAppointmentDate;

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
      print('User JSON: $userJson');
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      setState(() {
        userId = userMap['id'] as String? ?? '';
        patientName =
            '${userMap['name'] ?? ''} ${userMap['lastName'] ?? ''}'.trim();
        email = userMap['email'] as String? ?? 'johndoe@example.com';
      });
    }
  }

  // Print FCM token for testing
  Future<void> _printFCMToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('FCM_TOKEN');
      print('==========================');
      print('PATIENT FCM TOKEN for testing: $token');
      print('==========================');
    } catch (e) {
      print('Error getting FCM token: $e');
    }
  }

  // Function to select a date for appointments
  Future<void> _selectAppointmentDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedAppointmentDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
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

    if (picked != null && picked != _selectedAppointmentDate) {
      setState(() {
        _selectedAppointmentDate = picked;
        _updatePages();
      });
    }
  }

  // Reset appointment date filter
  void _resetAppointmentDateFilter() {
    setState(() {
      _selectedAppointmentDate = null;
      _updatePages();
    });
  }

  // Update pages list with current state
  void _updatePages() {
    setState(() {
      _pages = [
        const Dashboardpatient(),
        AppointmentsPatients(showAppBar: false),
        const ConversationsPage(),
        const ProfilePatient(),
      ];
    });
  }

  List<BottomNavigationBarItem> _navItems(BuildContext context) => [
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
    // Message with badge
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

  // Widget to display message icon with badge for unread messages
  Widget _buildMessageIcon(bool isActive) {
    return BlocBuilder<ConversationBloc, ConversationState>(
      buildWhen: (previous, current) {
        // Only rebuild when conversations loaded
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

  late List<Widget> _pages = [
    const Dashboardpatient(),
    AppointmentsPatients(showAppBar: false),
    const ConversationsPage(),
    const ProfilePatient(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // When messages tab is selected, refresh conversations
    if (index == 2 && userId.isNotEmpty) {
      context.read<ConversationBloc>().add(FetchConversationsEvent());
    }
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
    VoidCallback? onTap,
    int? badgeCount,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final textColor =
        color ?? (isDarkMode ? theme.textTheme.bodyLarge?.color : Colors.white);
    final iconColor =
        color ?? (isDarkMode ? theme.textTheme.bodyLarge?.color : Colors.white);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 22, color: iconColor),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.raleway(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
                if (badgeCount != null)
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red[600],
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badgeCount.toString(),
                      style: GoogleFonts.raleway(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    print("1111111111111111111111111111111");
    print("userId : $userId");
    return SafeArea(
      child: BlocListener<UpdateUserBloc, UpdateUserState>(
        listener: (context, state) {
          if (state is UpdateUserSuccess) {
            setState(() {
              patientName = '${state.user.name} ${state.user.lastName}'.trim();
              email = state.user.email;
              userId = state.user.id ?? '';
              _pages = [
                const Dashboardpatient(),
                AppointmentsPatients(showAppBar: false),
                const ConversationsPage(),
                const ProfilePatient(),
              ];
            });
          }
        },
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              _selectedIndex == 1 ? context.tr('appointments') : context.tr('medilink'),
              style: GoogleFonts.raleway(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.whiteColor,
              ),
            ),
            centerTitle: true,
            backgroundColor: AppColors.primaryColor,
            elevation: 0,
            actions: [
              if (_selectedIndex == 1) ...[
                IconButton(
                  icon: Icon(Icons.calendar_today, color: AppColors.whiteColor),
                  onPressed: () => _selectAppointmentDate(context),
                  tooltip: context.tr("filter_by_date"),
                ),
                if (_selectedAppointmentDate != null)
                  IconButton(
                    icon: Icon(Icons.clear, color: AppColors.whiteColor),
                    onPressed: _resetAppointmentDateFilter,
                    tooltip: context.tr("reset_filter"),
                  ),
              ],
              const NotificationBadge(
                iconColor: AppColors.whiteColor,
                iconSize: 24,
              ),
            ],
          ),
          body: _pages[_selectedIndex],

          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color:
                  isDarkMode ? theme.colorScheme.surface : AppColors.whiteColor,
              boxShadow: [
                BoxShadow(
                  color:
                      isDarkMode
                          ? Colors.black.withOpacity(0.3)
                          : AppColors.textSecondary.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              child: BottomNavigationBar(
                items: _navItems(context),
                currentIndex: _selectedIndex,
                selectedItemColor: AppColors.primaryColor,
                unselectedItemColor:
                    isDarkMode
                        ? theme.textTheme.bodySmall?.color?.withOpacity(0.7)
                        : AppColors.textSecondary,
                showSelectedLabels: true,
                showUnselectedLabels: true,
                type: BottomNavigationBarType.fixed,
                backgroundColor:
                    isDarkMode
                        ? theme.colorScheme.surface
                        : AppColors.whiteColor,
                elevation: 10,
                selectedLabelStyle: GoogleFonts.raleway(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: GoogleFonts.raleway(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                onTap: _onItemTapped,
              ),
            ),
          ),

          drawer: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Drawer(
              width: MediaQuery.of(context).size.width * 0.8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(24),
                ),
              ),
              elevation: 10,
              shadowColor: Colors.black26,
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
                              const Color(0xFF2fa7bb).withOpacity(0.85),
                            ],
                          ),
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.only(
                        top: 50,
                        left: 25,
                        right: 25,
                        bottom: 25,
                      ),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor:
                                  isDarkMode
                                      ? theme.colorScheme.primary.withOpacity(
                                        0.2,
                                      )
                                      : AppColors.whiteColor,
                              child: Icon(
                                Icons.person,
                                size: 36,
                                color:
                                    isDarkMode
                                        ? theme.colorScheme.primary
                                        : const Color(0xFF2fa7bb),
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            patientName,
                            style: GoogleFonts.raleway(
                              fontSize: 18,
                              color:
                                  isDarkMode
                                      ? theme.textTheme.bodyLarge?.color
                                      : AppColors.whiteColor,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            context.tr('patient'),
                            style: GoogleFonts.raleway(
                              fontSize: 14,
                              color:
                                  isDarkMode
                                      ? theme.textTheme.bodyMedium?.color
                                      : AppColors.whiteColor.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            email,
                            style: GoogleFonts.raleway(
                              fontSize: 14,
                              color:
                                  isDarkMode
                                      ? theme.textTheme.bodySmall?.color
                                      : AppColors.whiteColor.withOpacity(0.7),
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
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
                                const SettingsPatient(),
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
                                      color:
                                          isDarkMode
                                              ? theme.textTheme.bodyLarge?.color
                                              : Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      isDarkModeState
                                          ? context.tr('dark_mode')
                                          : context.tr('light_mode'),
                                      style: GoogleFonts.raleway(
                                        color:
                                            isDarkMode
                                                ? theme
                                                    .textTheme
                                                    .bodyLarge
                                                    ?.color
                                                : Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Spacer(),
                                    Transform.scale(
                                      scale: 0.8,
                                      child: const ThemeCubitSwitch(
                                        compact: true,
                                      ),
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
                      padding: EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 12,
                      ),
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
          ),
        ),
      ),
    );
  }
}
