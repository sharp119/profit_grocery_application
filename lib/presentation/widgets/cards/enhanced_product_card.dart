import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/product.dart';
import '../image_loader.dart';

/// An enhanced product card with improved UI following the design in Image 2
/// but keeping the dark theme from the original app
class EnhancedProductCard extends StatelessWidget {
  final String id;
  final String name;
  final String image;
  final double price;
  final double? mrp;
  final bool inStock;
  final VoidCallback onTap;
  final Function(int) onQuantityChanged;
  final int quantity;
  final Color? backgroundColor;
  final String? weight;
  final String? unit;

  const EnhancedProductCard({
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
    this.backgroundColor,
    this.weight,
    this.unit,
  }) : super(key: key);

  /// Create a ProductCard from a Product entity
  factory EnhancedProductCard.fromEntity({
    required Product product,
    required VoidCallback onTap,
    required Function(int) onQuantityChanged,
    int quantity = 0,
    Color? backgroundColor,
  }) {
    // Extract weight and unit if available in the product name
    String? weight;
    String? unit;
    String displayName = product.name;

    // Check for common patterns like "500g", "1kg", "250ml", etc.
    final RegExp weightPattern = RegExp(r'(\d+(?:\.\d+)?)\s*(g|kg|ml|l|pcs)');
    final match = weightPattern.firstMatch(product.name);
    
    if (match != null) {
      weight = match.group(1);
      unit = match.group(2);
      
      // Remove weight/unit from the display name if found at the end
      if (product.name.endsWith('${weight!}${unit!}')) {
        displayName = product.name.substring(0, product.name.length - ('${weight}${unit}'.length)).trim();
      }
    }
    
    // Alternatively, check if weight info is in the product fields
    String? productWeight = product.weight;
    if (weight == null && productWeight != null && productWeight.isNotEmpty) {
      // Try to parse the product weight field
      final weightMatch = weightPattern.firstMatch(productWeight);
      if (weightMatch != null) {
        weight = weightMatch.group(1);
        unit = weightMatch.group(2);
      } else {
        weight = productWeight;
        unit = '';
      }
    }

    return EnhancedProductCard(
      id: product.id,
      name: displayName,
      image: product.image,
      price: product.price,
      mrp: product.mrp,
      inStock: product.inStock,
      onTap: onTap,
      onQuantityChanged: onQuantityChanged,
      quantity: quantity,
      backgroundColor: backgroundColor,
      weight: weight,
      unit: unit,
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
    // Use a fixed height container that's shorter to prevent overflow
    return Container(
      height: 230.h, // Reduced fixed height to prevent overflow
      child: GestureDetector(
        onTap: inStock ? onTap : null,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor, // Use the app's dark theme
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: AppTheme.accentColor.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Discount badge and image - Fixed height
              SizedBox(
                height: 120.h, // Fixed height for image section
                child: Stack(
                  children: [
                    // Product image
                    Container(
                      width: double.infinity,
                      height: 120.h,
                      padding: EdgeInsets.all(8.r),
                      child: _buildProductImage(),
                    ),
                    
                    // Discount badge
                    if (hasDiscount)
                      Positioned(
                        top: 8.r,
                        left: 8.r,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.r, vertical: 2.r),
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
                    
                    // Out of stock overlay
                    if (!inStock)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(8.r),
                              topRight: Radius.circular(8.r),
                            ),
                          ),
                          child: Center(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.r,
                                vertical: 4.r,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.9),
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
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Product details - Fixed height section with simplified layout
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(8.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Product name - Limited height and lines
                      Expanded(
                        flex: 2,
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      
                      // Weight/quantity - if available
                      if (weight != null && unit != null)
                        Text(
                          '$weight $unit',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      
                      // Price section with smaller height
                      Expanded(
                        flex: 1,
                        child: Row(
                          children: [
                            // Current price
                            Text(
                              '${AppConstants.currencySymbol}${price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentColor,
                              ),
                            ),
                            
                            SizedBox(width: 4.w),
                            
                            // Original price if there's a discount
                            if (hasDiscount)
                              Flexible(
                                child: Text(
                                  '${AppConstants.currencySymbol}${mrp!.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      // Add to cart button - Fixed height
                      SizedBox(
                        height: 30.h, // Slightly smaller button
                        child: quantity > 0
                            ? _buildQuantitySelector()
                            : _buildAddButton(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to build product image with correct asset/network handling
  Widget _buildProductImage() {
    // Check if image is a network URL or an asset path
    bool isNetworkImage = image.startsWith('http') || image.startsWith('https');
    
    if (isNetworkImage) {
      // It's a network image
      return inStock
          ? ImageLoader.network(
              image,
              fit: BoxFit.contain,
              errorWidget: Icon(
                Icons.image_not_supported,
                color: Colors.grey,
                size: 40.r,
              ),
            )
          : Opacity(
              opacity: 0.5,
              child: ImageLoader.network(
                image,
                fit: BoxFit.contain,
                errorWidget: Icon(
                  Icons.image_not_supported,
                  color: Colors.grey,
                  size: 40.r,
                ),
              ),
            );
    } else {
      // It's an asset image
      return inStock
          ? Image.asset(
              image,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                print('Error loading asset image: $error for path: $image');
                return Icon(
                  Icons.image_not_supported,
                  color: Colors.grey,
                  size: 40.r,
                );
              },
            )
          : Opacity(
              opacity: 0.5,
              child: Image.asset(
                image,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.image_not_supported,
                    color: Colors.grey,
                    size: 40.r,
                  );
                },
              ),
            );
    }
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      height: 30.h,
      child: ElevatedButton(
        onPressed: inStock ? () => onQuantityChanged(1) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentColor,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.r),
          ),
          padding: EdgeInsets.zero,
          elevation: 0,
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

  Widget _buildQuantitySelector() {
    return Container(
      height: 30.h,
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.accentColor),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Decrease quantity
          InkWell(
            onTap: inStock ? () => onQuantityChanged(quantity - 1) : null,
            child: Container(
              width: 30.w,
              height: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.accentColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(3.r),
                  bottomLeft: Radius.circular(3.r),
                ),
              ),
              child: Icon(
                Icons.remove,
                color: Colors.black,
                size: 18.r,
              ),
            ),
          ),
          
          // Quantity
          Expanded(
            child: Center(
              child: Text(
                quantity.toString(),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          // Increase quantity
          InkWell(
            onTap: inStock ? () => onQuantityChanged(quantity + 1) : null,
            child: Container(
              width: 30.w,
              height: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.accentColor,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(3.r),
                  bottomRight: Radius.circular(3.r),
                ),
              ),
              child: Icon(
                Icons.add,
                color: Colors.black,
                size: 18.r,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
