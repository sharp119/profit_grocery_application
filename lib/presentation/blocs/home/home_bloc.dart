import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:profit_grocery_application/data/models/product_model.dart';
import 'package:profit_grocery_application/utils/cart_logger.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../data/inventory/bestseller_products.dart';
import '../../../data/inventory/product_inventory.dart';
import '../../../data/inventory/similar_products.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/product.dart';
import 'home_event.dart';
import 'home_state.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/storage_repository.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final CategoryRepository _categoryRepository;
  final StorageRepository _storageRepository;

  HomeBloc({
    CategoryRepository? categoryRepository,
    StorageRepository? storageRepository,
  }) 
      : _categoryRepository = categoryRepository ?? CategoryRepository(),
        _storageRepository = storageRepository ?? StorageRepository(),
        super(const HomeState()) {
    on<LoadHomeData>(_onLoadHomeData);
    on<RefreshHomeData>(_onRefreshHomeData);
    on<SelectCategoryTab>(_onSelectCategoryTab);
    on<UpdateCartQuantity>(_onUpdateCartQuantity);
    on<UpdateHomeCartData>(_onUpdateHomeCartData);
  }

  Future<void> _onLoadHomeData(
    LoadHomeData event,
    Emitter<HomeState> emit,
  ) async {
    try {
      emit(state.copyWith(status: HomeStatus.loading));
      
      // Get category groups for 4x2 grid widget
      final categoryGroups = await _categoryRepository.fetchCategories();
      
      // Use category groups for tabs instead of hardcoded values
      final tabs = categoryGroups.map((group) => group.title).toList();
      final banners = await _storageRepository.listImageUrls('promotional_banners');
      
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      emit(state.copyWith(
        status: HomeStatus.loaded,
        tabs: tabs,
        banners: banners,
        categoryGroups: categoryGroups,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: HomeStatus.error,
        errorMessage: 'Failed to load home data: $e',
      ));
    }
  }

  Future<void> _onRefreshHomeData(
    RefreshHomeData event,
    Emitter<HomeState> emit,
  ) async {
    try {
      // Load categories from Firestore
      final categoryGroups = await _categoryRepository.fetchCategories();

      emit(state.copyWith(
        status: HomeStatus.loaded,
        categoryGroups: categoryGroups,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: HomeStatus.error,
        errorMessage: 'Failed to refresh home data: $e',
      ));
    }
  }

  void _onSelectCategoryTab(
    SelectCategoryTab event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(selectedTabIndex: event.tabIndex));
  }
  
  void _onUpdateCartQuantity(
    UpdateCartQuantity event,
    Emitter<HomeState> emit,
  ) {
    final product = event.product;
    final quantity = event.quantity;
    
    CartLogger.log('HOME_BLOC', 'Updating cart quantity for product: ${product.name} (${product.id}), new quantity: $quantity');
    
    // Update cart quantities
    final updatedCartQuantities = Map<String, int>.from(state.cartQuantities);
    
    if (quantity <= 0) {
      CartLogger.info('HOME_BLOC', 'Removing product from cart: ${product.id}');
      updatedCartQuantities.remove(product.id);
    } else {
      CartLogger.info('HOME_BLOC', 'Setting product quantity in cart: ${product.id} = $quantity');
      updatedCartQuantities[product.id] = quantity;
    }
    
    // Calculate new cart total and count
    final cartItemCount = updatedCartQuantities.values.fold<int>(0, (sum, qty) => sum + qty);
    final cartTotalAmount = _calculateCartTotal(updatedCartQuantities);
    
    CartLogger.info('HOME_BLOC', 'Updated cart summary - items: $cartItemCount, total: $cartTotalAmount');
    CartLogger.info('HOME_BLOC', 'Cart quantities: $updatedCartQuantities');
    
    // Choose the first product in cart for preview, or null if cart empty
    // String? cartPreviewImage;
    // if (updatedCartQuantities.isNotEmpty) {
    //   final previewProductId = updatedCartQuantities.keys.first;
    //   // In a real app, we'd look up the product image from repository
    //   cartPreviewImage = '${AppConstants.assetsProductsPath}1.png';
    //   CartLogger.info('HOME_BLOC', 'Cart preview image set to: $cartPreviewImage');
    // } else {
    //   CartLogger.info('HOME_BLOC', 'No cart preview image (cart is empty)');
    // }
    
    emit(state.copyWith(
      cartQuantities: updatedCartQuantities,
      cartItemCount: cartItemCount,
      cartTotalAmount: cartTotalAmount,
      // cartPreviewImage: null,
    ));
    
    CartLogger.success('HOME_BLOC', 'Cart state updated successfully');
  }
  
  void _onUpdateHomeCartData(
    UpdateHomeCartData event,
    Emitter<HomeState> emit,
  ) {
    CartLogger.log('HOME_BLOC', 'Updating cart data from CartBloc sync');
    CartLogger.info('HOME_BLOC', 'Cart data: items: ${event.cartItemCount}, total: ${event.cartTotalAmount}');
    CartLogger.info('HOME_BLOC', 'Cart quantities: ${event.cartQuantities}');
    
    emit(state.copyWith(
      cartQuantities: event.cartQuantities,
      cartItemCount: event.cartItemCount,
      cartTotalAmount: event.cartTotalAmount,
      // cartPreviewImage: event.cartPreviewImage,
    ));
    
    CartLogger.success('HOME_BLOC', 'Cart data updated from CartBloc sync');
  }
  
  // Calculate total cart value
  double _calculateCartTotal(Map<String, int> cartQuantities) {
    double total = 0.0;
    
    // In a real app, we'd use a repository to get product prices
    // For demo, use mock price of ₹100 per item
    cartQuantities.forEach((productId, quantity) {
      total += 100.0 * quantity;
    });
    
    return total;
  }

  // Mock data methods
  List<String> _getMockBanners() {
    return [
      // Removed static banner paths, now fetched from Firebase Storage
    ];
  }
}