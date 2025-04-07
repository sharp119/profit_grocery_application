import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:profit_grocery_application/presentation/pages/category_products/category_products_page.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/product.dart';
import '../../blocs/product_details/product_details_bloc.dart';
import '../../blocs/product_details/product_details_event.dart';
import '../../blocs/product_details/product_details_state.dart';
import '../../widgets/base_layout.dart';
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
    return BlocProvider(
      create: (context) => ProductDetailsBloc()..add(LoadProductDetails(productId)),
      child: _ProductDetailsContent(categoryId: categoryId),
    );
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
    context.read<ProductDetailsBloc>().add(AddToCart(product, _quantity));
    
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
    return BlocConsumer<ProductDetailsBloc, ProductDetailsState>(
      listener: (context, state) {
        if (state.status == ProductDetailsStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'An error occurred'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        final cartItemCount = state.cartItemCount;
        
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
          floatingActionButton: cartItemCount > 0
              ? CartFAB(
                  itemCount: cartItemCount,
                  totalAmount: state.cartTotalAmount,
                  onTap: _navigateToCart,
                  previewImagePath: state.product?.image,
                )
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
                    return Container(
                      color: Colors.white.withOpacity(0.05),
                      padding: EdgeInsets.all(24.w),
                      child: Image.asset(
                        productImages[index],
                        fit: BoxFit.contain,
                      ),
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
                
                // Similar products section
                BlocBuilder<ProductDetailsBloc, ProductDetailsState>(
                  builder: (blocContext, blocState) {
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
                          height: 150.h,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 5, // Mock data
                            itemBuilder: (context, index) {
                              final categoryColor = product.categoryId != null
                                ? blocState.subcategoryColors[product.categoryId]
                                : AppTheme.secondaryColor;
                              
                              return Container(
                                width: 120.w,
                                margin: EdgeInsets.only(right: 12.w),
                                decoration: BoxDecoration(
                                  color: categoryColor,
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: AppTheme.accentColor.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Product image
                                    Expanded(
                                      child: Container(
                                        padding: EdgeInsets.all(8.w),
                                        child: Image.asset(
                                          '${AppConstants.assetsProductsPath}${(index % 6) + 1}.png',
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                    
                                    // Product name and price
                                    Padding(
                                      padding: EdgeInsets.all(8.w),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Similar Item ${index + 1}',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          
                                          SizedBox(height: 4.h),
                                          
                                          Text(
                                            '${AppConstants.currencySymbol}${(100 + index * 10).toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: AppTheme.accentColor,
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
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