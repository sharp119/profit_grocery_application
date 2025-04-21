import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:profit_grocery_application/domain/entities/cart.dart';
import 'package:profit_grocery_application/domain/repositories/cart_repository.dart';
import 'package:profit_grocery_application/domain/repositories/product_repository.dart';
import 'package:profit_grocery_application/presentation/blocs/cart/cart_bloc.dart';
import 'package:profit_grocery_application/presentation/blocs/cart/cart_event.dart' as cart_events;
import 'package:profit_grocery_application/presentation/blocs/cart/cart_state.dart';
import 'package:profit_grocery_application/presentation/blocs/products/products_bloc.dart';
import 'package:profit_grocery_application/presentation/blocs/products/products_event.dart';
import 'package:profit_grocery_application/presentation/blocs/products/products_state.dart';
import 'package:profit_grocery_application/presentation/pages/category_products/category_products_page.dart';
import 'package:profit_grocery_application/presentation/widgets/cards/universal_product_card.dart';
import 'package:profit_grocery_application/services/cart/cart_sync_service.dart';
import 'package:profit_grocery_application/services/product/shared_product_service.dart';

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
            create: (context) => GetIt.instance<ProductsBloc>()..add(const LoadRandomProducts(6)),
          ),
          BlocProvider<ProductDetailsBloc>(
            create: (context) => ProductDetailsBloc(
              productRepository: GetIt.instance<ProductRepository>(),
              productService: GetIt.instance<SharedProductService>(),
            )..add(LoadProductDetails(productId)),
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
            create: (context) => ProductDetailsBloc(
              productRepository: GetIt.instance<ProductRepository>(),
              productService: GetIt.instance<SharedProductService>(),
            )..add(LoadProductDetails(productId)),
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
            create: (context) => GetIt.instance<ProductsBloc>()..add(const LoadRandomProducts(6)),
          ),
          BlocProvider<ProductDetailsBloc>(
            create: (context) => ProductDetailsBloc(
              productRepository: GetIt.instance<ProductRepository>(),
              productService: GetIt.instance<SharedProductService>(),
            )..add(LoadProductDetails(productId)),
          ),
        ],
        child: _ProductDetailsContent(categoryId: categoryId),
      );
    }
    
    // Case 4: Only need ProductDetailsBloc
    else {
      return BlocProvider<ProductDetailsBloc>(
        create: (context) => ProductDetailsBloc(
          productRepository: GetIt.instance<ProductRepository>(),
          productService: GetIt.instance<SharedProductService>(),
        )..add(LoadProductDetails(productId)),
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
  final PageController _imagePageController = PageController();
  int _currentImageIndex = 0;
  int _quantity = 1;

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  void _navigateToCart() {
    Navigator.pushNamed(
      context,
      AppConstants.cartRoute,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductDetailsBloc, ProductDetailsState>(
      builder: (context, state) {
        return BlocBuilder<CartBloc, CartState>(
          builder: (context, cartState) {
            // Use the cart data from CartBloc instead of product details bloc
            final cartItemCount = cartState.itemCount;
            final cartTotalAmount = cartState.total;
            
            return Scaffold(
              backgroundColor: AppTheme.backgroundColor,
              appBar: AppBar(
                title: Text(state.product?.name ?? 'Product Details'),
                actions: [
                  if (widget.categoryId != null)
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          AppConstants.firestoreCategoryProductsRoute,
                          arguments: widget.categoryId,
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
      },
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
    // Get the background color based on the product's category
    final Color backgroundColor = ColorMapper.getColorForCategory(
      product.categoryGroup ?? product.categoryId
    );
    
    final hasDiscount = product.mrp != null && product.mrp! > product.price;
    final discountPercentage = hasDiscount
        ? ((product.mrp! - product.price) / product.mrp! * 100).round()
        : 0;
    
    // Check if image is a network URL    
    final bool isNetworkImage = product.image.startsWith('http') || 
                               product.image.startsWith('https');
        
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product images with page indicator
          Stack(
            children: [
              // Image container with background
              Container(
                height: 300.h,
                width: double.infinity,
                color: backgroundColor,
                child: Center(
                  child: isNetworkImage
                      ? CachedNetworkImage(
                          imageUrl: product.image,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.accentColor,
                            ),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                        )
                      : Image.asset(
                          product.image,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.image_not_supported,
                            color: Colors.red,
                            size: 48,
                          ),
                        ),
                ),
              ),
              
              // Out of stock overlay
              if (!product.inStock)
                Container(
                  height: 300.h,
                  width: double.infinity,
                  color: Colors.black.withOpacity(0.7),
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        'OUT OF STOCK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                
              // Discount tag
              if (hasDiscount)
                Positioned(
                  top: 16.h,
                  left: 16.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: Colors.red,
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
            ],
          ),
            
          // Product information section
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
                if (product.brand != null && product.brand!.isNotEmpty) 
                  _buildSpecificationItem('Brand', product.brand!),
                if (product.weight != null && product.weight!.isNotEmpty) 
                  _buildSpecificationItem('Weight', product.weight!),
                if (product.categoryName != null && product.categoryName!.isNotEmpty) 
                  _buildSpecificationItem('Category', product.categoryName!),
                if (product.sku != null && product.sku!.isNotEmpty) 
                  _buildSpecificationItem('SKU', product.sku!),
                if (product.ingredients != null && product.ingredients!.isNotEmpty) 
                  _buildSpecificationItem('Ingredients', product.ingredients!),
                if (product.nutritionalInfo != null && product.nutritionalInfo!.isNotEmpty) 
                  _buildSpecificationItem('Nutritional Info', product.nutritionalInfo!),
                
                SizedBox(height: 16.h),
                
                // Similar products section with Firebase integration
                Text(
                  'Similar Products',
                  style: TextStyle(
                    color: AppTheme.accentColor,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                SizedBox(height: 8.h),
                
                // Use the ProductsBloc to fetch similar products
                SizedBox(
                  height: 220.h,
                  child: BlocBuilder<ProductsBloc, ProductsState>(
                    builder: (context, productsState) {
                      // Check if we already have similar products data
                      final hasProductsData = productsState.randomProducts.isNotEmpty;
                      
                      if (!hasProductsData) {
                        // Dispatch event to load random products for similar products section
                        context.read<ProductsBloc>().add(const LoadRandomProducts(6));
                        
                        // Show loading indicator while data is being fetched
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: 5,
                          itemBuilder: (context, index) {
                            return Container(
                              width: 160.w,
                              margin: EdgeInsets.only(right: 12.w),
                              child: ShimmerLoader.customContainer(
                                height: 220.h,
                                width: 160.w,
                                borderRadius: 8.r,
                              ),
                            );
                          },
                        );
                      }
                      
                      // Use random products from Firebase
                      final similarProducts = productsState.randomProducts;
                      
                      // Create scrollable list
                      return BlocBuilder<CartBloc, CartState>(
                        builder: (context, cartState) {
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: similarProducts.length,
                            itemBuilder: (context, index) {
                              final similarProduct = similarProducts[index];
                              
                              // Don't show the current product in similar products
                              if (similarProduct.id == product.id) {
                                return const SizedBox.shrink();
                              }
                              
                              // Get color for category
                              final categoryColor = ColorMapper.getColorForCategory(
                                similarProduct.categoryGroup ?? similarProduct.categoryId
                              );
                              
                              // Check if this product is in cart
                              final quantity = cartState.getItemQuantity(similarProduct.id);
                              
                              return Container(
                                width: 160.w,
                                margin: EdgeInsets.only(right: 12.w),
                                child: UniversalProductCard(
                                  product: similarProduct,
                                  onTap: () {
                                    // Navigate to the similar product details
                                    Navigator.pushNamed(
                                      context,
                                      AppConstants.productDetailsRoute,
                                      arguments: {
                                        'productId': similarProduct.id,
                                        'categoryId': similarProduct.categoryId,
                                      },
                                    );
                                  },
                                  quantity: quantity,
                                  backgroundColor: categoryColor,
                                  useBackgroundColor: true,
                                  onQuantityChanged: (qty) {
                                    if (qty <= 0) {
                                      context.read<CartBloc>().add(
                                        cart_events.RemoveFromCart(similarProduct.id),
                                      );
                                    } else {
                                      context.read<CartBloc>().add(
                                        cart_events.AddToCart(
                                          similarProduct,
                                          qty,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              );
                            },
                          );
                        }
                      );
                    },
                  ),
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
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
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
    // Find this product in the cart
    final cartBloc = BlocProvider.of<CartBloc>(context);
    final productInCart = cartBloc.state.getItem(product.id);
    final quantityInCart = productInCart?.quantity ?? 0;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor.withOpacity(0.95),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.r),
          topRight: Radius.circular(16.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Quantity selector
          Container(
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _decrementQuantity,
                  icon: Icon(
                    Icons.remove,
                    color: _quantity > 1 ? Colors.white : Colors.grey,
                  ),
                ),
                Text(
                  _quantity.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _incrementQuantity,
                  icon: const Icon(
                    Icons.add,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(width: 16.w),
          
          // Add to cart button
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                // If product is already in cart, update quantity
                // Otherwise add it to cart
                if (quantityInCart > 0) {
                  cartBloc.add(cart_events.UpdateCartItemQuantity(
                    product.id,
                    quantityInCart + _quantity,
                  ));
                } else {
                  cartBloc.add(cart_events.AddToCart(
                    product,
                    _quantity,
                  ));
                }
                
                // Show confirmation
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Added ${_quantity.toString()} ${product.name} to cart',
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: AppTheme.accentColor,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                quantityInCart > 0 ? 'UPDATE CART' : 'ADD TO CART',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}