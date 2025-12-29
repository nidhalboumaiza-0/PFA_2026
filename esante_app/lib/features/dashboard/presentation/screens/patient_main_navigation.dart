import 'package:flutter/material.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../appointments/presentation/screens/patient_appointments_screen.dart';
import '../../../doctors/presentation/screens/doctor_search_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import 'patient_dashboard_content.dart';

/// Main navigation wrapper for patient users
/// Uses PageView for smooth transitions with WaterDropNavBar
class PatientMainNavigation extends StatefulWidget {
  final bool showProfileCompletionDialog;
  final int profileCompletionPercentage;
  final int initialIndex;

  const PatientMainNavigation({
    super.key,
    this.showProfileCompletionDialog = false,
    this.profileCompletionPercentage = 0,
    this.initialIndex = 0,
  });

  @override
  State<PatientMainNavigation> createState() => _PatientMainNavigationState();
}

class _PatientMainNavigationState extends State<PatientMainNavigation> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToTab(int index) {
    if (index != _currentIndex) {
      setState(() => _currentIndex = index);
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  static const List<NavBarItem> _navItems = [
    NavBarItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    NavBarItem(
      icon: Icons.search_outlined,
      activeIcon: Icons.search_rounded,
      label: 'Doctors',
    ),
    NavBarItem(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today_rounded,
      label: 'Appointments',
    ),
    NavBarItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          PatientDashboardContent(
            showProfileCompletionDialog: widget.showProfileCompletionDialog,
            profileCompletionPercentage: widget.profileCompletionPercentage,
            onNavigateToTab: _navigateToTab,
          ),
          const DoctorSearchScreen(showBackButton: false),
          const PatientAppointmentsScreen(showBackButton: false),
          const ProfileScreen(showCompletionDialog: false, showBackButton: false),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: AppBottomNavBar(
          currentIndex: _currentIndex,
          onTap: _navigateToTab,
          items: _navItems,
        ),
      ),
    );
  }
}
