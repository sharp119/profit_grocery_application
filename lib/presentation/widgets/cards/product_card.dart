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
    // Get screen dimensions to adapt sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Calculate responsive dimensions based on the available screen size
    final gridItemWidth = screenWidth / 2 - 20; // Account for grid spacing
    final aspectRatio = 0.75; // Maintain a consistent aspect ratio
    final calculatedHeight = gridItemWidth / aspectRatio;
    
    // Adapt dimensions proportionally to screen size
    final imageHeight = (calculatedHeight * 0.45).clamp(90.0, 120.0);
    final padding = (screenWidth / 50).clamp(6.0, 10.0);
    final borderRadius = (screenWidth / 40).clamp(10.0, 16.0);
    
    // Font sizes proportional to screen width
    final nameSize = (screenWidth / 35).clamp(10.0, 14.0);
    final priceSize = (screenWidth / 30).clamp(12.0, 16.0);
    final mrpSize = (screenWidth / 40).clamp(9.0, 12.0);
    final buttonHeight = (screenWidth / 15).clamp(24.0, 32.0);
    
    return GestureDetector(
      onTap: inStock ? onTap : null,
      child: Container(
        // Ensure container has no fixed height that could cause overflow
        decoration: BoxDecoration(
          color: AppTheme.secondaryColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: AppTheme.accentColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Important to prevent overflow
              children: [
                // Product image and discount badge
                Stack(
                  children: [
                    // Product image
                    ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(borderRadius),
                        topRight: Radius.circular(borderRadius),
                      ),
                      child: Container(
                        height: imageHeight,
                        width: double.infinity,
                        padding: EdgeInsets.all(padding),
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6.0,
                                      vertical: 3.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(4.0),
                                    ),
                                    child: const Text(
                                      'Out of Stock',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.0,
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
                        top: 6.0,
                        left: 6.0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4.0,
                            vertical: 2.0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            '${discountPercentage!.toInt()}% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                
                // Product details - using flexible layout
                Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Product name
                      Text(
                        name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: nameSize,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      SizedBox(height: padding / 2),
                      
                      // Price section
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Current price
                          Text(
                            '${AppConstants.currencySymbol}${price.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: AppTheme.accentColor,
                              fontSize: priceSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          
                          SizedBox(width: padding / 2),
                          
                          // Original price (MRP) if there is a discount
                          if (hasDiscount)
                            Flexible(
                              child: Text(
                                '${AppConstants.currencySymbol}${mrp!.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: mrpSize,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.lineThrough,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Add to cart button or quantity selector
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding / 2),
                  child: quantity > 0
                      ? _buildQuantitySelector(buttonHeight)
                      : _buildAddButton(buttonHeight),
                ),
              ],
            );
          }
        ),
      ),
    );
  }
  
  // Add to cart button
  Widget _buildAddButton(double buttonHeight) {
    final fontSize = (buttonHeight / 2.5).clamp(10.0, 14.0);
    
    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: inStock ? () => onQuantityChanged(1) : null,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: inStock ? AppTheme.accentColor : Colors.grey,
          padding: const EdgeInsets.symmetric(vertical: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.0),
          ),
          // Minimize internal padding
          minimumSize: Size.zero,
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
  
  // Quantity selector for products already in cart
  Widget _buildQuantitySelector(double buttonHeight) {
    final buttonMinWidth = (buttonHeight * 0.9).clamp(24.0, 32.0);
    final fontSize = (buttonHeight / 2.3).clamp(12.0, 16.0);
    final iconSize = (buttonHeight / 2.5).clamp(12.0, 16.0);
    
    return Container(
      height: buttonHeight,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(
          color: AppTheme.accentColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: [
          // Decrease quantity
          SizedBox(
            width: buttonMinWidth,
            child: InkWell(
              onTap: inStock && quantity > 1 ? () => onQuantityChanged(quantity - 1) : null,
              child: Center(
                child: Icon(
                  Icons.remove,
                  size: iconSize,
                  color: inStock && quantity > 1 ? Colors.white : Colors.grey,
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