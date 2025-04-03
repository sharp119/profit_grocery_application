import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/product.dart';

/// A reusable widget for displaying product cards
class ProductCard extends StatelessWidget {
  final String id;
  final String name;
  final String image;
  final double price;
  final double? mrp;
  final bool inStock;
  final VoidCallback onTap;
  final Function(int) onQuantityChanged;
  final int quantity;

  const ProductCard({
    Key? key,
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    this.mrp,
    required this.inStock,
    required this.onTap,
    required this.onQuantityChanged,
    this.quantity = 0,
  }) : super(key: key);

  /// Create a ProductCard from a Product entity
  factory ProductCard.fromEntity({
    required Product product,
    required VoidCallback onTap,
    required Function(int) onQuantityChanged,
    int quantity = 0,
  }) {
    return ProductCard(
      id: product.id,
      name: product.name,
      image: product.image,
      price: product.price,
      mrp: product.mrp,
      inStock: product.inStock,
      onTap: onTap,
      onQuantityChanged: onQuantityChanged,
      quantity: quantity,
    );
  }

  // Calculate discount percentage
  double? get discountPercentage {
    if (mrp != null && mrp! > price) {
      return ((mrp! - price) / mrp! * 100).roundToDouble();
    }
    return null;
  }

  // Check if the product has a discount
  bool get hasDiscount => discountPercentage != null && discountPercentage! > 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: inStock ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.secondaryColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppTheme.accentColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image and discount badge
            Stack(
              children: [
                // Product image
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12.r),
                    topRight: Radius.circular(12.r),
                  ),
                  child: Container(
                    height: 120.h,
                    width: double.infinity,
                    padding: EdgeInsets.all(8.w),
                    color: Colors.white.withOpacity(0.05),
                    child: inStock
                        ? Image.asset(
                            image,
                            fit: BoxFit.contain,
                          )
                        : Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset(
                                image,
                                fit: BoxFit.contain,
                                color: Colors.grey.withOpacity(0.5),
                                colorBlendMode: BlendMode.saturation,
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: Text(
                                  'Out of Stock',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                
                // Discount badge
                if (hasDiscount)
                  Positioned(
                    top: 8.h,
                    left: 8.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        '${discountPercentage!.toInt()}% OFF',
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
            
            // Product details
            Padding(
              padding: EdgeInsets.all(8.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name
                  Text(
                    name,
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
                        '${AppConstants.currencySymbol}${price.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: AppTheme.accentColor,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      SizedBox(width: 4.w),
                      
                      // Original price (MRP) if there is a discount
                      if (hasDiscount)
                        Text(
                          '${AppConstants.currencySymbol}${mrp!.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            // Add to cart button or quantity selector
            Padding(
              padding: EdgeInsets.all(8.w),
              child: quantity > 0
                  ? _buildQuantitySelector()
                  : _buildAddButton(),
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
      child: ElevatedButton(
        onPressed: inStock ? () => onQuantityChanged(1) : null,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: inStock ? AppTheme.accentColor : Colors.grey,
          padding: EdgeInsets.symmetric(vertical: 8.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
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
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: AppTheme.accentColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Decrease quantity
          IconButton(
            onPressed: inStock ? () => onQuantityChanged(quantity - 1) : null,
            icon: Icon(
              Icons.remove,
              size: 16.sp,
              color: inStock ? Colors.white : Colors.grey,
            ),
            padding: EdgeInsets.all(4.w),
            constraints: const BoxConstraints(),
          ),
          
          // Current quantity
          Expanded(
            child: Text(
              quantity.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Increase quantity
          IconButton(
            onPressed: inStock ? () => onQuantityChanged(quantity + 1) : null,
            icon: Icon(
              Icons.add,
              size: 16.sp,
              color: inStock ? Colors.white : Colors.grey,
            ),
            padding: EdgeInsets.all(4.w),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}