import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/product.dart';
import '../image_loader.dart';
import '../../../utils/add_button_handler.dart';

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
  final Color? backgroundColor;
  final String? weight;
  final String? unit;
  final String? categoryId;

  const EnhancedProductCard({
    Key? key,
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    this.mrp,
    required this.inStock,
    required this.onTap,
    this.backgroundColor,
    this.weight,
    this.unit,
    this.categoryId,
  }) : super(key: key);

  /// Create a ProductCard from a Product entity
  factory EnhancedProductCard.fromEntity({
    required Product product,
    required VoidCallback onTap,
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
      backgroundColor: backgroundColor,
      weight: weight,
      unit: unit,
      categoryId: product.categoryId,
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
    // Use a more flexible layout approach without fixed height constraint
    return GestureDetector(
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
          mainAxisSize: MainAxisSize.min, // Add this to prevent unnecessary expansion
          children: [
            // Discount badge and image - Use aspectRatio with shorter height
            AspectRatio(
              aspectRatio: 1.2, // Wider than tall for image container
              child: Stack(
                children: [
                  // Product image
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(6.r),
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
            Padding(
              padding: EdgeInsets.fromLTRB(6.r, 2.r, 6.r, 4.r), // Even tighter padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Prevent unnecessary expansion
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
                  
                  // Combine name and weight in a single line
                  if (weight != null && unit != null)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$weight $unit',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.grey,
                              fontWeight: FontWeight.w400,
                              height: 1.0, // Tighter line height
                            ),
                          ),
                        ),
                      ],
                    ),
                  
                  SizedBox(height: 1.h), // Even less spacing
                  
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
                  
                  SizedBox(height: 2.h), // Reduced space before button
                  
                  // Add button (cart functionality removed but button preserved)
                  SizedBox(
                    height: 28.h, // Even smaller button
                    width: double.infinity, // Ensure button takes full width
                    child: _buildAddButton(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to build product image with correct handling for different URL types
  Widget _buildProductImage() {
    // Check if image is a network URL, Firebase Storage URL, or an asset path
    bool isNetworkImage = image.startsWith('http') || image.startsWith('https');
    bool isFirebaseStorageUrl = image.startsWith('gs://');
    
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
          child: isNetworkImage || isFirebaseStorageUrl
            ? _buildNetworkImage()
            : _buildAssetImage(),
        ),
      ),
    );
  }
  
  // Specifically for network images and Firebase Storage URLs with better error handling
  Widget _buildNetworkImage() {
    // For Firebase Storage URLs, we need to convert or handle them differently
    String imageUrl = image;
    bool isFirebaseStorageUrl = image.startsWith('gs://');
    
    if (isFirebaseStorageUrl) {
      // In a proper implementation, you would use Firebase Storage to get download URL
      // For now, we'll use a placeholder and show the error in console
      print('Firebase Storage URL detected: $image - These should be converted to HTTPS URLs');
      
      // For debugging: show the placeholder but log the error
      return _buildErrorPlaceholder();
    }
    
    return inStock
      ? ImageLoader.network(
          imageUrl,
          fit: BoxFit.contain, // Changed to contain to ensure full image is visible
          width: double.infinity,
          height: double.infinity,
          errorWidget: _buildErrorPlaceholder(),
        )
      : Opacity(
          opacity: 0.5,
          child: ImageLoader.network(
            imageUrl,
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
        onPressed: inStock ? () {
          // Use the centralized AddButtonHandler
          AddButtonHandler().handleAddButtonClick(
            product: Product(
              id: id,
              name: name,
              price: price,
              mrp: mrp,
              image: image,
              inStock: inStock,
              weight: weight,
              categoryId: categoryId ?? '', // Provide default empty string for null categoryId
              description: '', // Not needed for this flow
              rating: 0, // Not needed for this flow
            ),
            quantity: 1,
            originalCallback: null, // No callback needed anymore
          );
        } : null,
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
}
