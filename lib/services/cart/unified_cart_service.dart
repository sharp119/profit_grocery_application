import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:profit_grocery_application/core/errors/failures.dart';

import '../../domain/entities/cart.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/cart_repository.dart';
import '../../presentation/blocs/cart/cart_bloc.dart';
import '../../presentation/blocs/cart/cart_event.dart';
import '../../utils/cart_logger.dart';

/// A truly universal cart service that provides a single interface for all cart operations
/// This service ensures consistent behavior across all screens and components
class UnifiedCartService {
  // Singleton pattern
  static final UnifiedCartService _instance = UnifiedCartService._internal();
  
  factory UnifiedCartService() {
    return _instance;
  }
  
  UnifiedCartService._internal();
  
  // Dependencies
  late final CartRepository _cartRepository = GetIt.instance<CartRepository>();
  
  // Stream controller for real-time cart updates
  
  /// Initialize the cart service
  void initialize() {
    CartLogger.log('UNIFIED_CART', 'Initializing unified cart service');
  }
  
  /// Get the current user's cart
  Future<Cart> getCart(String userId) async {
    CartLogger.log('UNIFIED_CART', 'Getting cart for user: $userId');
    
    final result = await _cartRepository.getCart(userId);
    
    return result.fold(
      (failure) {
        CartLogger.error('UNIFIED_CART', 'Failed to get cart: ${failure.message}');
        // Return empty cart on error
        return Cart(
          userId: userId,
          items: [],
          discount: 0,
          deliveryFee: 0,
        );
      },
      (cart) {
        CartLogger.success('UNIFIED_CART', 'Got cart with ${cart.items.length} items');
        return cart;
      },
    );
  }
  
  /// Add a product to the cart
  Future<void> addToCart({
    required BuildContext context,
    required String userId,
    required Product product,
    required int quantity,
  }) async {
    CartLogger.log('UNIFIED_CART', 'Adding to cart: ${product.name} (x$quantity)');
    
    try {
      // Call repository to add to Firebase
      final result = await _cartRepository.addToCart(
        userId: userId,
        productId: product.id,
        name: product.name,
        image: product.image,
        price: product.price,
        quantity: quantity,
        mrp: product.mrp,
        categoryId: product.categoryId,
        categoryName: product.categoryName,
      );
      
      // Update CartBloc if available
      _updateCartBloc(context, result);
      
      // Show user feedback
      _showFeedback(context, 'Added ${product.name} to cart');
      
      CartLogger.success('UNIFIED_CART', 'Successfully added product to cart');
    } catch (e) {
      CartLogger.error('UNIFIED_CART', 'Error adding to cart: $e');
      _showErrorFeedback(context, 'Failed to add product to cart');
    }
  }
  
  /// Update a product's quantity in the cart
  Future<void> updateCartQuantity({
    required BuildContext context,
    required String userId,
    required Product product,
    required int quantity,
  }) async {
    CartLogger.log('UNIFIED_CART', 'Updating cart quantity: ${product.name} to $quantity');
    
    try {
      Future<Either<Failure, Cart>> result;
      
      if (quantity <= 0) {
        // Remove product from cart
        result = _cartRepository.removeFromCart(
          userId: userId,
          productId: product.id,
        );
      } else {
        // Get existing quantity from cart first
        final cart = await getCart(userId);
        final existingItem = cart.items.where((item) => item.productId == product.id).toList();
        
        if (existingItem.isEmpty) {
          // Item not in cart, add it
          result = _cartRepository.addToCart(
            userId: userId,
            productId: product.id,
            name: product.name,
            image: product.image,
            price: product.price,
            quantity: quantity,
            mrp: product.mrp,
            categoryId: product.categoryId,
            categoryName: product.categoryName,
          );
        } else {
          // Update existing item
          result = _cartRepository.updateCartItemQuantity(
            userId: userId,
            productId: product.id,
            quantity: quantity,
          );
        }
      }
      
      // Wait for result and update CartBloc
      final finalResult = await result;
      _updateCartBloc(context, finalResult);
      
      // Show user feedback
      if (quantity <= 0) {
        _showFeedback(context, 'Removed ${product.name} from cart');
      } else {
        _showFeedback(context, 'Updated ${product.name} quantity');
      }
      
      CartLogger.success('UNIFIED_CART', 'Successfully updated cart quantity');
    } catch (e) {
      CartLogger.error('UNIFIED_CART', 'Error updating cart quantity: $e');
      _showErrorFeedback(context, 'Failed to update cart');
    }
  }
  
  /// Remove a product from the cart
  Future<void> removeFromCart({
    required BuildContext context,
    required String userId,
    required Product product,
  }) async {
    CartLogger.log('UNIFIED_CART', 'Removing from cart: ${product.name}');
    
    try {
      final result = await _cartRepository.removeFromCart(
        userId: userId,
        productId: product.id,
      );
      
      // Update CartBloc if available
      _updateCartBloc(context, result);
      
      // Show user feedback
      _showFeedback(context, 'Removed ${product.name} from cart');
      
      CartLogger.success('UNIFIED_CART', 'Successfully removed product from cart');
    } catch (e) {
      CartLogger.error('UNIFIED_CART', 'Error removing from cart: $e');
      _showErrorFeedback(context, 'Failed to remove product from cart');
    }
  }
  
  /// Clear the cart
  Future<void> clearCart({
    required BuildContext context,
    required String userId,
  }) async {
    CartLogger.log('UNIFIED_CART', 'Clearing cart');
    
    try {
      final result = await _cartRepository.clearCart(userId);
      
      // Update CartBloc if available
      _updateCartBloc(context, result);
      
      // Show user feedback
      _showFeedback(context, 'Cart cleared');
      
      CartLogger.success('UNIFIED_CART', 'Successfully cleared cart');
    } catch (e) {
      CartLogger.error('UNIFIED_CART', 'Error clearing cart: $e');
      _showErrorFeedback(context, 'Failed to clear cart');
    }
  }
  
  /// Get the quantity of a product in the cart
  Future<int> getProductQuantity(String userId, String productId) async {
    try {
      final cart = await getCart(userId);
      final item = cart.items.where((item) => item.productId == productId).toList();
      
      if (item.isEmpty) {
        return 0;
      } else {
        return item.first.quantity;
      }
    } catch (e) {
      CartLogger.error('UNIFIED_CART', 'Error getting product quantity: $e');
      return 0;
    }
  }
  
  // Private helper methods
  
  // Update CartBloc with new cart data
  void _updateCartBloc(BuildContext context, Either<Failure, Cart> result) {
    try {
      // Get CartBloc if available
      CartBloc? cartBloc;
      try {
        cartBloc = BlocProvider.of<CartBloc>(context);
      } catch (e) {
        // CartBloc not available, ignore
        return;
      }
      
      // Update CartBloc
      result.fold(
        (failure) {
          // Handle error
          CartLogger.error('UNIFIED_CART', 'Failed to update CartBloc: ${failure.message}');
        },
        (cart) {
          // Update CartBloc with new cart data
          cartBloc?.add(UpdateCartItems(cart.items));
          CartLogger.info('UNIFIED_CART', 'Updated CartBloc with ${cart.items.length} items');
        },
      );
    } catch (e) {
      CartLogger.error('UNIFIED_CART', 'Error updating CartBloc: $e');
    }
  }
  
  // Show success feedback
  void _showFeedback(BuildContext context, String message) {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $message'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Ignore errors when showing feedback
      CartLogger.error('UNIFIED_CART', 'Error showing feedback: $e');
    }
  }
  
  // Show error feedback
  void _showErrorFeedback(BuildContext context, String message) {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $message'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Ignore errors when showing feedback
      CartLogger.error('UNIFIED_CART', 'Error showing error feedback: $e');
    }
  }
}