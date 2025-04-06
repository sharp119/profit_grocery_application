import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';

import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/product.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/cart/cart_state.dart' as cart_state;
import '../../blocs/cart/cart_event.dart';
import '../../blocs/category_products/category_products_bloc.dart';
import '../../blocs/category_products/category_products_event.dart';
import '../../blocs/category_products/category_products_state.dart';
import '../../widgets/base_layout.dart';
import '../../widgets/loaders/shimmer_loader.dart';
import '../../widgets/panels/two_panel_category_product_view.dart';
import '../product_details/product_details_page.dart';

class CategoryProductsPage extends StatefulWidget {
  final String? initialCategoryId;
  final String? title;

  const CategoryProductsPage({
    Key? key,
    this.initialCategoryId,
    this.title,
  }) : super(key: key);

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  /// Find TwoPanelCategoryProductView in the widget tree
  /// Since we can't access the private state directly, we'll work with the public API
  TwoPanelCategoryProductView? findTwoPanelCategoryProductView(BuildContext context) {
    TwoPanelCategoryProductView? result;
    
    void visitor(Element element) {
      if (element.widget is TwoPanelCategoryProductView) {
        result = element.widget as TwoPanelCategoryProductView;
        return;
      }
      element.visitChildren(visitor);
    }
    
    context.visitChildElements(visitor);
    return result;
  }
  String? _currentTitle;

  @override
  void initState() {
    super.initState();
    
    // Initial title
    _currentTitle = widget.title ?? 'Categories';
    
    // Load all categories and products from the BlocProvider
    // NOTE: We now use the bloc from the BlocProvider instead of from GetIt directly
    Future.delayed(Duration.zero, () {
      final categoryProductsBloc = context.read<CategoryProductsBloc>();
      categoryProductsBloc.add(const LoadCategoriesAndProducts());
      
      // Set initial category if provided
      if (widget.initialCategoryId != null && widget.initialCategoryId!.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 100), () {
          categoryProductsBloc.add(SelectCategory(widget.initialCategoryId!));
          
          // Second delay for ensuring UI updates after selection
          Future.delayed(const Duration(milliseconds: 300), () {
            categoryProductsBloc.add(const RefreshCategoryView());
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTitle!),
        actions: [
          // Filter button
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showFilterDialog,
          ),
        ],
      ),

      body: BlocConsumer<CategoryProductsBloc, CategoryProductsState>(
        listener: (context, state) {
        // Update title when selected category changes
        if (state is CategoryProductsLoaded && state.selectedCategory != null) {
        setState(() {
        _currentTitle = state.selectedCategory!.name;
        });
          
          // If we have an initial category ID and this is the first load with the selected category,
          // we've already set it in the bloc, so no need to do anything more here.
          // The TwoPanelCategoryProductView will pick up the selected category from the state.
        }
      },
        builder: (context, state) {
          // Show loading state
          if (state is CategoryProductsInitial || state is CategoryProductsLoading) {
            return ShimmerLoader(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.w,
                  mainAxisSpacing: 16.h,
                  childAspectRatio: 0.7,
                ),
                itemCount: 10,
                padding: EdgeInsets.all(16.w),
                itemBuilder: (context, index) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            );
          }
          
          // Show error state
          if (state is CategoryProductsError) {
            return Center(
              child: Text(
                state.message,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                ),
              ),
            );
          }
          
          // Show loaded state
          if (state is CategoryProductsLoaded) {
            // Get cart data from cart bloc
            return BlocBuilder<CartBloc, cart_state.CartState>(
              builder: (context, cartState) {
                // Get cart quantities and total
                final cartQuantities = _getCartQuantities(cartState);
                final cartItemCount = _getCartItemCount(cartState);
                final totalAmount = _getTotalAmount(cartState);
                final cartPreviewImage = _getCartPreviewImage(cartState);
                
                return TwoPanelCategoryProductView(
                  categories: state.categories,
                  categoryProducts: state.filteredCategoryProducts,
                  onCategoryTap: (category) {
                    context.read<CategoryProductsBloc>().add(SelectCategory(category.id));
                  },
                  onProductTap: (product) {
                    _navigateToProductDetails(product);
                  },
                  onQuantityChanged: (product, quantity) {
                    _updateCartQuantity(product, quantity);
                  },
                  cartQuantities: cartQuantities,
                  cartItemCount: cartItemCount,
                  totalAmount: totalAmount,
                  onCartTap: _navigateToCart,
                  cartPreviewImage: cartPreviewImage,
                );
              },
            );
          }
          
          // Fallback
          return const Center(
            child: Text(
              'Something went wrong',
              style: TextStyle(color: Colors.white),
            ),
          );
        },
      ),
    );
  }

  /// Show filter dialog for sorting and filtering products
  void _showFilterDialog() {
    final categoryProductsBloc = context.read<CategoryProductsBloc>();
    final state = categoryProductsBloc.state;
    if (state is! CategoryProductsLoaded) return;
    
    String? selectedPriceSort = state.priceSort;
    bool? filterInStock = state.filterInStock;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppTheme.primaryColor,
            title: Text(
              'Filter Products',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price sorting
                Text(
                  'Sort by Price',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Radio<String?>(
                      value: 'high_to_low',
                      groupValue: selectedPriceSort,
                      onChanged: (value) {
                        setState(() => selectedPriceSort = value);
                      },
                      activeColor: AppTheme.accentColor,
                    ),
                    Text(
                      'High to Low',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Radio<String?>(
                      value: 'low_to_high',
                      groupValue: selectedPriceSort,
                      onChanged: (value) {
                        setState(() => selectedPriceSort = value);
                      },
                      activeColor: AppTheme.accentColor,
                    ),
                    Text(
                      'Low to High',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Radio<String?>(
                      value: null,
                      groupValue: selectedPriceSort,
                      onChanged: (value) {
                        setState(() => selectedPriceSort = value);
                      },
                      activeColor: AppTheme.accentColor,
                    ),
                    Text(
                      'No Sorting',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 16.h),
                
                // Availability filter
                Text(
                  'Availability',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Checkbox(
                      value: filterInStock ?? false,
                      onChanged: (value) {
                        setState(() => filterInStock = value);
                      },
                      activeColor: AppTheme.accentColor,
                    ),
                    Text(
                      'Show only in-stock items',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              // Reset button
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.read<CategoryProductsBloc>().add(const ResetFilters());
                },
                child: Text(
                  'Reset',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14.sp,
                  ),
                ),
              ),
              
              // Apply button
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.read<CategoryProductsBloc>().add(FilterProducts(
                    priceSort: selectedPriceSort,
                    filterInStock: filterInStock,
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                ),
                child: Text(
                  'Apply',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Navigate to product details page
  void _navigateToProductDetails(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductDetailsPage(
          productId: product.id,
        ),
      ),
    );
  }

  /// Navigate to cart page
  void _navigateToCart() {
    Navigator.of(context).pushNamed('/cart');
  }

  /// Get cart quantities from cart state
  Map<String, int> _getCartQuantities(cart_state.CartState cartState) {
    if (cartState.status == cart_state.CartStatus.loaded) {
      return cartState.items.fold<Map<String, int>>({}, (map, item) {
        map[item.productId] = item.quantity;
        return map;
      });
    }
    return {};
  }

  /// Get total cart items count
  int _getCartItemCount(cart_state.CartState cartState) {
    if (cartState.status == cart_state.CartStatus.loaded) {
      return cartState.itemCount;
    }
    return 0;
  }

  /// Get total cart amount
  double? _getTotalAmount(cart_state.CartState cartState) {
    if (cartState.status == cart_state.CartStatus.loaded) {
      return cartState.total;
    }
    return null;
  }

  /// Get preview image of first cart item
  String? _getCartPreviewImage(cart_state.CartState cartState) {
    if (cartState.status == cart_state.CartStatus.loaded && cartState.items.isNotEmpty) {
      return cartState.items.first.image;
    }
    return null;
  }

  /// Update product quantity in cart
  void _updateCartQuantity(Product product, int quantity) {
    final cartBloc = context.read<CartBloc>();
    
    if (quantity > 0) {
      cartBloc.add(UpdateCartItemQuantity(product.id, quantity));
    } else {
      cartBloc.add(RemoveFromCart(product.id));
    }
  }
}
