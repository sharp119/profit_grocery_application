import 'package:firebase_database/firebase_database.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../models/cart_model.dart';

abstract class CartRemoteDataSource {
  /// Gets the [CartModel] for the provided user ID from Firebase Realtime Database.
  ///
  /// Throws a [ServerException] for all error codes.
  Future<CartModel> getCart(String userId);

  /// Updates the [CartModel] in Firebase Realtime Database.
  ///
  /// Throws a [ServerException] for all error codes.
  Future<CartModel> updateCart(CartModel cart);

  /// Adds an item to the user's cart.
  ///
  /// If the item already exists, its quantity will be updated.
  /// Throws a [ServerException] for all error codes.
  Future<CartModel> addCartItem(String userId, CartItemModel item);

  /// Updates the quantity of an item in the user's cart.
  ///
  /// If quantity is 0 or less, the item will be removed.
  /// Throws a [ServerException] for all error codes.
  Future<CartModel> updateCartItemQuantity(String userId, String productId, int quantity);

  /// Removes an item from the user's cart.
  ///
  /// Throws a [ServerException] for all error codes.
  Future<CartModel> removeCartItem(String userId, String productId);

  /// Clears all items from the user's cart.
  ///
  /// Throws a [ServerException] for all error codes.
  Future<CartModel> clearCart(String userId);

  /// Applies a coupon to the user's cart.
  ///
  /// Throws a [ServerException] for all error codes.
  Future<CartModel> applyCoupon(String userId, String couponId, String couponCode, double discount);

  /// Removes the applied coupon from the user's cart.
  ///
  /// Throws a [ServerException] for all error codes.
  Future<CartModel> removeCoupon(String userId);
}

class CartRemoteDataSourceImpl implements CartRemoteDataSource {
  final FirebaseDatabase database;

  CartRemoteDataSourceImpl({required this.database});

  @override
  Future<CartModel> getCart(String userId) async {
    try {
      final ref = database.ref().child('users/$userId/cart');
      final snapshot = await ref.get();
      
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return CartModel.fromJson(data);
      } else {
        return CartModel.empty(userId);
      }
    } catch (e) {
      throw ServerException(message: 'Failed to fetch cart data: $e');
    }
  }

  @override
  Future<CartModel> updateCart(CartModel cart) async {
    try {
      final userId = cart.userId;
      final ref = database.ref().child('users/$userId/cart');
      
      await ref.set(cart.toJson());
      
      return cart;
    } catch (e) {
      throw ServerException(message: 'Failed to update cart: $e');
    }
  }

  @override
  Future<CartModel> addCartItem(String userId, CartItemModel item) async {
    try {
      // Get current cart
      final currentCart = await getCart(userId);
      
      // Check if item already exists
      final existingItemIndex = currentCart.items.indexWhere(
        (cartItem) => cartItem.productId == item.productId
      );
      
      final List<CartItemModel> updatedItems = List.from(
        currentCart.items.map((item) => item as CartItemModel)
      );
      
      if (existingItemIndex != -1) {
        // Update existing item quantity
        final existingItem = updatedItems[existingItemIndex];
        updatedItems[existingItemIndex] = existingItem.copyWith(
          quantity: existingItem.quantity + item.quantity
        ) as CartItemModel;
      } else {
        // Add new item
        updatedItems.add(item);
      }
      
      // Create updated cart
      final updatedCart = currentCart.copyWith(
        items: updatedItems
      ) as CartModel;
      
      // Save to Firebase
      return updateCart(updatedCart);
    } catch (e) {
      throw ServerException(message: 'Failed to add item to cart: $e');
    }
  }

  @override
  Future<CartModel> updateCartItemQuantity(String userId, String productId, int quantity) async {
    try {
      // Get current cart
      final currentCart = await getCart(userId);
      
      // Find item index
      final itemIndex = currentCart.items.indexWhere(
        (item) => item.productId == productId
      );
      
      if (itemIndex == -1) {
        throw ServerException(message: 'Item not found in cart');
      }
      
      final List<CartItemModel> updatedItems = List.from(
        currentCart.items.map((item) => item as CartItemModel)
      );
      
      if (quantity <= 0) {
        // Remove item if quantity is 0 or negative
        updatedItems.removeAt(itemIndex);
      } else {
        // Update item quantity
        final item = updatedItems[itemIndex];
        updatedItems[itemIndex] = item.copyWith(quantity: quantity) as CartItemModel;
      }
      
      // Create updated cart
      final updatedCart = currentCart.copyWith(
        items: updatedItems
      ) as CartModel;
      
      // Save to Firebase
      return updateCart(updatedCart);
    } catch (e) {
      throw ServerException(message: 'Failed to update item quantity: $e');
    }
  }

  @override
  Future<CartModel> removeCartItem(String userId, String productId) async {
    try {
      // Get current cart
      final currentCart = await getCart(userId);
      
      // Remove item
      final List<CartItemModel> updatedItems = List.from(
        currentCart.items.map((item) => item as CartItemModel)
      )..removeWhere((item) => item.productId == productId);
      
      // Create updated cart
      final updatedCart = currentCart.copyWith(
        items: updatedItems
      ) as CartModel;
      
      // Save to Firebase
      return updateCart(updatedCart);
    } catch (e) {
      throw ServerException(message: 'Failed to remove item from cart: $e');
    }
  }

  @override
  Future<CartModel> clearCart(String userId) async {
    try {
      // Create empty cart
      final emptyCart = CartModel.empty(userId);
      
      // Save to Firebase
      return updateCart(emptyCart);
    } catch (e) {
      throw ServerException(message: 'Failed to clear cart: $e');
    }
  }

  @override
  Future<CartModel> applyCoupon(String userId, String couponId, String couponCode, double discount) async {
    try {
      // Get current cart
      final currentCart = await getCart(userId);
      
      // Apply coupon
      final updatedCart = currentCart.copyWith(
        appliedCouponId: couponId,
        appliedCouponCode: couponCode,
        discount: discount
      ) as CartModel;
      
      // Save to Firebase
      return updateCart(updatedCart);
    } catch (e) {
      throw ServerException(message: 'Failed to apply coupon: $e');
    }
  }

  @override
  Future<CartModel> removeCoupon(String userId) async {
    try {
      // Get current cart
      final currentCart = await getCart(userId);
      
      // Remove coupon
      final updatedCart = currentCart.copyWith(
        appliedCouponId: null,
        appliedCouponCode: null,
        discount: 0.0
      ) as CartModel;
      
      // Save to Firebase
      return updateCart(updatedCart);
    } catch (e) {
      throw ServerException(message: 'Failed to remove coupon: $e');
    }
  }
}
