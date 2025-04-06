import 'package:equatable/equatable.dart';

abstract class CategoryProductsEvent extends Equatable {
  const CategoryProductsEvent();

  @override
  List<Object?> get props => [];
}

/// Load all categories and their products
class LoadCategoriesAndProducts extends CategoryProductsEvent {
  const LoadCategoriesAndProducts();
}

/// Select a specific category by ID
class SelectCategory extends CategoryProductsEvent {
  final String categoryId;

  const SelectCategory(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

/// Filter products by price, availability, etc.
class FilterProducts extends CategoryProductsEvent {
  final String? priceSort; // 'high_to_low', 'low_to_high'
  final bool? filterInStock;

  const FilterProducts({
    this.priceSort,
    this.filterInStock,
  });

  @override
  List<Object?> get props => [priceSort, filterInStock];
}

/// Reset all filters
class ResetFilters extends CategoryProductsEvent {
  const ResetFilters();
}

/// Refresh the category view without reloading data
/// Used to force UI updates when needed
class RefreshCategoryView extends CategoryProductsEvent {
  const RefreshCategoryView();
}
