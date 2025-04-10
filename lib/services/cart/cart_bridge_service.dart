import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/product.dart';
import '../../presentation/blocs/cart/cart_bloc.dart';
import '../../presentation/blocs/cart/cart_event.dart';
import '../../utils/cart_logger.dart';

/// Service to bridge cart-related operations between different parts of the app
class CartBridgeService {
  final CartBloc cartBloc;

  CartBridgeService({required this.cartBloc});

  /// Add a product to the cart
  void addToCart(Product product, int quantity) {
    CartLogger.log('CART_BRIDGE', 'Adding product to cart: ${product.name} (${product.id}), quantity: $quantity');
    cartBloc.add(AddToCart(product, quantity));
  }

  /// Update the quantity of a product in the cart
  void updateCartItemQuantity(String productId, int quantity) {
    CartLogger.log('CART_BRIDGE', 'Updating cart item quantity: $productId, quantity: $quantity');
    cartBloc.add(UpdateCartItemQuantity(productId, quantity));
  }

  /// Remove a product from the cart
  void removeFromCart(String productId) {
    CartLogger.log('CART_BRIDGE', 'Removing product from cart: $productId');
    cartBloc.add(RemoveFromCart(productId));
  }

  /// Clear the cart
  void clearCart() {
    CartLogger.log('CART_BRIDGE', 'Clearing cart');
    cartBloc.add(const ClearCart());
  }

  /// Force reload the cart
  void reloadCart() {
    CartLogger.log('CART_BRIDGE', 'Reloading cart');
    cartBloc.add(const LoadCart());
  }
}