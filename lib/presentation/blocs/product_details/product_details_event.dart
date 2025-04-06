import 'package:equatable/equatable.dart';
import '../../../domain/entities/product.dart';

abstract class ProductDetailsEvent extends Equatable {
  const ProductDetailsEvent();

  @override
  List<Object?> get props => [];
}

class LoadProductDetails extends ProductDetailsEvent {
  final String productId;

  const LoadProductDetails(this.productId);

  @override
  List<Object?> get props => [productId];
}

class AddToCart extends ProductDetailsEvent {
  final Product product;
  final int quantity;

  const AddToCart(this.product, this.quantity);

  @override
  List<Object?> get props => [product, quantity];
}

class RemoveFromCart extends ProductDetailsEvent {
  final String productId;

  const RemoveFromCart(this.productId);

  @override
  List<Object?> get props => [productId];
}