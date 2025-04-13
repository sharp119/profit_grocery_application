import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/entities/cart.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/repositories/cart_repository.dart';
import '../../../services/cart/cart_sync_service.dart';
import '../../../utils/cart_logger.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final CartRepository _cartRepository;
  final CartSyncService _cartSyncService;
  StreamSubscription<CartSyncStatus>? _syncSubscription;

  CartBloc({
    required CartRepository cartRepository,
    required CartSyncService cartSyncService,
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
    
    // Subscribe to sync status changes from the cart sync service
    _syncSubscription = _cartSyncService.syncStream.listen((status) {
      add(UpdateSyncStatus(status));
    });
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
      CartLogger.log('BLOC', 'Loading cart...');
      emit(state.copyWith(status: CartStatus.loading));

      // Get user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userTokenKey);
      CartLogger.info('BLOC', 'User ID for cart: $userId');
      
      if (userId == null || userId.isEmpty) {
        CartLogger.error('BLOC', 'User not authenticated');
        emit(state.copyWith(
          status: CartStatus.error,
          errorMessage: 'User not authenticated',
        ));
        return;
      }

      // Get cart from repository
      CartLogger.info('BLOC', 'Fetching cart from repository for user: $userId');
      final result = await _cartRepository.getCart(userId);
      
      result.fold(
        (failure) {
          CartLogger.error('BLOC', 'Failed to load cart: ${failure.message}');
          emit(state.copyWith(
            status: CartStatus.error,
            errorMessage: _mapFailureToMessage(failure),
          ));
        },
        (cart) {
          // Get current sync status from the sync service
          _cartSyncService.getCurrentSyncStatus().then((syncStatus) {
            CartLogger.info('BLOC', 'Cart sync status: $syncStatus');
            add(UpdateSyncStatus(syncStatus));
          });
          
          CartLogger.success('BLOC', 'Cart loaded successfully: ${cart.items.length} items, total: ${cart.total}');
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
    } catch (e, stackTrace) {
      CartLogger.error('BLOC', 'Exception loading cart', e, stackTrace);
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
      
      CartLogger.log('BLOC', 'Adding to cart: ${product.name} (${product.id}), quantity: $quantity');
      emit(state.copyWith(status: CartStatus.loading));
      
      // Get user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userTokenKey);
      CartLogger.info('BLOC', 'User ID for adding to cart: $userId');
      
      if (userId == null || userId.isEmpty) {
        CartLogger.error('BLOC', 'User not authenticated for adding to cart');
        emit(state.copyWith(
          status: CartStatus.error,
          errorMessage: 'User not authenticated',
        ));
        return;
      }

      // IMMEDIATE UI UPDATE: First update the state optimistically for immediate UI feedback
      // This helps keep the UI responsive while we wait for the actual repository operation
      final currentItems = List<CartItem>.from(state.items);
      final existingItemIndex = currentItems.indexWhere((item) => item.productId == product.id);
      
      if (existingItemIndex != -1) {
        // Update existing item
        final existingItem = currentItems[existingItemIndex];
        currentItems[existingItemIndex] = existingItem.copyWith(quantity: existingItem.quantity + quantity);
      } else {
        // Add new item
        currentItems.add(CartItem(
          productId: product.id,
          name: product.name,
          image: product.image,
          price: product.price,
          mrp: product.mrp,
          quantity: quantity,
          categoryId: product.categoryId,
          categoryName: product.categoryName,
        ));
      }
      
      // Calculate new totals
      final newSubtotal = currentItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
      final newItemCount = currentItems.fold(0, (sum, item) => sum + item.quantity);
      
      // Emit optimistic update
      emit(state.copyWith(
        items: currentItems,
        subtotal: newSubtotal,
        total: newSubtotal - state.discount + state.deliveryFee,
        itemCount: newItemCount,
        status: CartStatus.loading,
      ));
      
      // Use the cart sync service to persist changes
      CartLogger.info('BLOC', 'Adding item to cart via CartSyncService');
      final result = await _cartSyncService.addToCart(
        userId: userId,
        productId: product.id,
        name: product.name,
        image: product.image,
        price: product.price,
        quantity: quantity,
        categoryId: product.categoryId,
        categoryName: product.categoryName,
      );
      
      result.fold(
        (failure) {
          CartLogger.error('BLOC', 'Failed to add to cart: ${failure.message}');
          emit(state.copyWith(
            status: CartStatus.error,
            errorMessage: _mapFailureToMessage(failure),
          ));
        },
        (cart) {
          CartLogger.success('BLOC', 'Item added to cart successfully. Cart now has ${cart.items.length} items, total: ${cart.total}');
          CartLogger.info('BLOC', 'Cart items after add: ${cart.items.map((item) => "${item.name} (${item.quantity})").join(', ')}');
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
    } catch (e, stackTrace) {
      CartLogger.error('BLOC', 'Exception adding to cart', e, stackTrace);
      
      // Check if the error is a format exception for better user experience
      String errorMessage;
      if (e.toString().contains('FormatException')) {
        // Don't show the technical details to the user
        errorMessage = 'Unable to add product to cart';
      } else {
        // For other errors, provide a generic message
        errorMessage = 'Failed to add product to cart';
      }
      
      emit(state.copyWith(
        status: CartStatus.error,
        errorMessage: errorMessage,
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

      // Use the cart sync service
      final result = await _cartSyncService.updateCartItemQuantity(
        userId: userId,
        productId: productId,
        quantity: quantity,
      );
      
      result.fold(
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

      // Use the cart sync service
      final result = await _cartSyncService.removeFromCart(
        userId: userId,
        productId: productId,
      );
      
      result.fold(
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

      // Use the cart sync service
      final result = await _cartSyncService.clearCart(userId);
      
      result.fold(
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

      // Use the cart sync service
      final result = await _cartSyncService.applyCoupon(
        userId: userId,
        couponCode: event.code,
      );
      
      result.fold(
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

      // Use the cart sync service
      final result = await _cartSyncService.removeCoupon(userId);
      
      result.fold(
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
      // Set status to syncing
      emit(state.copyWith(
        syncStatus: CartSyncStatus.syncing,
      ));
      
      // Force sync using the cart sync service
      final syncStatus = await _cartSyncService.forceSync();
      
      emit(state.copyWith(
        syncStatus: syncStatus,
      ));
      
      // Reload cart after sync to ensure latest data
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
    // Check if the failure message contains FormatException
    if (failure.message.contains('FormatException')) {
      return 'Unable to add product to cart';
    }
    
    // Check for other common errors that should be user-friendly
    if (failure.message.contains('double') || 
        failure.message.contains('parse') ||
        failure.message.contains('Invalid')) {
      return 'Unable to process this product';
    }
    
    return failure.message;
  }
}