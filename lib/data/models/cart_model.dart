import '../../domain/entities/cart.dart';

class CartModel extends Cart {
  const CartModel({
    required String userId,
    List<CartItemModel> items = const [],
    String? appliedCouponId,
    double discount = 0.0,
  }) : super(
          userId: userId,
          items: items,
          appliedCouponId: appliedCouponId,
          discount: discount,
        );

  // Factory constructor to create a CartModel from JSON
  factory CartModel.fromJson(Map<String, dynamic> json) {
    return CartModel(
      userId: json['userId'],
      items: json['items'] != null
          ? List<CartItemModel>.from(
              json['items'].map((item) => CartItemModel.fromJson(item)))
          : [],
      appliedCouponId: json['appliedCouponId'],
      discount: json['discount']?.toDouble() ?? 0.0,
    );
  }

  // Convert CartModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'items': items.map((item) => (item as CartItemModel).toJson()).toList(),
      'appliedCouponId': appliedCouponId,
      'discount': discount,
    };
  }

  // Create a copy of the cart with updated fields
  @override
  CartModel copyWith({
    String? userId,
    List<CartItem>? items,
    String? appliedCouponId,
    double? discount,
  }) {
    return CartModel(
      userId: userId ?? this.userId,
      items: items != null
          ? List<CartItemModel>.from(items.map((e) => e as CartItemModel))
          : List<CartItemModel>.from(this.items.map((e) => e as CartItemModel)),
      appliedCouponId: appliedCouponId ?? this.appliedCouponId,
      discount: discount ?? this.discount,
    );
  }

  // Create an empty cart model
  static CartModel empty(String userId) {
    return CartModel(
      userId: userId,
    );
  }
}

class CartItemModel extends CartItem {
  const CartItemModel({
    required String productId,
    required String name,
    required String image,
    required double price,
    required int quantity,
  }) : super(
          productId: productId,
          name: name,
          image: image,
          price: price,
          quantity: quantity,
        );

  // Factory constructor to create a CartItemModel from JSON
  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      productId: json['productId'],
      name: json['name'],
      image: json['image'],
      price: json['price'].toDouble(),
      quantity: json['quantity'],
    );
  }

  // Convert CartItemModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'image': image,
      'price': price,
      'quantity': quantity,
    };
  }

  // Create a copy of the cart item with updated fields
  @override
  CartItemModel copyWith({
    String? productId,
    String? name,
    String? image,
    double? price,
    int? quantity,
  }) {
    return CartItemModel(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      image: image ?? this.image,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
    );
  }
}