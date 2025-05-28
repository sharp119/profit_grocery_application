import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/product.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/product/firestore_product_repository.dart';
import '../../../services/category/shared_category_service.dart';
import '../../../services/logging_service.dart';
import '../buttons/back_to_top_button.dart';
import '../buttons/cart_fab.dart';
// import '../cards/universal_product_card.dart';
import '../cards/improved_product_card.dart';
import '../../../data/repositories/rtdb_category_product_repository.dart'; 


/// A two-panel layout with categories on the left and products on the right,
/// optimized for efficient Firestore data loading with lazy loading support
class TwoPanelCategoryProductView extends StatefulWidget {
  final List<Category> categories;
  final Function(Category) onCategoryTap;
  final Function(Product) onProductTap;
  final Function(Product, int) onQuantityChanged;
  final Map<String, int> cartQuantities;
  final int cartItemCount;
  final double? totalAmount;
  final VoidCallback onCartTap;
  final String? cartPreviewImage;
  final Map<String, Color>? subcategoryColors;
  final bool useSearch;

  const TwoPanelCategoryProductView({
    Key? key,
    required this.categories,
    required this.onCategoryTap,
    required this.onProductTap,
    required this.onQuantityChanged,
    this.cartQuantities = const {},
    required this.cartItemCount,
    this.totalAmount,
    required this.onCartTap,
    this.cartPreviewImage,
    this.subcategoryColors,
    this.useSearch = false,
  }) : super(key: key);

  @override
  State<TwoPanelCategoryProductView> createState() => _TwoPanelCategoryProductViewState();
}

class _TwoPanelCategoryProductViewState extends State<TwoPanelCategoryProductView> {
  final ScrollController _productScrollController = ScrollController();
  final ScrollController _categoryScrollController = ScrollController();
  final RTDBCategoryProductRepository _rtdbProductRepository = RTDBCategoryProductRepository();
  final SharedCategoryService _categoryService = GetIt.instance<SharedCategoryService>();
  
  int _selectedCategoryIndex = 0;
  final Map<int, double> _categoryOffsets = {};
  late Category _selectedCategory;
  
  final Map<String, StreamSubscription<List<Product>>> _categoryStreamSubscriptions = {};


  // Keep track of products for each category
  final Map<String, List<Product>> _categoryProducts = {};
  
  // Keep track of loading state for each category
  final Map<String, bool> _isLoadingCategory = {};
  
  // Keep track of visibility for each category section in the scrolling view
  final Map<String, bool> _isCategoryVisible = {};
  
  // Keep track of whether categories have been initially loaded
  final Map<String, bool> _isCategoryInitiallyLoaded = {};
  
  // Keep track of displayed products count for each category (for batch loading)
  final Map<String, int> _displayedProductsCount = {};
  
  // Batch size for product loading
  final int _productBatchSize = 8;
  
  // Flag to track if more products are being loaded
  final Map<String, bool> _isLoadingMoreProducts = {};
  
  @override
  void initState() {
    super.initState();
    
    // Start with the first category selected
    if (widget.categories.isNotEmpty) {
      _selectedCategory = widget.categories.first;
      
      // Mark all categories as not initially loaded
      for (final category in widget.categories) {
        _isCategoryInitiallyLoaded[category.id] = false;
        _isCategoryVisible[category.id] = false;
        _displayedProductsCount[category.id] = 0;
        _isLoadingMoreProducts[category.id] = false;
      }
      
      // Load first category immediately
      _loadProductsForCategory(widget.categories.first);
      
      // Mark first category as visible
      _isCategoryVisible[widget.categories.first.id] = true;
    }
    
    // Listen to scroll events to highlight the correct category and load data as needed
    _productScrollController.addListener(_onProductScroll);
  }
  
 @override
void dispose() {
  _productScrollController.removeListener(_onProductScroll);
  _productScrollController.dispose();
  _categoryScrollController.dispose();
  // Cancel all stream subscriptions
  for (final sub in _categoryStreamSubscriptions.values) {
    sub.cancel();
  }
  _categoryStreamSubscriptions.clear();
  super.dispose();
}
  
  /// Load products for a specific category from Firestore
  Future<void> _loadProductsForCategory(Category category) async {
  final categoryId = category.id; // This is your 'categoryItem'

  // Prevent duplicate stream subscriptions
  if (_categoryStreamSubscriptions.containsKey(categoryId)) {
    return;
  }

  setState(() {
    _isLoadingCategory[categoryId] = true;
    _isCategoryInitiallyLoaded[categoryId] = false; // Reset for stream
    _categoryProducts[categoryId] = []; // Clear previous products
    _displayedProductsCount[categoryId] = 0;
  });

  LoggingService.logFirestore('TWOPANEL_RTDB: Setting up stream for category: $categoryId');
  print('TWOPANEL_RTDB: Setting up stream for category: $categoryId');

  // Determine categoryGroup
  final categoryParts = categoryId.split('_');
  String? categoryGroup;
  if (categoryParts.isNotEmpty) {
    categoryGroup = await _getCategoryGroupForItem(categoryId); // Your existing logic
    if (categoryGroup == null && categoryParts.length > 1) {
      categoryGroup = categoryParts[0];
    }
  }

  if (categoryGroup == null) {
    LoggingService.logError('TWOPANEL_RTDB', 'Could not determine category group for: $categoryId');
    print('TWOPANEL_RTDB ERROR: Could not determine category group for: $categoryId');
    if (mounted) {
      setState(() {
        _isLoadingCategory[categoryId] = false;
        _isCategoryInitiallyLoaded[categoryId] = true; // Mark as processed
      });
    }
    return;
  }

  final streamSubscription = _rtdbProductRepository.getCategoryProductsStream(
    categoryGroup: categoryGroup,
    categoryItem: categoryId,
  ).listen(
    (products) {
      if (mounted) {
        setState(() {
          _categoryProducts[categoryId] = products;
          _isLoadingCategory[categoryId] = false;
          _isCategoryInitiallyLoaded[categoryId] = true;
          // Reset displayed count or adjust based on new product list length
          _displayedProductsCount[categoryId] = _productBatchSize.clamp(0, products.length);
          _isLoadingMoreProducts[categoryId] = false;

          LoggingService.logFirestore('TWOPANEL_RTDB: Received ${products.length} products for $categoryId via stream');
          print('TWOPANEL_RTDB: Received ${products.length} products for $categoryId via stream, displaying ${_displayedProductsCount[categoryId]}');
        });
      }
    },
    onError: (error) {
      LoggingService.logError('TWOPANEL_RTDB', 'Error in stream for category $categoryId: $error');
      print('TWOPANEL_RTDB ERROR: Stream error for $categoryId: $error');
      if (mounted) {
        setState(() {
          _isLoadingCategory[categoryId] = false;
          _isCategoryInitiallyLoaded[categoryId] = true; // Mark as processed even on error
          // Optionally, set an error state for this specific category
        });
      }
    },
  );
  if (mounted) {
      _categoryStreamSubscriptions[categoryId] = streamSubscription;
  } else {
      streamSubscription.cancel();
  }
}
  /// Get the category group ID for a category item ID
  Future<String?> _getCategoryGroupForItem(String categoryItemId) async {
    try {
      // Try to get from shared service first
      final groupInfo = await _categoryService.findCategoryGroupForItem(categoryItemId);
      return groupInfo?.id;
    } catch (e) {
      print('TWOPANEL: Error finding category group for $categoryItemId: $e');
      return null;
    }
  }
  
  /// Handle scroll events to update selected category based on scroll position
  /// and to load data for visible categories
  void _onProductScroll() {
    if (_categoryOffsets.isEmpty || !_productScrollController.hasClients) return;
    
    final currentOffset = _productScrollController.offset;
    final viewportHeight = _productScrollController.position.viewportDimension;
    
    // Find the category containing the current scroll position
    int newSelectedIndex = 0;
    for (int i = 0; i < widget.categories.length; i++) {
      if (i + 1 < widget.categories.length) {
        if (currentOffset >= _categoryOffsets[i]! && 
            currentOffset < _categoryOffsets[i + 1]!) {
          newSelectedIndex = i;
          break;
        }
      } else {
        newSelectedIndex = i;
      }
    }
    
    // Update selected category if changed
    if (newSelectedIndex != _selectedCategoryIndex) {
      setState(() {
        _selectedCategoryIndex = newSelectedIndex;
        _selectedCategory = widget.categories[newSelectedIndex];
      });
      
      // Call onCategoryTap callback to inform parent of category change
      widget.onCategoryTap(_selectedCategory);
    }
    
    // Check which categories are visible in the viewport and load them if needed
    for (int i = 0; i < widget.categories.length; i++) {
      final category = widget.categories[i];
      
      if (!_categoryOffsets.containsKey(i)) continue;
      
      final categoryOffset = _categoryOffsets[i]!;
      final isVisible = (categoryOffset >= currentOffset - viewportHeight && 
                          categoryOffset <= currentOffset + (2 * viewportHeight));
      
      // Update visibility state
      final wasVisible = _isCategoryVisible[category.id] ?? false;
      _isCategoryVisible[category.id] = isVisible;
      
      // If category became visible and isn't loaded yet, load its products
      if (isVisible && !wasVisible && !(_isCategoryInitiallyLoaded[category.id] ?? false)) {
        _loadProductsForCategory(category);
      }
    }
    
    // Preload the next category's products if we're approaching its position
    final nextCategoryIndex = _selectedCategoryIndex + 1;
    if (nextCategoryIndex < widget.categories.length) {
      final nextCategory = widget.categories[nextCategoryIndex];
      
      // Check if we're approaching the next category
      if (_categoryOffsets.containsKey(nextCategoryIndex)) {
        final nextCategoryOffset = _categoryOffsets[nextCategoryIndex]!;
        final isApproaching = nextCategoryOffset - currentOffset < viewportHeight * 1.5;
        
        if (isApproaching && !(_isCategoryInitiallyLoaded[nextCategory.id] ?? false)) {
          _loadProductsForCategory(nextCategory);
        }
      }
    }
  }
  
  /// Scroll to a specific category when selected from the left panel
  void _scrollToCategory(int index) {
    if (_categoryOffsets.containsKey(index) && _productScrollController.hasClients) {
      _productScrollController.animateTo(
        _categoryOffsets[index]!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  /// Handle category tap from the left panel
  void _handleCategoryTap(int index, Category category) {
    setState(() {
      _selectedCategoryIndex = index;
      _selectedCategory = category;
    });
    
    // Load products for this category if not already loaded
    if (!(_isCategoryInitiallyLoaded[category.id] ?? false)) {
      _loadProductsForCategory(category);
    }
    
    _scrollToCategory(index);
    widget.onCategoryTap(category);
  }
  
  /// Scroll back to the top of the product list
  void _scrollToTop() {
    if (_productScrollController.hasClients) {
      _productScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left panel: Category navigation
            Expanded(
              // width: 80.w,
              flex: 1,
              child: ListView.builder(
                controller: _categoryScrollController,
                itemCount: widget.categories.length,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                itemBuilder: (context, index) {
                  final category = widget.categories[index];
                  final isSelected = index == _selectedCategoryIndex;
                  
                  // Get background color for the subcategory
                  final Color backgroundColor = widget.subcategoryColors?[category.id] ?? Colors.transparent;
                  
                  return GestureDetector(
                    onTap: () => _handleCategoryTap(index, category),
                    child: Container(
                      color: isSelected 
                          ? AppTheme.secondaryColor
                          : Colors.transparent,
                      padding: EdgeInsets.symmetric(
                        vertical: 12.h,
                        horizontal: 8.w,
                      ),
                      child: Column(
                        children: [
                          // Category icon
                          Container(
                            width: 50.w,
                            height: 50.w,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withOpacity(0.9)
                                  : Colors.white.withOpacity(0.0),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.accentColor
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(8.r),
                              child: CachedNetworkImage(
                                imageUrl: category.image,
                                fit: BoxFit.contain,
                                placeholder: (context, url) => Center(
                                  child: SizedBox(
                                    width: 20.w,
                                    height: 20.w,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.w,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppTheme.accentColor,
                                      ),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) {
                                  LoggingService.logError('TWOPANEL', 'Error loading image for ${category.name}: $error, URL: $url');
                                  print('TWOPANEL: Error loading image for ${category.name}: $error, URL: $url');
                                  return Icon(
                                    Icons.category,
                                    color: isSelected
                                        ? AppTheme.accentColor
                                        : Colors.white,
                                    size: 24.w,
                                  );
                                },
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 8.h),
                          
                          // Category name
                          Text(
                            category.name,
                            style: TextStyle(
                              color: isSelected
                                  ? AppTheme.accentColor
                                  : Colors.white,
                              fontSize: 12.sp,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          // Selected indicator
                          if (isSelected)
                            Container(
                              margin: EdgeInsets.only(top: 8.h),
                              width: 30.w,
                              height: 3.h,
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor,
                                borderRadius: BorderRadius.circular(1.5.r),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Right panel: Products for categories - Lazy loaded sections
            Expanded(
              flex: 4,
              child: CustomScrollView(
                controller: _productScrollController,
                slivers: [
                  // Display each category's products
                  for (int i = 0; i < widget.categories.length; i++)
                    SliverToBoxAdapter(
                      child: Builder(
                        builder: (context) {
                          final category = widget.categories[i];
                          final categoryId = category.id;
                          
                          // Store the offset of this category section
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            final renderBox = context.findRenderObject() as RenderBox?;
                            if (renderBox != null) {
                              _categoryOffsets[i] = renderBox.localToGlobal(Offset.zero).dy -
                                  AppBar().preferredSize.height -
                                  MediaQuery.of(context).padding.top;
                            }
                          });
                          
                          // Check if products are loading or have been loaded
                          final isLoading = _isLoadingCategory[categoryId] ?? false;
                          final products = _categoryProducts[categoryId] ?? [];
                          final isInitiallyLoaded = _isCategoryInitiallyLoaded[categoryId] ?? false;
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Category header
                              Padding(
                                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                                child: Text(
                                  category.name,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              
                              // Product count or loading indicator
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                child: isLoading
                                    ? Row(
                                        children: [
                                          SizedBox(
                                            width: 16.w,
                                            height: 16.h,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                AppTheme.accentColor,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 8.w),
                                          Text(
                                            'Loading products...',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.7),
                                              fontSize: 12.sp,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        '${products.length} products available',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 12.sp,
                                        ),
                                      ),
                              ),
                              
                              SizedBox(height: 8.h),
                              
                              // Products grid or loading placeholder
                              if (isLoading && !isInitiallyLoaded)
                                _buildLoadingProductsGrid()
                              else if (products.isEmpty && isInitiallyLoaded)
                                _buildEmptyProductsMessage()
                              else
                                _buildProductsGrid(products, category),
                              
                              SizedBox(height: 16.h),
                            ],
                          );
                        },
                      ),
                    ),
                  
                  // Extra space at the bottom for the FAB
                  SliverToBoxAdapter(
                    child: SizedBox(height: 100.h),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        // Back to top button
        Positioned(
          bottom: 80.h, // Adjust to position above the cart FAB
          right: 20.w,
          child: BackToTopButton.scrollAware(
            scrollController: _productScrollController,
            onTap: _scrollToTop,
            showAtOffset: 500.0,
          ),
        ),
        
        // Cart FAB using the updated implementation
        Positioned(
          bottom: 16.h,
          left: 0,
          right: 0,
          child: Center(
            child: CartFAB(
              onTap: widget.onCartTap,
              backgroundColor: AppTheme.accentColor,
            ),
          ),
        ),
      ],
    );
  }
  
  /// Build loading placeholder for products
  Widget _buildLoadingProductsGrid() {
    // Use a simpler layout to avoid overflow issues
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.63, // Same as product grid
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
        ),
        itemCount: 4, // Show 4 loading placeholders
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.zero,
            color: AppTheme.secondaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
            // Use Clip to ensure nothing exceeds the Card boundaries
            clipBehavior: Clip.antiAlias, 
            child: Stack(
              children: [
                // Use a Column with loose constraints to avoid overflow
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Image area - fixed aspect ratio
                    AspectRatio(
                      aspectRatio: 1.2,
                      child: Container(
                        color: Colors.grey.shade800,
                        child: Center(
                          child: SizedBox(
                            width: 32.w,
                            height: 32.h,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.accentColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Text placeholders with minimal height
                    Padding(
                      padding: EdgeInsets.all(8.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Title placeholder
                          Container(
                            width: double.infinity,
                            height: 10.h,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade800,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          
                          // Price placeholder
                          Container(
                            width: 80.w,
                            height: 10.h,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade800,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          
                          // Button placeholder
                          Container(
                            width: double.infinity,
                            height: 24.h, // Slightly shorter
                            decoration: BoxDecoration(
                              color: Colors.grey.shade800,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  /// Build message for empty products
  Widget _buildEmptyProductsMessage() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.h),
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.grey,
              size: 48.r,
            ),
            SizedBox(height: 16.h),
            Text(
              'No products available in this category',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  /// Load more products for a category when user scrolls to the bottom
  void _loadMoreProducts(String categoryId) {
    if (_isLoadingMoreProducts[categoryId] == true) return;
    
    final allProducts = _categoryProducts[categoryId] ?? [];
    final currentlyDisplayed = _displayedProductsCount[categoryId] ?? 0;
    
    // If we're already showing all products, don't do anything
    if (currentlyDisplayed >= allProducts.length) return;
    
    setState(() {
      _isLoadingMoreProducts[categoryId] = true;
    });
    
    // Simulate loading delay for better UX
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          // Calculate how many more to show (up to batch size)
          final newDisplayCount = (currentlyDisplayed + _productBatchSize).clamp(0, allProducts.length);
          _displayedProductsCount[categoryId] = newDisplayCount;
          _isLoadingMoreProducts[categoryId] = false;
          
          print('TWOPANEL: Loaded more products for $categoryId, now showing $newDisplayCount of ${allProducts.length}');
        });
      }
    });
  }

  /// Build grid of products with batch loading
  Widget _buildProductsGrid(List<Product> products, Category category) {
    final quantities = widget.cartQuantities;
    final categoryId = category.id;
    
    // Get category color
    final Color backgroundColor = widget.subcategoryColors?[categoryId] ?? Colors.transparent;
    
    // Get the number of products to display (batch loading)
    final displayCount = _displayedProductsCount[categoryId] ?? _productBatchSize.clamp(0, products.length);
    final displayedProducts = products.take(displayCount).toList();
    final isLoadingMore = _isLoadingMoreProducts[categoryId] ?? false;
    final hasMoreToLoad = displayCount < products.length;
    
    return Column(
      children: [
        // Products grid
        GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.50, // Decreased to provide more height for the content
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
          ),
          itemCount: displayedProducts.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          itemBuilder: (context, index) {
            final product = displayedProducts[index];
            final quantity = quantities[product.id] ?? 0;
            
            
            
            // Check if this is the last item in the current batch
            final isLastItem = index == displayedProducts.length - 1;
            
            // If this is the last item and there are more to load, trigger loading more
            if (isLastItem && hasMoreToLoad && !isLoadingMore) {
              // Use post-frame callback to avoid build issues
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _loadMoreProducts(categoryId);
              });
            }
            
            return ImprovedProductCard(
              product: product,
              onTap: () => widget.onProductTap(product),
              onQuantityChanged: (product, qty) => widget.onQuantityChanged(product, qty),
              quantity: quantity,
              backgroundColor: backgroundColor,
              showBrand: true,
              showWeight: true,
              enableQuantityControls: true,
            );
          },
        ),
        
        // Loading indicator for more products
        if (hasMoreToLoad)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: isLoadingMore
                ? Center(
                    child: SizedBox(
                      width: 24.w,
                      height: 24.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.w,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: () => _loadMoreProducts(categoryId),
                    child: Text(
                      'Load more products',
                      style: TextStyle(
                        color: AppTheme.accentColor,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
          ),
      ],
    );
  }
}