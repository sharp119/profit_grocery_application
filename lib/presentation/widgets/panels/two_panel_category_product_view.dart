import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/product.dart';
import '../buttons/back_to_top_button.dart';
import '../buttons/cart_fab.dart';
import '../grids/product_grid.dart';

/// A two-panel layout with categories on the left and products on the right
/// Supports synchronized scrolling between category selection and product display
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
  }) : super(key: key);

  @override
  State<TwoPanelCategoryProductView> createState() => _TwoPanelCategoryProductViewState();
}

class _TwoPanelCategoryProductViewState extends State<TwoPanelCategoryProductView> {
  final ScrollController _productScrollController = ScrollController();
  int _selectedCategoryIndex = 0;
  final Map<int, double> _categoryOffsets = {};
  late Category _selectedCategory;
  bool _initialScrollDone = false;
  
  @override
  void initState() {
    super.initState();
    
    // Listen to scroll events to highlight the correct category
    _productScrollController.addListener(_onProductScroll);
    
    // Find selected category from widget if available
    _initializeSelectedCategory();
  }
  
  void _initializeSelectedCategory() {
    if (widget.categories.isEmpty) return;
    
    // Find the selected category by looking at the BLoC state
    // If a category is already selected from the BLoC, use that one
    // This is important for deep linking and navigation
    final selectedCategoryId = widget.categories.indexWhere(
      (category) => widget.categoryProducts[category.id]?.isNotEmpty == true
    );
    
    if (selectedCategoryId >= 0) {
      _selectedCategoryIndex = selectedCategoryId;
      _selectedCategory = widget.categories[selectedCategoryId];
    } else {
      // Otherwise, start with the first category
      _selectedCategory = widget.categories.first;
    }
  }
  
  @override
  void didUpdateWidget(TwoPanelCategoryProductView oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // When the widget updates with different categories (like after loading data),
    // we need to find the initially selected category again
    if (oldWidget.categories != widget.categories) {
      _initializeSelectedCategory();
      
      // If we haven't done our initial scroll and we have category offsets,
      // scroll to the selected category
      if (!_initialScrollDone && _categoryOffsets.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToCategory(_selectedCategoryIndex);
          _initialScrollDone = true;
        });
      }
    }
  }
  
  @override
  void dispose() {
    _productScrollController.removeListener(_onProductScroll);
    _productScrollController.dispose();
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
      
      // Notify parent about category change without scrolling again
      // This ensures the app bar title and other UI elements update
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onCategoryTap(widget.categories[newSelectedIndex]);
      });
    }
  }
  
  /// Scroll to a specific category when selected from the left panel
  void _scrollToCategory(int index) {
    if (_categoryOffsets.containsKey(index) && _productScrollController.hasClients) {
      // Offset slightly to ensure the header is visible
      final offset = (_categoryOffsets[index]! > 10) ? _categoryOffsets[index]! - 10 : 0.0;
      
      // Animate to the category position with a smoother animation
      _productScrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
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
                itemCount: widget.categories.length,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                itemBuilder: (context, index) {
                  final category = widget.categories[index];
                  final isSelected = index == _selectedCategoryIndex;
                  
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
                          // Category icon with improved visual indicator
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Enhanced selection background
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 50.w,
                                height: 50.w,
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? LinearGradient(
                                          colors: [
                                            AppTheme.accentColor.withOpacity(0.2),
                                            AppTheme.accentColor.withOpacity(0.05),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  color: isSelected
                                      ? null
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.accentColor
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: AppTheme.accentColor.withOpacity(0.3),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                              
                              // Icon within container
                              SizedBox(
                                width: 30.w,
                                height: 30.w,
                                child: Image.asset(
                                  category.icon ?? category.image,
                                  color: isSelected
                                      ? AppTheme.accentColor
                                      : Colors.white,
                                  errorBuilder: (context, error, stackTrace) {
                                    // Fallback for missing images
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
                            ],
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
                          
                          // Enhanced selection indicator
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: EdgeInsets.only(top: 8.h),
                            width: isSelected ? 30.w : 0,
                            height: 3.h,
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor,
                              borderRadius: BorderRadius.circular(1.5.r),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.accentColor.withOpacity(0.5),
                                        blurRadius: 4,
                                        spreadRadius: 0,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Right panel: Product grid by category
            Expanded(
              child: CustomScrollView(
                controller: _productScrollController,
                slivers: [
                  // For each category, show a header and its products
                  for (int i = 0; i < widget.categories.length; i++)
                    SliverToBoxAdapter(
                      child: Builder(
                        builder: (context) {
                          final category = widget.categories[i];
                          final products = widget.categoryProducts[category.id] ?? [];
                          
                          // Store the offset of this category section
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                          final renderBox = context.findRenderObject() as RenderBox?;
                          if (renderBox != null && _productScrollController.hasClients) {
                          // Calculate position relative to scroll position rather than global position
                          // This is more accurate for determining scroll offsets
                          _categoryOffsets[i] = renderBox.localToGlobal(Offset.zero).dy -
                                AppBar().preferredSize.height -
                                  MediaQuery.of(context).padding.top +
          _productScrollController.offset;
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
                              
                              // Product grid for this category
                              if (products.isNotEmpty)
                                ProductGrid(
                                  products: products,
                                  onProductTap: widget.onProductTap,
                                  onQuantityChanged: widget.onQuantityChanged,
                                  cartQuantities: widget.cartQuantities,
                                  crossAxisCount: 2,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                                )
                              else
                                Padding(
                                  padding: EdgeInsets.all(16.w),
                                  child: Center(
                                    child: Text(
                                      'No products available in this category',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ),
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
        
        // Cart FAB
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