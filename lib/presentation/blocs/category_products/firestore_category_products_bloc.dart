import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get_it/get_it.dart';
import 'package:profit_grocery_application/services/user_service_interface.dart';
import 'package:profit_grocery_application/utils/cart_logger.dart';
import 'package:profit_grocery_application/services/firestore/firestore_product_service.dart';
import 'package:profit_grocery_application/data/models/firestore/firestore_category_model.dart';

import '../../../domain/entities/category.dart';
import '../../../domain/entities/product.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/product_model.dart';
import '../category_products/category_products_bloc.dart';

class FirestoreCategoryProductsBloc extends Bloc<CategoryProductsEvent, CategoryProductsState> {
  final FirestoreProductService _firestoreService;

  FirestoreCategoryProductsBloc({
    required FirestoreProductService firestoreService,
  }) : _firestoreService = firestoreService,
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
      
      List<CategoryModel> categories = [];
      Map<String, List<ProductModel>> categoryProducts = {};
      Map<String, Color> subcategoryColors = {};
      
      // If categoryId is specified, get items only from that group
      if (event.categoryId != null && event.categoryId == 'bakeries_biscuits') {
        // Get subcategories for bakeries_biscuits
        final firestoreCategories = await _firestoreService.getSubcategories('bakeries_biscuits');
        
        // Convert to standard CategoryModel and collect colors
        categories = _firestoreService.convertToStandardModels(firestoreCategories);
        
        // Store subcategory colors
        for (final category in firestoreCategories) {
          // Use the itemBackgroundColor if available, otherwise use a default color
          subcategoryColors[category.id] = category.itemBackgroundColor ?? const Color(0xFFFFECB3);
        }
        
        // Get products for each subcategory
        categoryProducts = await _firestoreService.getBakeriesBiscuitsSubcategoriesWithProducts();
      } else {
        // If no specific category was requested, load biscuits subcategories by default
        final firestoreCategories = await _firestoreService.getSubcategories('bakeries_biscuits');
        
        // Convert to standard CategoryModel
        categories = _firestoreService.convertToStandardModels(firestoreCategories);
        
        // Store subcategory colors
        for (final category in firestoreCategories) {
          // Use the itemBackgroundColor if available, otherwise use a default color
          subcategoryColors[category.id] = category.itemBackgroundColor ?? const Color(0xFFFFECB3);
        }
        
        // Get products for each subcategory
        categoryProducts = await _firestoreService.getBakeriesBiscuitsSubcategoriesWithProducts();
      }
      
      // Emit the loaded state, ensure at least one category is selected
      emit(CategoryProductsLoaded(
        categories: categories,
        categoryProducts: categoryProducts,
        selectedCategory: categories.isNotEmpty ? categories.first : const CategoryModel(
          id: 'default',
          name: 'Default',
          image: '',
          type: 'subcategory',
        ),
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
      
      // Direct test with Firebase Realtime Database
      try {
        final userId = GetIt.instance<IUserService>().getCurrentUserId();
        if (userId != null) {
          // Create a simple test path specific to this user's cart
          final database = GetIt.instance<FirebaseDatabase>();
          final ref = database.ref().child('carts_test/$userId');
          
          // Create specific message
          String cartMessage = "yoyo product with id ${event.product.id} got added in the cart";
          
          // Write entry with specific message
          ref.set({
            'product_id': event.product.id,
            'product_name': event.product.name,
            'quantity': event.quantity,
            'price': event.product.price,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'message': cartMessage,
            'test_entry': true
          });
          
          // Log the specific message
          CartLogger.success('CATEGORY_BLOC', cartMessage);
          print('CART TEST: $cartMessage');
        }
      } catch (e) {
        CartLogger.error('CATEGORY_BLOC', 'Failed to write test data to Firebase', e);
      }
      
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
    }
  }
}