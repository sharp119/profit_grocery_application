import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/bestseller_product.dart';
import '../../../services/logging_service.dart';

/// A specialized product card for bestseller products
/// Displays both regular product information and bestseller-specific discounts
class BestsellerProductCard extends StatelessWidget {
  final BestsellerProduct bestsellerProduct;
  final Color backgroundColor;
  final Function(BestsellerProduct)? onTap;
  final Function(BestsellerProduct, int)? onQuantityChanged;
  final int quantity;
  final bool showBestsellerBadge;

  const BestsellerProductCard({
    Key? key,
    required this.bestsellerProduct,
    required this.backgroundColor,
    this.onTap,
    this.onQuantityChanged,
    this.quantity = 0,
    this.showBestsellerBadge = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final product = bestsellerProduct.product;
    
    // Log when this product card is built
    LoggingService.logFirestore(
      'BESTSELLER_CARD: Building card for ${product.name} (${product.id}), '
      'Original price: ${product.price}, Final price: ${bestsellerProduct.finalPrice}, '
      'Discount: ${bestsellerProduct.hasSpecialDiscount ? "${bestsellerProduct.discountType}: ${bestsellerProduct.discountValue}" : "None"}'
    );
    
    print(
      'BESTSELLER_CARD: Building card for ${product.name} (${product.id}), '
      'Original price: ${product.price}, Final price: ${bestsellerProduct.finalPrice}, '
      'Discount: ${bestsellerProduct.hasSpecialDiscount ? "${bestsellerProduct.discountType}: ${bestsellerProduct.discountValue}" : "None"}'
    );
    
    // Calculate total discount percentage
    final discountPercentage = bestsellerProduct.totalDiscountPercentage.round();
    final discountVal = bestsellerProduct.discountValue?.toInt();

    return GestureDetector(
      onTap: () {
        LoggingService.logFirestore('BESTSELLER_CARD: Card tapped for ${product.name}');
        print('BESTSELLER_CARD: Card tapped for ${product.name}');
        if (onTap != null) {
          onTap!(bestsellerProduct);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.secondaryColor, // Default background for the entire card
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
                    color: backgroundColor, // Apply category color ONLY to the image background
                    padding: EdgeInsets.all(10.r),
                    child: CachedNetworkImage(
                      imageUrl: product.image,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.accentColor,
                          strokeWidth: 2.w,
                        ),
                      ),
                      errorWidget: (context, url, error) {
                        LoggingService.logError('BESTSELLER_CARD', 'Error loading image for ${product.name}: $error');
                        print('BESTSELLER_CARD ERROR: Failed to load image - $error');
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

                // Unified Discount Label (top right) - VERTICAL LAYOUT
                if (bestsellerProduct.hasSpecialDiscount || discountPercentage > 0)
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
                          // Discount Value on top - Shows either percentage or flat amount
                          Text(
                            bestsellerProduct.discountType == 'percentage' 
                              ? '$discountVal%'
                              : '₹${bestsellerProduct.discountValue?.toStringAsFixed(0)}',
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
                  // Product name - Increase height and ensure proper constraints
                  Container(
                    height: 38.h, // Fixed height for product name
                    child: Text(
                      product.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14.sp,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Product weight/quantity
                  if (product.weight != null && product.weight!.isNotEmpty)
                    Text(
                      product.weight!,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12.sp,
                      ),
                    )
                  else
                    SizedBox(height: 4.h), // Ensure consistent height even without weight
                    
                  SizedBox(height: 4.h),

                  // Product price with bestseller discount
                  Row(
                    children: <Widget>[
                      // Display final price (with bestseller discount applied)
                      Text(
                        '${AppConstants.currencySymbol}${bestsellerProduct.finalPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: bestsellerProduct.hasSpecialDiscount 
                              ? Colors.green // Highlight bestseller prices
                              : AppTheme.accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                        ),
                      ),

                      SizedBox(width: 8.w),

                      // Original price if there's a discount
                      if (product.mrp != null && product.mrp! > bestsellerProduct.finalPrice)
                        Text(
                          '${AppConstants.currencySymbol}${product.mrp?.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Colors.white70,
                            decoration: TextDecoration.lineThrough,
                            fontSize: 12.sp,
                          ),
                        )
                      
                      // Regular price if there's only a bestseller discount
                      else if (bestsellerProduct.hasSpecialDiscount)
                        Text(
                          '${AppConstants.currencySymbol}${product.price.toStringAsFixed(0)}',
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
                  if (product.inStock)
                    _buildQuantityControl()
                  else
                    ElevatedButton(
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
        ),
      ),
    );
  }

  // Build quantity control based on current quantity
  Widget _buildQuantityControl() {
    if (quantity <= 0) {
      // Show "Add" button if not in cart
      return SizedBox(
        height: 36.h, // Fixed height
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            LoggingService.logFirestore('BESTSELLER_CARD: Add button pressed for ${bestsellerProduct.name}');
            print('BESTSELLER_CARD: Add button pressed for ${bestsellerProduct.name}');
            if (onQuantityChanged != null) {
              onQuantityChanged!(bestsellerProduct, 1);
            }
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
              LoggingService.logFirestore('BESTSELLER_CARD: Decrease quantity for ${bestsellerProduct.name} to ${quantity - 1}');
              print('BESTSELLER_CARD: Decrease quantity for ${bestsellerProduct.name} to ${quantity - 1}');
              if (onQuantityChanged != null) {
                onQuantityChanged!(bestsellerProduct, quantity - 1);
              }
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
              LoggingService.logFirestore('BESTSELLER_CARD: Increase quantity for ${bestsellerProduct.name} to ${quantity + 1}');
              print('BESTSELLER_CARD: Increase quantity for ${bestsellerProduct.name} to ${quantity + 1}');
              if (onQuantityChanged != null) {
                onQuantityChanged!(bestsellerProduct, quantity + 1);
              }
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