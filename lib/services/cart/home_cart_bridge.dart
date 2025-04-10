import 'package:flutter/foundation.dart';
import '../../domain/entities/product.dart';
import '../../presentation/blocs/cart/cart_bloc.dart';
import '../../presentation/blocs/cart/cart_event.dart';
import '../../presentation/blocs/home/home_bloc.dart';
import '../../presentation/blocs/home/home_event.dart';
import '../../utils/cart_logger.dart';

/// A bridge to synchronize cart operations between HomeBloc and CartBloc
class HomeCartBridge {
  final CartBloc cartBloc;
  final HomeBloc homeBloc;

  HomeCartBridge({
    required this.cartBloc,
    required this.homeBloc,
  });

  /// Initialize the bridge by setting up listeners
  void initialize() {
    CartLogger.log('HOME_CART_BRIDGE', 'Initializing HomeCartBridge to sync cart actions');
    
    // Ensure that the CartBloc's state is loaded first before any operations
    cartBloc.add(const LoadCart());
  }

  /// Add a product to both HomeBloc and CartBloc
  void addToCart(Product product, int quantity) {
    CartLogger.log('HOME_CART_BRIDGE', 'Adding product to HomeBloc and CartBloc: ${product.name}, quantity: $quantity');
    
    // Add to CartBloc's cart state first (this persists to Firebase and local storage)
    cartBloc.add(AddToCart(product, quantity));
    
    // Add to HomeBloc's cart state
    homeBloc.add(UpdateCartQuantity(product, quantity));
  }

  /// Update a product quantity in both HomeBloc and CartBloc
  void updateCartItemQuantity(Product product, int quantity) {
    CartLogger.log('HOME_CART_BRIDGE', 'Updating product quantity in HomeBloc and CartBloc: ${product.id}, quantity: $quantity');
    
    // Update in CartBloc's cart state first
    cartBloc.add(UpdateCartItemQuantity(product.id, quantity));
    
    // Update in HomeBloc's cart state
    homeBloc.add(UpdateCartQuantity(product, quantity));
  }

  /// Remove a product from both HomeBloc and CartBloc
  void removeFromCart(Product product) {
    CartLogger.log('HOME_CART_BRIDGE', 'Removing product from HomeBloc and CartBloc: ${product.id}');
    
    // Remove from CartBloc's cart state first
    cartBloc.add(RemoveFromCart(product.id));
    
    // Remove from HomeBloc's cart state
    homeBloc.add(UpdateCartQuantity(product, 0));
  }
}