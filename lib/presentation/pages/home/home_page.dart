import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:profit_grocery_application/presentation/widgets/cards/promotional_category_card.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/product.dart';
import '../../blocs/home/home_bloc.dart';
import '../../blocs/home/home_event.dart';
import '../../blocs/home/home_state.dart';
import '../../widgets/banners/promotional_banner.dart';
import '../../widgets/base_layout.dart';
import '../../widgets/buttons/back_to_top_button.dart';
import '../../widgets/buttons/cart_fab.dart';
import '../../widgets/grids/category_grid_4x2.dart';
import '../../widgets/grids/dense_category_grid.dart';
import '../../widgets/grids/product_grid.dart';
import '../../widgets/loaders/shimmer_loader.dart';
import '../../widgets/section_header.dart';
import '../../widgets/tabs/horizontal_category_tabs.dart';
import '../cart/cart_page.dart';
import '../product_details/product_details_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc()..add(const LoadHomeData()),
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onCategoryTap(Category category) {
    // Navigate to category products screen
    debugPrint('Tapped on category: ${category.name}');
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => CategoryProductsPage(category: category),
    //   ),
    // );
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
    // Update cart
    context.read<HomeBloc>().add(UpdateCartQuantity(product, quantity));
  }

  void _navigateToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CartPage()),
    );
  }

  Future<void> _refreshData() async {
    context.read<HomeBloc>().add(const RefreshHomeData());
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
            title: Text(AppConstants.appName),
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
                             (state.status == HomeStatus.loading && state.categories.isEmpty)
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
              
              // Cart FAB
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
              height: 150.h, // Further reduced height
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: state.featuredPromotions.length,
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                itemBuilder: (context, index) {
                  final promotion = state.featuredPromotions[index];
                  return Container(
                    width: 160.w, // Reduced width
                    margin: EdgeInsets.symmetric(horizontal: 8.w),
                    child: PromotionalCategoryCard(
                      category: promotion,
                      height: 150.h, // Reduced height to prevent overflow
                      onTap: () => _onCategoryTap(promotion),
                    ),
                  );
                },
              ),
            ),
          ],
      
          // CategoryGrid4x2 Sections
          if (state.categoryGroups.isNotEmpty) ...
            state.categoryGroups.map((group) => CategoryGrid4x2(
              title: group.title,
              images: group.images,
              labels: group.labels,
              backgroundColor: group.backgroundColor,
              itemBackgroundColor: group.itemBackgroundColor,
              onItemTap: (index) {
                debugPrint('Tapped on ${group.items[index].label} in ${group.title}');
              },
            )).toList(),
            
          // Legacy Categories Sections (hidden)
          if (false && state.mainCategories.isNotEmpty) ...[
            DenseCategoryGrid.withHeader(
              title: 'Grocery & Kitchen',
              categories: state.mainCategories,
              onCategoryTap: _onCategoryTap,
              crossAxisCount: 2,
              spacing: 16.0,
            ),
          ],
          
          // Shop by Category Section (Snacks & Drinks) - Hidden
          if (false && state.snacksCategories.isNotEmpty) ...[
            DenseCategoryGrid.withHeader(
              title: 'Snacks & Drinks',
              categories: state.snacksCategories,
              onCategoryTap: _onCategoryTap,
              crossAxisCount: 2,
              spacing: 16.0,
            ),
          ],
          
          // Shop by Store Section - Hidden
          if (false && state.storeCategories.isNotEmpty) ...[
            DenseCategoryGrid.withHeader(
              title: 'Shop by store',
              categories: state.storeCategories,
              onCategoryTap: _onCategoryTap,
              crossAxisCount: 2,
              spacing: 16.0,
            ),
          ],
          
          // Bestsellers Section
          if (state.bestSellers.isNotEmpty) ...[
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
            ),
          ],
          
          SizedBox(height: 100.h), // Extra space for the floating action button
        ],
      ),
    );
  }
}