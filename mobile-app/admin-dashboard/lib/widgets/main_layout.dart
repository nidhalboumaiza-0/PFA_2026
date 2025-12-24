import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../widgets/responsive_layout.dart';
import '../widgets/sidebar_navigation.dart';

class MainLayout extends StatefulWidget {
  final int selectedIndex;
  final Widget child;
  final String title;

  const MainLayout({
    super.key,
    required this.selectedIndex,
    required this.child,
    required this.title,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final bool isMobile = ResponsiveLayout.isMobile(context);
    
    return Scaffold(
      key: _scaffoldKey,
      appBar: isMobile
          ? AppBar(
              title: Text(
                widget.title,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              leadingWidth: 56.w,
              leading: IconButton(
                icon: Icon(Icons.menu, size: 24.sp),
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
              ),
              toolbarHeight: 56.h,
            )
          : null,
      drawer: isMobile
          ? Drawer(
              width: 280.w,
              child: SidebarNavigation(
                selectedIndex: widget.selectedIndex,
              ),
            )
          : null,
      body: Row(
        children: [
          // Show sidebar only on tablet and desktop
          if (!isMobile)
            SidebarNavigation(
              selectedIndex: widget.selectedIndex,
            ),
          // Main content area
          Expanded(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
} 