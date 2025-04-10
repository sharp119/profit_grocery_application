import 'package:dartz/dartz.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/network_info.dart';
import '../../../domain/entities/cart.dart';
import '../../../domain/entities/coupon.dart';
import '../../../domain/repositories/cart_repository.dart';
import '../../../domain/repositories/coupon_repository.dart';
import '../../datasources/firebase/cart/cart_remote_datasource.dart';
import '../../datasources/local/cart_local_datasource.dart';
import '../../models/cart_model.dart';

class CartRepositoryImpl implements CartRepository {
  final CartRemoteDataSource remoteDataSource;
  final CartLocalDataSource localDataSource;
  final CouponRepository couponRepository;
  final NetworkInfo networkInfo;
  final FirebaseRemoteConfig remoteConfig;

  CartRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.couponRepository,
    required this.networkInfo,
    required this.remoteConfig,
  });

  @override
  Future<Either<Failure, Cart>> getCart(String userId) async {
    try {
      // First, try to get from remote source if online
      if (await networkInfo.isConnected) {
        try {
          final remoteCart = await remoteDataSource.getCart(userId);
          
          // Cache the remote cart locally
          await localDataSource.cacheCart(remoteCart);
          
          return Right(remoteCart);
        } on ServerException catch (e) {
          // If server fails, try to get from local cache
          try {
            final localCart = await localDataSource.getLastCart(userId);
            return Right(localCart);
          } on CacheException catch (e) {
            return Left(CacheFailure(message: e.message));
          }
        }
      } else {
        // If offline, try to get from local cache
        try {
          final localCart = await localDataSource.getLastCart(userId);
          return Right(localCart);
        } on CacheException catch (e) {
          return Left(CacheFailure(message: e.message));
        }
      }
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
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
    String? categoryId,
    String? categoryName,
  }) async {
    try {
      // Create cart item model
      final cartItem = CartItemModel(
        productId: productId,
        name: name,
        image: image,
        price: price,
        mrp: mrp,
        quantity: quantity,
        categoryId: categoryId,
        categoryName: categoryName,
      );
      
      // Try to add to remote if online
      if (await networkInfo.isConnected) {
        try {
          final updatedCart = await remoteDataSource.addCartItem(userId, cartItem);
          
          // Cache the updated cart locally
          await localDataSource.cacheCart(updatedCart);
          
          return Right(updatedCart);
        } on ServerException catch (e) {
          // Fallback to local update
          final localCart = await localDataSource.getLastCart(userId);
          
          // Check if item already exists
          final existingItemIndex = localCart.items.indexWhere(
            (item) => item.productId == productId
          );
          
          final List<CartItemModel> updatedItems = List.from(
            localCart.items.map((item) => item as CartItemModel)
          );
          
          if (existingItemIndex != -1) {
            // Update existing item quantity
            final existingItem = updatedItems[existingItemIndex];
            updatedItems[existingItemIndex] = existingItem.copyWith(
              quantity: existingItem.quantity + quantity
            );
          } else {
            // Add new item
            updatedItems.add(cartItem);
          }
          
          // Create updated cart
          final updatedCart = localCart.copyWith(
            items: updatedItems
          );
          
          // Save to local cache
          await localDataSource.cacheCart(updatedCart);
          
          return Right(updatedCart);
        }
      } else {
        // Offline mode - update local cache only
        final localCart = await localDataSource.getLastCart(userId);
        
        // Check if item already exists
        final existingItemIndex = localCart.items.indexWhere(
          (item) => item.productId == productId
        );
        
        final List<CartItemModel> updatedItems = List.from(
          localCart.items.map((item) => item as CartItemModel)
        );
        
        if (existingItemIndex != -1) {
          // Update existing item quantity
          final existingItem = updatedItems[existingItemIndex];
          updatedItems[existingItemIndex] = existingItem.copyWith(
            quantity: existingItem.quantity + quantity
          );
        } else {
          // Add new item
          updatedItems.add(cartItem);
        }
        
        // Create updated cart
        final updatedCart = localCart.copyWith(
          items: updatedItems
        );
        
        // Save to local cache
        await localDataSource.cacheCart(updatedCart);
        
        return Right(updatedCart);
      }
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Cart>> updateCartItemQuantity({
    required String userId,
    required String productId,
    required int quantity,
  }) async {
    try {
      // Try to update remote if online
      if (await networkInfo.isConnected) {
        try {
          final updatedCart = await remoteDataSource.updateCartItemQuantity(userId, productId, quantity);
          
          // Cache the updated cart locally
          await localDataSource.cacheCart(updatedCart);
          
          return Right(updatedCart);
        } on ServerException catch (e) {
          // Fallback to local update
          final localCart = await localDataSource.getLastCart(userId);
          
          // Find item index
          final itemIndex = localCart.items.indexWhere(
            (item) => item.productId == productId
          );
          
          if (itemIndex == -1) {
            return Left(NotFoundFailure(message: 'Item not found in cart'));
          }
          
          final List<CartItemModel> updatedItems = List.from(
            localCart.items.map((item) => item as CartItemModel)
          );
          
          if (quantity <= 0) {
            // Remove item if quantity is 0 or negative
            updatedItems.removeAt(itemIndex);
          } else {
            // Update item quantity
            final item = updatedItems[itemIndex];
            updatedItems[itemIndex] = item.copyWith(quantity: quantity);
          }
          
          // Create updated cart
          final updatedCart = localCart.copyWith(
            items: updatedItems
          );
          
          // Save to local cache
          await localDataSource.cacheCart(updatedCart);
          
          return Right(updatedCart);
        }
      } else {
        // Offline mode - update local cache only
        final localCart = await localDataSource.getLastCart(userId);
        
        // Find item index
        final itemIndex = localCart.items.indexWhere(
          (item) => item.productId == productId
        );
        
        if (itemIndex == -1) {
          return Left(NotFoundFailure(message: 'Item not found in cart'));
        }
        
        final List<CartItemModel> updatedItems = List.from(
          localCart.items.map((item) => item as CartItemModel)
        );
        
        if (quantity <= 0) {
          // Remove item if quantity is 0 or negative
          updatedItems.removeAt(itemIndex);
        } else {
          // Update item quantity
          final item = updatedItems[itemIndex];
          updatedItems[itemIndex] = item.copyWith(quantity: quantity);
        }
        
        // Create updated cart
        final updatedCart = localCart.copyWith(
          items: updatedItems
        );
        
        // Save to local cache
        await localDataSource.cacheCart(updatedCart);
        
        return Right(updatedCart);
      }
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Cart>> removeFromCart({
    required String userId,
    required String productId,
  }) async {
    try {
      // Try to remove from remote if online
      if (await networkInfo.isConnected) {
        try {
          final updatedCart = await remoteDataSource.removeCartItem(userId, productId);
          
          // Cache the updated cart locally
          await localDataSource.cacheCart(updatedCart);
          
          return Right(updatedCart);
        } on ServerException catch (e) {
          // Fallback to local update
          final localCart = await localDataSource.getLastCart(userId);
          
          // Remove item
          final List<CartItemModel> updatedItems = List.from(
            localCart.items.map((item) => item as CartItemModel)
          )..removeWhere((item) => item.productId == productId);
          
          // Create updated cart
          final updatedCart = localCart.copyWith(
            items: updatedItems
          );
          
          // Save to local cache
          await localDataSource.cacheCart(updatedCart);
          
          return Right(updatedCart);
        }
      } else {
        // Offline mode - update local cache only
        final localCart = await localDataSource.getLastCart(userId);
        
        // Remove item
        final List<CartItemModel> updatedItems = List.from(
          localCart.items.map((item) => item as CartItemModel)
        )..removeWhere((item) => item.productId == productId);
        
        // Create updated cart
        final updatedCart = localCart.copyWith(
          items: updatedItems
        );
        
        // Save to local cache
        await localDataSource.cacheCart(updatedCart);
        
        return Right(updatedCart);
      }
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Cart>> clearCart(String userId) async {
    try {
      // Try to clear remote if online
      if (await networkInfo.isConnected) {
        try {
          final emptyCart = await remoteDataSource.clearCart(userId);
          
          // Clear local cache
          await localDataSource.clearCart(userId);
          
          return Right(emptyCart);
        } on ServerException catch (e) {
          // Fallback to local clear
          await localDataSource.clearCart(userId);
          
          return Right(CartModel.empty(userId));
        }
      } else {
        // Offline mode - clear local cache only
        await localDataSource.clearCart(userId);
        
        return Right(CartModel.empty(userId));
      }
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Cart>> applyCoupon({
    required String userId,
    required String couponCode,
  }) async {
    try {
      // Get current cart
      final cartResult = await getCart(userId);
      
      return cartResult.fold(
        (failure) => Left(failure),
        (cart) async {
          // Validate coupon
          final validationResult = await validateCoupon(
            couponCode: couponCode,
            cartTotal: cart.subtotal,
            productIds: cart.items.map((item) => item.productId).toList(),
          );
          
          return validationResult.fold(
            (failure) => Left(failure),
            (coupon) async {
              // Calculate discount based on coupon type
              double discount = 0.0;
              
              switch(coupon.type) {
                case 'percentage':
                  discount = cart.subtotal * (coupon.value / 100);
                  break;
                case 'fixed':
                  discount = coupon.value;
                  break;
                case 'free_product':
                  // Free product offers would be handled in the checkout process
                  // For now, we'll just set the discount to 0
                  discount = 0.0;
                  break;
                case 'conditional':
                  // Handle conditional discounts
                  // This would typically be more complex in a real app
                  if (coupon.minPurchase != null && cart.subtotal >= coupon.minPurchase!) {
                    discount = coupon.value;
                  }
                  break;
                default:
                  discount = 0.0;
              }
              
              // Try to apply to remote if online
              if (await networkInfo.isConnected) {
                try {
                  final updatedCart = await remoteDataSource.applyCoupon(
                    userId, 
                    coupon.id, 
                    couponCode, 
                    discount
                  );
                  
                  // Cache the updated cart locally
                  await localDataSource.cacheCart(updatedCart);
                  
                  return Right(updatedCart);
                } on ServerException catch (e) {
                  // Fallback to local update
                  final localCart = await localDataSource.getLastCart(userId);
                  
                  // Apply coupon
                  final updatedCart = localCart.copyWith(
                    appliedCouponId: coupon.id,
                    appliedCouponCode: couponCode,
                    discount: discount
                  );
                  
                  // Save to local cache
                  await localDataSource.cacheCart(updatedCart);
                  
                  return Right(updatedCart);
                }
              } else {
                // Offline mode - update local cache only
                final localCart = await localDataSource.getLastCart(userId);
                
                // Apply coupon
                final updatedCart = localCart.copyWith(
                  appliedCouponId: coupon.id,
                  appliedCouponCode: couponCode,
                  discount: discount
                );
                
                // Save to local cache
                await localDataSource.cacheCart(updatedCart);
                
                return Right(updatedCart);
              }
            }
          );
        }
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Cart>> removeCoupon(String userId) async {
    try {
      // Try to remove from remote if online
      if (await networkInfo.isConnected) {
        try {
          final updatedCart = await remoteDataSource.removeCoupon(userId);
          
          // Cache the updated cart locally
          await localDataSource.cacheCart(updatedCart);
          
          return Right(updatedCart);
        } on ServerException catch (e) {
          // Fallback to local update
          final localCart = await localDataSource.getLastCart(userId);
          
          // Remove coupon
          final updatedCart = localCart.copyWith(
            appliedCouponId: null,
            appliedCouponCode: null,
            discount: 0.0
          );
          
          // Save to local cache
          await localDataSource.cacheCart(updatedCart);
          
          return Right(updatedCart);
        }
      } else {
        // Offline mode - update local cache only
        final localCart = await localDataSource.getLastCart(userId);
        
        // Remove coupon
        final updatedCart = localCart.copyWith(
          appliedCouponId: null,
          appliedCouponCode: null,
          discount: 0.0
        );
        
        // Save to local cache
        await localDataSource.cacheCart(updatedCart);
        
        return Right(updatedCart);
      }
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Coupon>> validateCoupon({
    required String couponCode,
    required double cartTotal,
    required List<String> productIds,
  }) async {
    // This should call the coupon repository to validate the coupon
    // For now, we'll delegate to the coupon repository
    return couponRepository.validateCoupon(
      code: couponCode,
      cartTotal: cartTotal,
      productIds: productIds,
    );
  }
}
