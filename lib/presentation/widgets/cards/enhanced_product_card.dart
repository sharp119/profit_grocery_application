/// EnhancedProductCard
/// 
/// An improved version of the product card with enhanced UI and additional features.
/// This card provides better product information display and weight/unit parsing.
/// 
/// Usage:
/// - Used in product details and featured sections
/// - Provides enhanced product information display
/// - Automatically parses weight and unit information
/// - Shows more detailed product information
/// 
/// Key Features:
/// - Weight and unit parsing from product name
/// - Enhanced UI following modern design principles
/// - Dark theme compatibility
/// - Improved product information layout
/// 
/// Example Usage:
/// ```dart
/// EnhancedProductCard.fromEntity(
///   product: product,
///   onTap: () => navigateToDetails(product),
///   backgroundColor: categoryColor,
/// )
/// ```
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/product.dart';
import '../../../services/product/product_dynamic_data_provider.dart';
import '../../../services/logging_service.dart';
import '../image_loader.dart';
import '../../widgets/buttons/add_button.dart';

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
  final String? categoryGroup;

  // Product dynamic data provider instance from GetIt
  final _dynamicDataProvider = GetIt.instance<ProductDynamicDataProvider>();

  EnhancedProductCard({
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
    this.categoryGroup,
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
      categoryGroup: product.categoryGroup,
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
    // Create a stream for the dynamic product data from RTDB
    Stream<ProductDynamicData> dynamicDataStream;
    
    if (categoryGroup != null && categoryGroup!.isNotEmpty && categoryId != null) {
      // Use full category path if available
      dynamicDataStream = _dynamicDataProvider.getProductStream(
        categoryGroup: categoryGroup!,
        categoryItem: categoryId!,
        productId: id,
      );
    } else {
      // Fallback to product ID only
      dynamicDataStream = _dynamicDataProvider.getProductStreamById(id);
    }

    // Use StreamBuilder to display real-time data from RTDB
    return StreamBuilder<ProductDynamicData>(
      stream: dynamicDataStream,
      builder: (context, snapshot) {
        // Show loading state while waiting for price data
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }
        
        // Default to original values if no RTDB data
        double finalPrice = price;
        bool productInStock = inStock;
        bool productHasDiscount = hasDiscount;
        double? productMrp = mrp;
        double? productDiscountPercentage = discountPercentage;
        
        // Update with real-time values when available
        if (snapshot.hasData && snapshot.data != null) {
          final dynamicData = snapshot.data!;
          
          // Only log when we have real data coming in with connectionState.active
          // This prevents logging on every widget rebuild
          if (snapshot.connectionState == ConnectionState.active && 
              snapshot.data != null) {
            LoggingService.logFirestore(
              'ENHANCED_CARD: Using RTDB data for ${name} - '
              'Price: ${dynamicData.price}, FinalPrice: ${dynamicData.finalPrice}, '
              'InStock: ${dynamicData.inStock}, Discount: ${dynamicData.hasDiscount == true ? "${dynamicData.discountType}: ${dynamicData.discountValue}" : "None"}'
            );
          }
          
          // Use RTDB price if available
          if (dynamicData.price > 0) {
            finalPrice = dynamicData.finalPrice;
            
            // If dynamic data has a discount, we need to update the MRP
            if (dynamicData.hasDiscount == true && 
                dynamicData.discountType != null && 
                dynamicData.discountValue != null) {
              productHasDiscount = true;
              
              // If discountType is percentage, calculate the original price
              if (dynamicData.discountType == 'percentage' && dynamicData.discountValue! > 0) {
                productDiscountPercentage = dynamicData.discountValue;
                // Calculate MRP from final price and discount percentage
                productMrp = dynamicData.price; // Original price before discount
              } else if (dynamicData.discountType == 'flat' && dynamicData.discountValue! > 0) {
                // For flat discount, calculate original price by adding discount value
                productMrp = dynamicData.price; // Original price before discount
                productDiscountPercentage = (dynamicData.discountValue! / productMrp! * 100).roundToDouble();
              }
            } else {
              productHasDiscount = false;
              productDiscountPercentage = null;
            }
          } else {
            // If price is 0 or invalid, continue showing the loading state
            // This ensures we don't display cards with zero prices
            return _buildLoadingCard();
          }
          
          // Use RTDB stock status
          productInStock = dynamicData.inStock;
          
        } else if (snapshot.hasError) {
          LoggingService.logError(
            'ENHANCED_CARD',
            'Error loading RTDB data for $id: ${snapshot.error}'
          );
          // If there's an error loading RTDB data, fall back to static data
          // Only proceed if we have a valid price
          if (price <= 0) {
            // If static price is also invalid, show error state
            return _buildErrorCard();
          }
        } else {
          // No data yet, show loading
          return _buildLoadingCard();
        }

        // Use a more flexible layout approach without fixed height constraint
        return GestureDetector(
          onTap: productInStock ? onTap : null,
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
                      if (productHasDiscount && productDiscountPercentage != null)
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
                              '${productDiscountPercentage.toInt()}% OFF',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      
                      // Out of stock overlay - Same styling
                      if (!productInStock)
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
                            '${AppConstants.currencySymbol}${finalPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accentColor,
                              height: 1.0, // Tighter line height
                            ),
                          ),
                          
                          SizedBox(width: 4.w),
                          
                          // Original price if there's a discount
                          if (productHasDiscount && productMrp != null)
                            Flexible(
                              child: Text(
                                '${AppConstants.currencySymbol}${productMrp.toStringAsFixed(0)}',
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
                      
                      // Add button with quantity controls
                      SizedBox(
                        height: 28.h,
                        child: AddButton(
                          productId: id,
                          sourceCardType: ProductCardType.enhanced,
                          height: 28.h,
                          fontSize: 13.sp,
                          inStock: productInStock,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

  // Build loading placeholder for the card
  Widget _buildLoadingCard() {
    return Container(
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image area placeholder
          AspectRatio(
            aspectRatio: 1.2,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade800.withOpacity(0.3),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8.r),
                  topRight: Radius.circular(8.r),
                ),
              ),
              child: Center(
                child: SizedBox(
                  width: 24.w,
                  height: 24.h,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
                  ),
                ),
              ),
            ),
          ),
          
          // Product details placeholders
          Padding(
            padding: EdgeInsets.all(8.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title placeholder
                Container(
                  width: double.infinity,
                  height: 12.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(height: 4.h),
                
                // Price placeholder
                Container(
                  width: 80.w,
                  height: 12.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(height: 8.h),
                
                // Button placeholder
                Container(
                  width: double.infinity,
                  height: 28.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Build error state card
  Widget _buildErrorCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Error icon area
          AspectRatio(
            aspectRatio: 1.2,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade900.withOpacity(0.5),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8.r),
                  topRight: Radius.circular(8.r),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.error_outline,
                  color: Colors.red.withOpacity(0.7),
                  size: 32.r,
                ),
              ),
            ),
          ),
          
          // Product name if available
          Padding(
            padding: EdgeInsets.all(8.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Price unavailable',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.red.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: 8.h),
                
                // Disabled button
                Container(
                  width: double.infinity,
                  height: 28.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Unavailable',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey,
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
