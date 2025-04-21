import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/product.dart';
import '../../widgets/image_loader.dart';
import '../../../core/utils/screen_size_utils.dart';

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
  final String? weight;

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
    this.weight,
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
      weight: product.weight,
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
    
    // Calculate responsive dimensions with bounds
    final gridItemWidth = screenWidth / 2 - 20; // Account for grid spacing
    final aspectRatio = 0.8; // Increased aspect ratio to provide more vertical space
    final calculatedHeight = gridItemWidth / aspectRatio;
    
    // Use safe dimensions to prevent layout crashes
    final imageHeight = ScreenSizeUtils.safeHeight((calculatedHeight * 0.4).clamp(80.0, 120.0));
    final padding = ScreenSizeUtils.safeWidth((screenWidth / 50).clamp(6.0, 10.0));
    final borderRadius = ScreenSizeUtils.safeRadius((screenWidth / 40).clamp(10.0, 16.0));
    
    // Font sizes proportional to screen width with safety bounds
    final nameSize = ScreenSizeUtils.safeFontSize((screenWidth / 38).clamp(11.0, 14.0));
    final weightSize = ScreenSizeUtils.safeFontSize((screenWidth / 45).clamp(9.0, 12.0));
    final priceSize = ScreenSizeUtils.safeFontSize((screenWidth / 32).clamp(12.0, 16.0));
    final mrpSize = ScreenSizeUtils.safeFontSize((screenWidth / 42).clamp(9.0, 12.0));
    final buttonHeight = ScreenSizeUtils.safeHeight((screenWidth / 15).clamp(28.0, 36.0));
    
    return GestureDetector(
      onTap: inStock ? onTap : null,
      child: Container(
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
                        // Product image container with category background color
                        Container(
                          width: double.infinity,
                          height: imageHeight,
                          color: backgroundColor ?? AppTheme.primaryColor,
                          child: inStock 
                            ? Center(
                                child: image.isNotEmpty
                                  ? ImageLoader.network(
                                      image,
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      height: imageHeight * 0.8,
                                      errorWidget: Icon(
                                        Icons.image_not_supported,
                                        color: Colors.white,
                                        size: imageHeight / 2,
                                      ),
                                    )
                                  : Icon(
                                      Icons.image_not_supported,
                                      color: Colors.white,
                                      size: imageHeight / 2,
                                    ),
                              )
                            : Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Faded unavailable image
                                  Opacity(
                                    opacity: 0.3,
                                    child: image.isNotEmpty
                                      ? ImageLoader.network(
                                          image,
                                          fit: BoxFit.contain,
                                          width: double.infinity,
                                          height: imageHeight * 0.8,
                                          errorWidget: Icon(
                                            Icons.image_not_supported,
                                            color: Colors.white,
                                            size: imageHeight / 2,
                                          ),
                                        )
                                      : Icon(
                                          Icons.image_not_supported,
                                          color: Colors.white,
                                          size: imageHeight / 2,
                                        ),
                                  ),
                                  // Out of stock overlay
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: padding,
                                      vertical: padding / 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Out of Stock',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: nameSize,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                        ),
                        
                        // Discount badge
                        if (hasDiscount)
                          Positioned(
                            top: 4.0,
                            left: 4.0,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 3.0,
                                vertical: 1.0,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(2.0),
                              ),
                              child: Text(
                                '${discountPercentage!.toInt()}% OFF',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: ScreenSizeUtils.safeFontSize(7.0),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    // Product details with new layout
                    Container(
                      color: Colors.white,
                      width: double.infinity,
                      padding: EdgeInsets.all(padding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Product name - allow 2 lines max with ellipsis
                          Text(
                            name,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: nameSize,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          // Weight display
                          if (weight != null && weight!.isNotEmpty)
                            Text(
                              weight!,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: weightSize,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          
                          SizedBox(height: 4.h),
                          
                          // Price section with new layout
                          Row(
                            children: [
                              // Current price
                              Text(
                                '${AppConstants.currencySymbol}${price.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: priceSize,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              
                              SizedBox(width: 6.w),
                              
                              // Original price (MRP) if there is a discount
                              if (hasDiscount)
                                Text(
                                  '${AppConstants.currencySymbol}${mrp!.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: mrpSize,
                                    fontWeight: FontWeight.w400,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              
                              const Spacer(),
                              
                              // Add button with new style
                              if (quantity == 0)
                                Container(
                                  height: buttonHeight,
                                  width: 70.w,
                                  child: ElevatedButton(
                                    onPressed: inStock ? () => onQuantityChanged(1) : null,
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: Colors.green,
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4.0),
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'ADD',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                _buildQuantitySelector(buttonHeight),
                            ],
                          ),
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
  
  // Quantity selector for products already in cart
  Widget _buildQuantitySelector(double buttonHeight) {
    final buttonMinWidth = (buttonHeight * 0.8).clamp(20.0, 28.0);
    final fontSize = (buttonHeight / 2.3).clamp(10.0, 14.0);
    final iconSize = (buttonHeight / 2.5).clamp(10.0, 14.0);
    
    return Container(
      height: buttonHeight,
      width: 90.w,
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Decrease quantity
          SizedBox(
            width: buttonMinWidth,
            child: InkWell(
              onTap: inStock ? () => onQuantityChanged(quantity - 1) : null,
              child: Center(
                child: Icon(
                  Icons.remove,
                  size: iconSize,
                  color: Colors.white,
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
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}