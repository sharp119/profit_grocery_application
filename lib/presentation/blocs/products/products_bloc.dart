import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'dart:math';

import '../../../services/product/product_service.dart';
import '../../../services/product/shared_product_service.dart';
import '../../../data/repositories/bestseller_repository.dart';
import '../../../services/logging_service.dart';
import 'products_event.dart';
import 'products_state.dart';

class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  final ProductService _productService;
  final SharedProductService _sharedProductService;
  final BestsellerRepository _bestsellerRepository;
  final Random _random = Random();

  ProductsBloc({
    ProductService? productService,
    SharedProductService? sharedProductService,
    BestsellerRepository? bestsellerRepository,
  }) : _productService = productService ?? GetIt.instance<ProductService>(),
       _sharedProductService = sharedProductService ?? GetIt.instance<SharedProductService>(),
       _bestsellerRepository = bestsellerRepository ?? GetIt.instance<BestsellerRepository>(),
       super(const ProductsState()) {
    on<LoadBestsellerProducts>(_onLoadBestsellerProducts);
    on<LoadProductsByCategory>(_onLoadProductsByCategory);
    on<LoadProductsBySubcategory>(_onLoadProductsBySubcategory);
    on<LoadSimilarProducts>(_onLoadSimilarProducts);
    on<LoadProductById>(_onLoadProductById);
    on<RefreshProducts>(_onRefreshProducts);
    on<LoadRandomProducts>(_onLoadRandomProducts);
  }

  Future<void> _onLoadBestsellerProducts(
    LoadBestsellerProducts event,
    Emitter<ProductsState> emit,
  ) async {
    try {
      // Only fetch if we don't already have bestseller products
      if (!state.areBestsellersLoaded) {
        emit(state.copyWith(status: ProductsStatus.loading));
        
        // Use the enhanced bestseller repository with options
        final products = await _bestsellerRepository.getBestsellerProducts(
          limit: event.limit ?? 6,
          ranked: event.ranked ?? true,
        );
        
        emit(state.copyWith(
          status: ProductsStatus.loaded,
          bestsellerProducts: products,
        ));
      }
    } catch (e) {
      LoggingService.logError('ProductsBloc', 'Error loading bestseller products: $e');
      emit(state.copyWith(
        status: ProductsStatus.error,
        errorMessage: 'Failed to load bestseller products: ${e.toString()}',
      ));
    }
  }

  Future<void> _onLoadProductsByCategory(
    LoadProductsByCategory event,
    Emitter<ProductsState> emit,
  ) async {
    try {
      // Only fetch if we don't already have products for this category
      if (!state.isCategoryLoaded(event.categoryId)) {
        emit(state.copyWith(status: ProductsStatus.loading));
        
        final products = await _productService.getProductsByCategory(event.categoryId);
        
        emit(state.copyWith(
          status: ProductsStatus.loaded,
          categoryProducts: products,
          currentCategoryId: event.categoryId,
        ));
      }
    } catch (e) {
      LoggingService.logError('ProductsBloc', 'Error loading category products: $e');
      emit(state.copyWith(
        status: ProductsStatus.error,
        errorMessage: 'Failed to load category products: ${e.toString()}',
      ));
    }
  }

  Future<void> _onLoadProductsBySubcategory(
    LoadProductsBySubcategory event,
    Emitter<ProductsState> emit,
  ) async {
    try {
      // Only fetch if we don't already have products for this subcategory
      if (!state.isSubcategoryLoaded(event.categoryId, event.subcategoryId)) {
        emit(state.copyWith(status: ProductsStatus.loading));
        
        final products = await _productService.getProductsBySubcategory(
          event.categoryId,
          event.subcategoryId,
        );
        
        emit(state.copyWith(
          status: ProductsStatus.loaded,
          subcategoryProducts: products,
          currentCategoryId: event.categoryId,
          currentSubcategoryId: event.subcategoryId,
        ));
      }
    } catch (e) {
      LoggingService.logError('ProductsBloc', 'Error loading subcategory products: $e');
      emit(state.copyWith(
        status: ProductsStatus.error,
        errorMessage: 'Failed to load subcategory products: ${e.toString()}',
      ));
    }
  }

  Future<void> _onLoadSimilarProducts(
    LoadSimilarProducts event,
    Emitter<ProductsState> emit,
  ) async {
    try {
      // Always fetch similar products, as they might be different based on availability
      emit(state.copyWith(status: ProductsStatus.loading));
      
      final products = await _productService.getSimilarProducts(
        event.productId,
        limit: event.limit ?? 3,
      );
      
      emit(state.copyWith(
        status: ProductsStatus.loaded,
        similarProducts: products,
      ));
    } catch (e) {
      LoggingService.logError('ProductsBloc', 'Error loading similar products: $e');
      emit(state.copyWith(
        status: ProductsStatus.error,
        errorMessage: 'Failed to load similar products: ${e.toString()}',
      ));
    }
  }

  Future<void> _onLoadProductById(
    LoadProductById event,
    Emitter<ProductsState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ProductsStatus.loading));
      
      final product = await _productService.getProductById(event.productId);
      
      if (product != null) {
        emit(state.copyWith(
          status: ProductsStatus.loaded,
          selectedProduct: product,
        ));
      } else {
        emit(state.copyWith(
          status: ProductsStatus.error,
          errorMessage: 'Product not found',
        ));
      }
    } catch (e) {
      LoggingService.logError('ProductsBloc', 'Error loading product: $e');
      emit(state.copyWith(
        status: ProductsStatus.error,
        errorMessage: 'Failed to load product: ${e.toString()}',
      ));
    }
  }

  Future<void> _onRefreshProducts(
    RefreshProducts event,
    Emitter<ProductsState> emit,
  ) async {
    emit(state.copyWith(status: ProductsStatus.loading));
    
    try {
      // Reload all currently loaded products
      final bestsellers = await _productService.getBestsellerProducts();
      
      List<Future<dynamic>> futures = [
        // Add other futures based on what's currently loaded
        if (state.currentCategoryId != null)
          _productService.getProductsByCategory(state.currentCategoryId!),
        
        if (state.currentCategoryId != null && state.currentSubcategoryId != null)
          _productService.getProductsBySubcategory(
            state.currentCategoryId!,
            state.currentSubcategoryId!,
          ),
        
        if (state.selectedProduct != null)
          _productService.getProductById(state.selectedProduct!.id),
      ];
      
      final results = await Future.wait(futures);
      
      emit(state.copyWith(
        status: ProductsStatus.loaded,
        bestsellerProducts: bestsellers,
        // Set other products based on results if available
        categoryProducts: results.isNotEmpty && state.currentCategoryId != null ? results[0] : state.categoryProducts,
        subcategoryProducts: results.length > 1 && state.currentSubcategoryId != null ? results[1] : state.subcategoryProducts,
        selectedProduct: results.length > 2 && state.selectedProduct != null ? results[2] : state.selectedProduct,
      ));
    } catch (e) {
      LoggingService.logError('ProductsBloc', 'Error refreshing products: $e');
      emit(state.copyWith(
        status: ProductsStatus.error,
        errorMessage: 'Failed to refresh products: ${e.toString()}',
      ));
    }
  }

  Future<void> _onLoadRandomProducts(
    LoadRandomProducts event,
    Emitter<ProductsState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ProductsStatus.loading));
      
      // Fetch all products (or we could fetch just popular categories to make it faster)
      final allProducts = await _productService.getAllProducts();
      
      // Randomize products
      if (allProducts.isNotEmpty) {
        allProducts.shuffle(_random);
        
        // Take the required number of products
        final randomProducts = allProducts.take(event.limit).toList();
        
        emit(state.copyWith(
          status: ProductsStatus.loaded,
          randomProducts: randomProducts,
        ));
      } else {
        // If no products are available, try to get bestsellers as a fallback
        final bestsellers = await _bestsellerRepository.getBestsellerProducts(
          limit: event.limit,
          ranked: false, // Get random bestsellers
        );
        
        emit(state.copyWith(
          status: ProductsStatus.loaded,
          randomProducts: bestsellers,
        ));
      }
    } catch (e) {
      LoggingService.logError('ProductsBloc', 'Error loading random products: $e');
      emit(state.copyWith(
        status: ProductsStatus.error,
        errorMessage: 'Failed to load random products: ${e.toString()}',
      ));
    }
  }
}