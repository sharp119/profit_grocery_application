import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/cart_repository.dart';
import '../../presentation/blocs/cart/cart_bloc.dart';
import '../../presentation/blocs/cart/cart_event.dart';
import '../../utils/cart_logger.dart';

/// An improved cart service that focuses on simplicity and reliability
/// This service ensures the cart widget is properly displayed when items exist
/// and simplifies the add-to-cart flow to only pass product IDs
class ImprovedCartService {
  // Singleton pattern
  static final ImprovedCartService _instance = ImprovedCartService._internal();
  
  factory ImprovedCartService() {
    return _instance;
  }
  
  ImprovedCartService._internal();
  
  // Dependencies
  late final CartRepository _cartRepository = GetIt.instance<CartRepository>();
  
  // Stream controller for real-time cart updates
  final _cartStreamController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get cartStream => _cartStreamController.stream;
  
  // Cache for quick access to current cart data
  bool _isInitialized = false;
  Map<String, int> _cartItemQuantities = {}; // productId -> quantity
  
  /// Initialize the cart service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    CartLogger.log('IMPROVED_CART', 'Initializing improved cart service');
    
    try {
      // Get user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userTokenKey);
      
      if (userId != null && userId.isNotEmpty) {
        // Load cart to cache
        final cart = await getCart(userId);
        
        // Update cache
        _updateCartCache(cart);
        
        // Emit initial cart state
        _emitCartUpdate();
      }
      
      _isInitialized = true;
      CartLogger.success('IMPROVED_CART', 'Improved cart service initialized successfully');
    } catch (e) {
      CartLogger.error('IMPROVED_CART', 'Error initializing improved cart service', e);
    }
  }
  
  /// Get the current user's cart
  Future<Cart> getCart(String userId) async {
    CartLogger.log('IMPROVED_CART', 'Getting cart for user: $userId');
    
    final result = await _cartRepository.getCart(userId);
    
    return result.fold(
      (failure) {
        CartLogger.error('IMPROVED_CART', 'Failed to get cart: ${failure.message}');
        // Return empty cart on error
        return Cart(
          userId: userId,
          items: [],
          discount: 0,
          deliveryFee: 0,
        );
      },
      (cart) {
        CartLogger.success('IMPROVED_CART', 'Got cart with ${cart.items.length} items');
        // Update cache
        _updateCartCache(cart);
        // Emit cart update
        _emitCartUpdate();
        return cart;
      },
    );
  }
  
  /// Add a product to the cart by ID only
  /// This simplifies the process and reduces data duplication
  Future<void> addToCartById({
    required BuildContext context,
    required String productId,
  }) async {
    CartLogger.log('IMPROVED_CART', 'Adding to cart by ID: $productId');
    
    try {
      // Get user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userTokenKey);
      
      if (userId == null || userId.isEmpty) {
        CartLogger.error('IMPROVED_CART', 'User not authenticated');
        _showErrorFeedback(context, 'Please log in to add items to cart');
        return;
      }

      // Get current quantity from cache
      final currentQuantity = _cartItemQuantities[productId] ?? 0;
      final newQuantity = currentQuantity + 1;
      
      // Update cache optimistically
      _cartItemQuantities[productId] = newQuantity;
      _emitCartUpdate();
      
      // Send update to the CartBloc immediately for UI feedback
      _updateCartBloc(context);
      
      // Show feedback to user
      _showFeedback(context, 'Item added to cart');
      
      // Perform the actual repository call
      final result = await _cartRepository.updateCartItemQuantity(
        userId: userId,
        productId: productId, 
        quantity: newQuantity,
      );
      
      // Process result
      result.fold(
        (failure) {
          CartLogger.error('IMPROVED_CART', 'Failed to add to cart: ${failure.message}');
          
          // Revert cache on failure
          if (currentQuantity > 0) {
            _cartItemQuantities[productId] = currentQuantity;
          } else {
            _cartItemQuantities.remove(productId);
          }
          
          _emitCartUpdate();
          _updateCartBloc(context);
          
          _showErrorFeedback(context, 'Failed to add item to cart');
        },
        (cart) {
          CartLogger.success('IMPROVED_CART', 'Successfully added to cart');
          // Update cache with server data
          _updateCartCache(cart);
          // Update UI with the latest cart data
          _emitCartUpdate();
          _updateCartBloc(context, result);
        },
      );
    } catch (e) {
      CartLogger.error('IMPROVED_CART', 'Error adding to cart by ID', e);
      _showErrorFeedback(context, 'Failed to add item to cart');
    }
  }
  
  /// Update cart item quantity (can increase or decrease)
  Future<void> updateQuantity({
    required BuildContext context,
    required String productId,
    required int quantity,
  }) async {
    CartLogger.log('IMPROVED_CART', 'Updating quantity for $productId to $quantity');
    
    try {
      // Get user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userTokenKey);
      
      if (userId == null || userId.isEmpty) {
        CartLogger.error('IMPROVED_CART', 'User not authenticated');
        _showErrorFeedback(context, 'Please log in to update cart');
        return;
      }

      // Get current quantity from cache
      final currentQuantity = _cartItemQuantities[productId] ?? 0;
      
      // Update cache optimistically
      if (quantity <= 0) {
        _cartItemQuantities.remove(productId);
      } else {
        _cartItemQuantities[productId] = quantity;
      }
      
      _emitCartUpdate();
      
      // Send update to the CartBloc immediately for UI feedback
      _updateCartBloc(context);
      
      // Show feedback to user
      if (quantity <= 0) {
        _showFeedback(context, 'Item removed from cart');
      } else {
        _showFeedback(context, 'Cart updated');
      }
      
      // Perform the actual repository call
      final result = quantity <= 0
          ? await _cartRepository.removeFromCart(userId: userId, productId: productId)
          : await _cartRepository.updateCartItemQuantity(
              userId: userId,
              productId: productId,
              quantity: quantity,
            );
      
      // Process result
      result.fold(
        (failure) {
          CartLogger.error('IMPROVED_CART', 'Failed to update cart: ${failure.message}');
          
          // Revert cache on failure
          if (currentQuantity > 0) {
            _cartItemQuantities[productId] = currentQuantity;
          } else {
            _cartItemQuantities.remove(productId);
          }
          
          _emitCartUpdate();
          _updateCartBloc(context);
          
          _showErrorFeedback(context, 'Failed to update cart');
        },
        (cart) {
          CartLogger.success('IMPROVED_CART', 'Successfully updated cart');
          // Update cache with server data
          _updateCartCache(cart);
          // Update UI with the latest cart data
          _emitCartUpdate();
          _updateCartBloc(context, result);
        },
      );
    } catch (e) {
      CartLogger.error('IMPROVED_CART', 'Error updating cart quantity', e);
      _showErrorFeedback(context, 'Failed to update cart');
    }
  }
  
  /// Get the current quantity of an item in the cart
  int getQuantity(String productId) {
    return _cartItemQuantities[productId] ?? 0;
  }
  
  /// Check if cart has any items
  bool get hasItems => _cartItemQuantities.isNotEmpty;
  
  /// Get total number of items in cart
  int get totalItems => _cartItemQuantities.values.fold(0, (sum, quantity) => sum + quantity);
  
  /// Clear the cart
  Future<void> clearCart(BuildContext context) async {
    CartLogger.log('IMPROVED_CART', 'Clearing cart');
    
    try {
      // Get user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userTokenKey);
      
      if (userId == null || userId.isEmpty) {
        CartLogger.error('IMPROVED_CART', 'User not authenticated');
        _showErrorFeedback(context, 'Please log in to clear cart');
        return;
      }

      // Update cache optimistically
      _cartItemQuantities.clear();
      _emitCartUpdate();
      
      // Send update to the CartBloc immediately for UI feedback
      _updateCartBloc(context);
      
      // Show feedback to user
      _showFeedback(context, 'Cart cleared');
      
      // Perform the actual repository call
      final result = await _cartRepository.clearCart(userId);
      
      // Process result
      result.fold(
        (failure) {
          CartLogger.error('IMPROVED_CART', 'Failed to clear cart: ${failure.message}');
          _showErrorFeedback(context, 'Failed to clear cart');
        },
        (cart) {
          CartLogger.success('IMPROVED_CART', 'Successfully cleared cart');
          // Update cart bloc
          _updateCartBloc(context, result);
        },
      );
    } catch (e) {
      CartLogger.error('IMPROVED_CART', 'Error clearing cart', e);
      _showErrorFeedback(context, 'Failed to clear cart');
    }
  }
  
  // Private helper methods
  
  // Update the cache with cart data
  void _updateCartCache(Cart cart) {
    _cartItemQuantities.clear();
    
    for (final item in cart.items) {
      _cartItemQuantities[item.productId] = item.quantity;
    }
  }
  
  // Emit cart update to listeners
  void _emitCartUpdate() {
    final update = {
      'hasItems': hasItems,
      'totalItems': totalItems,
      'itemQuantities': Map<String, int>.from(_cartItemQuantities),
    };
    
    _cartStreamController.add(update);
  }
  
  // Update CartBloc to reflect changes
  void _updateCartBloc(BuildContext context, [Either<Failure, Cart>? result]) {
    try {
      // Find the CartBloc
      CartBloc? cartBloc;
      try {
        cartBloc = BlocProvider.of<CartBloc>(context);
      } catch (e) {
        // CartBloc not available, ignore
        return;
      }
      
      if (result != null) {
        // If we have a result from an API call, use it
        result.fold(
          (failure) {
            // Handle error
            CartLogger.error('IMPROVED_CART', 'Failed to update CartBloc: ${failure.message}');
          },
          (cart) {
            // Update CartBloc with new cart data
            cartBloc?.add(UpdateCartItems(cart.items));
          },
        );
      } else {
        // Otherwise, we're doing an optimistic update
        // This could be refined if needed to create proper CartItem objects
        cartBloc.add(ForceSync());
      }
    } catch (e) {
      CartLogger.error('IMPROVED_CART', 'Error updating CartBloc: $e');
    }
  }
  
  // Show success feedback
  void _showFeedback(BuildContext context, String message) {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      // Ignore errors showing feedback
    }
  }
  
  // Show error feedback
  void _showErrorFeedback(BuildContext context, String message) {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      // Ignore errors showing feedback
    }
  }
  
  // Dispose resources
  void dispose() {
    _cartStreamController.close();
  }
}