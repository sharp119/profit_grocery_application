import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/product.dart';
import '../../../data/models/product_model.dart';
import '../../widgets/image_loader.dart';

/// A product card optimized for display in the two-panel view
class FirestoreProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final Function(int) onQuantityChanged;
  final int quantity;
  final Color? categoryColor;
  final bool showDiscountTag;
  final int discountPercent;

  const FirestoreProductCard({
    Key? key,
    required this.product,
    required this.onTap,
    required this.onQuantityChanged,
    this.quantity = 0,
    this.categoryColor,
    this.showDiscountTag = false,
    this.discountPercent = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: product.inStock ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.secondaryColor.withOpacity(0.6),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: AppTheme.accentColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image with stock indicator
            Stack(
              children: [
                // Product image
                Container(
                  height: 120.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: categoryColor?.withOpacity(0.15) ?? Colors.transparent,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8.r),
                      topRight: Radius.circular(8.r),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8.r),
                      topRight: Radius.circular(8.r),
                    ),
                    child: product.inStock 
                      ? ImageLoader.network(
                          product.image,
                          fit: BoxFit.contain,
                          placeholder: Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.accentColor,
                              strokeWidth: 2.w,
                            ),
                          ),
                          errorWidget: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                            size: 40.w,
                          ),
                        )
                      : Stack(
                          alignment: Alignment.center,
                          children: [
                            // Faded image for out of stock products
                            Opacity(
                              opacity: 0.3,
                              child: ImageLoader.network(
                                product.image,
                                fit: BoxFit.contain,
                                placeholder: Container(),
                                errorWidget: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                  size: 40.w,
                                ),
                              ),
                            ),
                          ],
                        ),
                  ),
                ),
                
                // Discount tag
                if (showDiscountTag && discountPercent > 0)
                  Positioned(
                    top: 8.h,
                    left: 8.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        '$discountPercent% OFF',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                
                // Out of stock indicator
                if (!product.inStock)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8.r),
                          topRight: Radius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        'Out of Stock',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            
            // Product details
            Padding(
              padding: EdgeInsets.all(8.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name
                  Text(
                    product.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  SizedBox(height: 4.h),
                  
                  // Price section
                  Row(
                    children: [
                      // Current price
                      Text(
                        '${AppConstants.currencySymbol}${product.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: AppTheme.accentColor,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      SizedBox(width: 4.w),
                      
                      // Original price (MRP) with strikethrough
                      if (product.mrp != null && product.mrp! > product.price)
                        Text(
                          '${AppConstants.currencySymbol}${product.mrp!.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12.sp,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                  
                  SizedBox(height: 8.h),
                  
                  // Add to cart button or quantity selector
                  quantity > 0
                      ? _buildQuantitySelector()
                      : _buildAddButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Add to cart button
  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      height: 36.h,
      child: ElevatedButton(
        onPressed: product.inStock ? () => onQuantityChanged(1) : null,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: product.inStock ? AppTheme.accentColor : Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.r),
          ),
        ),
        child: Text(
          'ADD',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  // Quantity selector for products already in cart
  Widget _buildQuantitySelector() {
    return Container(
      height: 36.h,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(
          color: AppTheme.accentColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Decrease button
          InkWell(
            onTap: product.inStock ? () => onQuantityChanged(quantity - 1) : null,
            child: Container(
              width: 36.w,
              height: 36.h,
              child: Center(
                child: Icon(
                  Icons.remove,
                  color: Colors.white,
                  size: 18.sp,
                ),
              ),
            ),
          ),
          
          // Current quantity
          Text(
            quantity.toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          // Increase button
          InkWell(
            onTap: product.inStock ? () => onQuantityChanged(quantity + 1) : null,
            child: Container(
              width: 36.w,
              height: 36.h,
              child: Center(
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 18.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}