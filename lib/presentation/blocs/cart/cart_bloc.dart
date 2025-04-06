import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/cart.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  // In a real app, we would inject repository dependencies here
  // final CartRepository _cartRepository;
  // final CouponRepository _couponRepository;

  CartBloc() : super(const CartState()) {
    on<LoadCart>(_onLoadCart);
    on<AddToCart>(_onAddToCart);
    on<UpdateCartItemQuantity>(_onUpdateCartItemQuantity);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<ClearCart>(_onClearCart);
    on<ApplyCoupon>(_onApplyCoupon);
    on<RemoveCoupon>(_onRemoveCoupon);
  }

  Future<void> _onLoadCart(
    LoadCart event,
    Emitter<CartState> emit,
  ) async {
    try {
      emit(state.copyWith(status: CartStatus.loading));

      // In a real app, we would fetch the cart from a repository
      // For now, we'll use mock data
      final items = _getMockCartItems();
      
      // Calculate cart totals
      final calculations = _calculateCartTotals(items, state.couponCode);
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));

      emit(state.copyWith(
        status: CartStatus.loaded,
        items: items,
        subtotal: calculations.subtotal,
        discount: calculations.discount,
        deliveryFee: calculations.deliveryFee,
        total: calculations.total,
        itemCount: calculations.itemCount,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CartStatus.error,
        errorMessage: 'Failed to load cart: $e',
      ));
    }
  }

  void _onAddToCart(
    AddToCart event,
    Emitter<CartState> emit,
  ) {
    try {
      final product = event.product;
      final quantity = event.quantity;
      
      // Check if product already exists in cart
      final existingItemIndex = state.items.indexWhere(
        (item) => item.productId == product.id,
      );
      
      final updatedItems = List<CartItem>.from(state.items);
      
      if (existingItemIndex != -1) {
        // Update quantity of existing item
        final existingItem = updatedItems[existingItemIndex];
        updatedItems[existingItemIndex] = CartItem(
          productId: existingItem.productId,
          name: existingItem.name,
          image: existingItem.image,
          price: existingItem.price,
          quantity: existingItem.quantity + quantity,
        );
      } else {
        // Add new item to cart
        updatedItems.add(CartItem(
          productId: product.id,
          name: product.name,
          image: product.image,
          price: product.price,
          quantity: quantity,
        ));
      }
      
      // Calculate cart totals
      final calculations = _calculateCartTotals(updatedItems, state.couponCode);
      
      emit(state.copyWith(
        status: CartStatus.loaded,
        items: updatedItems,
        subtotal: calculations.subtotal,
        discount: calculations.discount,
        deliveryFee: calculations.deliveryFee,
        total: calculations.total,
        itemCount: calculations.itemCount,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CartStatus.error,
        errorMessage: 'Failed to add to cart: $e',
      ));
    }
  }

  void _onUpdateCartItemQuantity(
    UpdateCartItemQuantity event,
    Emitter<CartState> emit,
  ) {
    try {
      final productId = event.productId;
      final quantity = event.quantity;
      
      // Update or remove item
      List<CartItem> updatedItems = List<CartItem>.from(state.items);
      
      if (quantity <= 0) {
        // Remove item from cart
        updatedItems.removeWhere((item) => item.productId == productId);
      } else {
        // Update item quantity
        final itemIndex = updatedItems.indexWhere(
          (item) => item.productId == productId,
        );
        
        if (itemIndex != -1) {
          final item = updatedItems[itemIndex];
          updatedItems[itemIndex] = CartItem(
            productId: item.productId,
            name: item.name,
            image: item.image,
            price: item.price,
            quantity: quantity,
          );
        }
      }
      
      // Calculate cart totals
      final calculations = _calculateCartTotals(updatedItems, state.couponCode);
      
      // Update coupon status if cart is empty
      final couponApplied = updatedItems.isEmpty ? false : state.couponApplied;
      final couponCode = updatedItems.isEmpty ? null : state.couponCode;
      
      emit(state.copyWith(
        status: CartStatus.loaded,
        items: updatedItems,
        subtotal: calculations.subtotal,
        discount: calculations.discount,
        deliveryFee: calculations.deliveryFee,
        total: calculations.total,
        itemCount: calculations.itemCount,
        couponApplied: couponApplied,
        couponCode: couponCode,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CartStatus.error,
        errorMessage: 'Failed to update cart item: $e',
      ));
    }
  }

  void _onRemoveFromCart(
    RemoveFromCart event,
    Emitter<CartState> emit,
  ) {
    try {
      final productId = event.productId;
      
      // Remove item from cart
      final updatedItems = List<CartItem>.from(state.items)
        ..removeWhere((item) => item.productId == productId);
      
      // Calculate cart totals
      final calculations = _calculateCartTotals(updatedItems, state.couponCode);
      
      // Update coupon status if cart is empty
      final couponApplied = updatedItems.isEmpty ? false : state.couponApplied;
      final couponCode = updatedItems.isEmpty ? null : state.couponCode;
      
      emit(state.copyWith(
        status: CartStatus.loaded,
        items: updatedItems,
        subtotal: calculations.subtotal,
        discount: calculations.discount,
        deliveryFee: calculations.deliveryFee,
        total: calculations.total,
        itemCount: calculations.itemCount,
        couponApplied: couponApplied,
        couponCode: couponCode,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CartStatus.error,
        errorMessage: 'Failed to remove from cart: $e',
      ));
    }
  }

  void _onClearCart(
    ClearCart event,
    Emitter<CartState> emit,
  ) {
    try {
      emit(state.copyWith(
        status: CartStatus.loaded,
        items: const [],
        subtotal: 0.0,
        discount: 0.0,
        deliveryFee: 0.0,
        total: 0.0,
        itemCount: 0,
        couponApplied: false,
        couponCode: null,
      ));
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
      
      // Simulate coupon validation delay
      await Future.delayed(const Duration(seconds: 1));
      
      // In a real app, we would validate the coupon with a repository
      // For now, we'll just accept any coupon
      final code = event.code;
      
      // Check if coupon is valid (mock validation)
      final isValidCoupon = code.isNotEmpty;
      
      if (isValidCoupon) {
        // Apply coupon discount (mock discount calculation)
        final updatedCalculations = _calculateCartTotals(
          state.items,
          code,
          forceCouponApply: true,
        );
        
        emit(state.copyWith(
          status: CartStatus.couponApplied,
          couponCode: code,
          couponApplied: true,
          discount: updatedCalculations.discount,
          total: updatedCalculations.total,
        ));
      } else {
        emit(state.copyWith(
          status: CartStatus.couponError,
          errorMessage: 'Invalid coupon code',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: CartStatus.couponError,
        errorMessage: 'Failed to apply coupon: $e',
      ));
    }
  }

  void _onRemoveCoupon(
    RemoveCoupon event,
    Emitter<CartState> emit,
  ) {
    try {
      // Calculate cart totals without coupon
      final calculations = _calculateCartTotals(state.items, null);
      
      emit(state.copyWith(
        status: CartStatus.loaded,
        couponCode: null,
        couponApplied: false,
        discount: 0.0,
        total: calculations.total,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CartStatus.error,
        errorMessage: 'Failed to remove coupon: $e',
      ));
    }
  }
  
  // Cart calculations helper
  _CartCalculations _calculateCartTotals(
    List<CartItem> items,
    String? couponCode, {
    bool forceCouponApply = false,
  }) {
    // Calculate subtotal
    final subtotal = items.fold<double>(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    
    // Calculate item count
    final itemCount = items.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
    
    // Calculate delivery fee
    final deliveryFee = subtotal >= 500 ? 0.0 : 40.0; // Free delivery above ₹500
    
    // Calculate discount
    double discount = 0.0;
    if ((couponCode != null && couponCode.isNotEmpty) || forceCouponApply) {
      // Apply mock discount based on coupon code or cart value
      if (couponCode == 'WELCOME10' || (forceCouponApply && subtotal < 300)) {
        discount = subtotal * 0.1; // 10% discount
      } else if (couponCode == 'SAVE15' || (forceCouponApply && subtotal >= 300 && subtotal < 500)) {
        discount = subtotal * 0.15; // 15% discount
      } else if (couponCode == 'FIRST20' || (forceCouponApply && subtotal >= 500)) {
        discount = subtotal * 0.2; // 20% discount
      } else {
        // Default discount
        discount = subtotal * 0.1; // 10% discount
      }
    }
    
    // Calculate total
    final total = subtotal - discount + deliveryFee;
    
    return _CartCalculations(
      subtotal: subtotal,
      discount: discount,
      deliveryFee: deliveryFee,
      total: total,
      itemCount: itemCount,
    );
  }
  
  // Mock data methods
  List<CartItem> _getMockCartItems() {
    return [
      CartItem(
        productId: '1',
        name: 'Fresh Organic Tomatoes',
        price: 49.0,
        quantity: 2,
        image: '${AppConstants.assetsProductsPath}1.png',
      ),
      CartItem(
        productId: '2',
        name: 'Premium Basmati Rice 5kg',
        price: 299.0,
        quantity: 1,
        image: '${AppConstants.assetsProductsPath}2.png',
      ),
      CartItem(
        productId: '3',
        name: 'Whole Wheat Atta 10kg',
        price: 450.0,
        quantity: 1,
        image: '${AppConstants.assetsProductsPath}3.png',
      ),
    ];
  }
}

class _CartCalculations {
  final double subtotal;
  final double discount;
  final double deliveryFee;
  final double total;
  final int itemCount;

  _CartCalculations({
    required this.subtotal,
    required this.discount,
    required this.deliveryFee,
    required this.total,
    required this.itemCount,
  });
}