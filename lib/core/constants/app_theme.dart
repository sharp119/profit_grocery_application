// lib/core/constants/app_theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Color constants for Light Theme
  static const Color primaryColorLight = Color(0xFFE0F2F7); // Light Sky Blue
  static const Color accentColorLight = Color(0xFFF0F8FF); // Alice Blue
  static const Color secondaryColorLight = Color(0xFFFFF8DC); // Cornsilk for cards
  static const Color backgroundColorLight = Color(0xFFFFFFF0); // Ivory background
  static const Color textPrimaryColorLight = Color(0xFF333333); // Dark Grey
  static const Color textSecondaryColorLight = Color(0xFF6A6A6A); // Medium Grey for secondary text
  static const Color errorColorLight = Color(0xFFEF9A9A); // Light Red

  // Existing dark theme colors (for reference, would remain if dark theme is also supported)
  static const Color primaryColor = Color(0xFF000000); // Deep black
  static const Color accentColor = Color(0xFFD4AF37); // Gold
  static const Color secondaryColor = Color(0xFF1E1E1E); // Slightly lighter black for cards
  static const Color backgroundColor = Color(0xFF121212); // Dark background
  static const Color textPrimaryColor = Colors.white;
  static const Color textSecondaryColor = Color(0xFFBDBDBD); // Grey for secondary text
  static const Color errorColor = Color(0xFFCF6679); // Error red

  // The main light theme data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryColorLight,
        secondary: accentColorLight,
        background: backgroundColorLight,
        surface: secondaryColorLight,
        error: errorColorLight,
        onPrimary: textPrimaryColorLight,
        onSecondary: textPrimaryColorLight, // Text on accent color should be dark
        onBackground: textPrimaryColorLight,
        onSurface: textPrimaryColorLight,
        onError: textPrimaryColorLight,
        brightness: Brightness.light,
      ),

      // App bar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColorLight,
        foregroundColor: textPrimaryColorLight,
        elevation: 0,
        iconTheme: IconThemeData(color: accentColorLight),
        titleTextStyle: TextStyle(
          color: textPrimaryColorLight,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Scaffold background color
      scaffoldBackgroundColor: backgroundColorLight,

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColorLight,
          foregroundColor: textPrimaryColorLight, // Text on accent color should be dark
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColorLight,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: secondaryColorLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentColorLight, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColorLight, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: textSecondaryColorLight),
        hintStyle: const TextStyle(color: textSecondaryColorLight),
      ),

      // Card theme
      cardTheme: CardTheme(
        color: secondaryColorLight,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: accentColorLight, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // Dialog theme
      dialogTheme: DialogTheme(
        backgroundColor: secondaryColorLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: accentColorLight, width: 1),
        ),
        titleTextStyle: const TextStyle(
          color: textPrimaryColorLight,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: const TextStyle(
          color: textSecondaryColorLight,
          fontSize: 16,
        ),
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: primaryColorLight,
        selectedItemColor: accentColorLight,
        unselectedItemColor: textSecondaryColorLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Text theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textPrimaryColorLight, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: textPrimaryColorLight, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: textPrimaryColorLight, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: textPrimaryColorLight, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: textPrimaryColorLight, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(color: textPrimaryColorLight, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: textPrimaryColorLight, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: textPrimaryColorLight),
        titleSmall: TextStyle(color: textPrimaryColorLight),
        bodyLarge: TextStyle(color: textPrimaryColorLight),
        bodyMedium: TextStyle(color: textPrimaryColorLight),
        bodySmall: TextStyle(color: textSecondaryColorLight),
        labelLarge: TextStyle(color: textPrimaryColorLight, fontWeight: FontWeight.bold),
        labelMedium: TextStyle(color: textPrimaryColorLight),
        labelSmall: TextStyle(color: textSecondaryColorLight),
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: accentColorLight,
        size: 24,
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: secondaryColorLight,
        thickness: 1,
        space: 1,
      ),

      // Floating action button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentColorLight,
        foregroundColor: textPrimaryColorLight,
        elevation: 8,
        shape: CircleBorder(),
      ),
    );
  }

  // Custom card decoration - pastel bordered
  static BoxDecoration pastelBorderedDecoration({
    double borderRadius = 16.0,
    double borderWidth = 1.0,
  }) {
    return BoxDecoration(
      color: secondaryColorLight,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: accentColorLight, width: borderWidth),
      boxShadow: [
        BoxShadow(
          color: accentColorLight.withOpacity(0.2),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // Custom text styles for light theme
  static const TextStyle headingTextStyleLight = TextStyle(
    color: textPrimaryColorLight,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle subheadingTextStyleLight = TextStyle(
    color: accentColorLight,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle pastelAccentTextStyleLight = TextStyle(
    color: accentColorLight,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  // Existing dark theme data
  static ThemeData get darkTheme {
    // ... (existing dark theme code would remain here if both themes are supported)
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        background: backgroundColor,
        surface: secondaryColor,
        error: errorColor,
        onPrimary: textPrimaryColor,
        onSecondary: primaryColor,
        onBackground: textPrimaryColor,
        onSurface: textPrimaryColor,
        onError: textPrimaryColor,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: textPrimaryColor,
        elevation: 0,
        iconTheme: IconThemeData(color: accentColor),
        titleTextStyle: TextStyle(
          color: textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      scaffoldBackgroundColor: backgroundColor,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: secondaryColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: textSecondaryColor),
        hintStyle: const TextStyle(color: textSecondaryColor),
      ),
      cardTheme: CardTheme(
        color: secondaryColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: accentColor, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: secondaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: accentColor, width: 1),
        ),
        titleTextStyle: const TextStyle(
          color: textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: const TextStyle(
          color: textSecondaryColor,
          fontSize: 16,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: primaryColor,
        selectedItemColor: accentColor,
        unselectedItemColor: textSecondaryColor,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: textPrimaryColor),
        titleSmall: TextStyle(color: textPrimaryColor),
        bodyLarge: TextStyle(color: textPrimaryColor),
        bodyMedium: TextStyle(color: textPrimaryColor),
        bodySmall: TextStyle(color: textSecondaryColor),
        labelLarge: TextStyle(color: textPrimaryColor, fontWeight: FontWeight.bold),
        labelMedium: TextStyle(color: textPrimaryColor),
        labelSmall: TextStyle(color: textSecondaryColor),
      ),
      iconTheme: const IconThemeData(
        color: accentColor,
        size: 24,
      ),
      dividerTheme: const DividerThemeData(
        color: secondaryColor,
        thickness: 1,
        space: 1,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: primaryColor,
        elevation: 8,
        shape: CircleBorder(),
      ),
    );
  }
}