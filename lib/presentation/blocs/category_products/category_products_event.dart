part of 'category_products_bloc.dart';

abstract class CategoryProductsEvent extends Equatable {
  const CategoryProductsEvent();

  @override
  List<Object?> get props => [];
}

/// Load categories and their associated products
class LoadCategoryProducts extends CategoryProductsEvent {
  final String? categoryId;
  
  const LoadCategoryProducts({this.categoryId});

  @override
  List<Object?> get props => [categoryId];
}

/// Select a specific category
class SelectCategory extends CategoryProductsEvent {
  final Category category;
  
  const SelectCategory(this.category);

  @override
  List<Object> get props => [category];
}

/// Update the quantity of a product in the cart
class UpdateCartQuantity extends CategoryProductsEvent {
  final Product product;
  final int quantity;
  
  const UpdateCartQuantity({
    required this.product,
    required this.quantity,
  });

  @override
  List<Object> get props => [product, quantity];
}
