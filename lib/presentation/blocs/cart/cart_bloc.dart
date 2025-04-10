import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/entities/cart.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/repositories/cart_repository.dart';
import '../../../services/cart/cart_sync_service.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final CartRepository _cartRepository;
  final CartSyncService? _cartSyncService;
  StreamSubscription<CartSyncStatus>? _syncSubscription;

  CartBloc({
    required CartRepository cartRepository,
    CartSyncService? cartSyncService,
  }) : _cartRepository = cartRepository,
       _cartSyncService = cartSyncService,
       super(const CartState()) {
    on<LoadCart>(_onLoadCart);
    on<AddToCart>(_onAddToCart);
    on<UpdateCartItemQuantity>(_onUpdateCartItemQuantity);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<ClearCart>(_onClearCart);
    on<ApplyCoupon>(_onApplyCoupon);
    on<RemoveCoupon>(_onRemoveCoupon);
    on<ForceSync>(_onForceSync);
    on<UpdateSyncStatus>(_onUpdateSyncStatus);
    
    // Subscribe to sync status changes if sync service is available
    if (_cartSyncService != null) {
      _syncSubscription = _cartSyncService!.syncStream.listen((status) {
        add(UpdateSyncStatus(status));
      });
    }
  }
  
  @override
  Future<void> close() {
    _syncSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadCart(
    LoadCart event,
    Emitter<CartState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CartStatus.loading));

      // Get user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userTokenKey);
      
      if (userId == null || userId.isEmpty) {
        emit(state.copyWith(
          status: CartStatus.error,
          errorMessage: 'User not authenticated',
        ));
        return;
      }

      // Get cart from repository
      final result = await _cartRepository.getCart(userId);
      
      await result.fold(
        (failure) {
          emit(state.copyWith(
            status: CartStatus.error,
            errorMessage: _mapFailureToMessage(failure),
          ));
        },
        (cart) {
          // Check sync status if sync service is available
          if (_cartSyncService != null) {
            _cartSyncService!.getCurrentSyncStatus().then((syncStatus) {
              add(UpdateSyncStatus(syncStatus));
            });
          }
          
          emit(state.copyWith(
            status: CartStatus.loaded,
            items: cart.items,
            subtotal: cart.subtotal,
            discount: cart.discount,
            deliveryFee: cart.deliveryFee,
            total: cart.total,
            itemCount: cart.itemCount,
            couponCode: cart.appliedCouponCode,
            couponApplied: cart.appliedCouponCode != null,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: CartStatus.error,
        errorMessage: 'Failed to load cart: $e',
      ));
    }
  }

  Future<void> _onAddToCart(
    AddToCart event,
    Emitter<CartState> emit,
  ) async {
    try {
      final product = event.product;
      final quantity = event.quantity;
      
      emit(state.copyWith(status: CartStatus.loading));
      
      // Get user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userTokenKey);
      
      if (userId == null || userId.isEmpty) {
        emit(state.copyWith(
          status: CartStatus.error,
          errorMessage: 'User not authenticated',
        ));
        return;
      }

      // Use sync service if available
      final result = _cartSyncService != null
        ? await _cartSyncService!.addToCart(
            userId: userId,
            productId: product.id,
            name: product.name,
            image: product.image,
            price: product.price,
            quantity: quantity,
            categoryId: product.categoryId,
            categoryName: product.categoryName,
          )
        : await _cartRepository.addToCart(
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
      
      await result.fold(
        (failure) {
          emit(state.copyWith(
            status: CartStatus.error,
            errorMessage: _mapFailureToMessage(failure),
          ));
        },
        (cart) {
          emit(state.copyWith(
            status: CartStatus.loaded,
            items: cart.items,
            subtotal: cart.subtotal,
            discount: cart.discount,
            deliveryFee: cart.deliveryFee,
            total: cart.total,
            itemCount: cart.itemCount,
            couponCode: cart.appliedCouponCode,
            couponApplied: cart.appliedCouponCode != null,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: CartStatus.error,
        errorMessage: 'Failed to add to cart: $e',
      ));
    }
  }

  Future<void> _onUpdateCartItemQuantity(
    UpdateCartItemQuantity event,
    Emitter<CartState> emit,
  ) async {
    try {
      final productId = event.productId;
      final quantity = event.quantity;
      
      emit(state.copyWith(status: CartStatus.loading));
      
      // Get user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userTokenKey);
      
      if (userId == null || userId.isEmpty) {
        emit(state.copyWith(
          status: CartStatus.error,
          errorMessage: 'User not authenticated',
        ));
        return;
      }

      // Use sync service if available
      final result = _cartSyncService != null
        ? await _cartSyncService!.updateCartItemQuantity(
            userId: userId,
            productId: productId,
            quantity: quantity,
          )
        : await _cartRepository.updateCartItemQuantity(
            userId: userId,
            productId: productId,
            quantity: quantity,
          );
      
      await result.fold(
        (failure) {
          emit(state.copyWith(
            status: CartStatus.error,
            errorMessage: _mapFailureToMessage(failure),
          ));
        },
        (cart) {
          emit(state.copyWith(
            status: CartStatus.loaded,
            items: cart.items,
            subtotal: cart.subtotal,
            discount: cart.discount,
            deliveryFee: cart.deliveryFee,
            total: cart.total,
            itemCount: cart.itemCount,
            couponCode: cart.appliedCouponCode,
            couponApplied: cart.appliedCouponCode != null,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: CartStatus.error,
        errorMessage: 'Failed to update cart item: $e',
      ));
    }
  }

  Future<void> _onRemoveFromCart(
    RemoveFromCart event,
    Emitter<CartState> emit,
  ) async {
    try {
      final productId = event.productId;
      
      emit(state.copyWith(status: CartStatus.loading));
      
      // Get user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userTokenKey);
      
      if (userId == null || userId.isEmpty) {
        emit(state.copyWith(
          status: CartStatus.error,
          errorMessage: 'User not authenticated',
        ));
        return;
      }

      // Use sync service if available
      final result = _cartSyncService != null
        ? await _cartSyncService!.removeFromCart(
            userId: userId,
            productId: productId,
          )
        : await _cartRepository.removeFromCart(
            userId: userId,
            productId: productId,
          );
      
      await result.fold(
        (failure) {
          emit(state.copyWith(
            status: CartStatus.error,
            errorMessage: _mapFailureToMessage(failure),
          ));
        },
        (cart) {
          emit(state.copyWith(
            status: CartStatus.loaded,
            items: cart.items,
            subtotal: cart.subtotal,
            discount: cart.discount,
            deliveryFee: cart.deliveryFee,
            total: cart.total,
            itemCount: cart.itemCount,
            couponCode: cart.appliedCouponCode,
            couponApplied: cart.appliedCouponCode != null,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: CartStatus.error,
        errorMessage: 'Failed to remove from cart: $e',
      ));
    }
  }

  Future<void> _onClearCart(
    ClearCart event,
    Emitter<CartState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CartStatus.loading));
      
      // Get user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userTokenKey);
      
      if (userId == null || userId.isEmpty) {
        emit(state.copyWith(
          status: CartStatus.error,
          errorMessage: 'User not authenticated',
        ));
        return;
      }

      // Use sync service if available
      final result = _cartSyncService != null
        ? await _cartSyncService!.clearCart(userId)
        : await _cartRepository.clearCart(userId);
      
      await result.fold(
        (failure) {
          emit(state.copyWith(
            status: CartStatus.error,
            errorMessage: _mapFailureToMessage(failure),
          ));
        },
        (cart) {
          emit(state.copyWith(
            status: CartStatus.loaded,
            items: cart.items,
            subtotal: cart.subtotal,
            discount: cart.discount,
            deliveryFee: cart.deliveryFee,
            total: cart.total,
            itemCount: cart.itemCount,
            couponCode: cart.appliedCouponCode,
            couponApplied: cart.appliedCouponCode != null,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: CartStatus.error,
        errorMessage: 'Failed to clear cart: $e',
      ));
    }
  }

  Future<void> _onApplyCoupon(
    ApplyCoupon event,
    Emitter<CartState> emit,
  ) async {
    try {
      if (state.items.isEmpty) {
        emit(state.copyWith(
          status: CartStatus.couponError,
          errorMessage: 'Cannot apply coupon to an empty cart',
        ));
        return;
      }
      
      emit(state.copyWith(status: CartStatus.applyingCoupon));
      
      // Get user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userTokenKey);
      
      if (userId == null || userId.isEmpty) {
        emit(state.copyWith(
          status: CartStatus.error,
          errorMessage: 'User not authenticated',
        ));
        return;
      }

      // Use sync service if available
      final result = _cartSyncService != null
        ? await _cartSyncService!.applyCoupon(
            userId: userId,
            couponCode: event.code,
          )
        : await _cartRepository.applyCoupon(
            userId: userId,
            couponCode: event.code,
          );
      
      await result.fold(
        (failure) {
          if (failure is CouponFailure) {
            emit(state.copyWith(
              status: CartStatus.couponError,
              errorMessage: failure.message,
            ));
          } else {
            emit(state.copyWith(
              status: CartStatus.error,
              errorMessage: _mapFailureToMessage(failure),
            ));
          }
        },
        (cart) {
          emit(state.copyWith(
            status: CartStatus.couponApplied,
            items: cart.items,
            subtotal: cart.subtotal,
            discount: cart.discount,
            deliveryFee: cart.deliveryFee,
            total: cart.total,
            itemCount: cart.itemCount,
            couponCode: cart.appliedCouponCode,
            couponApplied: cart.appliedCouponCode != null,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: CartStatus.couponError,
        errorMessage: 'Failed to apply coupon: $e',
      ));
    }
  }

  Future<void> _onRemoveCoupon(
    RemoveCoupon event,
    Emitter<CartState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CartStatus.loading));
      
      // Get user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userTokenKey);
      
      if (userId == null || userId.isEmpty) {
        emit(state.copyWith(
          status: CartStatus.error,
          errorMessage: 'User not authenticated',
        ));
        return;
      }

      // Use sync service if available
      final result = _cartSyncService != null
        ? await _cartSyncService!.removeCoupon(userId)
        : await _cartRepository.removeCoupon(userId);
      
      await result.fold(
        (failure) {
          emit(state.copyWith(
            status: CartStatus.error,
            errorMessage: _mapFailureToMessage(failure),
          ));
        },
        (cart) {
          emit(state.copyWith(
            status: CartStatus.loaded,
            items: cart.items,
            subtotal: cart.subtotal,
            discount: cart.discount,
            deliveryFee: cart.deliveryFee,
            total: cart.total,
            itemCount: cart.itemCount,
            couponCode: cart.appliedCouponCode,
            couponApplied: cart.appliedCouponCode != null,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: CartStatus.error,
        errorMessage: 'Failed to remove coupon: $e',
      ));
    }
  }
  
  Future<void> _onForceSync(
    ForceSync event,
    Emitter<CartState> emit,
  ) async {
    try {
      if (_cartSyncService == null) {
        emit(state.copyWith(
          syncStatus: CartSyncStatus.error,
        ));
        return;
      }
      
      emit(state.copyWith(
        syncStatus: CartSyncStatus.syncing,
      ));
      
      final syncStatus = await _cartSyncService!.forceSync();
      
      emit(state.copyWith(
        syncStatus: syncStatus,
      ));
      
      // Reload cart after sync
      add(const LoadCart());
    } catch (e) {
      emit(state.copyWith(
        syncStatus: CartSyncStatus.error,
      ));
    }
  }
  
  void _onUpdateSyncStatus(
    UpdateSyncStatus event,
    Emitter<CartState> emit,
  ) {
    emit(state.copyWith(
      syncStatus: event.status,
    ));
  }

  // Helper method to map failures to user-friendly messages
  String _mapFailureToMessage(Failure failure) {
    return failure.message;
  }
}