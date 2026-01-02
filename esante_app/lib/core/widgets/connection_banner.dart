import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/connectivity_service.dart';
import '../../injection_container.dart';

/// A slide-down banner that appears when internet connection is lost
class ConnectionBanner extends StatefulWidget {
  final Widget child;

  const ConnectionBanner({
    super.key,
    required this.child,
  });

  @override
  State<ConnectionBanner> createState() => _ConnectionBannerState();
}

class _ConnectionBannerState extends State<ConnectionBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  StreamSubscription<bool>? _subscription;
  bool _showBanner = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Listen to connectivity changes
    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    try {
      final connectivityService = sl<ConnectivityService>();
      
      // Check initial state
      if (!connectivityService.isConnected) {
        _showBanner = true;
        _animationController.forward();
      }
      
      // Listen for changes
      _subscription = connectivityService.onConnectivityChanged.listen((isConnected) {
        if (mounted) {
          setState(() {
            _showBanner = !isConnected;
          });
          
          if (!isConnected) {
            _animationController.forward();
          } else {
            _animationController.reverse();
          }
        }
      });
    } catch (e) {
      // Service not registered yet, ignore
      print('[ConnectionBanner] ConnectivityService not available: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showBanner)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _slideAnimation,
              child: SafeArea(
                bottom: false,
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.shade600,
                        Colors.orange.shade500,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.wifi_off_rounded,
                          size: 18.sp,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'No Internet Connection',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Some features may be unavailable',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.signal_cellular_connected_no_internet_0_bar_rounded,
                        size: 20.sp,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
