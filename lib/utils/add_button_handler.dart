import 'package:flutter/foundation.dart';
import '../services/simple_cart_service.dart';
import '../services/cart_provider.dart';

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
    required String productId,
    int quantity = 1,
  }) async {
    // Log the product ID to the console
    print('Product added to cart: $productId');
    
    // Update cart using the CartProvider for better synchronization
    final cartProvider = CartProvider();
    await cartProvider.updateAfterChange(productId, quantity);
  }
} 