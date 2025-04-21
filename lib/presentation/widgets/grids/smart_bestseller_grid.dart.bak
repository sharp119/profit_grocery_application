import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:profit_grocery_application/services/category/shared_category_service.dart';

import '../../../domain/entities/product.dart';
import '../../../data/repositories/bestseller_repository.dart';
import '../../../services/logging_service.dart';
import '../cards/smart_product_card.dart';

/// A grid that displays bestseller products using smart product cards
/// Fetches bestsellers on its own and handles its own state management
class SmartBestsellerGrid extends StatefulWidget {
  final Function(Product) onProductTap;
  final Function(Product, int) onQuantityChanged;
  final Map<String, int>? cartQuantities;
  final int limit;
  final bool ranked;
  final int crossAxisCount;

  const SmartBestsellerGrid({
    Key? key,
    required this.onProductTap,
    required this.onQuantityChanged,
    this.cartQuantities,
    this.limit = 6,
    this.ranked = true,
    this.crossAxisCount = 2,
  }) : super(key: key);

  @override
  State<SmartBestsellerGrid> createState() => _SmartBestsellerGridState();
}

class _SmartBestsellerGridState extends State<SmartBestsellerGrid> {
  late final BestsellerRepository _bestsellerRepository;
  List<String> _bestsellerIds = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _bestsellerRepository = GetIt.instance<BestsellerRepository>();
    _loadBestsellerIds();
  }

  Future<void> _loadBestsellerIds() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Log start of bestseller loading process
      LoggingService.logFirestore('SmartBestsellerGrid: Starting to load bestseller products');
      print('HOME_BESTSELLER: Starting to load bestseller products');

      // Fetch bestseller products with specified limit and ranking
      final products = await _bestsellerRepository.getBestsellerProducts(
        limit: widget.limit,
        ranked: widget.ranked,
      );

      // Extract just the product IDs
      final productIds = products.map((product) => product.id).toList();
      
      // Detailed logging for each product with its category
      LoggingService.logFirestore('HOME_BESTSELLER: Retrieved ${productIds.length} bestseller product IDs');
      print('HOME_BESTSELLER: Retrieved ${productIds.length} bestseller product IDs');
      print('HOME_BESTSELLER: Product IDs: ${productIds.join(', ')}');
      LoggingService.logFirestore('HOME_BESTSELLER: Product IDs: ${productIds.join(', ')}');
      
      // Log category information for each product
      for (final product in products) {
        final categoryName = product.categoryName ?? 'Unknown Category';
        final categoryId = product.categoryId ?? 'Unknown ID';
        final subcategoryId = product.subcategoryId ?? 'Unknown Subcategory';
        
        LoggingService.logFirestore('HOME_BESTSELLER: Product ${product.id} (${product.name}) belongs to category: $categoryName (ID: $categoryId), subcategory: $subcategoryId');
        print('HOME_BESTSELLER: Product ${product.id} (${product.name}) belongs to category: $categoryName (ID: $categoryId), subcategory: $subcategoryId');
        
        // Fetch and log detailed category group information
        try {
          final categoryService = GetIt.instance<SharedCategoryService>();
          final categoryGroup = await categoryService.getCategoryById(categoryName);
          
          if (categoryGroup != null) {
            // Log basic category group info
            LoggingService.logFirestore('HOME_BESTSELLER: CategoryGroup for ${product.name} - Title: ${categoryGroup.title}, ID: ${categoryGroup.id}');
            print('HOME_BESTSELLER: CategoryGroup for ${product.name} - Title: ${categoryGroup.title}, ID: ${categoryGroup.id}');
            
            // Count how many items are in this category group
            final itemCount = categoryGroup.items.length;
            LoggingService.logFirestore('HOME_BESTSELLER: CategoryGroup ${categoryGroup.title} has $itemCount subcategories');
            print('HOME_BESTSELLER: CategoryGroup ${categoryGroup.title} has $itemCount subcategories');
            
            // Find matching subcategory if available
            final matchingSubcategories = categoryGroup.items.where(
              (item) => item.id == subcategoryId
            ).toList();
            
            if (matchingSubcategories.isNotEmpty) {
              final subcategory = matchingSubcategories.first;
              LoggingService.logFirestore('HOME_BESTSELLER: Found matching subcategory "${subcategory.label}" for product ${product.name}');
              print('HOME_BESTSELLER: Found matching subcategory "${subcategory.label}" for product ${product.name}');
            }
          } else {
            LoggingService.logFirestore('HOME_BESTSELLER: Could not find category group for $categoryName');
            print('HOME_BESTSELLER: Could not find category group for $categoryName');
          }
        } catch (e) {
          LoggingService.logError('HOME_BESTSELLER', 'Error getting category details: $e');
          print('HOME_BESTSELLER: Error getting category details: $e');
        }
      }

      setState(() {
        _bestsellerIds = productIds;
        _isLoading = false;
      });

      LoggingService.logFirestore('SmartBestsellerGrid: Successfully loaded and displayed ${productIds.length} bestseller products');
    } catch (e) {
      LoggingService.logError(
          'SmartBestsellerGrid', 'Error loading bestseller IDs: $e');
      print('HOME_BESTSELLER ERROR: Failed to load bestsellers - $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load bestsellers';
        _isLoading = false;
      });
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

    if (_bestsellerIds.isEmpty) {
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
        childAspectRatio: 0.65, // Height is ~1.5x width
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.limit,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemBuilder: (context, index) {
        return _buildSkeletonCard();
      },
    );
  }

  Widget _buildSkeletonCard() {
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
              onPressed: _loadBestsellerIds,
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

    // Log when the bestseller grid starts displaying products
    LoggingService.logFirestore('HOME_BESTSELLER: Building grid view with ${_bestsellerIds.length} products');
    print('HOME_BESTSELLER: Building grid view with ${_bestsellerIds.length} products');

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
        childAspectRatio: 0.65, // Height is ~1.5x width
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _bestsellerIds.length,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemBuilder: (context, index) {
        final productId = _bestsellerIds[index];
        final quantity = quantities[productId] ?? 0;

        // Log when each individual product card is being created
        LoggingService.logFirestore('HOME_BESTSELLER: Creating product card for ID: $productId (position: ${index + 1})');
        print('HOME_BESTSELLER: Creating product card for ID: $productId (position: ${index + 1})');
        
        return SmartProductCard(
          productId: productId,
          onTap: widget.onProductTap,
          onQuantityChanged: widget.onQuantityChanged,
          quantity: quantity,
          onProductLoaded: (product) {
            // Log when product details are successfully loaded in the card
            if (product != null) {
              final categoryName = product.categoryName ?? 'Unknown Category';
              final categoryId = product.categoryId ?? 'Unknown ID';
              LoggingService.logFirestore('HOME_BESTSELLER: Displayed product ${product.id} (${product.name}) from category: $categoryName (ID: $categoryId)');
              print('HOME_BESTSELLER: Displayed product ${product.id} (${product.name}) from category: $categoryName (ID: $categoryId)');
            }
          },
        );
      },
    );
  }
}
