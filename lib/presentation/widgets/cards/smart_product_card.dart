import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/product.dart';
import '../../../services/product/shared_product_service.dart';
import '../../../services/logging_service.dart';
import '../../widgets/quantity_selector/quantity_selector.dart';

/// A smart product card that only needs a productId and loads its own data
/// This component independently requests product details via the shared service
class SmartProductCard extends StatefulWidget {
  final String productId;
  final Function(Product)? onTap;
  final Function(Product, int)? onQuantityChanged;
  final int quantity;
  final Color? backgroundColor;

  const SmartProductCard({
    Key? key,
    required this.productId,
    this.onTap,
    this.onQuantityChanged,
    this.quantity = 0,
    this.backgroundColor,
  }) : super(key: key);

  @override
  State<SmartProductCard> createState() => _SmartProductCardState();
}

class _SmartProductCardState extends State<SmartProductCard> {
  late final SharedProductService _productService;
  Product? _product;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _productService = GetIt.instance<SharedProductService>();
    _loadProductDetails();
  }

  Future<void> _loadProductDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final product = await _productService.getProductById(widget.productId);
      
      if (product != null) {
        setState(() {
          _product = product;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'Product not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      LoggingService.logError('SmartProductCard', 'Error loading product ${widget.productId}: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load product';
        _isLoading = false;
      });
    }
  }

  void _handleTap() {
    if (_product != null && widget.onTap != null) {
      widget.onTap!(_product!);
    }
  }

  void _handleQuantityChanged(int value) {
    if (_product != null && widget.onQuantityChanged != null) {
      widget.onQuantityChanged!(_product!, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the provided background color or a default
    final cardBackground = widget.backgroundColor ?? AppTheme.secondaryColor;
    
    return GestureDetector(
      onTap: _isLoading || _hasError ? null : _handleTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: _isLoading
            ? _buildLoadingState()
            : _hasError
                ? _buildErrorState()
                : _buildProductCard(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image placeholder
        Container(
          height: 120.h,
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12.r),
              topRight: Radius.circular(12.r),
            ),
          ),
          child: Center(
            child: CircularProgressIndicator(
              color: AppTheme.accentColor,
              strokeWidth: 2.w,
            ),
          ),
        ),
        
        // Content placeholder
        Padding(
          padding: EdgeInsets.all(10.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 16.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                width: 80.w,
                height: 12.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                width: double.infinity,
                height: 36.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Error image
        Container(
          height: 120.h,
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12.r),
              topRight: Radius.circular(12.r),
            ),
          ),
          child: Center(
            child: Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 40.r,
            ),
          ),
        ),
        
        // Error message
        Padding(
          padding: EdgeInsets.all(10.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Error',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                _errorMessage,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(height: 8.h),
              TextButton(
                onPressed: _loadProductDetails,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  backgroundColor: AppTheme.accentColor.withOpacity(0.2),
                ),
                child: Text(
                  'Retry',
                  style: TextStyle(
                    color: AppTheme.accentColor,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard() {
    final product = _product!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product image
        Stack(
          children: [
            // Product image with cached network image
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.r),
                topRight: Radius.circular(12.r),
              ),
              child: CachedNetworkImage(
                imageUrl: product.image,
                height: 120.h,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade800,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.accentColor,
                      strokeWidth: 2.w,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey.shade800,
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.white,
                      size: 30.r,
                    ),
                  ),
                ),
              ),
            ),
            
            // Discount tag
            if (product.mrp! > product.price)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(12.r),
                      bottomLeft: Radius.circular(12.r),
                    ),
                  ),
                  child: Text(
'${((((product.mrp ?? 1) - (product.price ?? 0)) / (product.mrp ?? 1)) * 100).round()}% OFF',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10.sp,
                    ),
                  ),
                ),
              ),
            
            // Out of stock badge
            if (!product.inStock)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12.r),
                      topRight: Radius.circular(12.r),
                    ),
                  ),
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        'OUT OF STOCK',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        
        // Product details
        Padding(
          padding: EdgeInsets.all(10.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product name
              Text(
                product.name,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14.sp,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              SizedBox(height: 4.h),
              
              // Product weight/quantity
              if (product.weight != null && product.weight!.isNotEmpty)
                Text(
                  product.weight!,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.sp,
                  ),
                ),
              
              SizedBox(height: 8.h),
              
              // Product price
              Row(
                children: [
                  Text(
                    '${AppConstants.currencySymbol}${product.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: AppTheme.accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                  
                  SizedBox(width: 8.w),
                  
                  // MRP if different from price
                  if (product.mrp! > product.price)
                    Text(
                      '${AppConstants.currencySymbol}${product.mrp?.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.white70,
                        decoration: TextDecoration.lineThrough,
                        fontSize: 12.sp,
                      ),
                    ),
                ],
              ),
              
              SizedBox(height: 8.h),
              
              // Add to cart button or quantity selector
              product.inStock
                  ? QuantitySelector(
                      quantity: widget.quantity,
                      onChanged: _handleQuantityChanged,
                      alignHorizontal: true,
                      accentColor: AppTheme.accentColor,
                      backgroundColor: Colors.black26,
                    )
                  : ElevatedButton(
                      onPressed: null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade700,
                        disabledBackgroundColor: Colors.grey.shade700,
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white70,
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      ),
                      child: Text(
                        'Out of Stock',
                        style: TextStyle(
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }


}
