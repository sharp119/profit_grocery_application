import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failures.dart';
import '../../../core/errors/exceptions.dart';
import '../../../domain/entities/cart.dart';
import '../../../domain/entities/cart_enums.dart';
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
    on<UpdateCartItems>(_onUpdateCartItems); // Register the UpdateCartItems handler
    
    // Subscribe to sync status changes from the cart sync service
    _syncSubscription = _cartSyncService.syncStream.listen((status) {
      this.add(UpdateSyncStatus(status));
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
            this.add(UpdateSyncStatus(syncStatus));
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
        CartLogger.error('BLOC', 'User not authenticated');
        emit(state.copyWith(
          status: CartStatus.error,
          errorMessage: 'User not authenticated',
        ));
        return;
      }

      // IMMEDIATE UI FEEDBACK: Update cart optimistically
      final currentItems = List<CartItem>.from(state.items);
      final existingItemIndex = currentItems.indexWhere((item) => item.productId == product.id);
      
      if (existingItemIndex != -1) {
        // Update existing item
        final existingItem = currentItems[existingItemIndex];
        currentItems[existingItemIndex] = CartItem(
          productId: existingItem.productId,
          name: existingItem.name,
          image: existingItem.image,
          price: existingItem.price,
          mrp: existingItem.mrp,
          quantity: existingItem.quantity + quantity,
          categoryId: existingItem.categoryId,
          categoryName: existingItem.categoryName,
        );
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
          categoryName: product.categoryName ?? '',
        ));
      }
      
      // Calculate new totals for optimistic update
      final newItemCount = currentItems.fold<int>(0, (sum, item) => sum + item.quantity);
      final newSubtotal = currentItems.fold<double>(0, (sum, item) => sum + (item.price * item.quantity));
      
      // Optimistic update
      emit(state.copyWith(
        items: currentItems,
        subtotal: newSubtotal,
        total: newSubtotal - state.discount + state.deliveryFee,
        itemCount: newItemCount,
        status: CartStatus.loading,
      ));
      
      // Now do the actual API call
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
      
      result.fold(
        (failure) {
          CartLogger.error('BLOC', 'Failed to add to cart: ${failure.message}');
          emit(state.copyWith(
            status: CartStatus.error,
            errorMessage: _mapFailureToMessage(failure),
          ));
        },
        (cart) {
          CartLogger.success('BLOC', 'Successfully added to cart. Items: ${cart.itemCount}');
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
      CartLogger.error('BLOC', 'Error adding to cart', e);
      String errorMessage = 'Failed to add product to cart';
      
      // Try to provide a more user-friendly message
      if (e.toString().contains('FormatException')) {
        errorMessage = 'Unable to add product to cart';
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
      
      CartLogger.log('BLOC', 'Updating cart quantity: $productId to $quantity');
      emit(state.copyWith(status: CartStatus.loading));
      
      // Get user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userTokenKey);
      
      if (userId == null || userId.isEmpty) {
        CartLogger.error('BLOC', 'User not authenticated');
        emit(state.copyWith(
          status: CartStatus.error,
          errorMessage: 'User not authenticated',
        ));
        return;
      }

      // IMMEDIATE UI FEEDBACK: Update optimistically
      final currentItems = List<CartItem>.from(state.items);
      
      if (quantity <= 0) {
        // Remove item for zero or negative quantity
        currentItems.removeWhere((item) => item.productId == productId);
      } else {
        // Update quantity
        final existingItemIndex = currentItems.indexWhere((item) => item.productId == productId);
        
        if (existingItemIndex != -1) {
          final existingItem = currentItems[existingItemIndex];
          currentItems[existingItemIndex] = CartItem(
            productId: existingItem.productId,
            name: existingItem.name,
            image: existingItem.image,
            price: existingItem.price,
            mrp: existingItem.mrp,
            quantity: quantity,
            categoryId: existingItem.categoryId,
            categoryName: existingItem.categoryName,
          );
        }
      }
      
      // Calculate new totals for optimistic update
      final newItemCount = currentItems.fold<int>(0, (sum, item) => sum + item.quantity);
      final newSubtotal = currentItems.fold<double>(0, (sum, item) => sum + (item.price * item.quantity));
      
      // Optimistic update
      emit(state.copyWith(
        items: currentItems,
        subtotal: newSubtotal,
        total: newSubtotal - state.discount + state.deliveryFee,
        itemCount: newItemCount,
        status: CartStatus.loading,
      ));
      
      // Now do the actual API call
      final result = await _cartRepository.updateCartItemQuantity(
        userId: userId,
        productId: productId,
        quantity: quantity,
      );
      
      result.fold(
        (failure) {
          CartLogger.error('BLOC', 'Failed to update cart: ${failure.message}');
          emit(state.copyWith(
            status: CartStatus.error,
            errorMessage: _mapFailureToMessage(failure),
          ));
        },
        (cart) {
          CartLogger.success('BLOC', 'Successfully updated cart. Items: ${cart.itemCount}');
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
      CartLogger.error('BLOC', 'Error updating cart item quantity', e);
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
      
      CartLogger.log('BLOC', 'Removing from cart: $productId');
      emit(state.copyWith(status: CartStatus.loading));
      
      // Get user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userTokenKey);
      
      if (userId == null || userId.isEmpty) {
        CartLogger.error('BLOC', 'User not authenticated');
        emit(state.copyWith(
          status: CartStatus.error,
          errorMessage: 'User not authenticated',
        ));
        return;
      }

      // IMMEDIATE UI FEEDBACK: Update optimistically
      final currentItems = List<CartItem>.from(state.items);
      currentItems.removeWhere((item) => item.productId == productId);
      
      // Calculate new totals for optimistic update
      final newItemCount = currentItems.fold<int>(0, (sum, item) => sum + item.quantity);
      final newSubtotal = currentItems.fold<double>(0, (sum, item) => sum + (item.price * item.quantity));
      
      // Optimistic update
      emit(state.copyWith(
        items: currentItems,
        subtotal: newSubtotal,
        total: newSubtotal - state.discount + state.deliveryFee,
        itemCount: newItemCount,
        status: CartStatus.loading,
      ));
      
      // Now do the actual API call
      final result = await _cartRepository.removeFromCart(
        userId: userId,
        productId: productId,
      );
      
      result.fold(
        (failure) {
          CartLogger.error('BLOC', 'Failed to remove from cart: ${failure.message}');
          emit(state.copyWith(
            status: CartStatus.error,
            errorMessage: _mapFailureToMessage(failure),
          ));
        },
        (cart) {
          CartLogger.success('BLOC', 'Successfully removed from cart. Items: ${cart.itemCount}');
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
      CartLogger.error('BLOC', 'Error removing from cart', e);
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
      CartLogger.log('BLOC', 'Clearing cart');
      emit(state.copyWith(status: CartStatus.loading));
      
      // Get user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userTokenKey);
      
      if (userId == null || userId.isEmpty) {
        CartLogger.error('BLOC', 'User not authenticated');
        emit(state.copyWith(
          status: CartStatus.error,
          errorMessage: 'User not authenticated',
        ));
        return;
      }

      // IMMEDIATE UI FEEDBACK: Clear all items
      emit(state.copyWith(
        items: [],
        subtotal: 0,
        total: 0,
        itemCount: 0,
        status: CartStatus.loading,
      ));
      
      // Now do the actual API call
      final result = await _cartRepository.clearCart(userId);
      
      result.fold(
        (failure) {
          CartLogger.error('BLOC', 'Failed to clear cart: ${failure.message}');
          emit(state.copyWith(
            status: CartStatus.error,
            errorMessage: _mapFailureToMessage(failure),
          ));
        },
        (cart) {
          CartLogger.success('BLOC', 'Successfully cleared cart');
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
      CartLogger.error('BLOC', 'Error clearing cart', e);
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
      
      CartLogger.log('BLOC', 'Applying coupon: ${event.code}');
      emit(state.copyWith(status: CartStatus.applyingCoupon));
      
      // Get user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userTokenKey);
      
      if (userId == null || userId.isEmpty) {
        CartLogger.error('BLOC', 'User not authenticated');
        emit(state.copyWith(
          status: CartStatus.error,
          errorMessage: 'User not authenticated',
        ));
        return;
      }

      // First validate the coupon to check requirements
      final validationResult = await _cartRepository.validateCoupon(
        couponCode: event.code,
        cartTotal: state.subtotal,
        productIds: state.items.map((item) => item.productId).toList(),
      );
      
      return validationResult.fold(
        (failure) {
          if (failure is CouponFailure) {
            CartLogger.error('BLOC', 'Coupon error: ${failure.message}');
            
            // Try to check if this is a requirement failure that can be resolved
            // Simulate coupon requirements - In a real app, this would come from a service
            final couponRequirements = _generateCouponRequirements(event.code, state);
            
            if (couponRequirements != null && !couponRequirements['isValid']) {
              // The coupon is valid but has unmet requirements
              emit(state.copyWith(
                status: CartStatus.couponError,
                errorMessage: failure.message,
                couponRequirements: couponRequirements,
              ));
            } else {
              // The coupon is completely invalid
              emit(state.copyWith(
                status: CartStatus.couponError,
                errorMessage: failure.message,
              ));
            }
          } else {
            CartLogger.error('BLOC', 'Failed to apply coupon: ${failure.message}');
            emit(state.copyWith(
              status: CartStatus.error,
              errorMessage: _mapFailureToMessage(failure),
            ));
          }
        },
        (coupon) async {
          // Coupon is valid, now apply it
          final result = await _cartRepository.applyCoupon(
            userId: userId,
            couponCode: event.code,
          );
          
          result.fold(
            (failure) {
              CartLogger.error('BLOC', 'Failed to apply coupon: ${failure.message}');
              emit(state.copyWith(
                status: CartStatus.error,
                errorMessage: _mapFailureToMessage(failure),
              ));
            },
            (cart) {
              CartLogger.success('BLOC', 'Successfully applied coupon. Discount: ${cart.discount}');
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
                couponRequirements: null, // Clear requirements when successfully applied
              ));
            },
          );
        },
      );
    } catch (e) {
      CartLogger.error('BLOC', 'Error applying coupon', e);
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
      CartLogger.log('BLOC', 'Removing coupon');
      emit(state.copyWith(
        status: CartStatus.loading,
        couponRequirements: null, // Clear any coupon requirements
      ));
      
      // Get user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userTokenKey);
      
      if (userId == null || userId.isEmpty) {
        CartLogger.error('BLOC', 'User not authenticated');
        emit(state.copyWith(
          status: CartStatus.error,
          errorMessage: 'User not authenticated',
        ));
        return;
      }

      final result = await _cartRepository.removeCoupon(userId);
      
      result.fold(
        (failure) {
          CartLogger.error('BLOC', 'Failed to remove coupon: ${failure.message}');
          emit(state.copyWith(
            status: CartStatus.error,
            errorMessage: _mapFailureToMessage(failure),
          ));
        },
        (cart) {
          CartLogger.success('BLOC', 'Successfully removed coupon');
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
            couponRequirements: null, // Ensure coupon requirements are cleared
          ));
        },
      );
    } catch (e) {
      CartLogger.error('BLOC', 'Error removing coupon', e);
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
      CartLogger.log('BLOC', 'Force syncing cart');
      emit(state.copyWith(syncStatus: CartSyncStatus.syncing));
      
      // Get user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userTokenKey);
      
      if (userId == null || userId.isEmpty) {
        CartLogger.error('BLOC', 'User not authenticated');
        emit(state.copyWith(
          syncStatus: CartSyncStatus.error,
        ));
        return;
      }
      
      // In the new system, we simply reload from repository
      final result = await _cartRepository.getCart(userId);
      
      result.fold(
        (failure) {
          CartLogger.error('BLOC', 'Sync failed: ${failure.message}');
          emit(state.copyWith(
            syncStatus: CartSyncStatus.error,
          ));
        },
        (cart) {
          CartLogger.success('BLOC', 'Sync completed successfully');
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
            syncStatus: CartSyncStatus.synced,
          ));
        },
      );
    } catch (e) {
      CartLogger.error('BLOC', 'Error during force sync', e);
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
  
  // New handler for the UpdateCartItems event
  void _onUpdateCartItems(
    UpdateCartItems event,
    Emitter<CartState> emit,
  ) {
    try {
      CartLogger.log('BLOC', 'Updating cart items directly with ${event.items.length} items');
      
      // Calculate totals
      final items = event.items;
      final itemCount = items.fold<int>(0, (sum, item) => sum + item.quantity);
      final subtotal = items.fold<double>(0, (sum, item) => sum + (item.price * item.quantity));
      
      // Maintain the current discount and delivery fee
      final discount = state.discount;
      final deliveryFee = state.deliveryFee;
      final total = subtotal - discount + deliveryFee;
      
      // Update the state with new items
      emit(state.copyWith(
        status: CartStatus.loaded,
        items: items,
        subtotal: subtotal,
        total: total,
        itemCount: itemCount,
      ));
      
      CartLogger.success('BLOC', 'Cart items updated directly. New count: $itemCount');
    } catch (e) {
      CartLogger.error('BLOC', 'Error updating cart items directly', e);
      // Don't emit error state to prevent UI disruption, 
      // this is usually called from other components
    }
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
  
  // Helper method to generate coupon requirements for demonstration purposes
  // In a real app, this would be provided by a proper coupon validation service
  Map<String, dynamic>? _generateCouponRequirements(String couponCode, CartState state) {
    // Create a base result structure
    final result = {
      'isValid': false,
      'missingRequirements': <Map<String, dynamic>>[],
      'errorMessage': '',
    };
    
    // Uppercase coupon code for matching
    final code = couponCode.toUpperCase();
    
    // Handle different coupon types based on coupon code
    if (code.startsWith('MIN')) {
      // Minimum purchase requirement coupon (e.g., MIN500)
      try {
        final requiredAmount = double.parse(code.substring(3));
        
        if (state.subtotal < requiredAmount) {
          result['errorMessage'] = 'This coupon requires a minimum purchase of ₹${requiredAmount.toStringAsFixed(0)}.';
          final missingRequirementsList = result['missingRequirements'] as List<Map<String, dynamic>>;
          missingRequirementsList.add({
            'type': 'minimum_purchase',
            'required': requiredAmount,
            'current': state.subtotal,
            'missing': requiredAmount - state.subtotal,
          });
          return result;
        }
      } catch (e) {
        // Invalid format, no specific requirements
        return null;
      }
    }
    
    // Buy X Get Y (e.g., BUY2GET1)
    else if (code.startsWith('BUY') && code.contains('GET')) {
      try {
        final parts = code.split('GET');
        final buyQuantity = int.parse(parts[0].substring(3));
        final getQuantity = int.parse(parts[1]);
        
        // Count total items in cart
        final totalItems = state.items.fold<int>(0, (sum, item) => sum + item.quantity);
        
        if (totalItems < buyQuantity) {
          result['errorMessage'] = 'You need to buy $buyQuantity items to get $getQuantity free.';
          final missingRequirementsList = result['missingRequirements'] as List<Map<String, dynamic>>;
          missingRequirementsList.add({
            'type': 'buy_quantity',
            'required': buyQuantity,
            'current': totalItems,
            'missing': buyQuantity - totalItems,
          });
          return result;
        }
      } catch (e) {
        // Invalid format
        return null;
      }
    }
    
    // Product combination coupon (e.g., COMBO50)
    else if (code == 'COMBO50') {
      // Simulate required products
      final requiredProducts = ['prod_rice_01', 'prod_dal_01'];
      final requiredQuantities = [1, 1];
      
      final cartProductIds = state.items.map((item) => item.productId).toList();
      final cartProductQuantities = {
        for (var item in state.items) item.productId: item.quantity
      };
      
      final missingProducts = <Map<String, dynamic>>[];
      
      for (int i = 0; i < requiredProducts.length; i++) {
        final productId = requiredProducts[i];
        final requiredQuantity = requiredQuantities[i];
        
        if (!cartProductIds.contains(productId)) {
          // Product not in cart
          missingProducts.add({
            'productId': productId,
            'requiredQuantity': requiredQuantity,
            'name': _getProductName(productId),
          });
        } else if (cartProductQuantities[productId]! < requiredQuantity) {
          // Product in cart but not enough quantity
          missingProducts.add({
            'productId': productId,
            'requiredQuantity': requiredQuantity,
            'currentQuantity': cartProductQuantities[productId],
            'missingQuantity': requiredQuantity - cartProductQuantities[productId]!,
            'name': _getProductName(productId),
          });
        }
      }
      
      if (missingProducts.isNotEmpty) {
        result['errorMessage'] = 'Add the required products to avail this offer.';
        final missingRequirementsList = result['missingRequirements'] as List<Map<String, dynamic>>;
        missingRequirementsList.add({
          'type': 'required_products',
          'missingProducts': missingProducts,
        });
        return result;
      }
    }
    
    // Trigger & discount combo coupon (e.g., BREADBUTTER)
    else if (code == 'BREADBUTTER') {
      final triggerProductId = 'prod_butter_01';
      final discountProductId = 'prod_bread_01';
      
      final hasTriggerProduct = state.items.any((item) => item.productId == triggerProductId);
      final hasDiscountProduct = state.items.any((item) => item.productId == discountProductId);
      
      if (!hasTriggerProduct || !hasDiscountProduct) {
        result['errorMessage'] = !hasTriggerProduct
            ? 'Add butter to your cart to get discount on bread.'
            : 'Add bread to your cart to avail this discount.';
        
        final missingItems = <Map<String, dynamic>>[];
        
        if (!hasTriggerProduct) {
          missingItems.add({
            'type': 'trigger_product',
            'productId': triggerProductId,
            'name': 'Butter',
          });
        }
        
        if (!hasDiscountProduct) {
          missingItems.add({
            'type': 'discount_product',
            'productId': discountProductId,
            'name': 'Bread',
          });
        }
        
        final missingRequirementsList = result['missingRequirements'] as List<Map<String, dynamic>>;
        missingRequirementsList.add({
          'type': 'trigger_discount_combo',
          'missingItems': missingItems,
        });
        return result;
      }
    }
    
    // BOGO coupon (e.g., BOGO)
    else if (code == 'BOGO') {
      // Simulate category restriction for this BOGO offer
      final eligibleCategoryIds = ['beverages'];
      
      final eligibleItems = state.items.where((item) => 
          eligibleCategoryIds.contains(item.categoryId)).toList();
      
      if (eligibleItems.isEmpty) {
        result['errorMessage'] = 'Add beverages to your cart to avail the buy-one-get-one offer.';
        final missingRequirementsList = result['missingRequirements'] as List<Map<String, dynamic>>;
        missingRequirementsList.add({
          'type': 'bogo_eligible_products',
        });
        return result;
      }
    }
    
    // No specific requirements found or all requirements met
    return null;
  }
  
  // Helper to get product name - in a real app this would come from a repository
  String _getProductName(String productId) {
    switch (productId) {
      case 'prod_rice_01':
        return 'Basmati Rice (1kg)';
      case 'prod_dal_01':
        return 'Yellow Dal (1kg)';
      case 'prod_butter_01':
        return 'Butter (500g)';
      case 'prod_bread_01':
        return 'Bread (400g)';
      default:
        // Try to extract a readable name from the product ID
        final parts = productId.split('_');
        if (parts.length > 1) {
          return parts[1].substring(0, 1).toUpperCase() + parts[1].substring(1);
        }
        return productId;
    }
  }
}