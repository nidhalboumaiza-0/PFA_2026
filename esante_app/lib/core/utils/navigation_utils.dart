import 'package:flutter/material.dart';

/// Navigation transition types
enum NavTransition {
  slideRight,
  slideLeft,
  slideUp,
  slideDown,
  fade,
  scale,
  fadeScale,
}

/// Navigation utility class for consistent page transitions
class AppNavigator {
  /// Navigate to a page with custom transition
  static Future<T?> push<T>(
    BuildContext context,
    Widget page, {
    NavTransition transition = NavTransition.slideRight,
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeOutCubic,
  }) {
    return Navigator.push<T>(
      context,
      _buildPageRoute<T>(page, transition, duration, curve),
    );
  }

  /// Replace current page with custom transition
  static Future<T?> pushReplacement<T, TO>(
    BuildContext context,
    Widget page, {
    NavTransition transition = NavTransition.slideRight,
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeOutCubic,
  }) {
    return Navigator.pushReplacement<T, TO>(
      context,
      _buildPageRoute<T>(page, transition, duration, curve),
    );
  }

  /// Push and remove all previous routes
  static Future<T?> pushAndRemoveAll<T>(
    BuildContext context,
    Widget page, {
    NavTransition transition = NavTransition.fade,
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeOutCubic,
  }) {
    return Navigator.pushAndRemoveUntil<T>(
      context,
      _buildPageRoute<T>(page, transition, duration, curve),
      (route) => false,
    );
  }

  /// Pop current page
  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.pop<T>(context, result);
  }

  /// Pop until a specific route
  static void popUntil(BuildContext context, String routeName) {
    Navigator.popUntil(context, ModalRoute.withName(routeName));
  }

  /// Build page route with transition
  static PageRouteBuilder<T> _buildPageRoute<T>(
    Widget page,
    NavTransition transition,
    Duration duration,
    Curve curve,
  ) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return _buildTransition(transition, animation, curve, child);
      },
    );
  }

  /// Build specific transition animation
  static Widget _buildTransition(
    NavTransition transition,
    Animation<double> animation,
    Curve curve,
    Widget child,
  ) {
    final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);

    switch (transition) {
      case NavTransition.slideRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case NavTransition.slideLeft:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case NavTransition.slideUp:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case NavTransition.slideDown:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case NavTransition.fade:
        return FadeTransition(
          opacity: curvedAnimation,
          child: child,
        );

      case NavTransition.scale:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: child,
        );

      case NavTransition.fadeScale:
        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(curvedAnimation),
            child: child,
          ),
        );
    }
  }
}

/// Extension on BuildContext for easier navigation
extension NavigationExtension on BuildContext {
  /// Navigate to a page with slide right transition (default)
  Future<T?> pushPage<T>(
    Widget page, {
    NavTransition transition = NavTransition.slideRight,
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return AppNavigator.push<T>(this, page, transition: transition, duration: duration);
  }

  /// Replace current page
  Future<T?> replacePage<T>(
    Widget page, {
    NavTransition transition = NavTransition.slideRight,
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return AppNavigator.pushReplacement<T, void>(this, page, transition: transition, duration: duration);
  }

  /// Push and remove all routes
  Future<T?> pushAndClearStack<T>(
    Widget page, {
    NavTransition transition = NavTransition.fade,
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return AppNavigator.pushAndRemoveAll<T>(this, page, transition: transition, duration: duration);
  }

  /// Pop current page
  void popPage<T>([T? result]) {
    AppNavigator.pop<T>(this, result);
  }
}
