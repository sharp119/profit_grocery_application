import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/product.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/product/rtdb_product_repository.dart';
import '../../../services/category/shared_category_service.dart';
import '../../../utils/stream_utils.dart';
import '../buttons/back_to_top_button.dart';
import '../buttons/cart_fab.dart';
import '../cards/universal_product_card.dart';

/// A two-panel layout with categories on the left and products on the right,
/// Optimized for real-time updates with Firebase Realtime Database and smooth scrolling
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
  final RTDBProductRepository _productRepository = RTDBProductRepository();
  final SharedCategoryService _categoryService = GetIt.instance<SharedCategoryService>();
  
  int _selectedCategoryIndex = 0;
  final Map<int, double> _categoryOffsets = {};
  late Category _selectedCategory;
  
  // Keep track of products for each category
  final Map<String, List<ProductModel>> _categoryProducts = {};
  
  // Keep track of loading state for each category
  final Map<String, bool> _isLoadingCategory = {};
  
  // Keep track of whether categories have stream subscriptions
  final Map<String, StreamSubscription<List<ProductModel>>?> _categoryStreams = {};
  
  // Track the last scroll time for throttling
  DateTime _lastScrollTime = DateTime.now();
  static const _scrollThrottleMs = 100; // Throttle scroll event processing
  
  @override
  void initState() {
    super.initState();
    
    // Start with the first category selected
    if (widget.categories.isNotEmpty) {
      _selectedCategory = widget.categories.first;
      
      // Setup listeners for first visible categories (optimized initial load)
      _setupInitialCategoryListeners();
    }
    
    // Listen to scroll events (throttled) to highlight the correct category
    _productScrollController.addListener(_throttledOnProductScroll);
  }
  
  @override
  void dispose() {
    // Remove scroll listener
    _productScrollController.removeListener(_throttledOnProductScroll);
    _productScrollController.dispose();
    _categoryScrollController.dispose();
    
    // Cancel all stream subscriptions to prevent memory leaks
    for (final subscription in _categoryStreams.values) {
      subscription?.cancel();
    }
    _categoryStreams.clear();
    
    // Dispose the repository to clean up its listeners
    _productRepository.dispose();
    
    super.dispose();
  }
  
  /// Setup listeners for the first few visible categories
  void _setupInitialCategoryListeners() {
    // Only setup initial listeners for the first 2-3 categories
    final initialCategories = widget.categories.take(3).toList();
    
    for (final category in initialCategories) {
      _setupCategoryListener(category);
    }
  }
  
  /// Setup a real-time listener for a specific category's products
  Future<void> _setupCategoryListener(Category category) async {
    final categoryId = category.id;
    
    // Skip if already subscribed
    if (_categoryStreams.containsKey(categoryId) && _categoryStreams[categoryId] != null) {
      return;
    }
    
    // Mark as loading
    setState(() {
      _isLoadingCategory[categoryId] = true;
    });
    
    try {
      // Get category group info
      final categoryGroup = await _getCategoryGroupForItem(categoryId);
      
      if (categoryGroup == null) {
        if (mounted) {
          setState(() {
            _isLoadingCategory[categoryId] = false;
            _categoryProducts[categoryId] = [];
          });
        }
        return;
      }
      
      // Create a stream subscription for real-time updates
      final stream = _productRepository.getProductsStream(categoryGroup, categoryId);
      final subscription = stream.listen((products) {
        if (mounted) {
          setState(() {
            _categoryProducts[categoryId] = products;
            _isLoadingCategory[categoryId] = false;
          });
        }
      }, onError: (error) {
        if (mounted) {
          setState(() {
            _isLoadingCategory[categoryId] = false;
            _categoryProducts[categoryId] = [];
          });
        }
      });
      
      // Store the subscription for cleanup
      _categoryStreams[categoryId] = subscription;
      
    } catch (e) {
      debugPrint('TwoPanelView: Error setting up listener for $categoryId: $e');
      
      if (mounted) {
        setState(() {
          _isLoadingCategory[categoryId] = false;
          _categoryProducts[categoryId] = [];
        });
      }
    }
  }
  
  /// Get the category group ID for a category item ID
  Future<String?> _getCategoryGroupForItem(String categoryItemId) async {
    try {
      // Try to get from shared service first
      final groupInfo = await _categoryService.findCategoryGroupForItem(categoryItemId);
      return groupInfo?.id;
    } catch (e) {
      debugPrint('TwoPanelView: Error finding category group for $categoryItemId: $e');
      
      // Fallback to using parts of the ID
      final categoryParts = categoryItemId.split('_');
      if (categoryParts.isNotEmpty) {
        return categoryParts[0];
      }
      
      return null;
    }
  }
  
  /// Throttled scroll event handler to reduce unnecessary processing
  void _throttledOnProductScroll() {
    // Skip processing if scrolled recently
    final now = DateTime.now();
    if (now.difference(_lastScrollTime).inMilliseconds < _scrollThrottleMs) {
      return;
    }
    _lastScrollTime = now;
    
    // Process scroll event
    _onProductScroll();
  }
  
  /// Handle scroll events to update selected category based on scroll position
  void _onProductScroll() {
    if (_categoryOffsets.isEmpty || !_productScrollController.hasClients) return;
    
    final currentOffset = _productScrollController.offset;
    final viewportHeight = _productScrollController.position.viewportDimension;
    
    // Find the category containing the current scroll position
    int newSelectedIndex = 0;
    for (int i = 0; i < widget.categories.length; i++) {
      if (i + 1 < widget.categories.length && _categoryOffsets.containsKey(i + 1)) {
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
    
    // Set up listeners for visible and soon-to-be-visible categories
    _setupVisibleCategoryListeners(currentOffset, viewportHeight);
  }
  
  /// Setup listeners for categories that are visible or about to be visible
  void _setupVisibleCategoryListeners(double currentOffset, double viewportHeight) {
    // Look-ahead distance (how far ahead we should pre-load categories)
    final lookAheadDistance = viewportHeight * 2;
    
    for (int i = 0; i < widget.categories.length; i++) {
      if (!_categoryOffsets.containsKey(i)) continue;
      
      final category = widget.categories[i];
      final categoryOffset = _categoryOffsets[i]!;
      
      // Category is visible or will be soon
      final isVisibleOrSoon = 
          (categoryOffset >= currentOffset - lookAheadDistance) && 
          (categoryOffset <= currentOffset + lookAheadDistance);
      
      if (isVisibleOrSoon && !_categoryStreams.containsKey(category.id)) {
        // Setup listener for this category if not already listening
        _setupCategoryListener(category);
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
    
    // Make sure this category has a listener
    _setupCategoryListener(category);
    
    // Scroll to the category
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
            SizedBox(
              width: 100.w,
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
                                  debugPrint('TwoPanelView: Error loading image for ${category.name}: $error');
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
            
            // Right panel: Products for categories with real-time updates
            Expanded(
              child: CustomScrollView(
                controller: _productScrollController,
                physics: const BouncingScrollPhysics(),
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
                            if (renderBox != null && mounted) {
                              final offset = renderBox.localToGlobal(Offset.zero).dy -
                                  AppBar().preferredSize.height -
                                  MediaQuery.of(context).padding.top;
                              
                              if (_categoryOffsets[i] != offset) {
                                _categoryOffsets[i] = offset;
                              }
                            }
                          });
                          
                          // Get products and loading state
                          final isLoading = _isLoadingCategory[categoryId] ?? false;
                          final products = _categoryProducts[categoryId] ?? [];
                          final hasStream = _categoryStreams.containsKey(categoryId);
                          
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
                              if (isLoading && products.isEmpty)
                                _buildLoadingProductsGrid()
                              else if (products.isEmpty && hasStream)
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.63,
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
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image area - Shimmer effect
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
                
                // Text placeholders
                Padding(
                  padding: EdgeInsets.all(8.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                        height: 24.h,
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
  
  /// Build grid of products
  Widget _buildProductsGrid(List<ProductModel> products, Category category) {
    final quantities = widget.cartQuantities;
    
    // Get category color
    final Color backgroundColor = widget.subcategoryColors?[category.id] ?? Colors.transparent;
    
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.63,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
      ),
      itemCount: products.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemBuilder: (context, index) {
        final product = products[index];
        final quantity = quantities[product.id] ?? 0;
        
        // Convert ProductModel to Product entity for the callbacks
        final productEntity = Product(
          id: product.id,
          name: product.name,
          description: product.description ?? '',
          price: product.price,
          mrp: product.mrp,
          image: product.image,
          inStock: product.inStock,
          categoryId: product.categoryId,
          categoryName: product.categoryName,
          subcategoryId: product.subcategoryId,
          weight: product.weight,
          brand: product.brand,
          isActive: true,
          isFeatured: false,
          tags: [],
          categoryGroup: product.categoryGroup,
        );
        
        return UniversalProductCard(
          product: productEntity,
          onTap: () => widget.onProductTap(productEntity),
          // quantity: quantity,
          backgroundColor: backgroundColor,
          useBackgroundColor: backgroundColor != Colors.transparent,
        );
      },
    );
  }
}