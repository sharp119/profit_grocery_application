import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get_it/get_it.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/product.dart';
import '../../../services/cart/improved_cart_service.dart';
import '../../../services/discount/discount_calculator.dart';
import '../../../services/logging_service.dart';

/// An improved product card that simplifies the add-to-cart flow
/// Only passes the product ID to the cart service
class ImprovedProductCard extends StatefulWidget {
  // Product data
  final Product product;
  final double finalPrice;
  final double? originalPrice; // Optional original price (for displaying strikethrough)
  final bool hasDiscount;
  final String? discountType; // 'percentage' or 'flat'
  final double? discountValue;

  // Card appearance
  final Color backgroundColor;
  
  // Callbacks
  final Function(Product)? onTap;

  const ImprovedProductCard({
    Key? key,
    required this.product,
    required this.finalPrice,
    this.originalPrice,
    this.hasDiscount = false,
    this.discountType,
    this.discountValue,
    required this.backgroundColor,
    this.onTap,
  }) : super(key: key);

  @override
  State<ImprovedProductCard> createState() => _ImprovedProductCardState();
}

class _ImprovedProductCardState extends State<ImprovedProductCard> {
  final ImprovedCartService _cartService = GetIt.instance<ImprovedCartService>();
  bool _initialized = false;
  
  @override
  void initState() {
    super.initState();
    _initializeCartService();
  }
  
  Future<void> _initializeCartService() async {
    if (!_initialized) {
      await _cartService.initialize();
      _initialized = true;
      // Force a rebuild after initialization to show the correct quantity
      if (mounted) setState(() {});
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Get current quantity from cart service
    final quantity = _cartService.getQuantity(widget.product.id);
    
    // Log when this product card is built
    LoggingService.logFirestore(
      'IMPROVED_PRODUCT_CARD: Building card for ${widget.product.name} (${widget.product.id}), '
      'Price: ${widget.finalPrice}, Quantity: $quantity, '
      'Discount: ${widget.hasDiscount ? "${widget.discountType}: ${widget.discountValue}" : "None"}'
    );
    
    // Get formatted discount for display using our calculator
    final String formattedDiscount = widget.hasDiscount && widget.discountType != null && widget.discountValue != null
        ? DiscountCalculator.formatDiscountForDisplay(
            discountType: widget.discountType,
            discountValue: widget.discountValue,
          )
        : '';
    
    return GestureDetector(
      onTap: () {
        LoggingService.logFirestore('IMPROVED_PRODUCT_CARD: Card tapped for ${widget.product.name}');
        if (widget.onTap != null) {
          widget.onTap!(widget.product);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.secondaryColor,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image with discount badge if applicable
            Stack(
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12.r),
                    topRight: Radius.circular(12.r),
                  ),
                  child: Container(
                    height: 120.h,
                    width: double.infinity,
                    color: widget.backgroundColor, // Apply category color to the image background
                    padding: EdgeInsets.all(10.r),
                    child: CachedNetworkImage(
                      imageUrl: widget.product.image,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.accentColor,
                          strokeWidth: 2.w,
                        ),
                      ),
                      errorWidget: (context, url, error) {
                        LoggingService.logError('IMPROVED_PRODUCT_CARD', 'Error loading image for ${widget.product.name}: $error');
                        return Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.white,
                            size: 30.r,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Discount badge (top right) - VERTICAL LAYOUT
                if (widget.hasDiscount && widget.discountValue != null && widget.discountValue! > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 48.w, // Fixed width for vertical layout
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 3.r,
                            offset: Offset(0, 1.h),
                          ),
                        ],
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(12.r),
                          bottomLeft: Radius.circular(12.r),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Discount value on top (either % or ₹)
                          Text(
                            widget.discountType == 'percentage' 
                              ? '${widget.discountValue?.toInt()}%'
                              : '₹${widget.discountValue?.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14.sp,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          // OFF text below
                          Text(
                            'OFF',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.sp,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                // Out of stock overlay
                if (!widget.product.inStock)
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

            // Product details - layout with 3 rows
            Padding(
              padding: EdgeInsets.all(10.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Product name (full width) - limited to 2 lines with ellipsis
                  Container(
                    width: double.infinity,
                    height: 40.h, // Fixed height to accommodate exactly 2 lines
                    child: Text(
                      widget.product.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14.sp,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis, // Ensures text ends with "..." if trimmed
                    ),
                  ),
                  
                  SizedBox(height: 8.h), // Space between name and second row
                  
                  // Row 2: Two equal columns for Weight/Quantity and Price
                  Row(
                    children: [
                      // Left column: Weight/Quantity
                      Expanded(
                        child: widget.product.weight != null && widget.product.weight!.isNotEmpty
                          ? Text(
                              widget.product.weight!,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12.sp,
                              ),
                            )
                          : SizedBox(height: 16.h), // Maintain consistent height
                      ),
                      
                      // Right column: Price and original price
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end, // Right-align text
                          children: [
                            // Current price
                            Text(
                              '${AppConstants.currencySymbol}${widget.finalPrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: widget.hasDiscount 
                                    ? Colors.green
                                    : AppTheme.accentColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16.sp,
                              ),
                            ),
                            // Strikethrough original price (if discounted)
                            Container(
                              height: 16.h, // Fixed height for this area
                              child: widget.originalPrice != null && widget.originalPrice! > widget.finalPrice
                                ? Text(
                                    '${AppConstants.currencySymbol}${widget.originalPrice?.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      decoration: TextDecoration.lineThrough,
                                      fontSize: 12.sp,
                                    ),
                                  )
                                : SizedBox(), // Empty but takes up the same space
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 8.h), // Space before the button
                  
                  // Row 3: Add button or quantity controls (with consistent height)
                  if (widget.product.inStock)
                    _buildQuantityControl(context, quantity)
                  else
                    SizedBox(
                      height: 36.h, // Same fixed height as the ADD button
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade700,
                          disabledBackgroundColor: Colors.grey.shade700,
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white70,
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                          // Ensure consistent shape with ADD button
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                        child: Text(
                          'Out of Stock',
                          style: TextStyle(
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build quantity control based on current quantity
  Widget _buildQuantityControl(BuildContext context, int quantity) {
    if (quantity <= 0) {
      // Show "Add" button if not in cart
      return SizedBox(
        height: 36.h, // Fixed height
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            LoggingService.logFirestore('IMPROVED_PRODUCT_CARD: Add button pressed for ${widget.product.name}');
            // Only pass the product ID to the cart service
            _cartService.addToCartById(
              context: context,
              productId: widget.product.id,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentColor,
            foregroundColor: Colors.black,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
          ),
          child: Text(
            'ADD',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
            ),
          ),
        ),
      );
    } else {
      // Show quantity selector if in cart
      return Row(
        children: <Widget>[
          // Minus button
          _buildQuantityButton(
            icon: Icons.remove,
            onPressed: () {
              LoggingService.logFirestore('IMPROVED_PRODUCT_CARD: Decrease quantity for ${widget.product.name} to ${quantity - 1}');
              _cartService.updateQuantity(
                context: context,
                productId: widget.product.id,
                quantity: quantity - 1,
              );
            },
          ),
          
          // Quantity display
          Expanded(
            child: Container(
              height: 36.h,
              alignment: Alignment.center,
              child: Text(
                quantity.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
            ),
          ),
          
          // Plus button
          _buildQuantityButton(
            icon: Icons.add,
            onPressed: () {
              LoggingService.logFirestore('IMPROVED_PRODUCT_CARD: Increase quantity for ${widget.product.name} to ${quantity + 1}');
              _cartService.updateQuantity(
                context: context,
                productId: widget.product.id,
                quantity: quantity + 1,
              );
            },
          ),
        ],
      );
    }
  }

  // Helper method to build quantity control buttons
  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 36.w,
      height: 36.h,
      decoration: BoxDecoration(
        color: AppTheme.accentColor,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon),
        color: Colors.black,
        iconSize: 18.r,
        onPressed: onPressed,
      ),
    );
  }
}