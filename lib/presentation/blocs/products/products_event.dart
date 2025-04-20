import 'package:equatable/equatable.dart';

abstract class ProductsEvent extends Equatable {
  const ProductsEvent();

  @override
  List<Object> get props => [];
}

class LoadBestsellerProducts extends ProductsEvent {
  final int? limit;
  final bool? ranked;
  
  const LoadBestsellerProducts({this.limit = 6, this.ranked = true});
  
  @override
  List<Object> get props => [limit ?? 6, ranked ?? true];
}

class LoadProductsByCategory extends ProductsEvent {
  final String categoryId;
  
  const LoadProductsByCategory(this.categoryId);
  
  @override
  List<Object> get props => [categoryId];
}

class LoadProductsBySubcategory extends ProductsEvent {
  final String categoryId;
  final String subcategoryId;
  
  const LoadProductsBySubcategory(this.categoryId, this.subcategoryId);
  
  @override
  List<Object> get props => [categoryId, subcategoryId];
}

class LoadSimilarProducts extends ProductsEvent {
  final String productId;
  final int limit;
  
  const LoadSimilarProducts(this.productId, {this.limit = 3});
  
  @override
  List<Object> get props => [productId, limit];
}

class LoadProductById extends ProductsEvent {
  final String productId;
  
  const LoadProductById(this.productId);
  
  @override
  List<Object> get props => [productId];
}

class RefreshProducts extends ProductsEvent {
  const RefreshProducts();
}
