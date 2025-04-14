import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/cart.dart';
import '../image_loader.dart';

/// A reusable widget for displaying cart item cards
class CartItemCard extends StatelessWidget {
  final String productId;
  final String name;
  final String image;
  final double price;
  final double? mrp;
  final int quantity;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;

  const CartItemCard({
    Key? key,
    required this.productId,
    required this.name,
    required this.image,
    required this.price,
    this.mrp,
    required this.quantity,
    required this.onQuantityChanged,
    required this.onRemove,
  }) : super(key: key);

  /// Create a CartItemCard from a CartItem entity
  factory CartItemCard.fromEntity({
    required CartItem item,
    required Function(int) onQuantityChanged,
    required VoidCallback onRemove,
  }) {
    return CartItemCard(
      productId: item.productId,
      name: item.name,
      image: item.image,
      price: item.price,
      mrp: item.mrp,
      quantity: item.quantity,
      onQuantityChanged: onQuantityChanged,
      onRemove: onRemove,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate discount percentage if MRP is available
    double? discountPercentage;
    if (mrp != null && mrp! > price) {
      discountPercentage = ((mrp! - price) / mrp! * 100).round().toDouble();
    }
    
    // Calculate item total
    final itemTotal = price * quantity;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product details section
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image with discount badge
                Stack(
                  children: [
                    // Product image with our improved ImageLoader
                    Container(
                      width: 80.w,
                      height: 80.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      padding: EdgeInsets.all(8.w),
                      child: ImageLoader.asset(
                        image,
                        fit: BoxFit.contain,
                        width: 64.w,
                        height: 64.w,
                        errorWidget: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey.withOpacity(0.5),
                          size: 24.sp,
                        ),
                      ),
                    ),
                    
                    // Discount badge
                    if (discountPercentage != null)
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(8.r),
                              bottomRight: Radius.circular(8.r),
                            ),
                          ),
                          child: Text(
                            '${discountPercentage.toInt()}% OFF',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                
                SizedBox(width: 12.w),
                
                // Product details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product name
                      Text(
                        name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      SizedBox(height: 8.h),
                      
                      // Price section
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Current price
                          Text(
                            '${AppConstants.currencySymbol}${price.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: AppTheme.accentColor,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          
                          if (mrp != null && mrp! > price) ...[
                            SizedBox(width: 8.w),
                            
                            // Original price (MRP)
                            Text(
                              '${AppConstants.currencySymbol}${mrp!.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12.sp,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                          
                          const Spacer(),
                          
                          // Item total
                          Text(
                            '${AppConstants.currencySymbol}${itemTotal.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Divider
          Divider(
            color: Colors.grey.withOpacity(0.2),
            height: 1,
          ),
          
          // Action bar (quantity selector and remove button)
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                // Quantity label
                Text(
                  'Qty:',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14.sp,
                  ),
                ),
                
                SizedBox(width: 12.w),
                
                // Quantity selector
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(4.r),
                    border: Border.all(
                      color: AppTheme.accentColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Decrease quantity
                      InkWell(
                        onTap: quantity > 1
                            ? () => onQuantityChanged(quantity - 1)
                            : null,
                        child: Container(
                          padding: EdgeInsets.all(6.w),
                          child: Icon(
                            Icons.remove,
                            size: 16.sp,
                            color: quantity > 1
                                ? Colors.white
                                : Colors.grey,
                          ),
                        ),
                      ),
                      
                      // Vertical divider
                      Container(
                        height: 24.h,
                        width: 1,
                        color: Colors.grey.withOpacity(0.3),
                      ),
                      
                      // Quantity
                      Container(
                        constraints: BoxConstraints(
                          minWidth: 32.w,
                        ),
                        alignment: Alignment.center,
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        child: Text(
                          quantity.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      
                      // Vertical divider
                      Container(
                        height: 24.h,
                        width: 1,
                        color: Colors.grey.withOpacity(0.3),
                      ),
                      
                      // Increase quantity
                      InkWell(
                        onTap: () => onQuantityChanged(quantity + 1),
                        child: Container(
                          padding: EdgeInsets.all(6.w),
                          child: Icon(
                            Icons.add,
                            size: 16.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Remove button
                TextButton.icon(
                  onPressed: onRemove,
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.red.withOpacity(0.8),
                    size: 18.sp,
                  ),
                  label: Text(
                    'Remove',
                    style: TextStyle(
                      color: Colors.red.withOpacity(0.8),
                      fontSize: 12.sp,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}