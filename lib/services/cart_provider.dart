import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import 'simple_cart_service.dart';

/// Provides cart data across the app
class CartProvider extends ChangeNotifier {
  static final CartProvider _instance = CartProvider._internal();
  
  factory CartProvider() {
    return _instance;
  }
  
  CartProvider._internal();
  
  Map<String, dynamic> _cartItems = {};
  bool _isInitialized = false;
  
  /// Get all cart items
  Map<String, dynamic> get cartItems => _cartItems;
  
  /// Check if cart is loaded
  bool get isInitialized => _isInitialized;
  
  /// Initialize the cart provider by loading cart data
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await loadCartItems();
      _isInitialized = true;
      notifyListeners();
      print('CartProvider: Initialized successfully with ${_cartItems.length} items');
    } catch (e) {
      print('CartProvider: Error initializing - $e');
    }
  }
  
// In lib/services/cart_provider.dart
// ... (other existing methods) ...

  /// Clears all cart data managed by SimpleCartService and reloads CartProvider's state.
  Future<void> clearCartAndRefresh() async {
    print('CartProvider: Attempting to clear cart data and refresh provider state...');
    try {
      final cartService = SimpleCartService(); // Get instance

      // 1. Instruct SimpleCartService to clear its underlying cache and RTDB data
      await cartService.clearCurrentUserCartData();
      print('CartProvider: Underlying SimpleCartService data cleared.');

      // 2. Reload cart items for CartProvider.
      // loadCartItems will now fetch from the cleared cache of SimpleCartService,
      // resulting in _cartItems becoming empty, and then it calls notifyListeners().
      await loadCartItems();
      print('CartProvider: State refreshed. Current item count: ${_cartItems.length}');

    } catch (e) {
      print('CartProvider: Error in clearCartAndRefresh: $e');
      // Rethrow so the caller (CartBloc) can be aware of the failure
      rethrow;
    }
  }
  
  /// Load cart items from cache and sync with Firestore
  Future<void> loadCartItems() async {
    try {
      final cartService = SimpleCartService();
      
      // First load from cache for quick startup
      _cartItems = await cartService.getCartItemsFromCache();
      notifyListeners();
      
      // Then sync with Firestore in the background
      await cartService.syncWithFirestore();
      
      // Finally reload from cache after sync
      _cartItems = await cartService.getCartItemsFromCache();
      notifyListeners();
      
      print('CartProvider: Loaded ${_cartItems.length} cart items');
    } catch (e) {
      print('CartProvider: Error loading cart items - $e');
    }
  }
  
  /// Check if a product is in the cart
  bool isInCart(String productId) {
    return _cartItems.containsKey(productId);
  }
  
  /// Get the quantity of a product in the cart
  int getQuantity(String productId) {
    if (!isInCart(productId)) return 0;
    
    try {
      final item = _cartItems[productId];
      return item['quantity'] ?? 0;
    } catch (e) {
      print('CartProvider: Error getting quantity - $e');
      return 0;
    }
  }
  
  /// Update cart after changes
  Future<void> updateAfterChange(String productId, int quantity) async {
    try {
      final cartService = SimpleCartService();
      
      // First update the cart service
      await cartService.addOrUpdateItem(
        productId: productId,
        quantity: quantity,
      );
      
      // Then reload cart items
      await loadCartItems();
    } catch (e) {
      print('CartProvider: Error updating after change - $e');
    }
  }
  
  /// Get user ID
  Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(AppConstants.userTokenKey);
    } catch (e) {
      print('CartProvider: Error getting user ID - $e');
      return null;
    }
  }
} 