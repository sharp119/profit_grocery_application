import 'package:equatable/equatable.dart';
import '../../../domain/entities/product.dart';

enum ProductsStatus { initial, loading, loaded, error }

class ProductsState extends Equatable {
  final ProductsStatus status;
  final List<Product> bestsellerProducts;
  final List<Product> categoryProducts;
  final List<Product> subcategoryProducts;
  final List<Product> similarProducts;
  final Product? selectedProduct;
  final String? errorMessage;
  final String? currentCategoryId;
  final String? currentSubcategoryId;
  
  const ProductsState({
    this.status = ProductsStatus.initial,
    this.bestsellerProducts = const [],
    this.categoryProducts = const [],
    this.subcategoryProducts = const [],
    this.similarProducts = const [],
    this.selectedProduct,
    this.errorMessage,
    this.currentCategoryId,
    this.currentSubcategoryId,
  });
  
  ProductsState copyWith({
    ProductsStatus? status,
    List<Product>? bestsellerProducts,
    List<Product>? categoryProducts,
    List<Product>? subcategoryProducts,
    List<Product>? similarProducts,
    Product? selectedProduct,
    String? errorMessage,
    String? currentCategoryId,
    String? currentSubcategoryId,
  }) {
    return ProductsState(
      status: status ?? this.status,
      bestsellerProducts: bestsellerProducts ?? this.bestsellerProducts,
      categoryProducts: categoryProducts ?? this.categoryProducts,
      subcategoryProducts: subcategoryProducts ?? this.subcategoryProducts,
      similarProducts: similarProducts ?? this.similarProducts,
      selectedProduct: selectedProduct ?? this.selectedProduct,
      errorMessage: errorMessage ?? this.errorMessage,
      currentCategoryId: currentCategoryId ?? this.currentCategoryId,
      currentSubcategoryId: currentSubcategoryId ?? this.currentSubcategoryId,
    );
  }
  
  // Helper method to check if bestsellers are loaded
  bool get areBestsellersLoaded => 
      status == ProductsStatus.loaded && bestsellerProducts.isNotEmpty;
  
  // Helper method to check if category products are loaded for a specific categoryId
  bool isCategoryLoaded(String categoryId) => 
      status == ProductsStatus.loaded && 
      currentCategoryId == categoryId && 
      categoryProducts.isNotEmpty;
  
  // Helper method to check if subcategory products are loaded for specific IDs
  bool isSubcategoryLoaded(String categoryId, String subcategoryId) => 
      status == ProductsStatus.loaded && 
      currentCategoryId == categoryId && 
      currentSubcategoryId == subcategoryId && 
      subcategoryProducts.isNotEmpty;
  
  // Helper method to check if similar products are loaded for a specific productId
  bool areSimilarProductsLoaded(String productId) => 
      status == ProductsStatus.loaded && 
      selectedProduct?.id == productId && 
      similarProducts.isNotEmpty;
  
  @override
  List<Object?> get props => [
    status, 
    bestsellerProducts, 
    categoryProducts, 
    subcategoryProducts,
    similarProducts,
    selectedProduct,
    errorMessage,
    currentCategoryId,
    currentSubcategoryId,
  ];
}
