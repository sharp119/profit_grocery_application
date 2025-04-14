import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/product.dart';
import '../buttons/back_to_top_button.dart';
import '../buttons/cart_fab.dart';
import '../grids/product_grid.dart';
import '../../../services/cart/universal/universal_cart_service.dart';

/// A two-panel layout with categories on the left and products on the right
class TwoPanelCategoryProductView extends StatefulWidget {
  final List<Category> categories;
  final Map<String, List<Product>> categoryProducts;
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
    required this.categoryProducts,
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
  int _selectedCategoryIndex = 0;
  final Map<int, double> _categoryOffsets = {};
  late Category _selectedCategory;
  
  @override
  void initState() {
    super.initState();
    
    // Start with the first category selected
    if (widget.categories.isNotEmpty) {
      _selectedCategory = widget.categories.first;
    }
    
    // Listen to scroll events to highlight the correct category
    _productScrollController.addListener(_onProductScroll);
  }
  
  @override
  void dispose() {
    _productScrollController.removeListener(_onProductScroll);
    _productScrollController.dispose();
    _categoryScrollController.dispose();
    super.dispose();
  }
  
  /// Handle scroll events to update selected category based on scroll position
  void _onProductScroll() {
    if (_categoryOffsets.isEmpty || !_productScrollController.hasClients) return;
    
    final currentOffset = _productScrollController.offset;
    
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
                                child: Image.asset(
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
            
            // Right panel: Products for selected category
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
                          final products = widget.categoryProducts[category.id] ?? [];
                          
                          // Store the offset of this category section
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            final renderBox = context.findRenderObject() as RenderBox?;
                            if (renderBox != null) {
                              _categoryOffsets[i] = renderBox.localToGlobal(Offset.zero).dy -
                                  AppBar().preferredSize.height -
                                  MediaQuery.of(context).padding.top;
                            }
                          });
                          
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
                              
                              // Product count
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                child: Text(
                                  '${products.length} products available',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                              
                              SizedBox(height: 8.h),
                              
                              // Products grid - Using the same grid widget with consistent behavior
                              ProductGrid(
                                products: products,
                                onProductTap: widget.onProductTap,
                                // We still need to provide this for backward compatibility,
                                // but the universal card will use the centralized service
                                onQuantityChanged: widget.onQuantityChanged,
                                cartQuantities: widget.cartQuantities,
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                subCategoryColors: widget.subcategoryColors,
                              ),
                              
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
        // The CartFAB component itself will handle visibility
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
}