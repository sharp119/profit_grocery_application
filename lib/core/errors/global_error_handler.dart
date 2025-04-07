import 'package:flutter/foundation.dart';

/// Global error handler to manage application-wide error states
class GlobalErrorHandler {
  // Private constructor to prevent instantiation
  GlobalErrorHandler._();
  
  /// ValueNotifier for showing welcome message for new users
  /// instead of "User not found" error
  static final ValueNotifier<bool> showNewUserNote = ValueNotifier<bool>(false);
  
  /// Show a welcome message for new users
  static void showNewUserWelcome() {
    showNewUserNote.value = true;
    
    // Auto-hide after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (showNewUserNote.value) {
        showNewUserNote.value = false;
      }
    });
  }
  
  /// Hide the welcome message
  static void hideNewUserWelcome() {
    showNewUserNote.value = false;
  }
}
