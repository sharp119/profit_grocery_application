import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/category_color_mapper.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/repositories/category_repository.dart';
import '../../../domain/repositories/product_repository.dart';
import 'category_products_event.dart';
import 'category_products_state.dart';

class CategoryProductsBloc extends Bloc<CategoryProductsEvent, CategoryProductsState> {
  final CategoryRepository categoryRepository;
  final ProductRepository productRepository;

  CategoryProductsBloc({
    required this.categoryRepository,
    required this.productRepository,
  }) : super(const CategoryProductsInitial()) {
    on<LoadCategoriesAndProducts>(_onLoadCategoriesAndProducts);
    on<SelectCategory>(_onSelectCategory);
    on<FilterProducts>(_onFilterProducts);
    on<ResetFilters>(_onResetFilters);
    on<RefreshCategoryView>(_onRefreshCategoryView);
  }
  
  /// Handle refreshing the category view without reloading data
  void _onRefreshCategoryView(
    RefreshCategoryView event,
    Emitter<CategoryProductsState> emit,
  ) {
    if (state is CategoryProductsLoaded) {
      final currentState = state as CategoryProductsLoaded;
      
      // Re-emit the current state to force UI update
      emit(currentState.copyWith());
    }
  }

  /// Handle loading categories and products
  Future<void> _onLoadCategoriesAndProducts(
    LoadCategoriesAndProducts event,
    Emitter<CategoryProductsState> emit,
  ) async {
    emit(const CategoryProductsLoading());

    try {
      // Fetch all categories
      final categoriesResult = await categoryRepository.getCategories();
      
      return categoriesResult.fold(
        (failure) => emit(CategoryProductsError(failure.message)),
        (categories) async {
          // Sort categories by display order if available
          categories.sort((a, b) => (a.displayOrder ?? 0).compareTo(b.displayOrder ?? 0));
          
          // Initialize map to hold products by category
          final Map<String, List<Product>> categoryProducts = {};
          
          // Preload category colors for consistent UI
          _preloadCategoryColors(categories);
          
          // Fetch products for each category
          for (final category in categories) {
            final productsResult = await productRepository.getProductsByCategory(category.id);
            
            productsResult.fold(
              (failure) {
                // On failure, add empty list for this category
                categoryProducts[category.id] = [];
              },
              (products) {
                // On success, add products to the map
                categoryProducts[category.id] = products;
                
                // Associate products with their category for consistent coloring
                for (final product in products) {
                  product.categoryId = category.id;
                  product.categoryName = category.name;
                }
              },
            );
          }
          
          // If we already have state and a selected category, keep it
          Category? selectedCategory;
          if (state is CategoryProductsLoaded && (state as CategoryProductsLoaded).selectedCategory != null) {
            final currentState = state as CategoryProductsLoaded;
            selectedCategory = currentState.selectedCategory;
          } else {
            // Otherwise set the first category as selected if available
            selectedCategory = categories.isNotEmpty ? categories.first : null;
          }
          
          emit(CategoryProductsLoaded(
            categories: categories,
            categoryProducts: categoryProducts,
            selectedCategory: selectedCategory,
            filteredCategoryProducts: categoryProducts,
          ));
        },
      );
    } catch (e) {
      emit(CategoryProductsError('Failed to load categories and products: $e'));
    }
  }
  
  /// Preload category colors for consistent UI
  void _preloadCategoryColors(List<Category> categories) {
    final categoryIds = categories.map((c) => c.id).toList();
    // Import from core/utils/category_color_mapper.dart
    // This is to ensure consistent coloring across the app
    final colorMapper = CategoryColorMapper();
    colorMapper.preAssignColors(categoryIds);
  }

  /// Handle selecting a specific category
  void _onSelectCategory(
    SelectCategory event,
    Emitter<CategoryProductsState> emit,
  ) {
    if (state is CategoryProductsLoaded) {
      final currentState = state as CategoryProductsLoaded;
      
      try {
        // Find the selected category by ID
        final selectedCategory = currentState.categories
            .firstWhere(
              (category) => category.id == event.categoryId,
              orElse: () => currentState.selectedCategory ?? currentState.categories.first,
            );
        
        // Check if the selected category has changed
        if (currentState.selectedCategory?.id != selectedCategory.id) {
          emit(currentState.copyWith(
            selectedCategory: selectedCategory,
          ));
        }
      } catch (e) {
        // If category not found, keep current state
        // This prevents crashes when selecting non-existent categories
        print('Error selecting category: $e');
      }
    }
  }

  /// Apply filters to products
  void _onFilterProducts(
    FilterProducts event,
    Emitter<CategoryProductsState> emit,
  ) {
    if (state is CategoryProductsLoaded) {
      final currentState = state as CategoryProductsLoaded;
      
      // Create a new map for filtered products
      final Map<String, List<Product>> filteredProducts = {};
      
      // Apply filters to each category's products
      for (final entry in currentState.categoryProducts.entries) {
        final categoryId = entry.key;
        var products = List<Product>.from(entry.value);
        
        // Filter by availability if specified
        if (event.filterInStock == true) {
          products = products.where((p) => p.inStock == true).toList();
        }
        
        // Sort by price if specified
        if (event.priceSort != null) {
          if (event.priceSort == 'high_to_low') {
            products.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
          } else if (event.priceSort == 'low_to_high') {
            products.sort((a, b) => (a.price ?? 0).compareTo(b.price ?? 0));
          }
        }
        
        filteredProducts[categoryId] = products;
      }
      
      emit(currentState.copyWith(
        priceSort: event.priceSort,
        filterInStock: event.filterInStock,
        filteredCategoryProducts: filteredProducts,
      ));
    }
  }

  /// Reset all applied filters
  void _onResetFilters(
    ResetFilters event,
    Emitter<CategoryProductsState> emit,
  ) {
    if (state is CategoryProductsLoaded) {
      final currentState = state as CategoryProductsLoaded;
      
      emit(currentState.copyWith(
        priceSort: null,
        filterInStock: null,
        filteredCategoryProducts: currentState.categoryProducts,
      ));
    }
  }
}
