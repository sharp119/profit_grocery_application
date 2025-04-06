import '../../domain/entities/cart.dart';

class CartModel extends Cart {
  const CartModel({
    required String userId,
    List<CartItemModel> items = const [],
    String? appliedCouponId,
    String? appliedCouponCode,
    double discount = 0.0,
    double deliveryFee = 0.0,
  }) : super(
          userId: userId,
          items: items,
          appliedCouponId: appliedCouponId,
          appliedCouponCode: appliedCouponCode,
          discount: discount,
          deliveryFee: deliveryFee,
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
      appliedCouponCode: json['appliedCouponCode'],
      discount: json['discount']?.toDouble() ?? 0.0,
      deliveryFee: json['deliveryFee']?.toDouble() ?? 0.0,
    );
  }

  // Convert CartModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'items': items.map((item) => (item as CartItemModel).toJson()).toList(),
      'appliedCouponId': appliedCouponId,
      'appliedCouponCode': appliedCouponCode,
      'discount': discount,
      'deliveryFee': deliveryFee,
    };
  }

  // Create a copy of the cart with updated fields
  @override
  CartModel copyWith({
    String? userId,
    List<CartItem>? items,
    String? appliedCouponId,
    String? appliedCouponCode,
    double? discount,
    double? deliveryFee,
  }) {
    return CartModel(
      userId: userId ?? this.userId,
      items: items != null
          ? List<CartItemModel>.from(items.map((e) => e as CartItemModel))
          : List<CartItemModel>.from(this.items.map((e) => e as CartItemModel)),
      appliedCouponId: appliedCouponId ?? this.appliedCouponId,
      appliedCouponCode: appliedCouponCode ?? this.appliedCouponCode,
      discount: discount ?? this.discount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
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
    double? mrp,
    required int quantity,
    String? categoryId,
    String? categoryName,
  }) : super(
          productId: productId,
          name: name,
          image: image,
          price: price,
          mrp: mrp,
          quantity: quantity,
          categoryId: categoryId,
          categoryName: categoryName,
        );

  // Factory constructor to create a CartItemModel from JSON
  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      productId: json['productId'],
      name: json['name'],
      image: json['image'],
      price: json['price'].toDouble(),
      mrp: json['mrp']?.toDouble(),
      quantity: json['quantity'],
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
    );
  }

  // Convert CartItemModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'image': image,
      'price': price,
      'mrp': mrp,
      'quantity': quantity,
      'categoryId': categoryId,
      'categoryName': categoryName,
    };
  }

  // Create a copy of the cart item with updated fields
  @override
  CartItemModel copyWith({
    String? productId,
    String? name,
    String? image,
    double? price,
    double? mrp,
    int? quantity,
    String? categoryId,
    String? categoryName,
  }) {
    return CartItemModel(
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
}