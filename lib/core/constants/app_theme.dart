import 'package:flutter/material.dart';

class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();
  
  // Color constants
  static const Color primaryColor = Color(0xFF000000); // Deep black
  static const Color accentColor = Color(0xFFD4AF37); // Gold
  static const Color secondaryColor = Color(0xFF1E1E1E); // Slightly lighter black for cards
  static const Color backgroundColor = Color(0xFF121212); // Dark background
  static const Color textPrimaryColor = Colors.white;
  static const Color textSecondaryColor = Color(0xFFBDBDBD); // Grey for secondary text
  static const Color errorColor = Color(0xFFCF6679); // Error red
  
  // The main theme data
  static ThemeData get darkTheme {
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
      
      // App bar theme
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
      
      // Scaffold background color
      scaffoldBackgroundColor: backgroundColor,
      
      // Elevated button theme
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
      
      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      // Input decoration theme
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
      
      // Card theme
      cardTheme: CardTheme(
        color: secondaryColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: accentColor, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      
      // Dialog theme
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
      
      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: primaryColor,
        selectedItemColor: accentColor,
        unselectedItemColor: textSecondaryColor,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // Text theme
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
      
      // Icon theme
      iconTheme: const IconThemeData(
        color: accentColor,
        size: 24,
      ),
      
      // Divider theme
      dividerTheme: const DividerThemeData(
        color: secondaryColor,
        thickness: 1,
        space: 1,
      ),
      
      // Floating action button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: primaryColor,
        elevation: 8,
        shape: CircleBorder(),
      ),
    );
  }
  
  // Custom card decoration - gold bordered
  static BoxDecoration goldBorderedDecoration({
    double borderRadius = 16.0,
    double borderWidth = 1.0,
  }) {
    return BoxDecoration(
      color: secondaryColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: accentColor, width: borderWidth),
      boxShadow: [
        BoxShadow(
          color: accentColor.withOpacity(0.2),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
  
  // Custom text styles
  static const TextStyle headingTextStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );
  
  static const TextStyle subheadingTextStyle = TextStyle(
    color: accentColor,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );
  
  static const TextStyle goldAccentTextStyle = TextStyle(
    color: accentColor,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );
}