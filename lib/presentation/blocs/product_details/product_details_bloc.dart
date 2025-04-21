import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:profit_grocery_application/domain/entities/cart.dart';
import 'package:profit_grocery_application/domain/repositories/product_repository.dart';
import 'package:profit_grocery_application/services/product/shared_product_service.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/color_mapper.dart';
import '../../../domain/entities/product.dart';
import '../../../services/logging_service.dart';
import 'product_details_event.dart';
import 'product_details_state.dart';

class ProductDetailsBloc extends Bloc<ProductDetailsEvent, ProductDetailsState> {
  final SharedProductService _productService;
  final ProductRepository _productRepository;

  ProductDetailsBloc({
    SharedProductService? productService,
    ProductRepository? productRepository,
  }) : 
    _productService = productService ?? GetIt.instance<SharedProductService>(),
    _productRepository = productRepository ?? GetIt.instance<ProductRepository>(),
    super(const ProductDetailsState()) {
    on<LoadProductDetails>(_onLoadProductDetails);
    on<AddToCart>(_onAddToCart);
    on<RemoveFromCart>(_onRemoveFromCart);
  }

  Future<void> _onLoadProductDetails(
    LoadProductDetails event,
    Emitter<ProductDetailsState> emit,
  ) async {
    try {
      emit(state.copyWith(status: ProductDetailsStatus.loading));

      // Fetch product from repository
      final product = await _productRepository.getProductById(event.productId);
      
      if (product == null) {
        emit(state.copyWith(
          status: ProductDetailsStatus.error,
          errorMessage: 'Product not found',
        ));
        return;
      }
      
      // Generate category background color
      final Color backgroundColor = ColorMapper.getColorForCategory(
        product.categoryGroup ?? product.categoryId
      );
      
      // Generate subcategory colors map
      final Map<String, Color> subcategoryColors = {
        product.categoryId: backgroundColor,
      };
      
      emit(state.copyWith(
        status: ProductDetailsStatus.loaded,
        product: product,
        subcategoryColors: subcategoryColors,
      ));
    } catch (e) {
      LoggingService.logError('ProductDetailsBloc', 'Error loading product details: $e');
      emit(state.copyWith(
        status: ProductDetailsStatus.error,
        errorMessage: 'Failed to load product details',
      ));
    }
  }

  void _onAddToCart(
    AddToCart event,
    Emitter<ProductDetailsState> emit,
  ) {
    // This is now handled by the CartBloc directly
  }

  void _onRemoveFromCart(
    RemoveFromCart event,
    Emitter<ProductDetailsState> emit,
  ) {
    // This is now handled by the CartBloc directly
  }
}