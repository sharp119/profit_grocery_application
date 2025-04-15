import 'package:flutter/material.dart';

/// Utility class for bottom navigation related functions
class BottomNavUtils {
  /// Function to create page transition animations
  static PageRouteBuilder createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 0.1);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
    );
  }

  /// Function to handle deep links by determining which tab should be activated
  static int getTabIndexFromDeepLink(String path) {
    if (path.startsWith('/cart')) {
      return 2; // Cart tab
    } else if (path.startsWith('/orders')) {
      return 1; // Orders tab
    } else if (path.startsWith('/profile') || path.startsWith('/settings')) {
      return 3; // Settings tab
    }
    // Default to home tab
    return 0;
  }
}
