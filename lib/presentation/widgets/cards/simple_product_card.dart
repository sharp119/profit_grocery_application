/**
 * SimpleProductCard
 * 
 * A simplified product card that displays only essential product information.
 * This card is optimized for performance and minimal UI elements.
 * 
 * Usage:
 * - Used in search results and quick product views
 * - Provides basic product information
 * - Optimized for performance
 * - Minimal UI elements
 * 
 * Key Features:
 * - Essential product information only
 * - Basic discount display
 * - Lightweight implementation
 * - Performance optimized
 * 
 * Where Used:
 * - Search Results: Quick product previews
 * - Category Quick Views: Fast loading product lists
 * - Performance-Critical Sections: Where minimal UI is preferred
 * - Mobile-Optimized Views: For better performance on low-end devices
 * 
 * Example Usage:
 * ```dart
 * SimpleProductCard(
 *   product: product,
 *   backgroundColor: categoryColor,
 *   onTap: (product) => navigateToDetails(product),
 * )
 * ```
 */

/// SimpleProductCard
/// 
/// A simplified product card that displays only essential product information.
/// This card is optimized for performance and minimal UI elements.
/// 
/// Usage:
/// - Used in search results and quick product views
/// - Provides basic product information
/// - Optimized for performance
/// - Minimal UI elements
/// 
/// Key Features:
/// - Essential product information only
/// - Basic discount display
/// - Lightweight implementation
/// - Performance optimized
/// 
/// Example Usage:
/// ```dart
/// SimpleProductCard(
///   product: product,
///   backgroundColor: categoryColor,
///   onTap: (product) => navigateToDetails(product),
/// )
/// ```
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/product.dart';
import '../../../services/logging_service.dart';
import '../../../services/discount/discount_service.dart';
import '../../widgets/buttons/add_button.dart';
import '../../widgets/discount/discount_display_widget.dart';
import '../../widgets/discount/discount_provider.dart';

/// A simplified product card that only displays essential information
class SimpleProductCard extends StatefulWidget {
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
  State<SimpleProductCard> createState() => _SimpleProductCardState();
}

class _SimpleProductCardState extends State<SimpleProductCard> {
  @override
  void initState() {
    super.initState();
    // Preload discount info for this product from Firestore
    DiscountProvider.preloadDiscountInfo(widget.product.id);
  }

  @override
  void didUpdateWidget(SimpleProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id != widget.product.id) {
      // If product changed, preload the new product's discount info from Firestore
      DiscountProvider.preloadDiscountInfo(widget.product.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Log when this product card is built
    LoggingService.logFirestore('PRODUCT_CARD_SIMPLE: Building card for ${widget.product.name} (${widget.product.id})');
    print('PRODUCT_CARD_SIMPLE: Building card for ${widget.product.name} (${widget.product.id})');
    
    return GestureDetector(
      onTap: () {
        LoggingService.logFirestore('PRODUCT_CARD_SIMPLE: Card tapped for ${widget.product.name}');
        print('PRODUCT_CARD_SIMPLE: Card tapped for ${widget.product.name}');
        if (widget.onTap != null) {
          widget.onTap!(widget.product);
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
                    color: widget.backgroundColor, // Apply category color ONLY to the image background
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
                        LoggingService.logError('PRODUCT_CARD_SIMPLE', 'Error loading image for ${widget.product.name}: $error');
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

                // Discount badge using the new DiscountDisplayWidget
                Positioned(
                  top: 0,
                  right: 0,
                  child: DiscountDisplayWidget(
                    productId: widget.product.id,
                    backgroundColor: Colors.red,
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
                      widget.product.name,
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
                  if (widget.product.weight != null && widget.product.weight!.isNotEmpty)
                    Text(
                      widget.product.weight!,
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
                        '${AppConstants.currencySymbol}${widget.product.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: AppTheme.accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                        ),
                      ),

                      SizedBox(width: 8.w),

                      // MRP if different from price - check with DiscountProvider
                      if (DiscountProvider.hasDiscount(widget.product.id))
                        Text(
                          '${AppConstants.currencySymbol}${widget.product.mrp?.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Colors.white70,
                            decoration: TextDecoration.lineThrough,
                            fontSize: 12.sp,
                          ),
                        ),
                    ],
                  ),

                  SizedBox(height: 8.h),

                  // Add button with quantity controls
                  AddButton(
                    productId: widget.product.id,
                    sourceCardType: ProductCardType.simple,
                    height: 36.h,
                    inStock: widget.product.inStock,
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