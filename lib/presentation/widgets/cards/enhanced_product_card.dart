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
    // More compact fixed height to make card less tall
    return Container(
      height: 210.h, // Even more reduced height
      child: GestureDetector(
        onTap: inStock ? onTap : null,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: AppTheme.accentColor.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Discount badge and image - Reduced fixed height
              SizedBox(
                height: 100.h, // Smaller image area
                child: Stack(
                  children: [
                    // Product image
                    Container(
                      width: double.infinity,
                      height: 100.h, // Smaller image container
                      padding: EdgeInsets.all(6.r), // Reduced padding
                      child: _buildProductImage(),
                    ),
                    
                    // Discount badge - Same position
                    if (hasDiscount)
                      Positioned(
                        top: 6.r,
                        left: 6.r,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 5.r, vertical: 1.r),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(3.r),
                          ),
                          child: Text(
                            '${discountPercentage!.toInt()}% OFF',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    
                    // Out of stock overlay - Same styling
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
                                horizontal: 6.r,
                                vertical: 3.r,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(3.r),
                              ),
                              child: Text(
                                'Out of Stock',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.sp,
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
              
              // Product details - Compact layout with minimal spacing
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(6.r, 4.r, 6.r, 6.r), // Tighter padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Product name - Limited height and lines
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          height: 1.1, // Tighter line height
                        ),
                      ),
                      
                      SizedBox(height: 2.h), // Minimal spacing
                      
                      // Weight/quantity - if available
                      if (weight != null && unit != null)
                        Text(
                          '$weight $unit',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey,
                            fontWeight: FontWeight.w400,
                            height: 1.0, // Tighter line height
                          ),
                        ),
                      
                      SizedBox(height: 2.h), // Minimal spacing
                      
                      // Price section - Compact
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          // Current price
                          Text(
                            '${AppConstants.currencySymbol}${price.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accentColor,
                              height: 1.0, // Tighter line height
                            ),
                          ),
                          
                          SizedBox(width: 4.w),
                          
                          // Original price if there's a discount
                          if (hasDiscount)
                            Flexible(
                              child: Text(
                                '${AppConstants.currencySymbol}${mrp!.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                  height: 1.0, // Tighter line height
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                      
                      Spacer(flex: 1), // Push button to bottom
                      
                      // Add to cart button - Fixed height at bottom
                      SizedBox(
                        height: 28.h, // Even smaller button
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
    
    // Create a container with padding for consistent sizing and spacing
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4.r),
      ),
      padding: EdgeInsets.all(4.r), // Add padding to ensure image doesn't touch edges
      child: Center( // Center the image within the container
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3.r),
          child: isNetworkImage
            ? _buildNetworkImage()
            : _buildAssetImage(),
        ),
      ),
    );
  }
  
  // Specifically for network images with better error handling
  Widget _buildNetworkImage() {
    return inStock
      ? ImageLoader.network(
          image,
          fit: BoxFit.contain, // Changed to contain to ensure full image is visible
          width: double.infinity,
          height: double.infinity,
          errorWidget: _buildErrorPlaceholder(),
        )
      : Opacity(
          opacity: 0.5,
          child: ImageLoader.network(
            image,
            fit: BoxFit.contain, // Changed to contain to ensure full image is visible
            width: double.infinity,
            height: double.infinity,
            errorWidget: _buildErrorPlaceholder(),
          ),
        );
  }
  
  // Specifically for asset images with better error handling
  Widget _buildAssetImage() {
    try {
      return inStock
        ? Image.asset(
            image,
            fit: BoxFit.contain, // Changed to contain to ensure full image is visible
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              print('Error loading asset image: $error for path: $image');
              return _buildErrorPlaceholder();
            },
          )
        : Opacity(
            opacity: 0.5,
            child: Image.asset(
              image,
              fit: BoxFit.contain, // Changed to contain to ensure full image is visible
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return _buildErrorPlaceholder();
              },
            ),
          );
    } catch (e) {
      print('Exception loading asset image: $e for path: $image');
      return _buildErrorPlaceholder();
    }
  }
  
  // Consistent error placeholder
  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.black.withOpacity(0.05),
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          color: Colors.grey,
          size: 28.r, // Smaller icon size
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      height: 28.h,
      child: ElevatedButton(
        onPressed: inStock ? () => onQuantityChanged(1) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentColor,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.r),
          ),
          padding: EdgeInsets.zero,
          elevation: 1, // Slight elevation for depth
          // Add gradient effect for premium look
          shadowColor: Colors.black.withOpacity(0.5),
        ),
        child: Text(
          'ADD',
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      height: 28.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4.r),
        // Add subtle gradient for depth
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryColor.withOpacity(0.8),
            AppTheme.primaryColor,
          ],
        ),
        // Add thin border for definition
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.8),
          width: 1,
        ),
        // Add subtle shadow for elevation
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Decrease quantity - improved tap target
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: inStock ? () => onQuantityChanged(quantity - 1) : null,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(3.r),
                bottomLeft: Radius.circular(3.r),
              ),
              child: Container(
                width: 26.w, // Slightly smaller for better spacing
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
                  size: 16.r, // Smaller icon
                ),
              ),
            ),
          ),
          
          // Quantity - improved display
          Expanded(
            child: Container(
              alignment: Alignment.center,
              child: Text(
                quantity.toString(),
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          // Increase quantity - improved tap target
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: inStock ? () => onQuantityChanged(quantity + 1) : null,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(3.r),
                bottomRight: Radius.circular(3.r),
              ),
              child: Container(
                width: 26.w, // Slightly smaller for better spacing
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
                  size: 16.r, // Smaller icon
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
