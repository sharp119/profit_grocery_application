import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:profit_grocery_application/data/inventory/product_inventory.dart';
import 'package:profit_grocery_application/data/inventory/similar_products.dart';
import 'package:profit_grocery_application/domain/repositories/cart_repository.dart';
import 'package:profit_grocery_application/presentation/blocs/cart/cart_bloc.dart';
import 'package:profit_grocery_application/presentation/blocs/cart/cart_event.dart' as cart_events;
import 'package:profit_grocery_application/presentation/blocs/cart/cart_state.dart';
import 'package:profit_grocery_application/presentation/blocs/products/products_bloc.dart';
import 'package:profit_grocery_application/presentation/blocs/products/products_event.dart';
import 'package:profit_grocery_application/presentation/blocs/products/products_state.dart';
import 'package:profit_grocery_application/presentation/pages/category_products/category_products_page.dart';
import 'package:profit_grocery_application/presentation/widgets/cards/enhanced_product_card.dart';
import 'package:profit_grocery_application/presentation/widgets/cards/universal_product_card.dart';
import 'package:profit_grocery_application/services/cart/cart_sync_service.dart';
import 'package:profit_grocery_application/services/cart/universal/universal_cart_service.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/utils/color_mapper.dart';
import '../../../domain/entities/product.dart';
import '../../blocs/product_details/product_details_bloc.dart';
import '../../blocs/product_details/product_details_event.dart';
import '../../blocs/product_details/product_details_state.dart';
import '../../widgets/buttons/cart_fab.dart';
import '../../widgets/loaders/shimmer_loader.dart';
import '../cart/cart_page.dart';

class ProductDetailsPage extends StatelessWidget {
  final String productId;
  final String? categoryId;

  const ProductDetailsPage({
    Key? key,
    required this.productId,
    this.categoryId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check for existing blocs
    CartBloc? existingCartBloc;
    ProductsBloc? existingProductsBloc;
    try {
      existingCartBloc = BlocProvider.of<CartBloc>(context, listen: false);
      existingProductsBloc = BlocProvider.of<ProductsBloc>(context, listen: false);
    } catch (_) {
      // Blocs not found
    }
    
    // Instead of trying to manipulate existing BlocProviders,
    // let's simplify and just handle all possible cases explicitly
    
    // Check which blocs we need
    bool needsCartBloc = existingCartBloc == null;
    bool needsProductsBloc = existingProductsBloc == null;
    
    // Case 1: Need all blocs
    if (needsCartBloc && needsProductsBloc) {
      return MultiBlocProvider(
        providers: [
          BlocProvider<CartBloc>(
            create: (context) => CartBloc(
              cartRepository: GetIt.instance<CartRepository>(),
              cartSyncService: GetIt.instance<CartSyncService>(),
            )..add(const cart_events.LoadCart()),
          ),
          BlocProvider<ProductsBloc>(
            create: (context) => GetIt.instance<ProductsBloc>(),
          ),
          BlocProvider<ProductDetailsBloc>(
            create: (context) => ProductDetailsBloc()..add(LoadProductDetails(productId)),
          ),
        ],
        child: _ProductDetailsContent(categoryId: categoryId),
      );
    }
    
    // Case 2: Need CartBloc and ProductDetailsBloc
    else if (needsCartBloc) {
      return MultiBlocProvider(
        providers: [
          BlocProvider<CartBloc>(
            create: (context) => CartBloc(
              cartRepository: GetIt.instance<CartRepository>(),
              cartSyncService: GetIt.instance<CartSyncService>(),
            )..add(const cart_events.LoadCart()),
          ),
          BlocProvider<ProductDetailsBloc>(
            create: (context) => ProductDetailsBloc()..add(LoadProductDetails(productId)),
          ),
        ],
        child: _ProductDetailsContent(categoryId: categoryId),
      );
    }
    
    // Case 3: Need ProductsBloc and ProductDetailsBloc
    else if (needsProductsBloc) {
      return MultiBlocProvider(
        providers: [
          BlocProvider<ProductsBloc>(
            create: (context) => GetIt.instance<ProductsBloc>(),
          ),
          BlocProvider<ProductDetailsBloc>(
            create: (context) => ProductDetailsBloc()..add(LoadProductDetails(productId)),
          ),
        ],
        child: _ProductDetailsContent(categoryId: categoryId),
      );
    }
    
    // Case 4: Only need ProductDetailsBloc
    else {
      return BlocProvider<ProductDetailsBloc>(
        create: (context) => ProductDetailsBloc()..add(LoadProductDetails(productId)),
        child: _ProductDetailsContent(categoryId: categoryId),
      );
    }
  }
}

class _ProductDetailsContent extends StatefulWidget {
  final String? categoryId;
  
  const _ProductDetailsContent({this.categoryId});

  @override
  State<_ProductDetailsContent> createState() => _ProductDetailsContentState();
}

class _ProductDetailsContentState extends State<_ProductDetailsContent> {
  int _quantity = 1;
  final PageController _imagePageController = PageController();
  int _currentImageIndex = 0;

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  void _increaseQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decreaseQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  void _addToCart(Product product) {
    // Add to ProductDetailsBloc for local state
    context.read<ProductDetailsBloc>().add(AddToCart(product, _quantity));
    
    // Also add to CartBloc for global state
    context.read<CartBloc>().add(cart_events.AddToCart(product, _quantity));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${product.name} to cart'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppTheme.secondaryColor,
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: AppTheme.accentColor,
          onPressed: _navigateToCart,
        ),
      ),
    );
  }
  
  void _navigateToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CartPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the actual cart data from CartBloc
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, cartState) {
        return BlocConsumer<ProductDetailsBloc, ProductDetailsState>(
          listener: (context, state) {
            if (state.status == ProductDetailsStatus.error) {
              // Check if the error is a FormatException
              final errorMsg = state.errorMessage ?? 'An error occurred';
              final isFormatException = errorMsg.contains('FormatException');
              
              // Only show user-friendly messages
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isFormatException 
                      ? 'Unable to add product to cart' 
                      : errorMsg),
                  backgroundColor: Colors.red,
                  action: SnackBarAction(
                    label: 'DISMISS',
                    textColor: Colors.white,
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    },
                  ),
                ),
              );
            }
          },
          builder: (context, state) {
            // Use the cart data from CartBloc instead of product details bloc
            final cartItemCount = cartState.itemCount;
            final cartTotalAmount = cartState.total;
            
            return Scaffold(
              backgroundColor: AppTheme.backgroundColor,
              appBar: AppBar(
                title: const Text('Product Details'),
              actions: [
                if (widget.categoryId != null)
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryProductsPage(categoryId: widget.categoryId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.grid_view, color: AppTheme.accentColor),
                    label: Text(
                      'View All',
                      style: TextStyle(
                        color: AppTheme.accentColor,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () {
                      // Share product
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite_border_outlined),
                    onPressed: () {
                      // Add to wishlist
                    },
                  ),
                  SizedBox(width: 8.w),
                ],
              ),
              body: state.status == ProductDetailsStatus.loading
                  ? _buildLoadingState()
                  : state.product == null
                      ? Center(child: Text('Product not found', style: TextStyle(color: Colors.white)))
                      : _buildProductDetails(state.product!),
              bottomNavigationBar: state.product != null && state.product!.inStock
                  ? _buildBottomActionBar(state.product!)
                  : null,
              // The CartFAB itself checks item count
              floatingActionButton: CartFAB(
                itemCount: cartItemCount,
                totalAmount: cartTotalAmount,
                onTap: _navigateToCart,
                previewImagePath: state.product?.image,
              ),
              floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
            );
          },
        );
      }
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerLoader.customContainer(height: 300.h, width: double.infinity),
          SizedBox(height: 16.h),
          ShimmerLoader.customContainer(height: 24.h, width: 200.w),
          SizedBox(height: 8.h),
          ShimmerLoader.customContainer(height: 20.h, width: 150.w),
          SizedBox(height: 16.h),
          ShimmerLoader.customContainer(height: 100.h, width: double.infinity),
          SizedBox(height: 16.h),
          ShimmerLoader.customContainer(height: 50.h, width: double.infinity),
        ],
      ),
    );
  }

  Widget _buildProductDetails(Product product) {
    // For the demo, assume product has at least one image
    // In a real app, multiple images would come from the Product entity
    final productImages = [
      product.image,
      '${AppConstants.assetsProductsPath}1.png',
      '${AppConstants.assetsProductsPath}2.png',
    ];
    
    final hasDiscount = product.mrp != null && product.mrp! > product.price;
    final discountPercentage = hasDiscount
        ? ((product.mrp! - product.price) / product.mrp! * 100).round()
        : 0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product images with page indicator
          Stack(
            children: [
              // Image carousel
              SizedBox(
                height: 300.h,
                child: PageView.builder(
                  controller: _imagePageController,
                  itemCount: productImages.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return BlocBuilder<ProductDetailsBloc, ProductDetailsState>(
                      builder: (context, blocState) {
                        // Get the background color based on the product's category
                        final Color backgroundColor = ColorMapper.getColorForCategory(
                          product.id.split('_').take(2).join('_')
                        );
                            
                        return Container(
                          color: backgroundColor,
                          padding: EdgeInsets.all(24.w),
                          child: Image.asset(
                            productImages[index],
                            fit: BoxFit.contain,
                          ),
                        );
                      }
                    );
                  },
                ),
              ),
              
              // Out of stock overlay
              if (!product.inStock)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.7),
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 10.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.7),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'OUT OF STOCK',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              
              // Discount badge
              if (hasDiscount)
                Positioned(
                  top: 16.h,
                  left: 16.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      '$discountPercentage% OFF',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              
              // Page indicator
              Positioned(
                bottom: 16.h,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    productImages.length,
                    (index) => Container(
                      width: 8.w,
                      height: 8.h,
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentImageIndex == index
                            ? AppTheme.accentColor
                            : Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Product info section
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product name
                Text(
                  product.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                SizedBox(height: 8.h),
                
                // Price section
                Row(
                  children: [
                    // Current price
                    Text(
                      '${AppConstants.currencySymbol}${product.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: AppTheme.accentColor,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    SizedBox(width: 12.w),
                    
                    // Original price (MRP) if there is a discount
                    if (hasDiscount)
                      Text(
                        '${AppConstants.currencySymbol}${product.mrp!.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      
                    const Spacer(),
                    
                    // In stock indicator
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: product.inStock ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4.r),
                        border: Border.all(
                          color: product.inStock ? Colors.green : Colors.red,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        product.inStock ? 'In Stock' : 'Out of Stock',
                        style: TextStyle(
                          color: product.inStock ? Colors.green : Colors.red,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 20.h),
                
                // Divider
                Divider(color: Colors.grey.withOpacity(0.3)),
                
                SizedBox(height: 16.h),
                
                // Product description
                Text(
                  'Description',
                  style: TextStyle(
                    color: AppTheme.accentColor,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                SizedBox(height: 8.h),
                
                Text(
                  product.description ?? 'No description available for this product.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16.sp,
                    height: 1.5,
                  ),
                ),
                
                SizedBox(height: 16.h),
                
                // Product specifications
                Text(
                  'Specifications',
                  style: TextStyle(
                    color: AppTheme.accentColor,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                SizedBox(height: 8.h),
                
                // Specification list
                _buildSpecificationItem(
                  'Brand',
                  product.brand ?? 'Generic',
                ),
                _buildSpecificationItem(
                  'Weight',
                  product.weight ?? '100g',
                ),
                _buildSpecificationItem(
                  'Category',
                  product.categoryName ?? product.categoryId,
                ),
                
                SizedBox(height: 16.h),
                
                // Similar products section with Firebase integration
                BlocBuilder<ProductDetailsBloc, ProductDetailsState>(
                  builder: (blocContext, blocState) {
                    // Trigger loading similar products from Firebase
                    if (blocState.status == ProductDetailsStatus.loaded && 
                        blocState.product != null) {
                      // Dispatch event to load similar products
                      context.read<ProductsBloc>().add(LoadSimilarProducts(product.id));
                    }
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Similar Products',
                          style: TextStyle(
                            color: AppTheme.accentColor,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        SizedBox(height: 8.h),
                        
                        SizedBox(
                          height: 250.h,
                          child: BlocBuilder<ProductsBloc, ProductsState>(
                            builder: (context, productsState) {
                              // Show loading state while fetching similar products
                              if (productsState.status == ProductsStatus.loading) {
                                return ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: 3,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      width: 160.w,
                                      margin: EdgeInsets.only(right: 12.w),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12.r),
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: AppTheme.accentColor,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }
                              
                              // Show error state if loading failed
                              if (productsState.status == ProductsStatus.error) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: Colors.red.withOpacity(0.7),
                                        size: 24.sp,
                                      ),
                                      SizedBox(height: 8.h),
                                      Text(
                                        'Failed to load similar products',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14.sp,
                                        ),
                                      ),
                                      SizedBox(height: 8.h),
                                      TextButton(
                                        onPressed: () {
                                          context.read<ProductsBloc>().add(LoadSimilarProducts(product.id));
                                        },
                                        child: Text('Retry'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              
                              // If similar products are loaded, display them
                              if (productsState.status == ProductsStatus.loaded && 
                                  productsState.similarProducts.isNotEmpty) {
                                return ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: productsState.similarProducts.length,
                                  itemBuilder: (context, index) {
                                    final similarProduct = productsState.similarProducts[index];
                                    
                                    // Get quantity from cart state
                                    int quantity = 0;
                                    final cartState = context.read<CartBloc>().state;
                                    if (cartState.status == CartStatus.loaded) {
                                      final cartItem = cartState.items
                                          .where((item) => item.productId == similarProduct.id)
                                          .toList();
                                      if (cartItem.isNotEmpty) {
                                        quantity = cartItem.first.quantity;
                                      }
                                    }
                                    
                                    return Container(
                                      width: 160.w,
                                      margin: EdgeInsets.only(right: 12.w),
                                      child: EnhancedProductCard.fromEntity(
                                        product: similarProduct,
                                        onTap: () {
                                          // Navigate to the similar product details
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ProductDetailsPage(
                                                productId: similarProduct.id,
                                                categoryId: similarProduct.categoryId,
                                              ),
                                            ),
                                          );
                                        },
                                        onQuantityChanged: (qty) {
                                          // Add to cart functionality
                                          if (qty <= 0) {
                                            context.read<CartBloc>().add(
                                              cart_events.RemoveFromCart(similarProduct.id),
                                            );
                                          } else {
                                            context.read<CartBloc>().add(
                                              cart_events.UpdateCartItemQuantity(similarProduct.id, qty),
                                            );
                                          }
                                        },
                                        quantity: quantity,
                                      ),
                                    );
                                  },
                                );
                              }
                              
                              // Fallback to local data if Firebase data is not available
                              final similarProductIds = SimilarProducts.getSimilarProductIds(
                                product.id,
                                limit: 3,
                              );
                              
                              // Get all products from inventory
                              final allProducts = ProductInventory.getAllProducts();
                              
                              // Find the similar products
                              final similarProducts = <Product>[];
                              
                              for (final productId in similarProductIds) {
                                try {
                                  final similarProduct = allProducts.firstWhere(
                                    (p) => p.id == productId,
                                  );
                                  similarProducts.add(similarProduct);
                                } catch (e) {
                                  // Skip if product not found
                                }
                              }
                              
                              if (similarProducts.isEmpty) {
                                return Center(
                                  child: Text(
                                    'No similar products found',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                );
                              }
                              
                              return ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: similarProducts.length,
                                itemBuilder: (context, index) {
                                  final similarProduct = similarProducts[index];
                                  
                                  // Get color for category
                                  final categoryColor = ColorMapper.getColorForCategory(
                                    similarProduct.id.split('_').take(2).join('_')
                                  );
                                  
                                  return Container(
                                    width: 160.w,
                                    margin: EdgeInsets.only(right: 12.w),
                                    child: UniversalProductCard(
                                      product: similarProduct,
                                      onTap: () {
                                        // Navigate to the similar product details
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ProductDetailsPage(
                                              productId: similarProduct.id,
                                              categoryId: similarProduct.categoryId,
                                            ),
                                          ),
                                        );
                                      },
                                      quantity: 0,
                                      backgroundColor: categoryColor,
                                      useBackgroundColor: true,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
                
                // Space for bottom bar
                SizedBox(height: 100.h),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSpecificationItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14.sp,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(Product product) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 12.h,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: AppTheme.accentColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Quantity selector
            Container(
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: AppTheme.accentColor.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Decrease button
                  IconButton(
                    onPressed: _decreaseQuantity,
                    icon: Icon(
                      Icons.remove,
                      color: Colors.white,
                      size: 16.sp,
                    ),
                    padding: EdgeInsets.all(4.w),
                    constraints: const BoxConstraints(),
                  ),
                  
                  // Quantity
                  Container(
                    constraints: BoxConstraints(
                      minWidth: 40.w,
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    child: Text(
                      _quantity.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  // Increase button
                  IconButton(
                    onPressed: _increaseQuantity,
                    icon: Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 16.sp,
                    ),
                    padding: EdgeInsets.all(4.w),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            
            SizedBox(width: 16.w),
            
            // Add to cart button
            Expanded(
              child: ElevatedButton(
                onPressed: () => _addToCart(product),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  'ADD TO CART',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}