import 'package:equatable/equatable.dart';

import '../../../domain/entities/cart.dart';
import '../../../domain/entities/product.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class LoadCart extends CartEvent {
  const LoadCart();
}

class AddToCart extends CartEvent {
  final Product product;
  final int quantity;

  const AddToCart(this.product, this.quantity);

  @override
  List<Object?> get props => [product, quantity];
}

class UpdateCartItemQuantity extends CartEvent {
  final String productId;
  final int quantity;

  const UpdateCartItemQuantity(this.productId, this.quantity);

  @override
  List<Object?> get props => [productId, quantity];
}

class RemoveFromCart extends CartEvent {
  final String productId;

  const RemoveFromCart(this.productId);

  @override
  List<Object?> get props => [productId];
}

class ClearCart extends CartEvent {
  const ClearCart();
}

class ApplyCoupon extends CartEvent {
  final String code;

  const ApplyCoupon(this.code);

  @override
  List<Object?> get props => [code];
}

class RemoveCoupon extends CartEvent {
  const RemoveCoupon();
}

class ForceSync extends CartEvent {
  const ForceSync();
}

/// Event to directly update cart items from an external source
/// This helps ensure consistent cart state across all screens
class UpdateCartItems extends CartEvent {
  final List<CartItem> items;

  const UpdateCartItems(this.items);

  @override
  List<Object?> get props => [items];
}