import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:profit_grocery_application/core/errors/global_error_handler.dart';
import 'package:profit_grocery_application/main.dart';
import 'package:profit_grocery_application/presentation/blocs/cart/cart_bloc.dart';
import 'package:profit_grocery_application/presentation/blocs/cart/cart_state.dart';
import 'package:profit_grocery_application/presentation/blocs/cart/cart_event.dart';
import 'package:profit_grocery_application/presentation/blocs/user/user_bloc.dart';
import 'package:profit_grocery_application/presentation/blocs/user/user_event.dart';
import 'package:profit_grocery_application/presentation/widgets/cards/promotional_category_card.dart';
import 'package:profit_grocery_application/presentation/widgets/profile/profile_completion_banner.dart';
import 'package:profit_grocery_application/services/logging_service.dart';
import 'package:profit_grocery_application/utils/cart_logger.dart';
import 'package:profit_grocery_application/presentation/widgets/grids/rtdb_bestseller_grid.dart';
import 'package:profit_grocery_application/presentation/widgets/grids/horizontal_bestseller_grid.dart';
import 'package:profit_grocery_application/services/category/shared_category_service.dart';
import 'package:profit_grocery_application/presentation/widgets/search/custom_search_bar.dart';
import 'package:profit_grocery_application/presentation/pages/category_products/category_products_page.dart';
import 'package:profit_grocery_application/presentation/pages/revamped_two_panel_view.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/user.dart';
import '../../../services/user_service_interface.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/home/home_bloc.dart';
import '../../blocs/home/home_event.dart';
import '../../blocs/home/home_state.dart';
import '../../blocs/products/products_bloc.dart';
import '../../../data/models/product_model.dart';
import '../../blocs/products/products_event.dart';
import '../../blocs/products/products_state.dart';
import '../../widgets/banners/promotional_banner.dart';
import '../../widgets/base_layout.dart';
import '../../widgets/buttons/back_to_top_button.dart';
import '../../widgets/buttons/cart_fab.dart';
import '../../widgets/grids/category_grid_4x2.dart';
import '../../widgets/grids/dense_category_grid.dart';
import '../../widgets/grids/product_grid.dart';
import '../../widgets/grids/firebase_product_grid.dart';
import '../../widgets/loaders/shimmer_loader.dart';
import '../../widgets/section_header.dart';
import '../../widgets/tabs/horizontal_category_tabs.dart';
import '../cart/cart_page.dart';
import '../category_products/category_products_page.dart';
// import '../product_details/product_details_page.dart';
import '../../blocs/categories/categories_bloc.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/product/firestore_product_repository.dart';
import '../../../data/models/firestore/category_group_firestore_model.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => HomeBloc()..add(const LoadHomeData()),
        ),
        BlocProvider(
          create: (context) => CategoriesBloc(
            repository: CategoryRepository(),
          )..add(LoadCategories()),
        ),
      ],
      child: const _HomePageContent(),
    );
  }
}

class _HomePageContent extends StatefulWidget {
  const _HomePageContent();

  @override
  State<_HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<_HomePageContent> {
  final _scrollController = ScrollController();
  final _refreshKey = GlobalKey<RefreshIndicatorState>();
  
  // User data
  User? _currentUser;
  late final SharedCategoryService _sharedCategoryService;
  
  @override
  void initState() {
    super.initState();
    _sharedCategoryService = GetIt.instance<SharedCategoryService>();
    
    // Listen to UserBloc state changes
    try {
      // Try to get the current UserBloc and listen to its state
      final userBloc = context.read<UserBloc>();
      userBloc.stream.listen((state) {
        if (state.user != null && mounted) {
          setState(() {
            _currentUser = state.user;
            LoggingService.logFirestore('HomePage: User data updated from UserBloc: ${state.user?.name}');
          });
        }
      });
    } catch (e) {
      LoggingService.logError('HomePage', 'UserBloc not available: $e');
    }
    
    // Listen to CartBloc state changes to sync with HomeBloc
    try {
      final cartBloc = context.read<CartBloc>();
      final homeBloc = context.read<HomeBloc>();
      
      // Listen to CartBloc state changes to update HomeBloc
      cartBloc.stream.listen((state) {
        if (state.status == CartStatus.loaded && mounted) {
          // Update HomeBloc with cart data from CartBloc
          homeBloc.add(UpdateHomeCartData(
            cartQuantities: state.cartQuantities,
            cartItemCount: state.itemCount,
            cartTotalAmount: state.total,
            cartPreviewImage: state.previewImage,
          ));
        }
      });
    } catch (e) {
      LoggingService.logError('HomePage', 'Error syncing CartBloc with HomeBloc: $e');
    }
    
    // Add a short delay to allow the UI to build, then check if user data is loaded
    Future.delayed(Duration.zero, () {
      // User data loading and updates are now handled by UserBloc
      LoggingService.logFirestore('HomePage: Relying on UserBloc for user data.');
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onCategoryTap(Category category) {
    // Navigate to category products screen
    debugPrint('Tapped on category: ${category.name}');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryProductsPage(
          categoryId: category.id,
        ),
      ),
    );
  }
  
  void _onProductTap(Product product) {
    // Navigate to product details screen
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => ProductDetailsPage(productId: product.id),
    //   ),
    // );
  }

  void _handleAddToCart(Product product, int quantity) {
    try {
      final cartBloc = context.read<CartBloc>();
      final homeBloc = context.read<HomeBloc>();
      
      // Update cart through CartBloc
      if (quantity <= 0) {
        cartBloc.add(RemoveFromCart(product.id));
      } else {
        cartBloc.add(AddToCart(product, quantity));
      }
      
      // Update HomeBloc directly
      homeBloc.add(UpdateCartQuantity(product, quantity));
      
      // Show feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(quantity > 0 
            ? 'Added ${product.name} to cart' 
            : 'Removed ${product.name} from cart'
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      LoggingService.logError('HomePage', 'Error updating cart: $e');
    }
  }

  void _navigateToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CartPage()),
    );
  }

  Future<void> _refreshData() async {
    context.read<HomeBloc>().add(const RefreshHomeData());
    context.read<ProductsBloc>().add(const RefreshProducts());
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Navigate to profile page
  void _navigateToProfile() {
    Navigator.pushNamed(context, AppConstants.profileRoute);
  }
  
  // Navigate to orders page
  void _navigateToOrders() {
    Navigator.pushNamed(context, AppConstants.ordersRoute);
  }
  
  // Navigate to addresses page
  void _navigateToAddresses() {
    Navigator.pushNamed(context, AppConstants.addressesRoute);
  }

  // Show profile options menu
  void _showUserProfileOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.secondaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.accentColor.withOpacity(0.2),
                      radius: 30.r,
                      child: Icon(
                        Icons.person,
                        size: 30.r,
                        color: AppTheme.accentColor,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentUser?.name ?? 'User',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            _currentUser?.phoneNumber ?? '',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 24.h),
                
                // Options
                ListTile(
                  leading: Icon(Icons.person_outline, color: AppTheme.accentColor),
                  title: Text('My Profile', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to profile page
                    _navigateToProfile();
                  },
                ),
                
                ListTile(
                  leading: Icon(Icons.shopping_bag_outlined, color: AppTheme.accentColor),
                  title: Text('My Orders', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to orders page
                    _navigateToOrders();
                  },
                ),
                
                ListTile(
                  leading: Icon(Icons.location_on_outlined, color: AppTheme.accentColor),
                  title: Text('My Addresses', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to addresses page
                    _navigateToAddresses();
                  },
                ),
                
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.redAccent),
                  title: Text('Logout', style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmLogout(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Show Firestore Data Explorer
  // Show cached categories information without fetching from Firestore
  void _showCachedCategoriesInfo(BuildContext context) async {
    try {
      // Get the shared category service
      final categoryService = GetIt.instance<SharedCategoryService>();
      
      // Log the start of cache inspection
      LoggingService.logFirestore('CAT_CACHE_INSPECT: Starting inspection of cached categories');
      print('CAT_CACHE_INSPECT: Starting inspection of cached categories');
      
      // Check if we have all categories cached
      final categoriesCache = categoryService.getCachedCategories();
      
      if (categoriesCache.isEmpty) {
        LoggingService.logFirestore('CAT_CACHE_INSPECT: No categories in cache yet');
        print('CAT_CACHE_INSPECT: No categories in cache yet');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No categories found in cache. Browse the app first to populate the cache.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      // Log the number of cached categories
      LoggingService.logFirestore('CAT_CACHE_INSPECT: Found ${categoriesCache.length} categories in cache');
      print('CAT_CACHE_INSPECT: Found ${categoriesCache.length} categories in cache');
      
      // Show a modal with the cached category information
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppTheme.secondaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        builder: (context) {
          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Column(
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20.r),
                        topRight: Radius.circular(20.r),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cached Categories (${categoriesCache.length})',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  
                  // Content
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: categoriesCache.length,
                      padding: EdgeInsets.all(16.r),
                      itemBuilder: (context, index) {
                        final category = categoriesCache[index];
                        
                        // Log each category being displayed
                        LoggingService.logFirestore('CAT_CACHE_INSPECT: Displaying category ${category.id} (${category.title})');
                        print('CAT_CACHE_INSPECT: Displaying category ${category.id} (${category.title})');
                        
                        return Card(
                          margin: EdgeInsets.only(bottom: 16.h),
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: ExpansionTile(
                            title: Row(
                              children: [
                                Container(
                                  width: 16.w,
                                  height: 16.h,
                                  decoration: BoxDecoration(
                                    color: category.itemBackgroundColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    category.title,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              'ID: ${category.id} • ${category.items.length} items',
                              style: TextStyle(color: Colors.white70),
                            ),
                            children: [
                              Padding(
                                padding: EdgeInsets.all(16.r),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Background Color: ${category.backgroundColor}',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    Text(
                                      'Item Background Color: ${category.itemBackgroundColor}',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    Divider(color: Colors.white24),
                                    
                                    // Subcategories grid
                                    Text(
                                      'Subcategories (${category.items.length}):',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        childAspectRatio: 3,
                                        crossAxisSpacing: 8.w,
                                        mainAxisSpacing: 8.h,
                                      ),
                                      itemCount: category.items.length,
                                      itemBuilder: (context, idx) {
                                        final item = category.items[idx];
                                        return Container(
                                          padding: EdgeInsets.all(8.r),
                                          decoration: BoxDecoration(
                                            color: category.itemBackgroundColor.withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(8.r),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                item.label,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12.sp,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                'ID: ${item.id}',
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 10.sp,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Stats footer
                  Container(
                    padding: EdgeInsets.all(16.r),
                    color: AppTheme.primaryColor,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Categories: ${categoriesCache.length}',
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          'Subcategories: ${categoriesCache.fold<int>(0, (sum, cat) => sum + cat.items.length)}',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
      
      // Log completion of cache inspection
      LoggingService.logFirestore('CAT_CACHE_INSPECT: Completed inspection of cached categories');
      print('CAT_CACHE_INSPECT: Completed inspection of cached categories');
      
    } catch (e) {
      LoggingService.logError('CAT_CACHE_INSPECT', 'Error displaying cached categories: $e');
      print('CAT_CACHE_INSPECT ERROR: Failed to display cached categories - $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().split('\n').first}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _showFirestoreDataExplorer(BuildContext context) async {
    try {
      // Start loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.secondaryColor,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTheme.accentColor),
              SizedBox(height: 16),
              Text('Loading Firestore data...', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );

      // Create repositories
      final categoryRepo = CategoryRepository();
      final productRepo = FirestoreProductRepository();

      // Fetch categories
      final categories = await categoryRepo.fetchCategories();

      // Fetch products for first category
      List<ProductModel> products = [];
      if (categories.isNotEmpty && categories.first.items.isNotEmpty) {
        final categoryGroup = categories.first.id;
        final categoryItem = categories.first.items.first.id;
        products = await productRepo.fetchProductsByCategory(
          categoryGroup: categoryGroup,
          categoryItem: categoryItem,
        );
      }

      // Dismiss loading dialog
      Navigator.pop(context);

      // Show the data explorer dialog
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppTheme.secondaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return DraggableScrollableSheet(
                initialChildSize: 0.9,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                expand: false,
                builder: (context, scrollController) {
                  return Column(
                    children: [
                      // Header
                      Container(
                        padding: EdgeInsets.all(16.r),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20.r),
                            topRight: Radius.circular(20.r),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Firestore Data Explorer',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      
                      // Content
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: EdgeInsets.all(16.r),
                          children: [
                            // Categories section
                            Text(
                              'Categories (${categories.length})',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentColor,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Container(
                              padding: EdgeInsets.all(12.r),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: categories.isEmpty
                                ? Text(
                                    'No categories found',
                                    style: TextStyle(color: Colors.white70),
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: categories.map((category) {
                                      return ExpansionTile(
                                        title: Text(
                                          category.title,
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        collapsedTextColor: Colors.white,
                                        textColor: AppTheme.accentColor,
                                        iconColor: AppTheme.accentColor,
                                        collapsedIconColor: Colors.white,
                                        children: category.items.map((item) {
                                          return ListTile(
                                            title: Text(
                                              item.label,
                                              style: TextStyle(color: Colors.white70),
                                            ),
                                            onTap: () async {
                                              try {
                                                // Show loading
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Loading products...'),
                                                    duration: Duration(seconds: 1),
                                                  ),
                                                );
                                                
                                                // Load products for this category
                                                final newProducts = await productRepo.fetchProductsByCategory(
                                                  categoryGroup: category.id,
                                                  categoryItem: item.id,
                                                );
                                                
                                                // Update products list
                                                setState(() {
                                                  products = newProducts;
                                                });
                                                
                                                // Scroll to products section
                                                scrollController.animateTo(
                                                  300.h,
                                                  duration: Duration(milliseconds: 500),
                                                  curve: Curves.easeInOut,
                                                );
                                              } catch (e) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Error: ${e.toString()}'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            },
                                          );
                                        }).toList(),
                                      );
                                    }).toList(),
                                  ),
                            ),
                            
                            SizedBox(height: 24.h),
                            
                            // Products section
                            Text(
                              'Products (${products.length})',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentColor,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Container(
                              padding: EdgeInsets.all(12.r),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: products.isEmpty
                                ? Text(
                                    'No products found or none selected. Tap a category item to view products.',
                                    style: TextStyle(color: Colors.white70),
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: products.map((product) {
                                      return ExpansionTile(
                                        title: Text(
                                          product.name,
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        subtitle: Text(
                                          '${AppConstants.currencySymbol}${product.price.toStringAsFixed(2)}',
                                          style: TextStyle(color: AppTheme.accentColor),
                                        ),
                                        collapsedTextColor: Colors.white,
                                        textColor: AppTheme.accentColor,
                                        iconColor: AppTheme.accentColor,
                                        collapsedIconColor: Colors.white,
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 16.r, vertical: 8.h),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                if (product.brand != null) _productDetailRow('Brand', product.brand!),
                                                _productDetailRow('SKU', product.sku ?? 'N/A'),
                                                _productDetailRow('Description', product.description ?? 'No description available'),
                                                _productDetailRow('In Stock', product.inStock ? 'Yes' : 'No'),
                                                if (product.ingredients != null) _productDetailRow('Ingredients', product.ingredients!),
                                                if (product.nutritionalInfo != null) _productDetailRow('Nutrition', product.nutritionalInfo!),
                                                if (product.weight != null) _productDetailRow('Weight', product.weight!),
                                                if (product.image.isNotEmpty) Padding(
                                                  padding: EdgeInsets.symmetric(vertical: 8.h),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        'Image URL: ${product.image.length > 60 ? product.image.substring(0, 60) + '...' : product.image}',
                                                        style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      if (product.image.contains('firebasestorage.googleapis.com'))
                                                        Text(
                                                          'Firebase Storage URL: Yes',
                                                          style: TextStyle(color: Colors.green, fontSize: 12.sp),
                                                          )
                                                      else if (product.image.isNotEmpty)
                                                        Text(
                                                          'Token required: ${product.image.contains("token=") ? "No" : "Yes"}',
                                                          style: TextStyle(
                                                            color: product.image.contains("token=") ? Colors.green : Colors.orange,
                                                            fontSize: 12.sp
                                                          ),
                                                        ),
                                                      Text(
                                                        'Valid URL: ${_isValidImageUrl(product.image) ? 'Yes' : 'No'}',
                                                        style: TextStyle(
                                                          color: _isValidImageUrl(product.image) ? Colors.green : Colors.red, 
                                                          fontSize: 12.sp
                                                        ),
                                                      ),
                                                      if (!_isValidImageUrl(product.image) && product.image.isNotEmpty)
                                                        Text(
                                                          'Issue: URL format problem',
                                                          style: TextStyle(color: Colors.red, fontSize: 12.sp),
                                                        ),
                                                      SizedBox(height: 8.h),
                                                      // Try to load the image with a CachedNetworkImage for better performance
                                                      _isValidImageUrl(product.image) 
                                                        ? ClipRRect(
                                                            borderRadius: BorderRadius.circular(8.r),
                                                            child: CachedNetworkImage(
                                                              imageUrl: product.image,
                                                              height: 100.h,
                                                              width: double.infinity,
                                                              fit: BoxFit.cover,
                                                              placeholder: (context, url) => Container(
                                                                height: 100.h,
                                                                color: Colors.grey.shade800,
                                                                child: Center(
                                                                  child: CircularProgressIndicator(
                                                                    color: AppTheme.accentColor,
                                                                  ),
                                                                ),
                                                              ),
                                                              errorWidget: (context, url, error) {
                                                                print('Image error for ${product.name}: $error');
                                                                return Container(
                                                                  height: 100.h,
                                                                  color: Colors.grey.shade800,
                                                                  child: Center(
                                                                    child: Column(
                                                                      mainAxisSize: MainAxisSize.min,
                                                                      children: [
                                                                        Icon(Icons.image_not_supported, color: Colors.white),
                                                                        SizedBox(height: 4.h),
                                                                        Text(
                                                                          'Error: ${error.toString().split('\n').first}',
                                                                          style: TextStyle(color: Colors.white70, fontSize: 10.sp),
                                                                          textAlign: TextAlign.center,
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          )
                                                        : Container(
                                                            height: 100.h,
                                                            color: Colors.grey.shade800,
                                                            child: Center(
                                                              child: Column(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                  Icon(Icons.broken_image, color: Colors.white),
                                                                  SizedBox(height: 4.h),
                                                                  Text(
                                                                    'Invalid Image URL',
                                                                    style: TextStyle(color: Colors.white70),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                            ),
                            
                            SizedBox(height: 16.h),
                            
                            // Fetch All Products Button
                            ElevatedButton(
                              onPressed: () async {
                                try {
                                  // Show loading
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Loading all products (this may take a while)...'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  
                                  // Fetch all products
                                  final allProducts = await productRepo.fetchAllProducts();
                                  
                                  // Update products list
                                  setState(() {
                                    products = allProducts;
                                  });
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accentColor,
                                foregroundColor: Colors.black,
                              ),
                              child: Text('Fetch All Products'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      );
    } catch (e) {
      // Dismiss loading dialog if showing
      try {
        Navigator.pop(context);
      } catch (_) {}
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper method to determine if a URL is valid
  bool _isValidImageUrl(String url) {
    if (url.isEmpty) return false;
    
    // Check if the URL has a valid scheme
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return false;
    }
    
    // Special check for Firebase Storage URLs
    if (url.contains('firebasestorage.googleapis.com')) {
      // Firebase Storage URLs are typically valid if they contain these components
      return url.contains('/o/') && (url.contains('?alt=media') || url.contains('&alt=media'));
    }
    
    // Basic URL validation for non-Firebase URLs
    try {
      Uri.parse(url);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Helper method to display product details
  Widget _productDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
  
  // Confirm logout dialog
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryColor,
        title: Text('Logout', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Perform logout
              context.read<AuthBloc>().add(const LogoutEvent());
              // Navigate to login page
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppConstants.loginRoute,
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeBloc, HomeState>(
      listener: (context, state) {
        if (state.status == HomeStatus.error) {
          // Show error snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'An error occurred'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        // Use the cart item count from the state
        final cartItemCount = state.cartItemCount;
        final cartPreviewImage = state.cartPreviewImage;
        final totalAmount = state.cartTotalAmount;

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
          automaticallyImplyLeading: false, // Disable back button since we're using bottom nav
          title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(AppConstants.appName),
                if (_currentUser?.name != null)
                  Text(
                    'Hello, ${_currentUser!.name}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.normal,
                      color: AppTheme.accentColor,
                    ),
                  ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  // Navigate to notifications
                },
              ),
              IconButton(
                icon: const Icon(Icons.account_circle_outlined),
                onPressed: () {
                  // Show user profile options
                  _showUserProfileOptions(context);
                },
              ),
              SizedBox(width: 8.w),
            ],
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  // Search bar (moved up)
                  CustomSearchBar(
                    onSearch: (query) {
                      // Handle search
                      debugPrint('Searching for: $query');
                    },
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
                  ),
                  
                  // Top Category Tabs
                  HorizontalCategoryTabs(
                    tabs: state.tabs,
                    categoryGroups: state.categoryGroups,
                    selectedIndex: state.selectedTabIndex,
                    onTabSelected: (index) {
                      // First update the selected tab in the HomeBloc
                      context.read<HomeBloc>().add(SelectCategoryTab(index));
                      
                      // Then navigate to the CategoryProductsPage with the selected category group
                      if (state.categoryGroups.isNotEmpty && index < state.categoryGroups.length) {
                        final selectedCategoryGroup = state.categoryGroups[index];
                        if (selectedCategoryGroup.items.isNotEmpty) {
                          // Navigate to the first category item in the group
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CategoryProductsPage(
                                categoryId: selectedCategoryGroup.items.first.id,
                              ),
                            ),
                          );
                        }
                      }
                    },
                    showNewBadge: false,
                  ),
                  
                  // Main content
                  Expanded(
                    child: RefreshIndicator(
                      key: _refreshKey,
                      onRefresh: _refreshData,
                      color: AppTheme.accentColor,
                      child: state.status == HomeStatus.initial || 
                             (state.status == HomeStatus.loading && state.categoryGroups.isEmpty)
                          ? _buildLoadingState()
                          : _buildContent(state),
                    ),
                  ),
                ],
              ),
              
              // Back to top button
              Positioned(
                bottom: 80.h,
                right: 16.w,
                child: BackToTopButton.scrollAware(
                  scrollController: _scrollController,
                  onTap: _scrollToTop,
                ),
              ),
              
              // Cart FAB - Always show it
              Positioned(
                bottom: 16.h,
                left: 0,
                right: 0,
                child: Center(
                  child: CartFAB(
                    onTap: _navigateToCart,
                    backgroundColor: AppTheme.accentColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          SizedBox(height: 16.h),
          
          // Banner shimmer
          ShimmerLoader.banner(),
          
          SizedBox(height: 16.h),
          
          // Section header shimmer
          ShimmerLoader.sectionHeader(),
          
          // Category grid shimmer
          ShimmerLoader.categoryGrid(),
          
          SizedBox(height: 16.h),
          
          // Featured products header shimmer
          ShimmerLoader.sectionHeader(),
          
          // Featured products shimmer
          ShimmerLoader.productGrid(),
          
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildContent(HomeState state) {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile completion banner if user profile is incomplete
          if (_currentUser != null && _currentUser!.name != null) ...[  
            SizedBox(height: 16.h),
            ProfileCompletionBanner(
              user: _currentUser!,
              onAddAddressTap: () => _navigateToAddresses(),
            ),
          ],
          
          // Promotional banners
          SizedBox(height: 16.h),
          PromotionalBanner(
            images: state.banners,
            onTapCallbacks: List.generate(
              state.banners.length,
              (index) => () {
                // Handle banner tap
                debugPrint('Tapped on banner $index');
              },
            ),
          ),
      
          // Featured Products Section
          if (state.featuredPromotions.isNotEmpty) ...[
            SectionHeader(
              title: 'Featured this week',
              viewAllText: 'View All',
              onViewAllTap: () {
                // Navigate to all featured promotions
              },
            ),
            
            SizedBox(
              height: 150.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: state.featuredPromotions.length,
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                itemBuilder: (context, index) {
                  final promotion = state.featuredPromotions[index];
                  return Container(
                    width: 160.w,
                    margin: EdgeInsets.symmetric(horizontal: 8.w),
                    child: PromotionalCategoryCard(
                      category: promotion,
                      height: 150.h,
                      onTap: () => _onCategoryTap(promotion),
                    ),
                  );
                },
              ),
            ),
          ],
      
          // Category Groups Section
          if (state.categoryGroups.isNotEmpty)
            ...state.categoryGroups.map((group) => CategoryGrid4x2(
              categoryGroup: group,
              onItemTap: (item) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryProductsPage(
                      categoryId: item.id,
                    ),
                  ),
                );
              },
            )).toList(),
            
          // Bestsellers Section - Using Horizontal Scrollable Grid
          HorizontalBestsellerSection(
            title: 'Bestsellers',
            viewAllText: 'View All',
            onViewAllTap: () {
              // Navigate to all bestsellers
            },
            onProductTap: _onProductTap,
            onQuantityChanged: _handleAddToCart,
            cartQuantities: state.cartQuantities,
            limit: AppConstants.bestsellerLimit ?? 12,  // Show up to 12 bestsellers
            ranked: AppConstants.bestsellerRanked ?? false,  // Randomize instead of sorting by rank
            useRealTimeUpdates: true,  // Enable real-time RTDB updates
            showBestsellerBadge: true,  // Show savings indicators
          ),
          
          SizedBox(height: 24.h),
          
          // Developer/Test Section
          // if (_userService.getCurrentUserId() != null) ...[
          //   const Divider(color: Colors.white24),
          //   Padding(
          //     padding: EdgeInsets.all(16.r),
          //     child: Column(
          //       crossAxisAlignment: CrossAxisAlignment.start,
          //       children: [
          //         Text(
          //           'Developer Testing',
          //           style: TextStyle(
          //             color: Colors.white,
          //             fontSize: 18.sp,
          //             fontWeight: FontWeight.bold,
          //           ),
          //         ),
          //         SizedBox(height: 16.h),
          //         ElevatedButton(
          //           onPressed: () {
          //             Navigator.pushNamed(
          //               context, 
          //               AppConstants.firestoreCategoryProductsRoute,
          //               arguments: 'bakeries_biscuits',
          //             );
          //           },
          //           style: ElevatedButton.styleFrom(
          //             backgroundColor: AppTheme.accentColor,
          //             foregroundColor: Colors.black,
          //           ),
          //           child: const Text('Bakery & Biscuits (Firestore)'),
          //         ),
          //         SizedBox(height: 8.h),
          //         ElevatedButton(
          //           onPressed: () {
          //             Navigator.pushNamed(context, AppConstants.developerMenuRoute);
          //           },
          //           style: ElevatedButton.styleFrom(
          //             backgroundColor: Colors.purple,
          //             foregroundColor: Colors.white,
          //           ),
          //           child: const Text('Developer Menu'),
          //         ),
          //         SizedBox(height: 8.h),
          //         ElevatedButton.icon(
          //           onPressed: () => _showFirestoreDataExplorer(context),
          //           style: ElevatedButton.styleFrom(
          //             backgroundColor: AppTheme.accentColor,
          //             foregroundColor: Colors.black,
          //             padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          //           ),
          //           icon: Icon(Icons.data_exploration),
          //           label: const Text('Explore Firestore Data'),
          //         ),
          //         SizedBox(height: 8.h),
          //         ElevatedButton.icon(
          //           onPressed: () => _showCachedCategoriesInfo(context),
          //           style: ElevatedButton.styleFrom(
          //             backgroundColor: Colors.teal,
          //             foregroundColor: Colors.white,
          //             padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          //           ),
          //           icon: Icon(Icons.category),
          //           label: const Text('Show Cached Categories'),
          //         ),
          //       ],
          //     ),
          //   ),
          // ],
          
          SizedBox(height: 100.h),

          // Button to navigate to Revamped Two-Panel View
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RevampedTwoPanelView(),
                  ),
                );
              },
              child: const Text('Go to Revamped Two-Panel View'),
            ),
          ),
          SizedBox(height: 24.h),

        ],
      ),
    );
  }
}