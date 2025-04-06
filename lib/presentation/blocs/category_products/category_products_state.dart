import 'package:equatable/equatable.dart';

import '../../../domain/entities/category.dart';
import '../../../domain/entities/product.dart';

abstract class CategoryProductsState extends Equatable {
  const CategoryProductsState();

  @override
  List<Object?> get props => [];
}

/// Initial state for category products
class CategoryProductsInitial extends CategoryProductsState {
  const CategoryProductsInitial();
}

/// Loading categories and products
class CategoryProductsLoading extends CategoryProductsState {
  const CategoryProductsLoading();
}

/// Successfully loaded categories and products
class CategoryProductsLoaded extends CategoryProductsState {
  final List<Category> categories;
  final Map<String, List<Product>> categoryProducts;
  final Category? selectedCategory;
  final String? priceSort;
  final bool? filterInStock;
  final Map<String, List<Product>> filteredCategoryProducts;

  const CategoryProductsLoaded({
    required this.categories,
    required this.categoryProducts,
    this.selectedCategory,
    this.priceSort,
    this.filterInStock,
    Map<String, List<Product>>? filteredCategoryProducts,
  }) : filteredCategoryProducts = filteredCategoryProducts ?? categoryProducts;

  /// Create a copy of this state with specified fields updated
  CategoryProductsLoaded copyWith({
    List<Category>? categories,
    Map<String, List<Product>>? categoryProducts,
    Category? selectedCategory,
    String? priceSort,
    bool? filterInStock,
    Map<String, List<Product>>? filteredCategoryProducts,
  }) {
    return CategoryProductsLoaded(
      categories: categories ?? this.categories,
      categoryProducts: categoryProducts ?? this.categoryProducts,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      priceSort: priceSort ?? this.priceSort,
      filterInStock: filterInStock ?? this.filterInStock,
      filteredCategoryProducts: filteredCategoryProducts ?? this.filteredCategoryProducts,
    );
  }

  @override
  List<Object?> get props => [
    categories, 
    categoryProducts, 
    selectedCategory, 
    priceSort, 
    filterInStock,
    filteredCategoryProducts,
  ];
}

/// Error loading categories and products
class CategoryProductsError extends CategoryProductsState {
  final String message;

  const CategoryProductsError(this.message);

  @override
  List<Object?> get props => [message];
}
