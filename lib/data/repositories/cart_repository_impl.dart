import 'package:dartz/dartz.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/coupon.dart';
import '../../domain/entities/coupon_enums.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/local/local_cart_data_source.dart';
import '../../utils/cart_logger.dart';

class CartRepositoryImpl implements CartRepository {
  final FirebaseDatabase database;
  final LocalCartDataSource localCartDataSource;
  final SharedPreferences sharedPreferences;

  CartRepositoryImpl({
    required this.database,
    required this.localCartDataSource,
    required this.sharedPreferences,
  });

  // Reference to the user's cart in Firebase Realtime Database
  DatabaseReference _getUserCartRef(String userId) {
    return database.ref().child('users/$userId/cart');
  }

  // Reference to cart items
  DatabaseReference _getCartItemsRef(String userId) {
    return _getUserCartRef(userId).child('items');
  }

  @override
  Future<Either<Failure, Cart>> getCart(String userId) async {
    try {
      CartLogger.log('CART_REPO', 'Getting cart for user: $userId');
      
      // First check local cache for faster response
      final localCart = await localCartDataSource.getCart();
      if (localCart != null) {
        CartLogger.info('CART_REPO', 'Retrieved cart from local cache with ${localCart.items.length} items');
        return Right(localCart);
      }
      
      // If not in cache, get from Firebase
      final snapshot = await _getUserCartRef(userId).get();
      
      if (!snapshot.exists) {
        // Create a new empty cart
        final emptyCart = Cart(
          userId: userId,
          items: [],
          discount: 0,
          deliveryFee: 0,
        );
        
        // Save the empty cart to Firebase
        await _getUserCartRef(userId).set({
          'subtotal': 0,
          'discount': 0,
          'deliveryFee': 0,
          'total': 0,
          'itemCount': 0,
          'appliedCouponCode': null,
          'updatedAt': ServerValue.timestamp,
          'items': {},
        });
        
        // Save to local cache
        await localCartDataSource.saveCart(emptyCart);
        
        CartLogger.info('CART_REPO', 'Created new empty cart for user');
        return Right(emptyCart);
      }
      
      // Parse the cart data
      final cartData = snapshot.value as Map<dynamic, dynamic>?;
      if (cartData == null) {
        CartLogger.error('CART_REPO', 'Cart data is null');
        return Left(ServerFailure(message: 'Failed to retrieve cart data'));
      }
      
      // Extract cart items
      final List<CartItem> items = [];
      final itemsData = cartData['items'] as Map<dynamic, dynamic>?;
      
      if (itemsData != null) {
        itemsData.forEach((key, value) {
          final item = value as Map<dynamic, dynamic>;
          items.add(CartItem(
            productId: key.toString(),
            name: item['name'] ?? '',
            image: item['image'] ?? '',
            price: (item['price'] ?? 0).toDouble(),
            mrp: item['mrp'] != null ? (item['mrp'] as num).toDouble() : null,
            quantity: item['quantity'] ?? 0,
            categoryId: item['categoryId'],
            categoryName: item['categoryName'] ?? '',
          ));
        });
      }
      
      // Create cart object
      final cart = Cart(
        userId: userId,
        items: items,
        discount: (cartData['discount'] ?? 0).toDouble(),
        deliveryFee: (cartData['deliveryFee'] ?? 0).toDouble(),
        appliedCouponCode: cartData['appliedCouponCode'],
      );
      
      // Save to local cache
      await localCartDataSource.saveCart(cart);
      
      CartLogger.success('CART_REPO', 'Retrieved cart from Firebase with ${items.length} items');
      return Right(cart);
    } catch (e) {
      CartLogger.error('CART_REPO', 'Error getting cart: $e');
      return Left(ServerFailure(message: 'Failed to get cart: $e'));
    }
  }

  @override
  Future<Either<Failure, Cart>> addToCart({
    required String userId,
    required String productId,
    required String name,
    required String image,
    required double price,
    required int quantity,
    double? mrp,
    required String? categoryId,
    String? categoryName,
  }) async {
    try {
      CartLogger.log('CART_REPO', 'Adding to cart: $name (x$quantity)');
      
      // Get the cart items reference
      final cartItemsRef = _getCartItemsRef(userId);
      
      // Check if the item already exists
      final snapshot = await cartItemsRef.child(productId).get();
      
      if (snapshot.exists) {
        // Item exists, update quantity
        final itemData = snapshot.value as Map<dynamic, dynamic>;
        final currentQuantity = itemData['quantity'] ?? 0;
        final newQuantity = currentQuantity + quantity;
        
        await cartItemsRef.child(productId).update({
          'quantity': newQuantity,
          'updatedAt': ServerValue.timestamp,
        });
        
        CartLogger.info('CART_REPO', 'Updated existing item quantity from $currentQuantity to $newQuantity');
      } else {
        // Item doesn't exist, add it
        await cartItemsRef.child(productId).set({
          'name': name,
          'image': image,
          'price': price,
          'mrp': mrp,
          'quantity': quantity,
          'categoryId': categoryId,
          'categoryName': categoryName,
          'addedAt': ServerValue.timestamp,
          'updatedAt': ServerValue.timestamp,
        });
        
        CartLogger.info('CART_REPO', 'Added new item to cart');
      }
      
      // Update cart totals
      await _updateCartTotals(userId);
      
      // Return the updated cart
      final updatedCart = await getCart(userId);
      
      // Invalidate local cache to force refresh
      await localCartDataSource.clearCart();
      
      CartLogger.success('CART_REPO', 'Successfully added item to cart');
      return updatedCart;
    } catch (e) {
      CartLogger.error('CART_REPO', 'Error adding to cart: $e');
      return Left(ServerFailure(message: 'Failed to add to cart: $e'));
    }
  }

  @override
  Future<Either<Failure, Cart>> updateCartItemQuantity({
    required String userId,
    required String productId,
    required int quantity,
  }) async {
    try {
      CartLogger.log('CART_REPO', 'Updating cart item quantity: $productId to $quantity');
      
      if (quantity <= 0) {
        // If quantity is zero or negative, remove item
        return removeFromCart(userId: userId, productId: productId);
      }
      
      // Check if the item exists
      final itemRef = _getCartItemsRef(userId).child(productId);
      final snapshot = await itemRef.get();
      
      if (!snapshot.exists) {
        CartLogger.error('CART_REPO', 'Item not found in cart: $productId');
        return Left(ServerFailure(message: 'Item not found in cart'));
      }
      
      // Update the quantity
      await itemRef.update({
        'quantity': quantity,
        'updatedAt': ServerValue.timestamp,
      });
      
      // Update cart totals
      await _updateCartTotals(userId);
      
      // Return the updated cart
      final updatedCart = await getCart(userId);
      
      // Invalidate local cache
      await localCartDataSource.clearCart();
      
      CartLogger.success('CART_REPO', 'Successfully updated item quantity');
      return updatedCart;
    } catch (e) {
      CartLogger.error('CART_REPO', 'Error updating cart item quantity: $e');
      return Left(ServerFailure(message: 'Failed to update cart item: $e'));
    }
  }

  @override
  Future<Either<Failure, Cart>> removeFromCart({
    required String userId,
    required String productId,
  }) async {
    try {
      CartLogger.log('CART_REPO', 'Removing from cart: $productId');
      
      // Remove the item
      await _getCartItemsRef(userId).child(productId).remove();
      
      // Update cart totals
      await _updateCartTotals(userId);
      
      // Return the updated cart
      final updatedCart = await getCart(userId);
      
      // Invalidate local cache
      await localCartDataSource.clearCart();
      
      CartLogger.success('CART_REPO', 'Successfully removed item from cart');
      return updatedCart;
    } catch (e) {
      CartLogger.error('CART_REPO', 'Error removing from cart: $e');
      return Left(ServerFailure(message: 'Failed to remove from cart: $e'));
    }
  }

  @override
  Future<Either<Failure, Cart>> clearCart(String userId) async {
    try {
      CartLogger.log('CART_REPO', 'Clearing cart for user: $userId');
      
      // Clear all items
      await _getCartItemsRef(userId).remove();
      
      // Reset cart totals
      await _getUserCartRef(userId).update({
        'subtotal': 0,
        'discount': 0,
        'deliveryFee': 0,
        'total': 0,
        'itemCount': 0,
        'appliedCouponCode': null,
        'updatedAt': ServerValue.timestamp,
      });
      
      // Create empty cart object
      final emptyCart = Cart(
        userId: userId,
        items: [],
        discount: 0,
        deliveryFee: 0,
      );
      
      // Update local cache
      await localCartDataSource.saveCart(emptyCart);
      
      CartLogger.success('CART_REPO', 'Successfully cleared cart');
      return Right(emptyCart);
    } catch (e) {
      CartLogger.error('CART_REPO', 'Error clearing cart: $e');
      return Left(ServerFailure(message: 'Failed to clear cart: $e'));
    }
  }

  @override
  Future<Either<Failure, Cart>> applyCoupon({
    required String userId,
    required String couponCode,
  }) async {
    try {
      CartLogger.log('CART_REPO', 'Applying coupon: $couponCode');
      
      // Get current cart
      final cartResult = await getCart(userId);
      
      return cartResult.fold(
        (failure) => Left(failure),
        (cart) async {
          // Validate coupon
          final couponResult = await validateCoupon(
            couponCode: couponCode,
            cartTotal: cart.subtotal,
            productIds: cart.items.map((item) => item.productId).toList(),
          );
          
          return couponResult.fold(
            (failure) => Left(failure),
            (coupon) async {
              // Calculate discount
              double discount = 0;
              
              switch (coupon.type) {
                case CouponType.percentage:
                  discount = cart.subtotal * (coupon.value / 100);
                  if (coupon.maxDiscount != null && discount > coupon.maxDiscount!) {
                    discount = coupon.maxDiscount!;
                  }
                  break;
                case CouponType.fixedAmount:
                  discount = coupon.value;
                  break;
                case CouponType.freeDelivery:
                  discount = cart.deliveryFee;
                  break;
                case CouponType.buyOneGetOne:
                  // For simplicity, apply 50% discount on the cheapest item
                  if (cart.items.isNotEmpty) {
                    final cheapestItem = cart.items.reduce(
                      (a, b) => a.price < b.price ? a : b);
                    discount = cheapestItem.price;
                  }
                  break;
                case CouponType.freeProduct:
                  // For free product, no direct discount is applied
                  // In a real app, this would add a free product to the cart
                  discount = 0;
                  break;
                case CouponType.conditional:
                  // For conditional discounts, would implement specific logic
                  // For now, no discount is applied
                  discount = 0;
                  break;
              }
              
              // Update cart with coupon
              await _getUserCartRef(userId).update({
                'discount': discount,
                'total': cart.subtotal - discount + cart.deliveryFee,
                'appliedCouponCode': couponCode,
                'updatedAt': ServerValue.timestamp,
              });
              
              // Return updated cart
              final updatedCart = await getCart(userId);
              
              // Invalidate local cache
              await localCartDataSource.clearCart();
              
              CartLogger.success('CART_REPO', 'Successfully applied coupon, discount: $discount');
              return updatedCart;
            },
          );
        },
      );
    } catch (e) {
      CartLogger.error('CART_REPO', 'Error applying coupon: $e');
      return Left(ServerFailure(message: 'Failed to apply coupon: $e'));
    }
  }

  @override
  Future<Either<Failure, Cart>> removeCoupon(String userId) async {
    try {
      CartLogger.log('CART_REPO', 'Removing coupon');
      
      // Get current cart
      final cartResult = await getCart(userId);
      
      return cartResult.fold(
        (failure) => Left(failure),
        (cart) async {
          // Update cart
          await _getUserCartRef(userId).update({
            'discount': 0,
            'total': cart.subtotal + cart.deliveryFee,
            'appliedCouponCode': null,
            'updatedAt': ServerValue.timestamp,
          });
          
          // Return updated cart
          final updatedCart = await getCart(userId);
          
          // Invalidate local cache
          await localCartDataSource.clearCart();
          
          CartLogger.success('CART_REPO', 'Successfully removed coupon');
          return updatedCart;
        },
      );
    } catch (e) {
      CartLogger.error('CART_REPO', 'Error removing coupon: $e');
      return Left(ServerFailure(message: 'Failed to remove coupon: $e'));
    }
  }

  @override
  Future<Either<Failure, Coupon>> validateCoupon({
    required String couponCode,
    required double cartTotal,
    required List<String> productIds,
  }) async {
    try {
      CartLogger.log('CART_REPO', 'Validating coupon: $couponCode');
      
      // In a real app, we would fetch coupon from database
      // For demo purposes, use a few hardcoded coupons
      final coupons = {
        'WELCOME': {
          'type': 'percentage',
          'value': 10.0,
          'minPurchase': 0.0,
          'maxDiscount': 100.0,
          'isActive': true,
        },
        'FLAT50': {
          'type': 'fixedAmount',
          'value': 50.0,
          'minPurchase': 200.0,
          'isActive': true,
        },
        'FREE': {
          'type': 'freeDelivery',
          'value': 0.0,
          'minPurchase': 500.0,
          'isActive': true,
        },
      };
      
      final couponData = coupons[couponCode.toUpperCase()];
      if (couponData == null) {
        CartLogger.error('CART_REPO', 'Invalid coupon code: $couponCode');
        return Left(CouponFailure(message: 'Invalid coupon code'));
      }
      
      // Check if coupon is active
      if (!(couponData['isActive'] as bool)) {
        CartLogger.error('CART_REPO', 'Coupon is not active: $couponCode');
        return Left(CouponFailure(message: 'This coupon is no longer active'));
      }
      
      // Check minimum purchase
      final minPurchase = couponData['minPurchase'] as double;
      if (cartTotal < minPurchase) {
        CartLogger.error('CART_REPO', 'Minimum purchase not met for coupon: $couponCode');
        return Left(CouponFailure(
          message: 'Minimum purchase of ${AppConstants.currencySymbol}$minPurchase required',
        ));
      }
      
      // Create coupon object
      final couponType = _getCouponTypeFromString(couponData['type'] as String);
      final coupon = Coupon(
        id: 'coupon_${couponCode.toLowerCase()}',
        code: couponCode.toUpperCase(),
        type: couponType,
        value: couponData['value'] as double,
        minPurchase: minPurchase,
        maxDiscount: couponData['maxDiscount'] as double?,
        description: 'Special offer',
      );
      
      CartLogger.success('CART_REPO', 'Coupon validated successfully: $couponCode');
      return Right(coupon);
    } catch (e) {
      CartLogger.error('CART_REPO', 'Error validating coupon: $e');
      return Left(ServerFailure(message: 'Failed to validate coupon: $e'));
    }
  }
  
  // Helper method to update cart totals
  Future<void> _updateCartTotals(String userId) async {
    try {
      // Get all cart items
      final snapshot = await _getCartItemsRef(userId).get();
      
      if (!snapshot.exists) {
        // No items, set all totals to zero
        await _getUserCartRef(userId).update({
          'subtotal': 0,
          'total': 0,
          'itemCount': 0,
          'discount': 0,
          'updatedAt': ServerValue.timestamp,
        });
        return;
      }
      
      // Calculate totals
      final itemsData = snapshot.value as Map<dynamic, dynamic>;
      double subtotal = 0;
      int itemCount = 0;
      
      itemsData.forEach((key, value) {
        final item = value as Map<dynamic, dynamic>;
        final price = (item['price'] ?? 0).toDouble();
        final quantity = (item['quantity'] ?? 0) as int;
        
        subtotal += price * quantity;
        itemCount += quantity;
      });
      
      // Get current cart for discount and delivery fee
      final cartSnapshot = await _getUserCartRef(userId).get();
      final cartData = cartSnapshot.value as Map<dynamic, dynamic>?;
      
      double discount = 0;
      double deliveryFee = 0;
      String? appliedCouponCode;
      
      if (cartData != null) {
        discount = (cartData['discount'] ?? 0).toDouble();
        deliveryFee = (cartData['deliveryFee'] ?? 0).toDouble();
        appliedCouponCode = cartData['appliedCouponCode'];
      }
      
      // Calculate total
      double total = subtotal - discount + deliveryFee;
      
      // Update cart document
      await _getUserCartRef(userId).update({
        'subtotal': subtotal,
        'discount': discount,
        'deliveryFee': deliveryFee,
        'total': total,
        'itemCount': itemCount,
        'appliedCouponCode': appliedCouponCode,
        'updatedAt': ServerValue.timestamp,
      });
      
      CartLogger.info('CART_REPO', 'Updated cart totals: subtotal=$subtotal, total=$total, items=$itemCount');
    } catch (e) {
      CartLogger.error('CART_REPO', 'Error updating cart totals: $e');
      rethrow; // Rethrow to be handled by the calling method
    }
  }
  
  CouponType _getCouponTypeFromString(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'percentage':
        return CouponType.percentage;
      case 'fixed_amount':
      case 'fixedamount':
        return CouponType.fixedAmount;
      case 'free_delivery':
      case 'freedelivery':
        return CouponType.freeDelivery;
      case 'buy_one_get_one':
      case 'buyonegetone':
      case 'bogo':
        return CouponType.buyOneGetOne;
      case 'free_product':
      case 'freeproduct':
        return CouponType.freeProduct;
      case 'conditional':
        return CouponType.conditional;
      default:
        return CouponType.percentage;
    }
  }
}