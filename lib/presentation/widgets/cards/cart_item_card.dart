import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/cart.dart';

/// A reusable widget for displaying cart item cards
class CartItemCard extends StatelessWidget {
  final String productId;
  final String name;
  final String image;
  final double price;
  final int quantity;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;

  const CartItemCard({
    Key? key,
    required this.productId,
    required this.name,
    required this.image,
    required this.price,
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
      quantity: item.quantity,
      onQuantityChanged: onQuantityChanged,
      onRemove: onRemove,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Product image
          Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            padding: EdgeInsets.all(8.w),
            child: Image.asset(
              image,
              fit: BoxFit.contain,
            ),
          ),
          
          SizedBox(width: 12.w),
          
          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                
                SizedBox(height: 4.h),
                
                Text(
                  '${AppConstants.currencySymbol}${price.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: AppTheme.accentColor,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                SizedBox(height: 8.h),
                
                // Quantity selector
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Row(
                        children: [
                          // Decrease quantity
                          IconButton(
                            onPressed: quantity > 1
                                ? () => onQuantityChanged(quantity - 1)
                                : null,
                            icon: Icon(
                              Icons.remove,
                              size: 16.sp,
                              color: quantity > 1
                                  ? Colors.white
                                  : Colors.grey,
                            ),
                            padding: EdgeInsets.all(4.w),
                            constraints: const BoxConstraints(),
                          ),
                          
                          SizedBox(width: 8.w),
                          
                          // Quantity
                          Text(
                            quantity.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          
                          SizedBox(width: 8.w),
                          
                          // Increase quantity
                          IconButton(
                            onPressed: () => onQuantityChanged(quantity + 1),
                            icon: Icon(
                              Icons.add,
                              size: 16.sp,
                              color: Colors.white,
                            ),
                            padding: EdgeInsets.all(4.w),
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Remove item
                    IconButton(
                      onPressed: onRemove,
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20.sp,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}