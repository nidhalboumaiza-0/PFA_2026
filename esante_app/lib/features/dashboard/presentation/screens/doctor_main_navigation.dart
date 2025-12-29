import 'package:flutter/material.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../appointments/presentation/screens/doctor_appointments_screen.dart';
import '../../../appointments/presentation/screens/doctor_availability_screen.dart';
import '../../../profile/presentation/screens/doctor_profile_screen.dart';
import 'doctor_dashboard_content.dart';

/// Main navigation wrapper for doctor users
/// Uses PageView for smooth transitions with WaterDropNavBar
class DoctorMainNavigation extends StatefulWidget {
  final int initialIndex;

  const DoctorMainNavigation({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<DoctorMainNavigation> createState() => _DoctorMainNavigationState();
}

class _DoctorMainNavigationState extends State<DoctorMainNavigation> {
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
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: 'Dashboard',
    ),
    NavBarItem(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today_rounded,
      label: 'Appointments',
    ),
    NavBarItem(
      icon: Icons.schedule_outlined,
      activeIcon: Icons.schedule_rounded,
      label: 'Availability',
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
          DoctorDashboardContent(onNavigateToTab: _navigateToTab),
          const DoctorAppointmentsScreen(showBackButton: false),
          const DoctorAvailabilityScreen(showBackButton: false),
          const DoctorProfileScreen(showBackButton: false),
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
