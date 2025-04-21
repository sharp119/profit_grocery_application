import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';

import '../../../domain/entities/product.dart';
import '../../../data/repositories/bestseller_repository_simple.dart';
import '../../../services/logging_service.dart';
import '../../../services/product/shared_product_service.dart';
import '../../../services/category/shared_category_service.dart';
import '../cards/simple_product_card.dart';
import '../../../core/constants/app_theme.dart';

/// A simplified grid that displays bestseller products
/// Gets product IDs first, then loads each product from cache or Firestore
class SimpleBestsellerGrid extends StatefulWidget {
  final Function(Product)? onProductTap;
  final Function(Product, int)? onQuantityChanged;
  final Map<String, int>? cartQuantities;
  final int limit;
  final bool ranked;
  final int crossAxisCount;

  const SimpleBestsellerGrid({
    Key? key,
    this.onProductTap,
    this.onQuantityChanged,
    this.cartQuantities,
    this.limit = 12,
    this.ranked = false,
    this.crossAxisCount = 2,
  }) : super(key: key);

  @override
  State<SimpleBestsellerGrid> createState() => _SimpleBestsellerGridState();
}

class _SimpleBestsellerGridState extends State<SimpleBestsellerGrid> {
  final BestsellerRepositorySimple _bestsellerRepository = BestsellerRepositorySimple();
  final SharedProductService _productService = GetIt.instance<SharedProductService>();
  final SharedCategoryService _categoryService = GetIt.instance<SharedCategoryService>();
  
  List<String> _productIds = [];
  Map<String, Product> _products = {};
  Map<String, Color> _productColors = {};
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadBestsellerProducts();
  }

  Future<void> _loadBestsellerProducts() async {
    try {
      LoggingService.logFirestore('BESTSELLER_SIMPLE_GRID: Starting to load bestseller products');
      print('BESTSELLER_SIMPLE_GRID: Starting to load bestseller products');
      
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Step 1: Get bestseller product IDs
      final productIds = await _bestsellerRepository.getBestsellerProductIds(
        limit: widget.limit,
        ranked: widget.ranked,
      );
      
      LoggingService.logFirestore('BESTSELLER_SIMPLE_GRID: Retrieved ${productIds.length} bestseller product IDs');
      print('BESTSELLER_SIMPLE_GRID: Retrieved ${productIds.length} bestseller product IDs');
      
      // Clear existing data
      _products.clear();
      _productColors.clear();
      
      // Step 2: Load product details and category colors for each ID
      for (final productId in productIds) {
        await _loadProductDetails(productId);
      }
      
      setState(() {
        _productIds = productIds;
        _isLoading = false;
      });

      LoggingService.logFirestore('BESTSELLER_SIMPLE_GRID: Successfully loaded ${_products.length} bestseller products');
      print('BESTSELLER_SIMPLE_GRID: Successfully loaded ${_products.length} bestseller products');
    } catch (e) {
      LoggingService.logError('BESTSELLER_SIMPLE_GRID', 'Error loading bestseller products: $e');
      print('BESTSELLER_SIMPLE_GRID ERROR: Failed to load bestsellers - $e');
      
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load bestsellers';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProductDetails(String productId) async {
    try {
      LoggingService.logFirestore('BESTSELLER_SIMPLE_GRID: Loading details for product ID: $productId');
      print('BESTSELLER_SIMPLE_GRID: Loading details for product ID: $productId');
      
      // Get product from cache or Firestore
      final product = await _productService.getProductById(productId);
      
      if (product == null) {
        LoggingService.logFirestore('BESTSELLER_SIMPLE_GRID: Product not found for ID: $productId');
        print('BESTSELLER_SIMPLE_GRID: Product not found for ID: $productId');
        return;
      }
      
      LoggingService.logFirestore('BESTSELLER_SIMPLE_GRID: Found product: ${product.name}, CategoryName: ${product.categoryName}');
      print('BESTSELLER_SIMPLE_GRID: Found product: ${product.name}, CategoryName: ${product.categoryName}');
      
      // Get background color from category
      if (product.categoryName != null) {
        final color = await _getProductBackgroundColor(product);
        
        if (mounted) {
          setState(() {
            _products[productId] = product;
            _productColors[productId] = color;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _products[productId] = product;
            _productColors[productId] = AppTheme.secondaryColor; // Default color
          });
        }
      }
    } catch (e) {
      LoggingService.logError('BESTSELLER_SIMPLE_GRID', 'Error loading product $productId: $e');
      print('BESTSELLER_SIMPLE_GRID ERROR: Failed to load product $productId - $e');
    }
  }

  Future<Color> _getProductBackgroundColor(Product product) async {
    try {
      LoggingService.logFirestore('BESTSELLER_SIMPLE_GRID: Getting background color for ${product.name}');
      print('BESTSELLER_SIMPLE_GRID: Getting background color for ${product.name}');
      
      // Default color if we can't determine a better one
      Color bgColor = AppTheme.secondaryColor;
      
      if (product.categoryName == null) {
        return bgColor;
      }
      
      // Try to get category group from cache
      final categoryGroup = await _categoryService.getCategoryById(product.categoryName!);
      
      if (categoryGroup != null) {
        LoggingService.logFirestore('BESTSELLER_SIMPLE_GRID: Found category group: ${categoryGroup.title}');
        print('BESTSELLER_SIMPLE_GRID: Found category group: ${categoryGroup.title}');
        
        // Use the itemBackgroundColor from the category group
        bgColor = categoryGroup.itemBackgroundColor;
        
        LoggingService.logFirestore('BESTSELLER_SIMPLE_GRID: Using background color from category: ${bgColor.toString()}');
        print('BESTSELLER_SIMPLE_GRID: Using background color from category: ${bgColor.toString()}');
      } else {
        LoggingService.logFirestore('BESTSELLER_SIMPLE_GRID: Category group not found, using default color');
        print('BESTSELLER_SIMPLE_GRID: Category group not found, using default color');
      }
      
      return bgColor;
    } catch (e) {
      LoggingService.logError('BESTSELLER_SIMPLE_GRID', 'Error getting background color: $e');
      print('BESTSELLER_SIMPLE_GRID ERROR: Failed to get background color - $e');
      return AppTheme.secondaryColor; // Default color on error
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_productIds.isEmpty) {
      return _buildEmptyState();
    }

    return _buildGrid();
  }

  Widget _buildLoadingState() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
        childAspectRatio: 0.62, // Adjusted aspect ratio to prevent overflow
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.limit,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              Container(
                height: 120.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12.r),
                    topRight: Radius.circular(12.r),
                  ),
                ),
              ),
              
              // Content placeholders
              Padding(
                padding: EdgeInsets.all(10.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16.h,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade700,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      width: 80.w,
                      height: 12.h,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade700,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      width: double.infinity,
                      height: 36.h,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade700,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48.r,
            ),
            SizedBox(height: 16.h),
            Text(
              _errorMessage,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: _loadBestsellerProducts,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
              child: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.amber,
              size: 48.r,
            ),
            SizedBox(height: 16.h),
            Text(
              'No bestseller products found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    final quantities = widget.cartQuantities ?? <String, int>{};
    
    LoggingService.logFirestore('BESTSELLER_SIMPLE_GRID: Building grid with ${_productIds.length} products');
    print('BESTSELLER_SIMPLE_GRID: Building grid with ${_productIds.length} products');

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
        childAspectRatio: 0.65, // Height is ~1.5x width
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _productIds.length,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemBuilder: (context, index) {
        final productId = _productIds[index];
        final product = _products[productId];
        final color = _productColors[productId] ?? AppTheme.secondaryColor;
        final quantity = quantities[productId] ?? 0;
        
        if (product == null) {
          // Return empty container if product details not loaded yet
          return Container();
        }
        
        LoggingService.logFirestore('BESTSELLER_SIMPLE_GRID: Building product card at position ${index + 1} for ${product.name}');
        print('BESTSELLER_SIMPLE_GRID: Building product card at position ${index + 1} for ${product.name}');

        return SimpleProductCard(
          product: product,
          backgroundColor: color,
          onTap: widget.onProductTap,
          onQuantityChanged: widget.onQuantityChanged,
          quantity: quantity,
        );
      },
    );
  }
}