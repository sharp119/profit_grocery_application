import 'package:equatable/equatable.dart';

class Cart extends Equatable {
  final String userId;
  final List<CartItem> items;
  final String? appliedCouponId;
  final String? appliedCouponCode;
  final double discount;
  final double deliveryFee;

  const Cart({
    required this.userId,
    this.items = const [],
    this.appliedCouponId,
    this.appliedCouponCode,
    this.discount = 0.0,
    this.deliveryFee = 0.0,
  });

  // Calculate subtotal (before discount)
  double get subtotal {
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  // Calculate final total (after discount + delivery fee)
  double get total {
    return subtotal - discount + deliveryFee;
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
    String? appliedCouponCode,
    double? discount,
    double? deliveryFee,
  }) {
    return Cart(
      userId: userId ?? this.userId,
      items: items ?? this.items,
      appliedCouponId: appliedCouponId ?? this.appliedCouponId,
      appliedCouponCode: appliedCouponCode ?? this.appliedCouponCode,
      discount: discount ?? this.discount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        items,
        appliedCouponId,
        appliedCouponCode,
        discount,
        deliveryFee,
      ];
}

class CartItem extends Equatable {
  final String productId;
  final String name;
  final String image;
  final double price;
  final double? mrp; // Market Retail Price (original price before discount)
  final int quantity;
  final String? categoryId;
  final String? categoryName;

  const CartItem({
    required this.productId,
    required this.name,
    required this.image,
    required this.price,
    this.mrp,
    required this.quantity,
    this.categoryId,
    this.categoryName,
  });

  // Calculate total price for this item
  double get totalPrice => price * quantity;
  
  // Calculate discount percentage if MRP is available
  double? get discountPercentage {
    if (mrp != null && mrp! > price) {
      return ((mrp! - price) / mrp! * 100).roundToDouble();
    }
    return null;
  }

  // Check if the item has a discount
  bool get hasDiscount => discountPercentage != null && discountPercentage! > 0;

  // Create a copy of the cart item with updated properties
  CartItem copyWith({
    String? productId,
    String? name,
    String? image,
    double? price,
    double? mrp,
    int? quantity,
    String? categoryId,
    String? categoryName,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      image: image ?? this.image,
      price: price ?? this.price,
      mrp: mrp ?? this.mrp,
      quantity: quantity ?? this.quantity,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
    );
  }

  @override
  List<Object?> get props => [
        productId,
        name,
        image,
        price,
        mrp,
        quantity,
        categoryId,
        categoryName,
      ];
}