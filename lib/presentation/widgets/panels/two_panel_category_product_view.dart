import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/product.dart';
import '../buttons/back_to_top_button.dart';
import '../buttons/cart_fab.dart';
import '../cards/smart_product_card.dart';
import '../../../services/cart/universal/universal_cart_service.dart';

/// A two-panel layout with categories on the left and products on the right
class TwoPanelCategoryProductView extends StatefulWidget {
  final List<Category> categories;
  final Map<String, List<String>> categoryProductIds; // Changed to store product IDs only
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
    required this.categoryProductIds, // Changed parameter
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
              width: 110.w, // Slightly wider for better visibility
              child: ListView.builder(
                controller: _categoryScrollController,
                itemCount: widget.categories.length,
                padding: EdgeInsets.symmetric(vertical: 20.h),
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
                        vertical: 16.h,
                        horizontal: 8.w,
                      ),
                      child: Column(
                        children: [
                          // Category icon
                          Container(
                            width: 60.w,
                            height: 60.w,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? backgroundColor.withOpacity(0.8)
                                  : backgroundColor.withOpacity(0.4),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.accentColor
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 36.w,
                                height: 36.w,
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
                                      size: 28.w,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 12.h),
                          
                          // Category name
                          Text(
                            category.name,
                            style: TextStyle(
                              color: isSelected
                                  ? AppTheme.accentColor
                                  : Colors.white,
                              fontSize: 13.sp,
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
                              margin: EdgeInsets.only(top: 10.h),
                              width: 36.w,
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
                          final productIds = widget.categoryProductIds[category.id] ?? [];
                          
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
                                padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 8.h),
                                child: Text(
                                  category.name,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              
                              // Product count
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20.w),
                                child: Text(
                                  '${productIds.length} products available',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 13.sp,
                                  ),
                                ),
                              ),
                              
                              SizedBox(height: 16.h),
                              
                              // Products grid - Using Smart Product Cards
                              if (productIds.isEmpty)
                                Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(20.h),
                                    child: Text(
                                      'No products available',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                _buildProductGrid(productIds, category.id),
                              
                              SizedBox(height: 20.h),
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
  
  // Build a grid of smart product cards
  Widget _buildProductGrid(List<String> productIds, String categoryId) {
    // Get the background color for this category
    final Color? categoryColor = widget.subcategoryColors?[categoryId];
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.w,
          mainAxisSpacing: 16.h,
          childAspectRatio: 0.7, // Better aspect ratio for product cards
        ),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: productIds.length,
        itemBuilder: (context, index) {
          final productId = productIds[index];
          final quantity = widget.cartQuantities[productId] ?? 0;
          
          return SmartProductCard(
            productId: productId,
            onTap: widget.onProductTap,
            onQuantityChanged: widget.onQuantityChanged,
            quantity: quantity,
            backgroundColor: categoryColor,
          );
        },
      ),
    );
  }
}