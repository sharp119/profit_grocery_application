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
                position: badges.BadgePosition.topEnd(top: -8, end: -8),
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
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.black,
                      width: 1,
                    ),
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: EdgeInsets.all(4.w),
                      child: Image.asset(
                        previewImagePath!,
                        fit: BoxFit.contain,
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
                position: badges.BadgePosition.topEnd(top: -8, end: -8),
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
                child: Icon(
                  Icons.shopping_cart,
                  color: Colors.black,
                  size: 28.sp,
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
                
                // Show total amount if available
                if (totalAmount != null)
                  Text(
                    '₹${totalAmount!.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.7),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            
            SizedBox(width: 6.w),
            
            // Arrow icon
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.black,
              size: 14.sp,
            ),
          ],
        ),
      ),
    );
  }
}