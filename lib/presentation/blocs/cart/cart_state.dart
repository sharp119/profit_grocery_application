import 'package:equatable/equatable.dart';

import '../../../domain/entities/cart.dart';

enum CartStatus {
  initial,
  loading,
  loaded,
  error,
  applyingCoupon,
  couponApplied,
  couponError,
  syncing,
}

class CartState extends Equatable {
  final CartStatus status;
  final List<CartItem> items;
  final double subtotal;
  final double discount;
  final double deliveryFee;
  final double total;
  final int itemCount;
  final String? couponCode;
  final bool couponApplied;
  final String? errorMessage;
  final Map<String, dynamic>? couponRequirements;

  const CartState({
    this.status = CartStatus.initial,
    this.items = const [],
    this.subtotal = 0.0,
    this.discount = 0.0,
    this.deliveryFee = 0.0,
    this.total = 0.0,
    this.itemCount = 0,
    this.couponCode,
    this.couponApplied = false,
    this.errorMessage,
    this.couponRequirements,
  });

  CartState copyWith({
    CartStatus? status,
    List<CartItem>? items,
    double? subtotal,
    double? discount,
    double? deliveryFee,
    double? total,
    int? itemCount,
    String? couponCode,
    bool? couponApplied,
    String? errorMessage,
    Map<String, dynamic>? couponRequirements,
  }) {
    return CartState(
      status: status ?? this.status,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      total: total ?? this.total,
      itemCount: itemCount ?? this.itemCount,
      couponCode: couponCode ?? this.couponCode,
      couponApplied: couponApplied ?? this.couponApplied,
      errorMessage: errorMessage ?? this.errorMessage,
      couponRequirements: couponRequirements ?? this.couponRequirements,
    );
  }

  @override
  List<Object?> get props => [
    status,
    items,
    subtotal,
    discount,
    deliveryFee,
    total,
    itemCount,
    couponCode,
    couponApplied,
    errorMessage,
    couponRequirements,
  ];
}