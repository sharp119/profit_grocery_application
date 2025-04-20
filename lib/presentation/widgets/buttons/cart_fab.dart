import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:badges/badges.dart' as badges;

import '../../../core/constants/app_theme.dart';
import '../../../utils/cart_logger.dart';

/// An enhanced floating action button for cart functionality
/// Supports item count badge, item preview, and price display
class CartFAB extends StatelessWidget {
  final int itemCount;
  final double? totalAmount;
  final VoidCallback onTap;
  final String? previewImagePath;
  final bool showPreview;

  const CartFAB({
    Key? key,
    required this.itemCount,
    this.totalAmount,
    required this.onTap,
    this.previewImagePath,
    this.showPreview = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Make sure we don't show the FAB when cart is empty
    CartLogger.log('CART_FAB', 'Building CartFAB with itemCount: $itemCount, totalAmount: $totalAmount');
    
    // Detailed logging for debugging
    CartLogger.info('CART_FAB', 'CartFAB build details - itemCount type: ${itemCount.runtimeType}, value: $itemCount');
    CartLogger.info('CART_FAB', 'CartFAB build details - totalAmount type: ${totalAmount?.runtimeType}, value: $totalAmount');
    
    // Check if cart has items
    if (itemCount <= 0) {
      CartLogger.info('CART_FAB', 'Cart is empty, not showing FAB');
      return const SizedBox.shrink(); // Don't show when cart is empty
    }
    
    CartLogger.info('CART_FAB', 'Building cart FAB with $itemCount items and ₹$totalAmount');
    
    // Calculate proper image size - slightly bigger than before
    final imageSize = 48.w;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 12.h,
        ),
        decoration: BoxDecoration(
          color: AppTheme.accentColor,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Item preview with badge
            if (showPreview && previewImagePath != null)
              badges.Badge(
                position: badges.BadgePosition.topEnd(top: -6, end: -6),
                badgeAnimation: const badges.BadgeAnimation.slide(),
                badgeStyle: badges.BadgeStyle(
                  badgeColor: Colors.white,
                  padding: EdgeInsets.all(6.w),
                ),
                badgeContent: Text(
                  itemCount.toString(),
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: Container(
                  width: imageSize,
                  height: imageSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.black,
                      width: 1,
                    ),
                    // Add slight shadow for depth
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: EdgeInsets.all(3.w), // Reduced padding for bigger image
                      child: Image.asset(
                        previewImagePath!,
                        fit: BoxFit.cover, // Changed to cover for better display
                        errorBuilder: (context, error, stackTrace) {
                          // Return a fallback icon if image fails to load
                          return Icon(
                            Icons.shopping_bag,
                            color: Colors.black,
                            size: 24.w,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              )
            else
              badges.Badge(
                position: badges.BadgePosition.topEnd(top: -6, end: -6),
                badgeAnimation: const badges.BadgeAnimation.slide(),
                badgeStyle: badges.BadgeStyle(
                  badgeColor: Colors.white,
                  padding: EdgeInsets.all(6.w),
                ),
                badgeContent: Text(
                  itemCount.toString(),
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: Container(
                  width: imageSize,
                  height: imageSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.shopping_cart,
                    color: Colors.black,
                    size: 28.sp,
                  ),
                ),
              ),
            
            SizedBox(width: 12.w),
            
            // View cart text
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View cart',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                // Show total amount if available with improved styling
                if (totalAmount != null)
                  Text(
                    '₹${totalAmount!.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            
            SizedBox(width: 8.w),
            
            // Arrow icon
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.black,
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }
}