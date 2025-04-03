import 'package:equatable/equatable.dart';

class Cart extends Equatable {
  final String userId;
  final List<CartItem> items;
  final String? appliedCouponId;
  final double discount;

  const Cart({
    required this.userId,
    this.items = const [],
    this.appliedCouponId,
    this.discount = 0.0,
  });

  // Calculate subtotal (before discount)
  double get subtotal {
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  // Calculate final total (after discount)
  double get total {
    return subtotal - discount;
  }

  // Get total number of items
  int get itemCount {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  // Check if cart is empty
  bool get isEmpty => items.isEmpty;

  // Check if cart has a specific item
  bool hasItem(String productId) {
    return items.any((item) => item.productId == productId);
  }

  // Get a specific item from cart
  CartItem? getItem(String productId) {
    try {
      return items.firstWhere((item) => item.productId == productId);
    } catch (_) {
      return null;
    }
  }

  // Create a copy of the cart with updated properties
  Cart copyWith({
    String? userId,
    List<CartItem>? items,
    String? appliedCouponId,
    double? discount,
  }) {
    return Cart(
      userId: userId ?? this.userId,
      items: items ?? this.items,
      appliedCouponId: appliedCouponId ?? this.appliedCouponId,
      discount: discount ?? this.discount,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        items,
        appliedCouponId,
        discount,
      ];
}

class CartItem extends Equatable {
  final String productId;
  final String name;
  final String image;
  final double price;
  final int quantity;

  const CartItem({
    required this.productId,
    required this.name,
    required this.image,
    required this.price,
    required this.quantity,
  });

  // Calculate total price for this item
  double get totalPrice => price * quantity;

  // Create a copy of the cart item with updated properties
  CartItem copyWith({
    String? productId,
    String? name,
    String? image,
    double? price,
    int? quantity,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      image: image ?? this.image,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object?> get props => [
        productId,
        name,
        image,
        price,
        quantity,
      ];
}