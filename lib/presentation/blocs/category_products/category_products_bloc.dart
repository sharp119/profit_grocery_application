import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/entities/category.dart';
import '../../../domain/entities/product.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/product/firestore_product_repository.dart';
import '../../../services/user_service_interface.dart';
import '../../../services/logging_service.dart';
import '../../../services/category/shared_category_service.dart';
import '../../../utils/cart_logger.dart';

part 'category_products_event.dart';
part 'category_products_state.dart';

class CategoryProductsBloc extends Bloc<CategoryProductsEvent, CategoryProductsState> {
  final CategoryRepository _categoryRepository;
  final FirestoreProductRepository _productRepository;
  final SharedCategoryService _categoryService;

  CategoryProductsBloc({
    CategoryRepository? categoryRepository,
    FirestoreProductRepository? productRepository,
    SharedCategoryService? categoryService,
  }) : _categoryRepository = categoryRepository ?? CategoryRepository(),
       _productRepository = productRepository ?? FirestoreProductRepository(),
       _categoryService = categoryService ?? GetIt.instance<SharedCategoryService>(),
       super(CategoryProductsInitial()) {
    on<LoadCategoryProducts>(_onLoadCategoryProducts);
    on<SelectCategory>(_onSelectCategory);
    on<UpdateCartQuantity>(_onUpdateCartQuantity);
  }

  Future<void> _onLoadCategoryProducts(
    LoadCategoryProducts event,
    Emitter<CategoryProductsState> emit,
  ) async {
    try {
      emit(CategoryProductsLoading());
      
      LoggingService.logFirestore('CATEGORY_BLOC: Loading category products for ${event.categoryId ?? "all categories"}');
      print('CATEGORY_BLOC: Loading category products for ${event.categoryId ?? "all categories"}');
      
      // Get all category items using the CategoryRepository
      List<Category> categories;
      Map<String, Color> subcategoryColors = {};
      
      // If categoryId is specified, load just that category group
      if (event.categoryId != null) {
        final categoryGroups = await _categoryRepository.fetchCategories();
        
        // Find the specific group
        final group = categoryGroups.firstWhere(
          (group) => group.id == event.categoryId,
          orElse: () => categoryGroups.first,
        );
        
        // Convert category items to Category entities
        categories = group.items.map((item) => Category(
          id: item.id,
          name: item.label,
          image: item.imagePath, 
          type: 'subcategory',
        )).toList();
        
        // Get colors for subcategories
        for (final item in group.items) {
          subcategoryColors[item.id] = group.itemBackgroundColor;
        }
      } else {
        // If no categoryId specified, get all categories
        final categoryGroups = await _categoryRepository.fetchCategories();
        List<Category> allCategories = [];
        
        for (final group in categoryGroups) {
          final groupCategories = group.items.map((item) => Category(
            id: item.id,
            name: item.label,
            image: item.imagePath, 
            type: 'subcategory',
          )).toList();
          
          allCategories.addAll(groupCategories);
          
          // Store colors for all subcategories
          for (final item in group.items) {
            subcategoryColors[item.id] = group.itemBackgroundColor;
          }
        }
        
        categories = allCategories;
      }
      
      // If no categories were found, show error
      if (categories.isEmpty) {
        emit(CategoryProductsError('No categories found'));
        return;
      }
      
      LoggingService.logFirestore('CATEGORY_BLOC: Found ${categories.length} categories');
      print('CATEGORY_BLOC: Found ${categories.length} categories');
      
      // Load products for the first category
      final firstCategory = categories.first;
      LoggingService.logFirestore('CATEGORY_BLOC: Loading products for first category: ${firstCategory.id}');
      print('CATEGORY_BLOC: Loading products for first category: ${firstCategory.id}');
      
      // Get category group ID for the first category
      final categoryGroup = await _getCategoryGroupForItem(firstCategory.id);
      
      if (categoryGroup == null) {
        LoggingService.logError('CATEGORY_BLOC', 'Could not determine category group for: ${firstCategory.id}');
        print('CATEGORY_BLOC ERROR: Could not determine category group for: ${firstCategory.id}');
        
        // Emit with empty products but valid categories
        emit(CategoryProductsLoaded(
          categories: categories,
          categoryProducts: {},
          selectedCategory: firstCategory,
          cartQuantities: const {},
          subcategoryColors: subcategoryColors,
        ));
        return;
      }
      
      // Load products for the first category
      final productModels = await _productRepository.fetchProductsByCategory(
        categoryGroup: categoryGroup,
        categoryItem: firstCategory.id,
      );
      
      // Convert ProductModel to Product entities
      final products = productModels.map((model) => Product(
        id: model.id,
        name: model.name,
        description: model.description ?? '',
        price: model.price,
        mrp: model.mrp,
        image: model.image,
        inStock: model.inStock,
        categoryId: firstCategory.id,
        categoryName: model.categoryName,
        subcategoryId: model.subcategoryId,
        weight: model.weight,
        brand: model.brand,
        isActive: true,
        isFeatured: false,
        tags: [],
      )).toList();
      
      LoggingService.logFirestore('CATEGORY_BLOC: Loaded ${products.length} products for category: ${firstCategory.id}');
      print('CATEGORY_BLOC: Loaded ${products.length} products for category: ${firstCategory.id}');
      
      // Create a map with only the first category's products
      final Map<String, List<Product>> categoryProducts = {
        firstCategory.id: products,
      };
      
      // Emit loaded state with first category's products
      emit(CategoryProductsLoaded(
        categories: categories,
        categoryProducts: categoryProducts,
        selectedCategory: firstCategory,
        cartQuantities: const {},
        subcategoryColors: subcategoryColors,
      ));
    } catch (error) {
      LoggingService.logError('CATEGORY_BLOC', 'Failed to load categories and products: $error');
      print('CATEGORY_BLOC ERROR: Failed to load categories and products: $error');
      emit(CategoryProductsError('Failed to load categories and products: $error'));
    }
  }

  Future<String?> _getCategoryGroupForItem(String categoryItemId) async {
    try {
      // Try to get from shared service first
      final groupInfo = await _categoryService.findCategoryGroupForItem(categoryItemId);
      return groupInfo?.id;
    } catch (e) {
      print('CATEGORY_BLOC: Error finding category group for $categoryItemId: $e');
      return null;
    }
  }

  void _onSelectCategory(
    SelectCategory event,
    Emitter<CategoryProductsState> emit,
  ) async {
    if (state is CategoryProductsLoaded) {
      final currentState = state as CategoryProductsLoaded;
      
      // First just update the selected category
      emit(currentState.copyWith(selectedCategory: event.category));
      
      // Check if we already have products for this category
      if (currentState.categoryProducts.containsKey(event.category.id) && 
          currentState.categoryProducts[event.category.id]!.isNotEmpty) {
        // We already have products, no need to load again
        return;
      }
      
      try {
        // Get the category group ID for this category
        final categoryGroup = await _getCategoryGroupForItem(event.category.id);
        
        if (categoryGroup == null) {
          LoggingService.logError('CATEGORY_BLOC', 'Could not determine category group for: ${event.category.id}');
          print('CATEGORY_BLOC ERROR: Could not determine category group for: ${event.category.id}');
          return;
        }
        
        // Load products for this category
        final productModels = await _productRepository.fetchProductsByCategory(
          categoryGroup: categoryGroup,
          categoryItem: event.category.id,
        );
        
        // Convert to Product entities
        final products = productModels.map((model) => Product(
          id: model.id,
          name: model.name,
          description: model.description ?? '',
          price: model.price,
          mrp: model.mrp,
          image: model.image,
          inStock: model.inStock,
          categoryId: event.category.id,
          categoryName: model.categoryName,
          subcategoryId: model.subcategoryId,
          weight: model.weight,
          brand: model.brand,
          isActive: true,
          isFeatured: false,
          tags: [],
        )).toList();
        
        LoggingService.logFirestore('CATEGORY_BLOC: Loaded ${products.length} products for selected category: ${event.category.id}');
        print('CATEGORY_BLOC: Loaded ${products.length} products for selected category: ${event.category.id}');
        
        // Create updated map with new products
        final Map<String, List<Product>> updatedCategoryProducts = Map.from(currentState.categoryProducts);
        updatedCategoryProducts[event.category.id] = products;
        
        // Emit updated state with new products
        emit(currentState.copyWith(
          categoryProducts: updatedCategoryProducts,
        ));
      } catch (e) {
        LoggingService.logError('CATEGORY_BLOC', 'Error loading products for category ${event.category.id}: $e');
        print('CATEGORY_BLOC ERROR: Error loading products for category ${event.category.id}: $e');
      }
    }
  }

  void _onUpdateCartQuantity(
    UpdateCartQuantity event,
    Emitter<CategoryProductsState> emit,
  ) {
    if (state is CategoryProductsLoaded) {
      final currentState = state as CategoryProductsLoaded;
      
      // Make a copy of the current cart quantities
      final Map<String, int> updatedQuantities = Map.from(currentState.cartQuantities);
      
      // Update the quantity for the specific product
      if (event.quantity <= 0) {
        updatedQuantities.remove(event.product.id);
        emit(currentState.copyWith(
          cartQuantities: updatedQuantities,
          lastAddedProduct: null
        ));
      } else {
        updatedQuantities[event.product.id] = event.quantity;
        emit(currentState.copyWith(
          cartQuantities: updatedQuantities,
          lastAddedProduct: event.product
        ));
      }
      
      // Log the update
      CartLogger.success('CATEGORY_BLOC', 'Updated cart quantity for ${event.product.name}: ${event.quantity}');
    }
  }
}