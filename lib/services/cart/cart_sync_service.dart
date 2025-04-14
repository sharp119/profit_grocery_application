import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/cart_enums.dart';
import '../../domain/repositories/cart_repository.dart';
import '../../presentation/blocs/cart/cart_event.dart';
import '../../utils/cart_logger.dart';

/// CartSyncService provides backward compatibility with the new centralized cart system
/// It uses the same CartRepository but with a simplified implementation
class CartSyncService {
  final CartRepository _cartRepository;
  final SharedPreferences _sharedPreferences;
  final FirebaseDatabase _database;

  // Stream controller for sync status
  final _syncController = StreamController<CartSyncStatus>.broadcast();
  Stream<CartSyncStatus> get syncStream => _syncController.stream;

  // Current sync status
  CartSyncStatus _currentStatus = CartSyncStatus.synced;

  CartSyncService({
    required CartRepository cartRepository,
    required SharedPreferences sharedPreferences,
    required FirebaseDatabase database,
  })   : _cartRepository = cartRepository,
        _sharedPreferences = sharedPreferences,
        _database = database;

  // Initialize the service (minimal implementation for backward compatibility)
  void init() {
    // Emit initial sync status
    _updateSyncStatus(CartSyncStatus.synced);
  }

  // Get the current sync status
  Future<CartSyncStatus> getCurrentSyncStatus() async {
    return _currentStatus;
  }

  // Force sync (reload cart)
  Future<CartSyncStatus> forceSync() async {
    try {
      _updateSyncStatus(CartSyncStatus.syncing);
      
      // Get user ID
      final userId = _sharedPreferences.getString(AppConstants.userTokenKey);
      
      if (userId != null && userId.isNotEmpty) {
        // Reload cart from repository
        await _cartRepository.getCart(userId);
      }
      
      _updateSyncStatus(CartSyncStatus.synced);
      return _currentStatus;
    } catch (e) {
      _updateSyncStatus(CartSyncStatus.error);
      return _currentStatus;
    }
  }

  // Add to cart
  Future<Either<Failure, Cart>> addToCart({
    required String userId,
    required String productId,
    required String name,
    required String image,
    required double price,
    required int quantity,
    String? categoryId,
    String? categoryName,
  }) async {
    try {
      CartLogger.log('SYNC_SERVICE', 'Adding to cart: $name ($productId), quantity: $quantity');
      
      // Forward directly to repository
      return _cartRepository.addToCart(
        userId: userId,
        productId: productId,
        name: name,
        image: image,
        price: price,
        quantity: quantity,
        categoryId: categoryId,
        categoryName: categoryName,
      );
    } catch (e) {
      // Handle errors
      CartLogger.error('SYNC_SERVICE', 'Error adding to cart', e);
      return Left(ServerFailure(message: 'Failed to add to cart: $e'));
    }
  }

  // Update cart item quantity
  Future<Either<Failure, Cart>> updateCartItemQuantity({
    required String userId,
    required String productId,
    required int quantity,
  }) async {
    try {
      CartLogger.log('SYNC_SERVICE', 'Updating cart item quantity: $productId, quantity: $quantity');
      
      // Forward directly to repository
      return _cartRepository.updateCartItemQuantity(
        userId: userId,
        productId: productId,
        quantity: quantity,
      );
    } catch (e) {
      // Handle errors
      CartLogger.error('SYNC_SERVICE', 'Error updating cart item quantity', e);
      return Left(ServerFailure(message: 'Failed to update cart item: $e'));
    }
  }

  // Remove from cart
  Future<Either<Failure, Cart>> removeFromCart({
    required String userId,
    required String productId,
  }) async {
    try {
      CartLogger.log('SYNC_SERVICE', 'Removing from cart: $productId');
      
      // Forward directly to repository
      return _cartRepository.removeFromCart(
        userId: userId,
        productId: productId,
      );
    } catch (e) {
      // Handle errors
      CartLogger.error('SYNC_SERVICE', 'Error removing from cart', e);
      return Left(ServerFailure(message: 'Failed to remove from cart: $e'));
    }
  }

  // Clear cart
  Future<Either<Failure, Cart>> clearCart(String userId) async {
    try {
      CartLogger.log('SYNC_SERVICE', 'Clearing cart');
      
      // Forward directly to repository
      return _cartRepository.clearCart(userId);
    } catch (e) {
      // Handle errors
      CartLogger.error('SYNC_SERVICE', 'Error clearing cart', e);
      return Left(ServerFailure(message: 'Failed to clear cart: $e'));
    }
  }

  // Apply coupon
  Future<Either<Failure, Cart>> applyCoupon({
    required String userId,
    required String couponCode,
  }) async {
    try {
      CartLogger.log('SYNC_SERVICE', 'Applying coupon: $couponCode');
      
      // Forward directly to repository
      return _cartRepository.applyCoupon(
        userId: userId,
        couponCode: couponCode,
      );
    } catch (e) {
      // Handle errors
      CartLogger.error('SYNC_SERVICE', 'Error applying coupon', e);
      return Left(ServerFailure(message: 'Failed to apply coupon: $e'));
    }
  }

  // Remove coupon
  Future<Either<Failure, Cart>> removeCoupon(String userId) async {
    try {
      CartLogger.log('SYNC_SERVICE', 'Removing coupon');
      
      // Forward directly to repository
      return _cartRepository.removeCoupon(userId);
    } catch (e) {
      // Handle errors
      CartLogger.error('SYNC_SERVICE', 'Error removing coupon', e);
      return Left(ServerFailure(message: 'Failed to remove coupon: $e'));
    }
  }

  // Update sync status and notify listeners
  void _updateSyncStatus(CartSyncStatus status) {
    _currentStatus = status;
    _syncController.add(status);
  }

  // Clean up resources
  void dispose() {
    _syncController.close();
  }
}