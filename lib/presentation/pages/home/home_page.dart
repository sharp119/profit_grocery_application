import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/product.dart';
import '../../blocs/home/home_bloc.dart';
import '../../blocs/home/home_event.dart';
import '../../blocs/home/home_state.dart';
import '../../widgets/banners/promotional_banner.dart';
import '../../widgets/base_layout.dart';
import '../../widgets/grids/category_grid.dart';
import '../../widgets/grids/product_grid.dart';
import '../../widgets/loaders/shimmer_loader.dart';
import '../../widgets/section_header.dart';
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
  final _refreshKey = GlobalKey<RefreshIndicatorState>();

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
    debugPrint('Tapped on product: ${product.name}');
    // In a real app, we would navigate to the product details page
    // For now, let's just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected: ${product.name}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _onProductQuantityChanged(Product product, int quantity) {
    // Update cart
    debugPrint('Changed quantity for ${product.name} to $quantity');
    // In a real app, we would update the cart through a BLoC
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

        return BaseLayout.withCartFAB(
          title: AppConstants.appName,
          showBackButton: false,
          cartItemCount: cartItemCount,
          onCartTap: _navigateToCart,
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // Navigate to search page
              },
            ),
          ],
          body: Column(
            children: [
              // Category tabs
              _buildCategoryTabs(state),
              
              // Main content
              Expanded(
                child: RefreshIndicator(
                  key: _refreshKey,
                  onRefresh: _refreshData,
                  color: AppTheme.accentColor,
                  child: state.status == HomeStatus.initial || state.status == HomeStatus.loading && state.categories.isEmpty
                      ? _buildLoadingState()
                      : _buildContent(state),
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
      
          // Shop by Category section
          SectionHeader(
            title: 'Shop by Category',
            viewAllText: 'View All',
            onViewAllTap: () {
              // Navigate to all categories
            },
          ),
          
          // Category grid
          CategoryGrid(
            categories: state.categories,
            onCategoryTap: _onCategoryTap,
            useStaggeredLayout: true,
          ),
          
          // Featured Products section
          if (state.featuredProducts.isNotEmpty) ...[
            SectionHeader(
              title: 'Featured Products',
              viewAllText: 'View All',
              onViewAllTap: () {
                // Navigate to all featured products
              },
            ),
            
            ProductGrid(
              products: state.featuredProducts,
              onProductTap: _onProductTap,
              onQuantityChanged: _onProductQuantityChanged,
              crossAxisCount: 2,
            ),
          ],
          
          // New Arrivals section
          if (state.newArrivals.isNotEmpty) ...[
            SectionHeader(
              title: 'New Arrivals',
              viewAllText: 'View All',
              onViewAllTap: () {
                // Navigate to all new arrivals
              },
            ),
            
            ProductGrid(
              products: state.newArrivals,
              onProductTap: _onProductTap,
              onQuantityChanged: _onProductQuantityChanged,
              crossAxisCount: 2,
            ),
          ],
          
          // Bestsellers section
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
              crossAxisCount: 2,
            ),
          ],
          
          SizedBox(height: 100.h), // Extra space for the floating action button
        ],
      ),
    );
  }
  
  Widget _buildCategoryTabs(HomeState state) {
    return SizedBox(
      height: 50.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: state.tabs.length,
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        itemBuilder: (context, index) {
          final isSelected = state.selectedTabIndex == index;
          
          return GestureDetector(
            onTap: () {
              context.read<HomeBloc>().add(SelectCategoryTab(index));
            },
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: 8.w,
                vertical: 8.h,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 8.h,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.accentColor
                    : AppTheme.secondaryColor,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                state.tabs.isEmpty ? 'Loading...' : state.tabs[index],
                style: TextStyle(
                  color: isSelected
                      ? Colors.black
                      : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
