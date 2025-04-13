part of 'category_products_bloc.dart';

abstract class CategoryProductsState extends Equatable {
  const CategoryProductsState();
  
  @override
  List<Object?> get props => [];
}

/// Initial state when the bloc is created
class CategoryProductsInitial extends CategoryProductsState {}

/// Loading state while fetching data
class CategoryProductsLoading extends CategoryProductsState {}

/// Error state when data fetching fails
class CategoryProductsError extends CategoryProductsState {
  final String message;
  
  const CategoryProductsError(this.message);

  @override
  List<Object> get props => [message];
}

/// Loaded state with categories and products
class CategoryProductsLoaded extends CategoryProductsState {
  final List<Category> categories;
  final Map<String, List<Product>> categoryProducts;
  final Category selectedCategory;
  final Map<String, int> cartQuantities;
  final Map<String, Color> subcategoryColors;
  final Product? lastAddedProduct; // Product that was last added to cart
  
  const CategoryProductsLoaded({
    required this.categories,
    required this.categoryProducts,
    required this.selectedCategory,
    required this.cartQuantities,
    this.subcategoryColors = const {},
    this.lastAddedProduct,
  });
  
  /// Total number of products in the cart
  int get cartItemCount => cartQuantities.values.fold(0, (sum, quantity) => sum + quantity);
  
  /// Total amount in the cart
  double get cartTotal {
    double total = 0;
    
    cartQuantities.forEach((productId, quantity) {
      for (final products in categoryProducts.values) {
        final product = products.firstWhereOrNull(
          (p) => p.id == productId,
        );
        
        if (product != null) {
        // Use price directly since it's already the discounted price in our model
        total += product.price * quantity;
          break;
          }
      }
    });
    
    return total;
  }
  
  /// Creates a copy of the current state with optional new values
  CategoryProductsLoaded copyWith({
    List<Category>? categories,
    Map<String, List<Product>>? categoryProducts,
    Category? selectedCategory,
    Map<String, int>? cartQuantities,
    Map<String, Color>? subcategoryColors,
    Product? lastAddedProduct,
  }) {
    return CategoryProductsLoaded(
      categories: categories ?? this.categories,
      categoryProducts: categoryProducts ?? this.categoryProducts,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      cartQuantities: cartQuantities ?? this.cartQuantities,
      subcategoryColors: subcategoryColors ?? this.subcategoryColors,
      lastAddedProduct: lastAddedProduct, // No default - it should be null unless specified
    );
  }

  @override
  List<Object?> get props => [
    categories,
    categoryProducts,
    selectedCategory,
    cartQuantities,
    subcategoryColors,
    lastAddedProduct,
  ];
}

/// Extension to find first element or return null
extension FirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
