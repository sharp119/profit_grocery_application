import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';

import '../../../core/utils/category_assets.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/category_group_model.dart';
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
      
      // Use the CategoryGroups for better subcategory organization
      // For demo purposes, use the predefined category groups
      final List<CategoryGroup> categoryGroups = CategoryGroups.all;
      
      // Get the selected category group based on the categoryId
      CategoryGroup selectedGroup;
      if (event.categoryId != null) {
        // Try to find a direct match first
        try {
          selectedGroup = categoryGroups.firstWhere(
            (group) => group.id == event.categoryId,
          );
        } catch (e) {
          // Try to find a matching group by partial ID match
          final matchingGroups = categoryGroups.where(
            (group) => group.id.startsWith(event.categoryId!) ||
                      event.categoryId!.startsWith(group.id)
          ).toList();
          
          selectedGroup = matchingGroups.isNotEmpty ? matchingGroups.first : categoryGroups.first;
        }
      } else {
        selectedGroup = categoryGroups.first;
      }
      
      // Create subcategory models from ALL the CategoryItems in the selected group
      // Make sure to use all 8 subcategories
      final List<CategoryModel> subcategories = selectedGroup.items.map((item) {
        return CategoryModel(
          id: item.id,
          name: item.label,
          image: item.imagePath,
          type: 'subcategory',
        );
      }).toList();
      
      // Create product mapping for each subcategory
      final Map<String, List<ProductModel>> subcategoryProducts = {};
      final Map<String, Color> subcategoryColors = {};
      
      // Generate 8-15 products for each subcategory with sequential naming
      for (final subcategory in subcategories) {
        // Generate a random number of products between 8 and 15
        final productCount = 8 + (subcategory.id.hashCode % 8); // Between 8 and 15
        
        subcategoryProducts[subcategory.id] = _generateSequentialProducts(
          subcategory, 
          productCount,
          selectedGroup.itemBackgroundColor
        );
        
        // Set the subcategory color from the CategoryGroup
        subcategoryColors[subcategory.id] = selectedGroup.itemBackgroundColor;
      }
      
      emit(CategoryProductsLoaded(
        categories: subcategories,
        categoryProducts: subcategoryProducts,
        selectedCategory: subcategories.first,
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

  // Generate sequentially named products for a given subcategory
  List<ProductModel> _generateSequentialProducts(Category subcategory, int count, Color backgroundColor) {
    return List.generate(count, (index) {
      final bool isDiscounted = index % 3 == 0;
      final double originalPrice = 50.0 + (index * 10);
      final double discountPercentage = isDiscounted ? (10 + (index % 3) * 5) : 0;
      final double discountedPrice = isDiscounted
          ? originalPrice * (1 - discountPercentage / 100)
          : originalPrice;
      
      // Create product ID with subcategory ID prefix for easy color mapping
      final productId = '${subcategory.id}_product_${index + 1}';
      
      return ProductModel(
        id: productId,
        name: '${subcategory.name} Product ${index + 1}', // Include subcategory name for clearer mapping
        description: 'This is product ${index + 1} in the ${subcategory.name} subcategory',
        price: discountedPrice.roundToDouble(),
        mrp: isDiscounted ? originalPrice.roundToDouble() : null,
        categoryId: subcategory.id,  // Important: Use subcategory ID for color mapping
        subcategoryId: subcategory.id,
        image: CategoryAssets.getRandomProductImage(),
        inStock: index % 5 != 0, // 80% of products are in stock
        tags: [subcategory.id], // Add subcategory ID as a tag for easier filtering
      );
    });
  }
}