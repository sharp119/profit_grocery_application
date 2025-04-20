import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Utility class to provide safe screen extensions with fallbacks
/// This helps prevent layout crashes when screen sizes cause constraints issues
class ScreenSizeUtils {
  /// Safe width extension with maximum bound
  static double safeWidth(double width) {
    try {
      final result = width.w;
      // Ensure we don't return extreme values that could break layouts
      if (result.isNaN || result.isInfinite || result <= 0 || result > 1000) {
        return width; // Fall back to original value
      }
      return result;
    } catch (e) {
      return width; // Fall back to original value
    }
  }

  /// Safe height extension with maximum bound
  static double safeHeight(double height) {
    try {
      final result = height.h;
      // Ensure we don't return extreme values that could break layouts
      if (result.isNaN || result.isInfinite || result <= 0 || result > 1000) {
        return height; // Fall back to original value
      }
      return result;
    } catch (e) {
      return height; // Fall back to original value
    }
  }

  /// Safe radius extension with maximum bound
  static double safeRadius(double radius) {
    try {
      final result = radius.r;
      // Ensure we don't return extreme values that could break layouts
      if (result.isNaN || result.isInfinite || result <= 0 || result > 100) {
        return radius; // Fall back to original value
      }
      return result;
    } catch (e) {
      return radius; // Fall back to original value
    }
  }

  /// Safe font size extension with maximum bound
  static double safeFontSize(double fontSize) {
    try {
      final result = fontSize.sp;
      // Ensure we don't return extreme values that could break layouts
      if (result.isNaN || result.isInfinite || result <= 0 || result > 60) {
        return fontSize; // Fall back to original value
      }
      return result;
    } catch (e) {
      return fontSize; // Fall back to original value
    }
  }

  /// Get a width that's responsive but limited to reasonable bounds
  static double adaptiveWidth(BuildContext context, double percentage) {
    try {
      final screenWidth = MediaQuery.of(context).size.width;
      return screenWidth * (percentage / 100);
    } catch (e) {
      return 100; // Fallback to a safe value
    }
  }

  /// Get a height that's responsive but limited to reasonable bounds
  static double adaptiveHeight(BuildContext context, double percentage) {
    try {
      final screenHeight = MediaQuery.of(context).size.height;
      return screenHeight * (percentage / 100);
    } catch (e) {
      return 100; // Fallback to a safe value
    }
  }
} 