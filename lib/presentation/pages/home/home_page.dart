import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:profit_grocery_application/core/errors/global_error_handler.dart';
import 'package:profit_grocery_application/main.dart';
import 'package:profit_grocery_application/presentation/blocs/cart/cart_bloc.dart';
import 'package:profit_grocery_application/presentation/blocs/cart/cart_state.dart';
import 'package:profit_grocery_application/presentation/blocs/user/user_bloc.dart';
import 'package:profit_grocery_application/presentation/blocs/user/user_event.dart';
import 'package:profit_grocery_application/presentation/widgets/cards/promotional_category_card.dart';
import 'package:profit_grocery_application/presentation/widgets/profile/profile_completion_banner.dart';
import 'package:profit_grocery_application/services/cart/home_cart_bridge.dart';
import 'package:profit_grocery_application/services/logging_service.dart';
import 'package:profit_grocery_application/utils/cart_logger.dart';

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
import '../product_details/product_details_page.dart';
import '../../blocs/categories/categories_bloc.dart';
import '../../../data/repositories/category_repository.dart';
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
  late IUserService _userService;
  late final Stream<User?> _userStream;
  
  @override
  void initState() {
    super.initState();
    _userService = GetIt.instance<IUserService>();
    _currentUser = _userService.getCurrentUser();
    _userStream = _userService.userStream;
    
    // Listen to user changes from UserService
    _userStream.listen((user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
          LoggingService.logFirestore('HomePage: User data updated: ${user?.name ?? "null"}');
        });
      }
    });
    
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
      
      // Create a HomeCartBridge and initialize it
      final bridge = HomeCartBridge(
        cartBloc: cartBloc,
        homeBloc: homeBloc,
      );
      bridge.initialize();
      
      // Listen to CartBloc state changes to update HomeBloc
      cartBloc.stream.listen((state) {
        if (state.status == CartStatus.loaded && mounted) {
          // Create a map of product IDs to quantities from cart items
          final Map<String, int> cartQuantities = {};
          for (final item in state.items) {
            cartQuantities[item.productId] = item.quantity;
          }
          
          // Get the first product image for cart preview
          String? cartPreviewImage;
          if (state.items.isNotEmpty) {
            cartPreviewImage = state.items.first.image;
          }
          
          // Update HomeBloc with cart data from CartBloc
          homeBloc.add(UpdateHomeCartData(
            cartQuantities: cartQuantities,
            cartItemCount: state.itemCount,
            cartTotalAmount: state.total,
            cartPreviewImage: cartPreviewImage,
          ));
        }
      });
    } catch (e) {
      LoggingService.logError('HomePage', 'Error syncing CartBloc with HomeBloc: $e');
    }
    
    // Add a short delay to allow the UI to build, then check if user data is loaded
    Future.delayed(Duration.zero, () {
      if (_currentUser == null || _currentUser?.name == null) {
        // Silently try to reload user data without showing "not found" message
        final userId = _userService.getCurrentUserId();
        if (userId != null) {
          // First try to load directly from service
          _userService.loadUserData(userId);
          
          // Also trigger through UserBloc if available
          try {
            context.read<UserBloc>().add(LoadUserProfileEvent(userId));
          } catch (e) {
            LoggingService.logError('HomePage', 'Error triggering UserBloc: $e');
          }
        }
      } else {
        // Silently log that user data is loaded
        LoggingService.logFirestore('HomePage: User data loaded: ${_currentUser?.name}');
      }
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsPage(productId: product.id),
      ),
    );
  }

  void _onProductQuantityChanged(Product product, int quantity) {
    CartLogger.log('HOME_PAGE', 'Product quantity changed: ${product.name}, quantity: $quantity');
    
    // Get the CartBloc
    final cartBloc = context.read<CartBloc>();
    
    // Create a temporary HomeCartBridge
    final bridge = HomeCartBridge(
      cartBloc: cartBloc,
      homeBloc: context.read<HomeBloc>(),
    );
    
    // Direct test with Firebase Realtime Database
    try {
      final userId = GetIt.instance<IUserService>().getCurrentUserId();
      if (userId != null) {
        // Create a simple test path specific to this user's cart
        final database = GetIt.instance<FirebaseDatabase>();
        final ref = database.ref().child('carts_test/$userId');
        
        // Create specific message
        String cartMessage = "yoyo product with id ${product.id} got added in the cart";
        
        // Write entry with specific message
        ref.set({
          'product_id': product.id,
          'product_name': product.name,
          'quantity': quantity,
          'price': product.price,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'message': cartMessage,
          'test_entry': true
        });
        
        // Log the specific message
        CartLogger.success('HOME_PAGE', cartMessage);
        print('CART TEST: $cartMessage');
        
        // Also show a notification with the specific message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $cartMessage'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      CartLogger.error('HOME_PAGE', 'Failed to write test data to Firebase', e);
      
      // Show error notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Firebase test failed: ${e.toString().split('\n').first}'),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    // Use the bridge to update cart as usual
    if (quantity <= 0) {
      bridge.removeFromCart(product);
    } else {
      bridge.updateCartItemQuantity(product, quantity);
    }
    
    CartLogger.success('HOME_PAGE', 'Cart updated via bridge');
  }

  void _navigateToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CartPage()),
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

  List<IconData> _getCategoryIcons() {
    return [
      Icons.storefront_outlined, // All
      Icons.devices_outlined,     // Electronics
      Icons.face_outlined,        // Beauty
      Icons.child_care_outlined,  // Kids
      Icons.card_giftcard_outlined, // Gifting
    ];
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
                icon: const Icon(Icons.search),
                onPressed: () {
                  // Navigate to search page
                },
              ),
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
                  // Top Category Tabs
                  HorizontalCategoryTabs(
                    tabs: state.tabs,
                    icons: _getCategoryIcons(),
                    selectedIndex: state.selectedTabIndex,
                    onTabSelected: (index) {
                      context.read<HomeBloc>().add(SelectCategoryTab(index));
                    },
                    showNewBadge: true,
                    newTabIndex: 3, // Show "New" badge on Kids tab (index 3)
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
              
              // Cart FAB - Only show when cart has items
              if (cartItemCount > 0)
                Positioned(
                  bottom: 16.h,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: CartFAB(
                      itemCount: cartItemCount,
                      totalAmount: totalAmount,
                      onTap: _navigateToCart,
                      previewImagePath: cartPreviewImage,
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
            
          // Bestsellers Section - Firebase version
          BlocBuilder<ProductsBloc, ProductsState>(
            builder: (context, productsState) {
              if (productsState.status == ProductsStatus.loading) {
                return Column(
                  children: [
                    SectionHeader(
                      title: 'Bestsellers',
                      viewAllText: 'View All',
                      onViewAllTap: () {
                        // Navigate to all bestsellers
                      },
                    ),
                    ShimmerLoader.productGrid(),
                  ],
                );
              } else if (productsState.status == ProductsStatus.loaded && 
                       productsState.bestsellerProducts.isNotEmpty) {
                return Column(
                  children: [
                    SectionHeader(
                      title: 'Bestsellers',
                      viewAllText: 'View All',
                      onViewAllTap: () {
                        // Navigate to all bestsellers
                      },
                    ),
                    FirebaseProductGrid(
                      products: productsState.bestsellerProducts,
                      onProductTap: _onProductTap,
                      onQuantityChanged: _onProductQuantityChanged,
                      cartQuantities: state.cartQuantities,
                      crossAxisCount: 2,
                      subCategoryColors: state.subcategoryColors,
                    ),
                  ],
                );
              } else if (productsState.status == ProductsStatus.error) {
                return Padding(
                  padding: EdgeInsets.all(16.r),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48.sp,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          productsState.errorMessage ?? 'Error loading bestsellers',
                          style: TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16.h),
                        ElevatedButton(
                          onPressed: () {
                            context.read<ProductsBloc>().add(const LoadBestsellerProducts());
                          },
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              } else if (state.bestSellers.isNotEmpty) {
                // Fallback to local data if Firebase data is not available
                return Column(
                  children: [
                    SectionHeader(
                      title: 'Bestsellers',
                      viewAllText: 'View All',
                      onViewAllTap: () {
                        // Navigate to all bestsellers
                      },
                    ),
                    ProductGrid(
                      products: state.bestSellers,
                      onProductTap: _onProductTap,
                      onQuantityChanged: _onProductQuantityChanged,
                      cartQuantities: state.cartQuantities,
                      crossAxisCount: 2,
                      subCategoryColors: state.subcategoryColors,
                    ),
                  ],
                );
              }
              
              // Return empty container if no bestseller products
              return SizedBox();
            },
          ),
          
          SizedBox(height: 24.h),
          
          // Developer/Test Section
          if (_userService.getCurrentUserId() != null) ...[
            const Divider(color: Colors.white24),
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Developer Testing',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context, 
                        AppConstants.firestoreCategoryProductsRoute,
                        arguments: 'bakeries_biscuits',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Bakery & Biscuits (Firestore)'),
                  ),
                  SizedBox(height: 8.h),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppConstants.developerMenuRoute);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Developer Menu'),
                  ),
                ],
              ),
            ),
          ],
          
          SizedBox(height: 100.h),
        ],
      ),
    );
  }
}