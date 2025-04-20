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
                    // Product image with improved size and fit
                    Container(
                      width: 90.w,
                      height: 90.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(8.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(6.w), // Reduced padding for larger image
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6.r),
                        child: ImageLoader.asset(
                          image,
                          fit: BoxFit.cover, // Changed to cover for better display
                          width: 78.w,
                          height: 78.w,
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
                      
                      // Price section with improved layout
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Price column with current and original price stacked
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Current price with larger, more visible text
                              Text(
                                '${AppConstants.currencySymbol}${price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: AppTheme.accentColor,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              
                              if (mrp != null && mrp! > price)
                                // Original price (MRP) below current price
                                Text(
                                  '${AppConstants.currencySymbol}${mrp!.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12.sp,
                                    decoration: TextDecoration.lineThrough,
                                    height: 1.2,
                                  ),
                                ),
                            ],
                          ),
                          
                          const Spacer(),
                          
                          // Per unit and total amount in clean column layout
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Total amount with highlighting
                              Text(
                                '${AppConstants.currencySymbol}${itemTotal.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              
                              // Per unit text below, smaller and subdued
                              Text(
                                'Total',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11.sp,
                                  height: 1.2,
                                ),
                              ),
                            ],
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
          
          // Action bar with enhanced quantity selector and remove button
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.3),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12.r),
                bottomRight: Radius.circular(12.r),
              ),
            ),
            child: Row(
              children: [
                // Improved quantity selector with more prominent buttons
                Container(
                  height: 36.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.secondaryColor.withOpacity(0.9),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: AppTheme.accentColor.withOpacity(0.4),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Decrease quantity - larger touch target
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: quantity > 1
                              ? () => onQuantityChanged(quantity - 1)
                              : null,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(8.r),
                            bottomLeft: Radius.circular(8.r),
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w),
                            height: 36.h,
                            decoration: BoxDecoration(
                              color: quantity > 1
                                  ? Colors.transparent
                                  : Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(8.r),
                                bottomLeft: Radius.circular(8.r),
                              ),
                            ),
                            child: Icon(
                              Icons.remove,
                              size: 18.sp,
                              color: quantity > 1
                                  ? AppTheme.accentColor
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      
                      // Quantity with better visibility
                      Container(
                        constraints: BoxConstraints(
                          minWidth: 36.w,
                        ),
                        height: 36.h,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: AppTheme.accentColor.withOpacity(0.1),
                              width: 1,
                            ),
                            right: BorderSide(
                              color: AppTheme.accentColor.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          color: Colors.black.withOpacity(0.2),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        child: Text(
                          quantity.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      
                      // Increase quantity - larger touch target
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => onQuantityChanged(quantity + 1),
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(8.r),
                            bottomRight: Radius.circular(8.r),
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w),
                            height: 36.h,
                            child: Icon(
                              Icons.add,
                              size: 18.sp,
                              color: AppTheme.accentColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Enhanced remove button with better visual cues
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8.r),
                  child: InkWell(
                    onTap: onRemove,
                    borderRadius: BorderRadius.circular(8.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal:
                        10.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: Colors.red.withOpacity(0.9),
                            size: 18.sp,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Remove',
                            style: TextStyle(
                              color: Colors.red.withOpacity(0.9),
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
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