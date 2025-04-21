import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../domain/repositories/cart_repository.dart';
import '../../../../services/cart/cart_sync_service.dart';
import '../../../../services/firestore/firestore_product_service.dart';
import '../../../../utils/test/firestore_test_data_sync.dart';
import '../../../blocs/cart/cart_bloc.dart';
import '../../../blocs/cart/cart_event.dart';
import '../../../blocs/cart/cart_state.dart';
import '../../../blocs/category_products/category_products_bloc.dart';
import '../../../blocs/category_products/firestore_category_products_bloc.dart';
import '../../../widgets/loaders/shimmer_loader.dart';
import '../../../widgets/panels/two_panel_category_product_view.dart';
import '../../product_details/product_details_page.dart';

class FirestoreCategoryProductsPage extends StatelessWidget {
  final String? categoryId;

  const FirestoreCategoryProductsPage({
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
          cartSyncService: GetIt.instance<CartSyncService>(),
        )..add(const LoadCart()),
        child: _buildMainContent(context),
      );
    } else {
      return _buildMainContent(context);
    }
  }
  
  Widget _buildMainContent(BuildContext context) {
    return BlocProvider(
      create: (context) => FirestoreCategoryProductsBloc(
        firestoreService: GetIt.instance<FirestoreProductService>(),
      )..add(LoadCategoryProducts(categoryId: categoryId)),
      child: BlocListener<FirestoreCategoryProductsBloc, CategoryProductsState>(
        listener: (context, state) {
          // When state changes, check if a product was added to show feedback
          if (state is CategoryProductsLoaded && state.lastAddedProduct != null) {
            String cartMessage = "${state.lastAddedProduct!.name} added to cart";
            
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
            actions: _buildAppBarActions(context),
          ),
          body: SafeArea(
            child: BlocBuilder<FirestoreCategoryProductsBloc, CategoryProductsState>(
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
    return BlocBuilder<FirestoreCategoryProductsBloc, CategoryProductsState>(
      builder: (context, state) {
        String title = categoryId != null ? 'All Categories' : 'Browse Products';
        
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
        } else {
          title = 'Bakery & Biscuits'; // Default to show we're in bakery section
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

  List<Widget> _buildAppBarActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(
          Icons.search,
          color: Colors.white,
        ),
        onPressed: () {
          // Implement search
        },
      ),
      IconButton(
        icon: const Icon(
          Icons.filter_list,
          color: Colors.white,
        ),
        onPressed: () {
          // Implement filter
        },
      ),
      IconButton(
        icon: const Icon(
          Icons.sync,
          color: Colors.white,
        ),
        onPressed: () {
          _syncTestData(context);
        },
        tooltip: 'Sync test data to Firestore',
      ),
    ];
  }
  
  // Sync test data to Firestore
  void _syncTestData(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.secondaryColor,
          title: Text(
            'Syncing Data',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: AppTheme.accentColor,
              ),
              SizedBox(height: 16.h),
              Text(
                'Syncing test data to Firestore...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
      
      // Initialize FirestoreTestDataSync
      final testDataSync = FirestoreTestDataSync();
      
      // Sync data
      await testDataSync.syncBakeriesBiscuitsCategory();
      
      // Close dialog
      Navigator.pop(context);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data synced successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Reload data
      context.read<FirestoreCategoryProductsBloc>().add(
        LoadCategoryProducts(categoryId: categoryId),
      );
      
    } catch (e) {
      // Close dialog if open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error syncing data: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
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
                          decoration: const BoxDecoration(
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
              // Implement search
            },
          ),
        ),
        
        // Category-Product two panel view
        Expanded(
          child: BlocBuilder<CartBloc, CartState>(
            builder: (context, cartState) {
              return TwoPanelCategoryProductView(
                categories: state.categories,
                categoryProducts: state.categoryProducts,
                onCategoryTap: (category) {
                  context.read<FirestoreCategoryProductsBloc>().add(SelectCategory(category));
                },
                onProductTap: (product) {
                  // Navigate to product details
                  Navigator.pushNamed(
                    context,
                    AppConstants.productDetailsRoute,
                    arguments: {
                      'productId': product.id,
                      'categoryId': product.categoryId,
                    },
                  );
                },
                onQuantityChanged: (product, quantity) {
                  // Add to CategoryProductsBloc for local state
                  context.read<FirestoreCategoryProductsBloc>().add(
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
                  
                  // Show manual snackbar feedback
                  String cartMessage = "Product '${product.name}' added to cart";
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ $cartMessage'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                cartQuantities: state.cartQuantities,
                cartItemCount: cartState.itemCount ?? 0, // Use the CartBloc's item count with null safety
                totalAmount: cartState.total ?? 0.0, // Use the CartBloc's total with null safety
                onCartTap: () {
                  // Navigate to cart using proper route constant
                  Navigator.pushNamed(context, AppConstants.cartRoute);
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
                BlocProvider.of<FirestoreCategoryProductsBloc>(context).add(
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