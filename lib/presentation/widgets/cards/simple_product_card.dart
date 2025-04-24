import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/product.dart';
import '../../../services/logging_service.dart';
import '../../../utils/add_button_handler.dart';

/// A simplified product card that only displays essential information
class SimpleProductCard extends StatelessWidget {
  final Product product;
  final Color backgroundColor;
  final Function(Product)? onTap;

  const SimpleProductCard({
    Key? key,
    required this.product,
    required this.backgroundColor,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Log when this product card is built
    LoggingService.logFirestore('PRODUCT_CARD_SIMPLE: Building card for ${product.name} (${product.id})');
    print('PRODUCT_CARD_SIMPLE: Building card for ${product.name} (${product.id})');
    
    // Calculate discount percentage if there's a discount
    int discountPercentage = 0;
    if (product.mrp != null && product.mrp! > product.price) {
      discountPercentage = ((((product.mrp ?? 0) - product.price) / (product.mrp ?? 1)) * 100).round();
      LoggingService.logFirestore('PRODUCT_CARD_SIMPLE: Product has discount of $discountPercentage% (${product.mrp} → ${product.price})');
      print('PRODUCT_CARD_SIMPLE: Product has discount of $discountPercentage% (${product.mrp} → ${product.price})');
    }

    return GestureDetector(
      onTap: () {
        LoggingService.logFirestore('PRODUCT_CARD_SIMPLE: Card tapped for ${product.name}');
        print('PRODUCT_CARD_SIMPLE: Card tapped for ${product.name}');
        if (onTap != null) {
          onTap!(product);
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
                        LoggingService.logError('PRODUCT_CARD_SIMPLE', 'Error loading image for ${product.name}: $error');
                        print('PRODUCT_CARD_SIMPLE ERROR: Failed to load image - $error');
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

                // Discount badge
                if (discountPercentage > 0)
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
                        '$discountPercentage% OFF',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10.sp,
                        ),
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

                  // Add button (cart functionality removed but button preserved)
                  if (product.inStock)
                    _buildAddButton()
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

  // Build the ADD button that uses AddButtonHandler
  Widget _buildAddButton() {
    return SizedBox(
      height: 36.h, // Fixed height
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // Use the centralized AddButtonHandler
          AddButtonHandler().handleAddButtonClick(
            productId: product.id,
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
  }
}