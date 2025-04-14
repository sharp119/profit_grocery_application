import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/product.dart';
import '../../widgets/image_loader.dart';

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
  final Color? backgroundColor;

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
    this.backgroundColor,
  }) : super(key: key);

  /// Create a ProductCard from a Product entity
  factory ProductCard.fromEntity({
    required Product product,
    required VoidCallback onTap,
    required Function(int) onQuantityChanged,
    int quantity = 0,
    Color? backgroundColor,
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
      backgroundColor: backgroundColor,
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
    // Get screen dimensions to adapt sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Calculate responsive dimensions
    final gridItemWidth = screenWidth / 2 - 20; // Account for grid spacing
    final aspectRatio = 0.7; // Decreased aspect ratio to provide more vertical space
    final calculatedHeight = gridItemWidth / aspectRatio;
    
    // Adapt dimensions proportionally to screen size
    final imageHeight = (calculatedHeight * 0.35).clamp(70.0, 110.0); // Further reduced image height
    final padding = (screenWidth / 50).clamp(6.0, 10.0);
    final borderRadius = (screenWidth / 40).clamp(10.0, 16.0);
    
    // Font sizes proportional to screen width
    final nameSize = (screenWidth / 38).clamp(9.0, 13.0); // Smaller font
    final priceSize = (screenWidth / 32).clamp(11.0, 15.0); // Smaller font
    final mrpSize = (screenWidth / 42).clamp(8.0, 11.0); // Smaller font
    final buttonHeight = (screenWidth / 15).clamp(24.0, 32.0);
    
    return GestureDetector(
      onTap: inStock ? onTap : null,
      child: Container(
        // No fixed height to avoid overflow
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: AppTheme.accentColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                    // Product image and discount badge
                    Stack(
                      children: [
                        // Product image with colored background
                        Container(
                          height: imageHeight,
                          width: double.infinity,
                          color: backgroundColor ?? AppTheme.secondaryColor,
                          padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding/2),
                          child: inStock
                              ? Container(
                                  color: backgroundColor ?? AppTheme.secondaryColor,
                                  child: ImageLoader.asset(
                                    image,
                                    fit: BoxFit.contain,
                                    width: double.infinity,
                                    height: imageHeight,
                                    borderRadius: 4.0,
                                    errorWidget: Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey.withOpacity(0.5),
                                      size: imageHeight * 0.5,
                                    ),
                                  ),
                                )
                              : Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      color: backgroundColor ?? AppTheme.secondaryColor,
                                      child: ImageLoader.asset(
                                        image,
                                        fit: BoxFit.contain,
                                        width: double.infinity,
                                        height: imageHeight,
                                        borderRadius: 4.0,
                                        color: Colors.grey.withOpacity(0.5),
                                        colorBlendMode: BlendMode.saturation,
                                        errorWidget: Icon(
                                          Icons.image_not_supported,
                                          color: Colors.grey.withOpacity(0.3),
                                          size: imageHeight * 0.5,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4.0,
                                        vertical: 2.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(2.0),
                                      ),
                                      child: const Text(
                                        'Out of Stock',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 8.0, // Smaller font
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        
                        // Discount badge - more compact
                        if (hasDiscount)
                          Positioned(
                            top: 4.0,
                            left: 4.0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3.0,
                                vertical: 1.0,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(2.0),
                              ),
                              child: Text(
                                '${discountPercentage!.toInt()}% OFF',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 7.0, // Smaller font
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    // Product details - using flexible layout with different background
                    Container(
                      color: AppTheme.secondaryColor,
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding / 2), // Reduced vertical padding
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start, // Align content to top
                        children: [
                          // Product name - allow 1 line max with ellipsis to prevent overflow
                          Text(
                            name,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: nameSize,
                              fontWeight: FontWeight.w500,
                              height: 1.0, // Minimize line height
                            ),
                            maxLines: 1, // Allow only one line to prevent overflow
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          SizedBox(height: 1.h), // Minimal spacing
                          
                          // Price section - made more compact
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Current price
                              Text(
                                '${AppConstants.currencySymbol}${price.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: AppTheme.accentColor,
                                  fontSize: priceSize - 1, // Slightly smaller font 
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              
                              SizedBox(width: 4.0), // Fixed small width
                              
                              // Original price (MRP) if there is a discount
                              if (hasDiscount)
                                Flexible(
                                  child: Text(
                                    '${AppConstants.currencySymbol}${mrp!.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: mrpSize - 1, // Slightly smaller font
                                      fontWeight: FontWeight.w500,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                          
                          // Add to cart button or quantity selector with minimal height
                          SizedBox(height: 1.h), // Minimal spacing
                          quantity > 0
                              ? _buildQuantitySelector(16.h) // Further reduced height
                              : _buildAddButton(16.h),    // Further reduced height
                        ],
                      ),
                    ),
                  ],
                );
            },
          ),
        ),
      ),
    );
  }
  
  // Add to cart button - more compact
  Widget _buildAddButton(double buttonHeight) {
    final fontSize = (buttonHeight / 2.5).clamp(9.0, 12.0); // Smaller font
    
    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: inStock ? () => onQuantityChanged(1) : null,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: inStock ? AppTheme.accentColor : Colors.grey,
          padding: EdgeInsets.zero, // No padding
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.0), // Smaller radius
          ),
          // Absolutely minimize internal padding
          minimumSize: Size.zero,
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          'ADD',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  // Quantity selector for products already in cart - more compact
  Widget _buildQuantitySelector(double buttonHeight) {
    final buttonMinWidth = (buttonHeight * 0.8).clamp(20.0, 28.0); // Smaller width
    final fontSize = (buttonHeight / 2.3).clamp(10.0, 14.0); // Smaller font
    final iconSize = (buttonHeight / 2.5).clamp(10.0, 14.0); // Smaller icons
    
    return Container(
      height: buttonHeight,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(4.0), // Smaller radius
        border: Border.all(
          color: AppTheme.accentColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: [
          // Decrease quantity - allow decreasing to 0 to remove from cart
          SizedBox(
            width: buttonMinWidth,
            child: InkWell(
              onTap: inStock ? () => onQuantityChanged(quantity - 1) : null,
              child: Center(
                child: Icon(
                  Icons.remove,
                  size: iconSize,
                  color: inStock ? Colors.white : Colors.grey,
                ),
              ),
            ),
          ),
          
          // Current quantity
          Expanded(
            child: Center(
              child: Text(
                quantity.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          // Increase quantity
          SizedBox(
            width: buttonMinWidth,
            child: InkWell(
              onTap: inStock ? () => onQuantityChanged(quantity + 1) : null,
              child: Center(
                child: Icon(
                  Icons.add,
                  size: iconSize,
                  color: inStock ? Colors.white : Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}