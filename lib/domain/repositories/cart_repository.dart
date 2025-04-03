import 'package:dartz/dartz.dart';

import '../entities/cart.dart';
import '../entities/coupon.dart';
import '../../core/errors/failures.dart';

abstract class CartRepository {
  /// Get current user's cart
  Future<Either<Failure, Cart>> getCart(String userId);
  
  /// Add item to cart
  Future<Either<Failure, Cart>> addToCart({
    required String userId,
    required String productId,
    required String name,
    required String image,
    required double price,
    required int quantity,
  });
  
  /// Update item quantity in cart
  Future<Either<Failure, Cart>> updateCartItemQuantity({
    required String userId,
    required String productId,
    required int quantity,
  });
  
  /// Remove item from cart
  Future<Either<Failure, Cart>> removeFromCart({
    required String userId,
    required String productId,
  });
  
  /// Clear cart
  Future<Either<Failure, Cart>> clearCart(String userId);
  
  /// Apply coupon to cart
  Future<Either<Failure, Cart>> applyCoupon({
    required String userId,
    required String couponCode,
  });
  
  /// Remove coupon from cart
  Future<Either<Failure, Cart>> removeCoupon(String userId);
  
  /// Check if coupon is valid and applicable
  Future<Either<Failure, Coupon>> validateCoupon({
    required String couponCode,
    required double cartTotal,
    required List<String> productIds,
  });
}