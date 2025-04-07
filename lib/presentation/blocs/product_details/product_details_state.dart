import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../domain/entities/product.dart';

enum ProductDetailsStatus {
  initial,
  loading,
  loaded,
  error,
}

class ProductDetailsState extends Equatable {
  final ProductDetailsStatus status;
  final Product? product;
  final String? errorMessage;
  final int cartItemCount;
  final double? cartTotalAmount;
  final Map<String, int> cartQuantities;
  final Map<String, Color> subcategoryColors;

  const ProductDetailsState({
    this.status = ProductDetailsStatus.initial,
    this.product,
    this.errorMessage,
    this.cartItemCount = 0,
    this.cartTotalAmount,
    this.cartQuantities = const {},
    this.subcategoryColors = const {},
  });

  ProductDetailsState copyWith({
    ProductDetailsStatus? status,
    Product? product,
    String? errorMessage,
    int? cartItemCount,
    double? cartTotalAmount,
    Map<String, int>? cartQuantities,
    Map<String, Color>? subcategoryColors,
  }) {
    return ProductDetailsState(
      status: status ?? this.status,
      product: product ?? this.product,
      errorMessage: errorMessage ?? this.errorMessage,
      cartItemCount: cartItemCount ?? this.cartItemCount,
      cartTotalAmount: cartTotalAmount ?? this.cartTotalAmount,
      cartQuantities: cartQuantities ?? this.cartQuantities,
      subcategoryColors: subcategoryColors ?? this.subcategoryColors,
    );
  }

  @override
  List<Object?> get props => [
    status,
    product,
    errorMessage,
    cartItemCount,
    cartTotalAmount,
    cartQuantities,
    subcategoryColors,
  ];
}