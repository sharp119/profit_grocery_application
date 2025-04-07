import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';

import '../../../data/inventory/product_mapping.dart';
import '../../../data/models/category_model.dart';
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

  Future<void> _onLoadCategoryProducts(
    LoadCategoryProducts event,
    Emitter<CategoryProductsState> emit,
  ) async {
    try {
      emit(CategoryProductsLoading());
      
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Initialize product mapping if needed
      ProductMapping.initialize();
      
      // Get all category items in their original order
      List<CategoryItem> allCategoryItems = [];
      
      // If categoryId is specified, get items only from that group
      if (event.categoryId != null) {
        // Find the specific group
        try {
          final group = CategoryGroups.all.firstWhere(
            (group) => group.id == event.categoryId,
          );
          allCategoryItems = group.items;
        } catch (_) {
          // If group not found, get all items
          allCategoryItems = ProductMapping.getAllCategoryItems();
        }
      } else {
        // Get all items from all groups in their original order
        allCategoryItems = ProductMapping.getAllCategoryItems();
      }
      
      // Convert CategoryItems to CategoryModel for the UI
      final List<CategoryModel> categories = allCategoryItems.map((item) => 
        CategoryModel(
          id: item.id,
          name: item.label,
          image: item.imagePath,
          type: 'subcategory',
        )
      ).toList();
      
      // Get product mapping for all categories
      final Map<String, List<Product>> categoryProducts = {};
      final Map<String, Color> subcategoryColors = {};
      
      for (final category in categories) {
        // Get products for this category
        categoryProducts[category.id] = ProductMapping.getProducts(category.id);
        
        // Get color for this category
        subcategoryColors[category.id] = ProductMapping.getColorForSubcategory(category.id) ?? Colors.transparent;
      }
      
      // Emit the loaded state
      emit(CategoryProductsLoaded(
        categories: categories,
        categoryProducts: categoryProducts,
        selectedCategory: categories.first,
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
}