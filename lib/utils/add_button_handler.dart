import 'package:flutter/foundation.dart';
import '../domain/entities/product.dart';
import '../utils/cart_logger.dart';

/// A centralized handler for all ADD button clicks across the application
class AddButtonHandler {
  /// Singleton instance
  static final AddButtonHandler _instance = AddButtonHandler._internal();
  
  /// Factory constructor to return the singleton instance
  factory AddButtonHandler() {
    return _instance;
  }
  
  /// Private constructor for singleton
  AddButtonHandler._internal();
  
  /// Handle the ADD button click
  /// 
  /// This method will be called whenever an ADD button is clicked
  /// from anywhere in the application.
  void handleAddButtonClick({
    required Product product,
    required int quantity,
    required Function(Product, int)? originalCallback,
  }) {
    // ONLY print the required message to the console
    print('hello its me bob');
    
    // No longer logging to Firebase or calling the original callback
    // This ensures we're just printing the message and nothing else
  }
} 