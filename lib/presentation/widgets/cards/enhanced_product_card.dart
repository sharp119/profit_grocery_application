import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/product.dart';
import '../../../services/product/product_service.dart';
import '../../widgets/image_loader.dart';

/// An enhanced product card with premium design and Firebase integration
class EnhancedProductCard extends StatefulWidget {
  final String id;
  final String? name;
  final String? image;
  final double? price;
  final double? mrp;
  final bool? inStock;
  final String? categoryId; // Added categoryId parameter
  final VoidCallback onTap;
  final Function(int) onQuantityChanged;
  final int quantity;
  final Color? backgroundColor;
  final bool showAddButton;
  final bool loadFromFirebase;

  const EnhancedProductCard({
    Key? key,
    required this.id,
    this.name,
    this.image,
    this.price,
    this.mrp,
    this.inStock,
    this.categoryId, // Added categoryId parameter
    required this.onTap,
    required this.onQuantityChanged,
    this.quantity = 0,
    this.backgroundColor,
    this.showAddButton = true,
    this.loadFromFirebase = true,
  }) : super(key: key);

  /// Create a EnhancedProductCard from a Product entity
  factory EnhancedProductCard.fromEntity({
    required Product product,
    required VoidCallback onTap,
    required Function(int) onQuantityChanged,
    int quantity = 0,
    Color? backgroundColor,
    bool showAddButton = true,
  }) {
    return EnhancedProductCard(
      id: product.id,
      name: product.name,
      image: product.image,
      price: product.price,
      mrp: product.mrp,
      inStock: product.inStock,
      categoryId: product.categoryId, // Pass the categoryId
      onTap: onTap,
      onQuantityChanged: onQuantityChanged,
      quantity: quantity,
      backgroundColor: backgroundColor,
      showAddButton: showAddButton,
      loadFromFirebase: false,
    );
  }

  @override
  State<EnhancedProductCard> createState() => _EnhancedProductCardState();
}

class _EnhancedProductCardState extends State<EnhancedProductCard> {
  Product? _product;
  bool _loading = false;
  bool _error = false;
  
  @override
  void initState() {
    super.initState();
    
    if (widget.loadFromFirebase) {
      _fetchProductFromFirebase();
    } else {
      // Use the provided data
      _product = Product(
        id: widget.id,
        name: widget.name ?? 'Product',
        image: widget.image ?? '',
        price: widget.price ?? 0.0,
        mrp: widget.mrp,
        inStock: widget.inStock ?? true,
        categoryId: widget.categoryId ?? 'unknown', // Use the provided categoryId or a default value
      );
    }
  }
  
  Future<void> _fetchProductFromFirebase() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = false;
      });
    }
    
    try {
      final productService = GetIt.instance<ProductService>();
      final product = await productService.getProductById(widget.id);
      
      if (mounted) {
        setState(() {
          _product = product;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = true;
          _loading = false;
        });
      }
    }
  }

  // Calculate discount percentage
  double? get discountPercentage {
    final product = _product;
    if (product == null) return null;
    
    if (product.mrp != null && product.mrp! > product.price) {
      return ((product.mrp! - product.price) / product.mrp! * 100).roundToDouble();
    }
    return null;
  }

  // Check if the product has a discount
  bool get hasDiscount => discountPercentage != null && discountPercentage! > 0;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _buildLoadingState();
    }
    
    if (_error || _product == null) {
      return _buildErrorState();
    }
    
    final product = _product!;
    
    // Get screen dimensions to adapt sizing
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calculate responsive dimensions
    final gridItemWidth = (screenWidth / 2) - 24;
    final aspectRatio = 0.7;
    final calculatedHeight = gridItemWidth / aspectRatio;
    
    // Adapt dimensions proportionally to screen size
    final imageHeight = (calculatedHeight * 0.35).clamp(70.0, 110.0);
    final borderRadius = 12.r;
    
    return GestureDetector(
      onTap: product.inStock ? widget.onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: AppTheme.accentColor.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Product image and discount badge
              Stack(
                children: [
                  // Product image with colored background
                  Container(
                    height: imageHeight,
                    width: double.infinity,
                    color: widget.backgroundColor ?? AppTheme.secondaryColor,
                    padding: EdgeInsets.all(8.r),
                    child: product.inStock
                        ? ImageLoader.network(
                            product.image,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: imageHeight,
                            borderRadius: 4.0,
                            errorWidget: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey.withOpacity(0.5),
                              size: imageHeight * 0.5,
                            ),
                          )
                        : Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                color: widget.backgroundColor ?? AppTheme.secondaryColor,
                                child: ImageLoader.network(
                                  product.image,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  height: imageHeight,
                                  borderRadius: 4.0,
                                  color: Colors.grey.withOpacity(0.5),
                                  colorBlendMode: BlendMode.saturation,
                                  errorWidget: Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey.withOpacity(0.3),
                                    size: imageHeight * 0.5,
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6.w,
                                  vertical: 3.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: Text(
                                  'Out of Stock',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                  
                  // Discount badge - more premium look
                  if (hasDiscount)
                    Positioned(
                      top: 8.h,
                      left: 8.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          '${discountPercentage!.toInt()}% OFF',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              
              // Product details
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(8.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Product name
                      Text(
                        product.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          height: 1.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      SizedBox(height: 4.h),
                      
                      // Weight info if available
                      if (product.weight != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: 2.h),
                          child: Text(
                            product.weight!,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 10.sp,
                            ),
                          ),
                        ),
                      
                      // Spacer that takes remaining space
                      const Spacer(),
                      
                      // Price section
                      Row(
                        children: [
                          // Current price
                          Text(
                            '${AppConstants.currencySymbol}${product.price.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: AppTheme.accentColor,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          
                          SizedBox(width: 4.w),
                          
                          // Original price (MRP) if there is a discount
                          if (hasDiscount)
                            Expanded(
                              child: Text(
                                '${AppConstants.currencySymbol}${product.mrp!.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.lineThrough,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                      
                      SizedBox(height: 6.h),
                      
                      // Add to cart button or quantity selector
                      if (widget.showAddButton)
                        widget.quantity > 0
                            ? _buildQuantitySelector()
                            : _buildAddButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Shimmer for image
          Container(
            height: 110.h,
            width: double.infinity,
            color: AppTheme.secondaryColor,
          ),
          
          // Shimmer for content
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(8.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 12.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    height: 12.h,
                    width: 100.w,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: 32.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorState() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.red.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.withOpacity(0.7),
            size: 32.sp,
          ),
          SizedBox(height: 8.h),
          Text(
            'Error loading product',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          SizedBox(
            height: 28.h,
            child: TextButton(
              onPressed: _fetchProductFromFirebase,
              child: Text(
                'Retry',
                style: TextStyle(
                  color: AppTheme.accentColor,
                  fontSize: 12.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Add to cart button with premium styling
  Widget _buildAddButton() {
    final product = _product!;
    
    return SizedBox(
      width: double.infinity,
      height: 32.h,
      child: ElevatedButton(
        onPressed: product.inStock ? () => widget.onQuantityChanged(1) : null,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: product.inStock ? AppTheme.accentColor : Colors.grey,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.r),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_shopping_cart,
              size: 16.sp,
            ),
            SizedBox(width: 4.w),
            Text(
              'ADD',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Quantity selector with premium styling
  Widget _buildQuantitySelector() {
    return Container(
      height: 32.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(6.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.7),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Decrease quantity
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(6.r),
              bottomLeft: Radius.circular(6.r),
            ),
            child: InkWell(
              onTap: () => widget.onQuantityChanged(widget.quantity - 1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(6.r),
                bottomLeft: Radius.circular(6.r),
              ),
              child: Container(
                width: 32.w,
                height: double.infinity,
                alignment: Alignment.center,
                child: Icon(
                  Icons.remove,
                  size: 16.sp,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          // Current quantity
          Expanded(
            child: Container(
              alignment: Alignment.center,
              child: Text(
                widget.quantity.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // Increase quantity
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(6.r),
              bottomRight: Radius.circular(6.r),
            ),
            child: InkWell(
              onTap: () => widget.onQuantityChanged(widget.quantity + 1),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(6.r),
                bottomRight: Radius.circular(6.r),
              ),
              child: Container(
                width: 32.w,
                height: double.infinity,
                alignment: Alignment.center,
                child: Icon(
                  Icons.add,
                  size: 16.sp,
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