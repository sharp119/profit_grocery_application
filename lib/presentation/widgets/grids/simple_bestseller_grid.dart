import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';

import '../../../domain/entities/product.dart';
import '../../../domain/entities/bestseller_item.dart';
import '../../../domain/entities/bestseller_product.dart';
import '../../../data/repositories/bestseller_repository_simple.dart';
import '../../../services/logging_service.dart';
import '../../../services/product/shared_product_service.dart';
import '../../../services/category/shared_category_service.dart';
import '../cards/simple_product_card.dart';
import '../cards/bestseller_product_card.dart';
import '../../../core/constants/app_theme.dart';

/// A simplified grid that displays bestseller products with their special discounts
class SimpleBestsellerGrid extends StatefulWidget {
  final Function(Product)? onProductTap;
  final Function(Product, int)? onQuantityChanged;
  final Map<String, int>? cartQuantities;
  final int limit;
  final bool ranked;
  final int crossAxisCount;
  final bool showBestsellerBadge;

  const SimpleBestsellerGrid({
    Key? key,
    this.onProductTap,
    this.onQuantityChanged,
    this.cartQuantities,
    this.limit = 4,
    this.ranked = false,
    this.crossAxisCount = 2,
    this.showBestsellerBadge = true,
  }) : super(key: key);


  @override
  State<SimpleBestsellerGrid> createState() => _SimpleBestsellerGridState();
}

class _SimpleBestsellerGridState extends State<SimpleBestsellerGrid> {
  final BestsellerRepositorySimple _bestsellerRepository = GetIt.instance<BestsellerRepositorySimple>();
  final SharedProductService _productService = GetIt.instance<SharedProductService>();
  final SharedCategoryService _categoryService = GetIt.instance<SharedCategoryService>();
  
  List<BestsellerProduct> _bestsellerProducts = [];
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
      LoggingService.logFirestore('BESTSELLER_GRID: Starting to load bestseller products');
      print('BESTSELLER_GRID: Starting to load bestseller products');
      
      if (mounted) {
        setState(() {
          _isLoading = true;
          _hasError = false;
        });
      }

      // Step 1: Get bestseller items with discount information
      final bestsellerItems = await _bestsellerRepository.getBestsellerItems(
        limit: widget.limit,
        ranked: widget.ranked,
      );
      
      LoggingService.logFirestore('BESTSELLER_GRID: Retrieved ${bestsellerItems.length} bestseller items');
      print('BESTSELLER_GRID: Retrieved ${bestsellerItems.length} bestseller items');
      
      // Only log if needed to reduce console noise
      if (bestsellerItems.isNotEmpty) {
        print('BESTSELLER_GRID_DEBUG: First few bestseller items:');
        final itemsToLog = bestsellerItems.length > 3 ? bestsellerItems.sublist(0, 3) : bestsellerItems;
        itemsToLog.forEach((item) {
          print('BESTSELLER_GRID_DEBUG: ProductID: ${item.productId}, Rank: ${item.rank}, ' +
                'DiscountType: ${item.discountType}, DiscountValue: ${item.discountValue}');
        });
      }
      
      // Clear existing data
      _bestsellerProducts = [];
      _productColors.clear();
      
      if (bestsellerItems.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }
      
      // Step 2: Load product details in batch for better performance
      await _loadProductDetailsInBatch(bestsellerItems);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      LoggingService.logFirestore('BESTSELLER_GRID: Successfully loaded ${_bestsellerProducts.length} bestseller products');
      print('BESTSELLER_GRID: Successfully loaded ${_bestsellerProducts.length} bestseller products');
    } catch (e) {
      LoggingService.logError('BESTSELLER_GRID', 'Error loading bestseller products: $e');
      print('BESTSELLER_GRID ERROR: Failed to load bestsellers - $e');
      
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load bestsellers';
          _isLoading = false;
        });
      }
    }
  }
  
  // New optimized batch loading method
  Future<void> _loadProductDetailsInBatch(List<BestsellerItem> bestsellerItems) async {
    try {
      // Extract all product IDs for batch loading
      final productIds = bestsellerItems.map((item) => item.productId).toList();
      
      // Create a map of bestseller items for easy lookup
      final Map<String, BestsellerItem> bestsellerItemsMap = {
        for (var item in bestsellerItems) item.productId: item
      };
      
      print('BESTSELLER_GRID: Batch loading ${productIds.length} products');
      
      // Load all products in one batch operation for better performance
      final products = await _productService.getProductsByIds(productIds);
      
      // Load category colors in parallel for all products
      final categoryIds = products
          .where((product) => product.categoryName != null)
          .map((product) => product.categoryName!)
          .toSet()
          .toList();
      
      // Pre-fetch all needed category colors
      final Map<String, Color> categoryColors = {};
      await Future.wait(
        categoryIds.map((categoryId) async {
          try {
            final category = await _categoryService.getCategoryById(categoryId);
            if (category != null) {
              categoryColors[categoryId] = category.itemBackgroundColor;
            }
          } catch (e) {
            print('BESTSELLER_GRID: Error fetching category color: $e');
          }
        })
      );
      
      // Create bestseller products and store colors
      final List<BestsellerProduct> bestsellerProducts = [];
      
      for (final product in products) {
        final bestsellerItem = bestsellerItemsMap[product.id];
        if (bestsellerItem != null) {
          final bestsellerProduct = BestsellerProduct(
            product: product,
            bestsellerInfo: bestsellerItem,
          );
          
          bestsellerProducts.add(bestsellerProduct);
          
          // Get background color from category or use default
          Color bgColor = AppTheme.secondaryColor;
          if (product.categoryName != null && categoryColors.containsKey(product.categoryName)) {
            bgColor = categoryColors[product.categoryName]!;
          }
          
          _productColors[product.id] = bgColor;
        }
      }
      
      // Sort products by rank if needed
      if (widget.ranked) {
        bestsellerProducts.sort((a, b) => a.rank.compareTo(b.rank));
      }
      
      if (mounted) {
        setState(() {
          _bestsellerProducts = bestsellerProducts;
        });
      }
      
      print('BESTSELLER_GRID: Loaded ${bestsellerProducts.length} bestseller products with batch loading');
    } catch (e) {
      LoggingService.logError('BESTSELLER_GRID', 'Error batch loading products: $e');
      print('BESTSELLER_GRID ERROR: Batch loading failed - $e');
      
      // Fallback to individual loading if batch loading fails
      if (bestsellerItems.isNotEmpty) {
        for (final item in bestsellerItems) {
          await _loadProductDetailsForBestseller(item);
        }
      }
    }
  }

  // Kept for fallback but not used in main flow anymore
  Future<void> _loadProductDetailsForBestseller(BestsellerItem bestsellerItem) async {
    try {
      final productId = bestsellerItem.productId;
      
      LoggingService.logFirestore('BESTSELLER_GRID: Loading details for product ID: $productId');
      print('BESTSELLER_GRID: Loading details for product ID: $productId');
      
      // Get product from cache or Firestore
      final product = await _productService.getProductById(productId);
      
      if (product == null) {
        LoggingService.logFirestore('BESTSELLER_GRID: Product not found for ID: $productId');
        print('BESTSELLER_GRID: ⚠️ WARNING - Product not found for ID: $productId');
        return;
      }
      
      LoggingService.logFirestore(
        'BESTSELLER_GRID: Found product: ${product.name}, CategoryName: ${product.categoryName}, '
        'Bestseller discount: ${bestsellerItem.discountType ?? 'None'} ${bestsellerItem.discountValue ?? '0'}'
      );
      
      print(
        'BESTSELLER_GRID: Found product: ${product.name}, CategoryName: ${product.categoryName}, '
        'Bestseller discount: ${bestsellerItem.discountType ?? 'None'} ${bestsellerItem.discountValue ?? '0'}'
      );
      
      // Create a BestsellerProduct combining the product and bestseller information
      final bestsellerProduct = BestsellerProduct(
        product: product,
        bestsellerInfo: bestsellerItem,
      );
      
      // Get background color from category
      if (product.categoryName != null) {
        final color = await _getProductBackgroundColor(product);
        
        if (mounted) {
          setState(() {
            _bestsellerProducts.add(bestsellerProduct);
            _productColors[productId] = color;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _bestsellerProducts.add(bestsellerProduct);
            _productColors[productId] = AppTheme.secondaryColor; // Default color
          });
        }
      }
      
      // Sort products by rank if needed
      if (widget.ranked && mounted) {
        setState(() {
          _bestsellerProducts.sort((a, b) => a.rank.compareTo(b.rank));
        });
      }
    } catch (e) {
      LoggingService.logError('BESTSELLER_GRID', 'Error loading product ${bestsellerItem.productId}: $e');
      print('BESTSELLER_GRID ERROR: Failed to load product ${bestsellerItem.productId} - $e');
    }
  }

  Future<Color> _getProductBackgroundColor(Product product) async {
    try {
      // Default color if we can't determine a better one
      Color bgColor = AppTheme.secondaryColor;
      
      if (product.categoryName == null) {
        return bgColor;
      }
      
      // Try to get category group from cache
      final categoryGroup = await _categoryService.getCategoryById(product.categoryName!);
      
      if (categoryGroup != null) {
        // Use the itemBackgroundColor from the category group
        bgColor = categoryGroup.itemBackgroundColor;
      }
      
      return bgColor;
    } catch (e) {
      print('BESTSELLER_GRID ERROR: Failed to get background color - $e');
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

    if (_bestsellerProducts.isEmpty) {
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
    
    LoggingService.logFirestore('BESTSELLER_GRID: Building grid with ${_bestsellerProducts.length} products');
    print('BESTSELLER_GRID: Building grid with ${_bestsellerProducts.length} products');

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
        childAspectRatio: 0.65, // Height is ~1.5x width
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _bestsellerProducts.length,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemBuilder: (context, index) {
        final bestsellerProduct = _bestsellerProducts[index];
        final product = bestsellerProduct.product;
        final productId = product.id;
        final color = _productColors[productId] ?? AppTheme.secondaryColor;
        final quantity = quantities[productId] ?? 0;

        // Use the BestsellerProductCard for enhanced display
        return BestsellerProductCard(
          bestsellerProduct: bestsellerProduct,
          backgroundColor: color,
          onTap: widget.onProductTap != null ? 
            (bestsellerProduct) => widget.onProductTap!(bestsellerProduct.product) : null,
          onQuantityChanged: widget.onQuantityChanged != null ?
            (bestsellerProduct, qty) => widget.onQuantityChanged!(bestsellerProduct.product, qty) : null,
          quantity: quantity,
          showBestsellerBadge: widget.showBestsellerBadge,
        );
      },
    );
  }
}