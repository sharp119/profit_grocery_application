import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';

import '../../../core/utils/category_assets.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/product_model.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/product.dart';

part 'category_products_event.dart';
part 'category_products_state.dart';

class CategoryProductsBloc extends Bloc<CategoryProductsEvent, CategoryProductsState> {
  CategoryProductsBloc() : super(CategoryProductsInitial()) {
    on<LoadCategoryProducts>(_onLoadCategoryProducts);
    on<SelectCategory>(_onSelectCategory);
    on<UpdateCartQuantity>(_onUpdateCartQuantity);
  }

  // Simulates loading categories and products from a repository
  Future<void> _onLoadCategoryProducts(
    LoadCategoryProducts event,
    Emitter<CategoryProductsState> emit,
  ) async {
    try {
      emit(CategoryProductsLoading());
      
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 800));
      
      // For demo purposes, generate mock data
      final List<CategoryModel> allCategories = _generateMockCategories();
      final List<CategoryModel> categories = event.categoryId != null
          ? allCategories.where((c) => c.id == event.categoryId).toList()
          : allCategories;
      
      // Handle case where no categories match the filter
      if (categories.isEmpty && event.categoryId != null) {
        categories.addAll(allCategories);
      }
      
      final Map<String, List<ProductModel>> categoryProducts = {};
      
      // Generate products for each category
      for (final category in categories) {
        categoryProducts[category.id] = _generateMockCategoryProducts(category);
      }
      
      // If a specific category ID is provided, select it
      CategoryModel selectedCategory;
      if (event.categoryId != null && categories.isNotEmpty) {
        try {
          selectedCategory = categories.firstWhere(
            (c) => c.id == event.categoryId,
            orElse: () => categories.first,
          );
        } catch (e) {
          // Fallback if categories is empty or firstWhere fails
          selectedCategory = categories.isNotEmpty ? categories.first : _generateMockCategories().first;
        }
      } else {
        selectedCategory = categories.isNotEmpty ? categories.first : _generateMockCategories().first;
      }
      
      // Generate subcategory colors
      final Map<String, Color> subcategoryColors = _generateSubcategoryColors();
      
      emit(CategoryProductsLoaded(
        categories: categories,
        categoryProducts: categoryProducts,
        selectedCategory: selectedCategory,
        cartQuantities: const {},
        subcategoryColors: subcategoryColors,
      ));
    } catch (error) {
      emit(CategoryProductsError('Failed to load categories and products: $error'));
    }
  }

  void _onSelectCategory(
    SelectCategory event,
    Emitter<CategoryProductsState> emit,
  ) {
    if (state is CategoryProductsLoaded) {
      final currentState = state as CategoryProductsLoaded;
      emit(currentState.copyWith(selectedCategory: event.category));
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
      } else {
        updatedQuantities[event.product.id] = event.quantity;
      }
      
      emit(currentState.copyWith(cartQuantities: updatedQuantities));
    }
  }

  // Generate mock categories for demo purposes
  List<CategoryModel> _generateMockCategories() {
    return [
      CategoryModel(
        id: 'vegetables',
        name: 'Vegetables & Fruits',
        image: 'assets/images/categories/vegetables.png',
        type: 'regular',
      ),
      CategoryModel(
        id: 'dairy',
        name: 'Dairy & Breakfast',
        image: 'assets/images/categories/dairy.png',
        type: 'regular',
      ),
      CategoryModel(
        id: 'snacks',
        name: 'Chips & Namkeen',
        image: 'assets/images/categories/snacks.png',
        type: 'regular',
      ),
      CategoryModel(
        id: 'beverages',
        name: 'Cold Drinks & Juices',
        image: 'assets/images/categories/beverages.png',
        type: 'regular',
      ),
      CategoryModel(
        id: 'grocery',
        name: 'Atta, Rice & Dal',
        image: 'assets/images/categories/grocery.png',
        type: 'regular',
      ),
      CategoryModel(
        id: 'household',
        name: 'Cleaning & Household',
        image: 'assets/images/categories/household.png',
        type: 'regular',
      ),
      CategoryModel(
        id: 'personal_care',
        name: 'Personal Care',
        image: 'assets/images/categories/personal_care.png',
        type: 'regular',
      ),
      CategoryModel(
        id: 'baby_care',
        name: 'Baby Care',
        image: 'assets/images/categories/baby_care.png',
        type: 'regular',
      ),
    ];
  }

  // Generate subcategory colors for products
  Map<String, Color> _generateSubcategoryColors() {
    final Map<String, Color> colors = {};
    
    // Colors for standard category IDs
    colors['vegetables'] = const Color(0xFF1A5D1A); // Dark green for vegetables
    colors['dairy'] = const Color(0xFFE5BEEC);      // Light lavender for dairy
    colors['snacks'] = const Color(0xFFECB159);     // Yellow/orange for chips
    colors['beverages'] = const Color(0xFF219C90);  // Teal for drinks
    colors['grocery'] = const Color(0xFFD5A021);    // Gold/yellow for grains
    colors['household'] = const Color(0xFF3F4E4F);  // Dark slate for household
    colors['personal_care'] = const Color(0xFF9E4784); // Purple for personal care
    colors['baby_care'] = const Color(0xFF8ECDDD);  // Light blue for baby care
    
    // Add mappings for dynamic category product IDs that will be generated
    // Each mock product gets the color of its parent category
    colors['vegetables_prod_0'] = colors['vegetables']!;
    colors['vegetables_prod_1'] = colors['vegetables']!;
    colors['vegetables_prod_2'] = colors['vegetables']!;
    colors['vegetables_prod_3'] = colors['vegetables']!;
    colors['vegetables_prod_4'] = colors['vegetables']!;
    colors['vegetables_prod_5'] = colors['vegetables']!;
    colors['vegetables_prod_6'] = colors['vegetables']!;
    colors['vegetables_prod_7'] = colors['vegetables']!;
    
    colors['dairy_prod_0'] = colors['dairy']!;
    colors['dairy_prod_1'] = colors['dairy']!;
    colors['dairy_prod_2'] = colors['dairy']!;
    colors['dairy_prod_3'] = colors['dairy']!;
    colors['dairy_prod_4'] = colors['dairy']!;
    colors['dairy_prod_5'] = colors['dairy']!;
    colors['dairy_prod_6'] = colors['dairy']!;
    colors['dairy_prod_7'] = colors['dairy']!;
    
    colors['snacks_prod_0'] = colors['snacks']!;
    colors['snacks_prod_1'] = colors['snacks']!;
    colors['snacks_prod_2'] = colors['snacks']!;
    colors['snacks_prod_3'] = colors['snacks']!;
    colors['snacks_prod_4'] = colors['snacks']!;
    colors['snacks_prod_5'] = colors['snacks']!;
    colors['snacks_prod_6'] = colors['snacks']!;
    colors['snacks_prod_7'] = colors['snacks']!;
    
    colors['beverages_prod_0'] = colors['beverages']!;
    colors['beverages_prod_1'] = colors['beverages']!;
    colors['beverages_prod_2'] = colors['beverages']!;
    colors['beverages_prod_3'] = colors['beverages']!;
    colors['beverages_prod_4'] = colors['beverages']!;
    colors['beverages_prod_5'] = colors['beverages']!;
    colors['beverages_prod_6'] = colors['beverages']!;
    colors['beverages_prod_7'] = colors['beverages']!;
    
    colors['grocery_prod_0'] = colors['grocery']!;
    colors['grocery_prod_1'] = colors['grocery']!;
    colors['grocery_prod_2'] = colors['grocery']!;
    colors['grocery_prod_3'] = colors['grocery']!;
    colors['grocery_prod_4'] = colors['grocery']!;
    colors['grocery_prod_5'] = colors['grocery']!;
    colors['grocery_prod_6'] = colors['grocery']!;
    colors['grocery_prod_7'] = colors['grocery']!;
    
    colors['household_prod_0'] = colors['household']!;
    colors['household_prod_1'] = colors['household']!;
    colors['household_prod_2'] = colors['household']!;
    colors['household_prod_3'] = colors['household']!;
    colors['household_prod_4'] = colors['household']!;
    colors['household_prod_5'] = colors['household']!;
    colors['household_prod_6'] = colors['household']!;
    colors['household_prod_7'] = colors['household']!;
    
    colors['personal_care_prod_0'] = colors['personal_care']!;
    colors['personal_care_prod_1'] = colors['personal_care']!;
    colors['personal_care_prod_2'] = colors['personal_care']!;
    colors['personal_care_prod_3'] = colors['personal_care']!;
    colors['personal_care_prod_4'] = colors['personal_care']!;
    colors['personal_care_prod_5'] = colors['personal_care']!;
    colors['personal_care_prod_6'] = colors['personal_care']!;
    colors['personal_care_prod_7'] = colors['personal_care']!;
    
    colors['baby_care_prod_0'] = colors['baby_care']!;
    colors['baby_care_prod_1'] = colors['baby_care']!;
    colors['baby_care_prod_2'] = colors['baby_care']!;
    colors['baby_care_prod_3'] = colors['baby_care']!;
    colors['baby_care_prod_4'] = colors['baby_care']!;
    colors['baby_care_prod_5'] = colors['baby_care']!;
    colors['baby_care_prod_6'] = colors['baby_care']!;
    colors['baby_care_prod_7'] = colors['baby_care']!;
    
    return colors;
  }
  
  // Generate mock products for a given category
  List<ProductModel> _generateMockCategoryProducts(Category category) {
    // Reduce the number of products to 8 per category maximum
    final productCount = 8;
    
    return List.generate(productCount, (index) {
      final bool isDiscounted = index % 3 == 0;
      final double originalPrice = 50.0 + (index * 10) + (category.id.hashCode % 10);
      final double discountPercentage = isDiscounted ? (10 + (index % 3) * 5) : 0;
      final double discountedPrice = isDiscounted
          ? originalPrice * (1 - discountPercentage / 100)
          : originalPrice;
      
      return ProductModel(
        id: '${category.id}_prod_$index',
        name: '${category.name} Item ${index + 1}',
        description: 'This is a sample product in the ${category.name} category',
        price: discountedPrice, // Use the calculated discounted price as the actual price
        mrp: isDiscounted ? originalPrice : null, // Set the mrp only if there's a discount
        categoryId: category.id,
        image: CategoryAssets.getRandomProductImage(),
        inStock: index % 5 != 0, // 80% of products are in stock
      );
    });
  }
}
