import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/product.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/product/firestore_product_repository.dart';
import '../../../services/category/shared_category_service.dart';
import '../../../services/logging_service.dart';
import '../buttons/back_to_top_button.dart';
import '../buttons/cart_fab.dart';
import '../cards/universal_product_card.dart';

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
  }) : super(key: key);

  @override
  State<TwoPanelCategoryProductView> createState() => _TwoPanelCategoryProductViewState();
}

class _TwoPanelCategoryProductViewState extends State<TwoPanelCategoryProductView> {
  final ScrollController _productScrollController = ScrollController();
  final ScrollController _categoryScrollController = ScrollController();
  final FirestoreProductRepository _productRepository = FirestoreProductRepository();
  final SharedCategoryService _categoryService = GetIt.instance<SharedCategoryService>();
  
  int _selectedCategoryIndex = 0;
  final Map<int, double> _categoryOffsets = {};
  late Category _selectedCategory;
  
  // Keep track of products for each category
  final Map<String, List<ProductModel>> _categoryProducts = {};
  
  // Keep track of loading state for each category
  final Map<String, bool> _isLoadingCategory = {};
  
  // Keep track of visibility for each category section in the scrolling view
  final Map<String, bool> _isCategoryVisible = {};
  
  // Keep track of whether categories have been initially loaded
  final Map<String, bool> _isCategoryInitiallyLoaded = {};
  
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
    super.dispose();
  }
  
  /// Load products for a specific category from Firestore
  Future<void> _loadProductsForCategory(Category category) async {
    final categoryId = category.id;
    
    // Skip if already loading or loaded
    if (_isLoadingCategory[categoryId] == true || 
        (_categoryProducts[categoryId]?.isNotEmpty ?? false)) {
      return;
    }
    
    try {
      setState(() {
        _isLoadingCategory[categoryId] = true;
      });
      
      LoggingService.logFirestore('TWOPANEL: Loading products for category: $categoryId');
      print('TWOPANEL: Loading products for category: $categoryId');
      
      // Get category group info from shared service
      final categoryParts = categoryId.split('_');
      String? categoryGroup;
      
      if (categoryParts.isNotEmpty) {
        // Try exact match first
        categoryGroup = await _getCategoryGroupForItem(categoryId);
        
        // If not found, try using just the first part of the ID
        if (categoryGroup == null && categoryParts.length > 1) {
          categoryGroup = categoryParts[0];
        }
      }
      
      if (categoryGroup == null) {
        LoggingService.logError('TWOPANEL', 'Could not determine category group for: $categoryId');
        print('TWOPANEL ERROR: Could not determine category group for: $categoryId');
        
        setState(() {
          _isLoadingCategory[categoryId] = false;
          _categoryProducts[categoryId] = [];
          _isCategoryInitiallyLoaded[categoryId] = true;
        });
        return;
      }
      
      // Load products from Firestore
      final products = await _productRepository.fetchProductsByCategory(
        categoryGroup: categoryGroup,
        categoryItem: categoryId,
      );
      
      // Update state with loaded products
      if (mounted) {
        setState(() {
          _categoryProducts[categoryId] = products;
          _isLoadingCategory[categoryId] = false;
          _isCategoryInitiallyLoaded[categoryId] = true;
        });
      }
      
      LoggingService.logFirestore('TWOPANEL: Loaded ${products.length} products for category: $categoryId');
      print('TWOPANEL: Loaded ${products.length} products for category: $categoryId');
    } catch (e) {
      LoggingService.logError('TWOPANEL', 'Error loading products for category $categoryId: $e');
      print('TWOPANEL ERROR: Failed to load products for category $categoryId: $e');
      
      if (mounted) {
        setState(() {
          _isLoadingCategory[categoryId] = false;
          _categoryProducts[categoryId] = [];
          _isCategoryInitiallyLoaded[categoryId] = true;
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
                                  ? backgroundColor.withOpacity(0.8)
                                  : backgroundColor.withOpacity(0.4),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.accentColor
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 30.w,
                                height: 30.w,
                                child: Image.network(
                                  category.image,
                                  color: isSelected
                                      ? Colors.black.withOpacity(0.7)
                                      : Colors.white,
                                  errorBuilder: (context, error, stackTrace) {
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
          bottom: 80.h,
          right: 16.w,
          child: BackToTopButton.scrollAware(
            scrollController: _productScrollController,
            onTap: _scrollToTop,
            showAtOffset: 500.0,
          ),
        ),
        
        // Cart FAB - Always create it regardless of item count
        Positioned(
          bottom: 16.h,
          left: 0,
          right: 0,
          child: Center(
            child: CartFAB(
              itemCount: widget.cartItemCount,
              totalAmount: widget.totalAmount,
              onTap: widget.onCartTap,
              previewImagePath: widget.cartPreviewImage,
            ),
          ),
        ),
      ],
    );
  }
  
  /// Build loading placeholder for products
  Widget _buildLoadingProductsGrid() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
      ),
      itemCount: 4, // Show 4 loading placeholders
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              Container(
                height: 120.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8.r),
                    topRight: Radius.circular(8.r),
                  ),
                ),
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
              
              // Content placeholders
              Padding(
                padding: EdgeInsets.all(8.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 12.h,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      width: 80.w,
                      height: 12.h,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Container(
                      width: double.infinity,
                      height: 32.h,
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
        childAspectRatio: 0.68,
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
        );
        
        return UniversalProductCard(
          product: productEntity,
          onTap: () => widget.onProductTap(productEntity),
          quantity: quantity,
          backgroundColor: backgroundColor,
          useBackgroundColor: backgroundColor != Colors.transparent,
        );
      },
    );
  }
}