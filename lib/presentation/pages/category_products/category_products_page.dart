import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/repositories/cart_repository.dart';
import '../../../services/simple_cart_service.dart';
import '../../../services/logging_service.dart';
// import '../product_details/product_details_page.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/cart/cart_event.dart';
import '../../blocs/cart/cart_state.dart';
import '../../blocs/category_products/category_products_bloc.dart';
import '../../widgets/loaders/shimmer_loader.dart';
import '../../widgets/panels/two_panel_category_product_view.dart';
import '../../pages/cart/cart_page.dart';

class CategoryProductsPage extends StatelessWidget {
  final String? categoryId;

  const CategoryProductsPage({
    Key? key,
    this.categoryId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Try to access the CartBloc - if not available, provide it
    CartBloc? cartBloc;
    try {
      cartBloc = BlocProvider.of<CartBloc>(context, listen: false);
    } catch (_) {
      // No CartBloc found
    }
    
    if (cartBloc == null) {
      return BlocProvider(
        create: (context) => CartBloc(
          cartRepository: GetIt.instance<CartRepository>(),
          simpleCartService: GetIt.instance<SimpleCartService>(),
        )..add(const LoadCart()),
        child: _buildMainContent(context),
      );
    } else {
      return _buildMainContent(context);
    }
  }
  
  Widget _buildMainContent(BuildContext context) {
    return BlocProvider(
      create: (context) => CategoryProductsBloc()
        ..add(LoadCategoryProducts(categoryId: categoryId)),
      child: BlocListener<CategoryProductsBloc, CategoryProductsState>(
        listener: (context, state) {
          // When state changes, check if a product was added to show feedback
          if (state is CategoryProductsLoaded && state.lastAddedProduct != null) {
            String cartMessage = "Product '${state.lastAddedProduct!.name}' added to cart";
            
            // Show a snackbar message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ $cartMessage'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: AppTheme.primaryColor,
          appBar: AppBar(
            backgroundColor: AppTheme.primaryColor,
            title: _buildAppBarTitle(),
            elevation: 0,
            actions: _buildAppBarActions(),
          ),
          body: SafeArea(
            child: BlocBuilder<CategoryProductsBloc, CategoryProductsState>(
              builder: (context, state) {
                if (state is CategoryProductsInitial || state is CategoryProductsLoading) {
                  return _buildLoadingState();
                } else if (state is CategoryProductsLoaded) {
                  return _buildLoadedState(context, state);
                } else if (state is CategoryProductsError) {
                  return _buildErrorState(context, state);
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBarTitle() {
    return BlocBuilder<CategoryProductsBloc, CategoryProductsState>(
      builder: (context, state) {
        // Always set to "All Categories" since we now show all categories across groups
        String title = "All Categories";
        
        // Map category ID to display title if provided
        if (categoryId != null) {
          final Map<String, String> categoryTitles = {
            'grocery_kitchen': 'Grocery & Kitchen',
            'snacks_drinks': 'Snacks & Drinks',
            'beauty_personal_care': 'Beauty & Personal Care',
            'fruits_vegetables': 'Fruits & Vegetables',
            'dairy_bread': 'Dairy, Bread & Eggs',
            'bakeries_biscuits': 'Bakery & Biscuits',
          };
          
          title = categoryTitles[categoryId] ?? 'All Categories';
        }
        
        return Row(
          children: [
            const Icon(
              Icons.shopping_basket_outlined,
              color: AppTheme.accentColor,
            ),
            SizedBox(width: 8.w),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildAppBarActions() {
    return [
      IconButton(
        icon: const Icon(
          Icons.search,
          color: Colors.white,
        ),
        onPressed: () {
          // Search functionality
        },
      ),
      IconButton(
        icon: const Icon(
          Icons.filter_list,
          color: Colors.white,
        ),
        onPressed: () {
          // Filter functionality
        },
      ),
    ];
  }

  Widget _buildLoadingState() {
    return ShimmerLoader.withChild(
      Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left panel shimmer
            SizedBox(
              width: 100.w,
              child: ListView.builder(
                itemCount: 8,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                itemBuilder: (context, index) {
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 8.h),
                    padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
                    child: Column(
                      children: [
                        Container(
                          width: 50.w,
                          height: 50.w,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          width: 60.w,
                          height: 12.h,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Right panel shimmer
            Expanded(
              child: ListView.builder(
                itemCount: 3,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                itemBuilder: (context, index) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                        width: 120.w,
                        height: 18.h,
                        color: Colors.white,
                      ),
                      GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.68,
                          crossAxisSpacing: 12.w,
                          mainAxisSpacing: 12.h,
                        ),
                        itemCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        itemBuilder: (context, index) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  height: 120.h,
                                  color: Colors.white,
                                ),
                                SizedBox(height: 8.h),
                                Container(
                                  margin: EdgeInsets.symmetric(horizontal: 8.w),
                                  height: 16.h,
                                  color: Colors.white,
                                ),
                                SizedBox(height: 4.h),
                                Container(
                                  margin: EdgeInsets.symmetric(horizontal: 8.w),
                                  height: 14.h,
                                  width: 80.w,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedState(BuildContext context, CategoryProductsLoaded state) {
    LoggingService.logFirestore('CATEGORY_PAGE: Building loaded state with ${state.categories.length} categories');
    
    return Column(
      children: [
        // Search bar
        Padding(
          padding: EdgeInsets.all(16.w),
          child: TextField(
            decoration: InputDecoration(
              filled: true,
              fillColor: AppTheme.secondaryColor,
              hintText: 'Search products',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14.sp,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.white.withOpacity(0.5),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                vertical: 12.h,
                horizontal: 16.w,
              ),
            ),
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
            ),
            cursorColor: AppTheme.accentColor,
            onChanged: (query) {
              // Search functionality
            },
          ),
        ),
        
        // Category-Product two panel view
        Expanded(
          child: BlocBuilder<CartBloc, CartState>(
            builder: (context, cartState) {
              return TwoPanelCategoryProductView(
                categories: state.categories,
                onCategoryTap: (category) {
                  context.read<CategoryProductsBloc>().add(SelectCategory(category));
                },
                onProductTap: (product) {
                  // Navigate to product details
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => ProductDetailsPage(
                  //       productId: product.id,
                  //       categoryId: product.categoryId, // Use product's categoryId to preserve color
                  //     ),
                  //   ),
                  // );
                },
                onQuantityChanged: (product, quantity) {
                  // Add to CategoryProductsBloc for local state
                  context.read<CategoryProductsBloc>().add(
                    UpdateCartQuantity(
                      product: product,
                      quantity: quantity,
                    ),
                  );
                  
                  // Also add to CartBloc for global cart state
                  if (quantity > 0) {
                    context.read<CartBloc>().add(AddToCart(product, quantity));
                  } else {
                    context.read<CartBloc>().add(RemoveFromCart(product.id));
                  }
                },
                cartQuantities: state.cartQuantities,
                cartItemCount: cartState.itemCount ?? 0, // Use the CartBloc's item count with null safety
                totalAmount: cartState.total ?? 0.0, // Use the CartBloc's total with null safety
                onCartTap: () {
                  // Navigate to cart using direct navigation instead of named route
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CartPage()),
                  );
                },
                cartPreviewImage: (cartState.itemCount ?? 0) > 0 && state.categoryProducts.isNotEmpty
                    ? _getCartPreviewImage(state)
                    : null,
                subcategoryColors: state.subcategoryColors,
              );
            },
          ),
        ),
      ],
    );
  }

  // Helper method to safely get a cart preview image
  String _getCartPreviewImage(CategoryProductsLoaded state) {
    try {
      // First try to find a product that's in the cart
      if (state.categoryProducts.values.isNotEmpty) {
        final allProducts = state.categoryProducts.values.expand((products) => products).toList();
        
        if (allProducts.isNotEmpty) {
          // Look for a product in the cart
          final cartProduct = allProducts.firstWhere(
            (product) => state.cartQuantities.containsKey(product.id),
            orElse: () => allProducts.first, // Fallback to first product if none in cart
          );
          
          return cartProduct.image;
        }
      }
      
      // If we can't find any valid product, return a default image
      return 'assets/images/categories/vegetables.png';
    } catch (e) {
      // Return a default image in case of any error
      LoggingService.logError('CATEGORY_PAGE', 'Error getting cart preview image: $e');
      return 'assets/images/categories/vegetables.png';
    }
  }

  Widget _buildErrorState(BuildContext context, CategoryProductsError state) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64.w,
            ),
            SizedBox(height: 16.h),
            Text(
              'Error',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              state.message,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () {
                BlocProvider.of<CategoryProductsBloc>(context).add(
                  LoadCategoryProducts(categoryId: categoryId),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                  vertical: 12.h,
                ),
              ),
              child: Text(
                'Retry',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}