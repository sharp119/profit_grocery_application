part of 'category_products_bloc.dart';

abstract class CategoryProductsState extends Equatable {
  const CategoryProductsState();
  
  @override
  List<Object?> get props => [];
}

class CategoryProductsInitial extends CategoryProductsState {}

class CategoryProductsLoading extends CategoryProductsState {}

class CategoryProductsLoaded extends CategoryProductsState {
  final List<Category> categories;
  final Map<String, List<Product>> categoryProducts;
  final Category selectedCategory;
  final Map<String, int> cartQuantities;
  final Product? lastAddedProduct;
  final Map<String, Color> subcategoryColors;

  const CategoryProductsLoaded({
    required this.categories,
    required this.categoryProducts,
    required this.selectedCategory,
    required this.cartQuantities,
    this.lastAddedProduct,
    this.subcategoryColors = const {},
  });

  @override
  List<Object?> get props => [
    categories, 
    categoryProducts, 
    selectedCategory, 
    cartQuantities, 
    lastAddedProduct,
    subcategoryColors,
  ];

  CategoryProductsLoaded copyWith({
    List<Category>? categories,
    Map<String, List<Product>>? categoryProducts,
    Category? selectedCategory,
    Map<String, int>? cartQuantities,
    Product? lastAddedProduct,
    Map<String, Color>? subcategoryColors,
  }) {
    return CategoryProductsLoaded(
      categories: categories ?? this.categories,
      categoryProducts: categoryProducts ?? this.categoryProducts,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      cartQuantities: cartQuantities ?? this.cartQuantities,
      lastAddedProduct: lastAddedProduct,
      subcategoryColors: subcategoryColors ?? this.subcategoryColors,
    );
  }
}

class CategoryProductsError extends CategoryProductsState {
  final String message;

  const CategoryProductsError(this.message);

  @override
  List<Object> get props => [message];
}