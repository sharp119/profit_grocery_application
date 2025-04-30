import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/product.dart';
import '../../../services/logging_service.dart';
import '../../widgets/buttons/add_button.dart';

/**
 * ReusableProductCard
 * 
 * A base product card component that serves as the foundation for other specialized product cards.
 * This card implements the core product display functionality and is used by other card types.
 * 
 * Usage:
 * - Used as a base component by BestsellerProductCard, StandardProductCard, etc.
 * - Provides consistent product display across the app
 * - Handles product images, pricing, and basic interactions
 * 
 * Key Features:
 * - Vertical layout with product name at top
 * - Quantity/price display in middle
 * - Action button at bottom
 * - Discount display
 * - Image loading with error handling
 * 
 * Where Used:
 * - Base Component: Extended by other product cards
 * - Custom Product Cards: When building specialized displays
 * - Consistent Layouts: For uniform product presentation
 * - Theme Integration: For app-wide product display consistency
 * 
 * Example Usage:
 * ```dart
 * ReusableProductCard(
 *   product: product,
 *   finalPrice: finalPrice,
 *   originalPrice: originalPrice,
 *   hasDiscount: hasDiscount,
 *   discountType: discountType,
 *   discountValue: discountValue,
 *   backgroundColor: categoryColor,
 *   onTap: (product) => handleTap(product),
 * )
 * ```
 */

/// A reusable product card that can be used across the app
/// Uses the new vertical layout with product name at top, quantity/price in middle, and action button at bottom
class ReusableProductCard extends StatelessWidget {
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

  const ReusableProductCard({
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
  Widget build(BuildContext context) {
    // Log when this product card is built
    LoggingService.logFirestore(
      'PRODUCT_CARD: Building card for ${product.name} (${product.id}), '
      'Price: $finalPrice, '
      'Discount: ${hasDiscount ? "$discountType: $discountValue" : "None"}'
    );
    
    return GestureDetector(
      onTap: () {
        LoggingService.logFirestore('PRODUCT_CARD: Card tapped for ${product.name}');
        if (onTap != null) {
          onTap!(product);
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
                    color: backgroundColor, // Apply category color to the image background
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
                        LoggingService.logError('PRODUCT_CARD', 'Error loading image for ${product.name}: $error');
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
                if (hasDiscount && discountValue != null && discountValue! > 0)
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
                            discountType == 'percentage' 
                              ? '${discountValue?.toInt()}%'
                              : '₹${discountValue?.toStringAsFixed(0)}',
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
                      product.name,
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
                        child: product.weight != null && product.weight!.isNotEmpty
                          ? Text(
                              product.weight!,
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
                              '${AppConstants.currencySymbol}${finalPrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: hasDiscount 
                                    ? Colors.green
                                    : AppTheme.accentColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16.sp,
                              ),
                            ),
                            // Strikethrough original price (if discounted)
                            Container(
                              height: 16.h, // Fixed height for this area
                              child: originalPrice != null && originalPrice! > finalPrice
                                ? Text(
                                    '${AppConstants.currencySymbol}${originalPrice?.toStringAsFixed(0)}',
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
                  
                  // Add button with quantity controls
                  AddButton(
                    productId: product.id,
                    sourceCardType: ProductCardType.reusable,
                    height: 36.h,
                    inStock: product.inStock,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}