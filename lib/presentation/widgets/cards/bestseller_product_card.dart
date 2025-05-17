import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../domain/entities/bestseller_product.dart';
import '../../../services/logging_service.dart';
import '../../../services/discount/discount_service.dart';
import '../../../services/product/product_dynamic_data_provider.dart';
import '../../../core/constants/app_theme.dart';
import 'reusable_product_card.dart';

/**
 * BestsellerProductCard
 * 
 * A specialized product card for bestseller products that uses the ReusableProductCard component.
 * This card is specifically designed for the bestseller section in the home screen.
 * Uses Firebase Realtime Database for dynamic price and stock updates.
 * 
 * Usage:
 * - Used in SimpleBestsellerGrid for displaying bestseller products
 * - Shows special bestseller discounts (percentage or flat)
 * - Displays bestseller badge
 * - Handles cart quantity changes
 * - Updates price and stock status in real-time from RTDB
 * 
 * Key Features:
 * - Special bestseller pricing and discounts
 * - Rank information
 * - Bestseller badge
 * - Cart functionality
 * - Real-time price and stock updates
 * 
 * Where Used:
 * - Home Screen: SimpleBestsellerGrid (12 bestsellers in 2-column grid)
 * - Bestseller Collections: Shows special discounts and badges
 * - Featured Sections: When highlighting bestseller products
 */

/// A specialized product card for bestseller products
/// Uses the reusable product card component with real-time data from RTDB
class BestsellerProductCard extends StatelessWidget {
  final BestsellerProduct bestsellerProduct;
  final Color backgroundColor;
  final Function(BestsellerProduct)? onTap;
  final Function(BestsellerProduct, int)? onQuantityChanged;
  final int quantity;
  final bool showBestsellerBadge;
  
  // Product dynamic data provider instance from GetIt
  final _dynamicDataProvider = GetIt.instance<ProductDynamicDataProvider>();

  BestsellerProductCard({
    Key? key,
    required this.bestsellerProduct,
    required this.backgroundColor,
    this.onTap,
    this.onQuantityChanged,
    this.quantity = 0,
    this.showBestsellerBadge = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final product = bestsellerProduct.product;
    
    // Log the bestseller-specific info
    LoggingService.logFirestore(
      'BESTSELLER_CARD: Using bestseller product ${product.name} with rank ${bestsellerProduct.rank}'
    );

    // Handle callbacks by wrapping them to pass BestsellerProduct instead of Product
    void _handleTap(dynamic _) {
      if (onTap != null) {
        onTap!(bestsellerProduct);
      }
    }

    // Get the categoryGroup and categoryItem from the product
    final categoryGroup = product.categoryGroup ?? '';
    final categoryItem = product.categoryId; // Use categoryId as fallback for categoryItem
    final productId = product.id;

    // Create a stream for the dynamic product data from RTDB
    Stream<ProductDynamicData> dynamicDataStream;
    
    if (categoryGroup.isNotEmpty && categoryItem.isNotEmpty) {
      // Use full category path if available
      dynamicDataStream = _dynamicDataProvider.getProductStream(
        categoryGroup: categoryGroup,
        categoryItem: categoryItem,
        productId: productId,
      );
    } else {
      // Fallback to product ID only
      dynamicDataStream = _dynamicDataProvider.getProductStreamById(productId);
    }

    // Use StreamBuilder to display real-time data from RTDB
    return StreamBuilder<ProductDynamicData>(
      stream: dynamicDataStream,
      builder: (context, snapshot) {
        // Show loading state while waiting for price data
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard(context);
        }
        
        // Default to original values if no RTDB data
        double finalPrice = bestsellerProduct.finalPrice;
        bool inStock = product.inStock;
        bool hasDiscount = bestsellerProduct.hasSpecialDiscount;
        String? discountType = bestsellerProduct.discountType;
        double? discountValue = bestsellerProduct.discountValue;
        
        // Update with real-time values when available
        if (snapshot.hasData && snapshot.data != null) {
          final dynamicData = snapshot.data!;
          
          // Only log when we have real data coming in with connectionState.active
          // This prevents logging on every widget rebuild
          if (snapshot.connectionState == ConnectionState.active && 
              snapshot.data != null) {
            // Log data with a specific tag for debugging
            LoggingService.logFirestore(
              'BESTSELLER_CARD: Using RTDB data for ${product.name} - '
              'Price: ${dynamicData.price}, FinalPrice: ${dynamicData.finalPrice}, '
              'InStock: ${dynamicData.inStock}, Discount: ${dynamicData.hasDiscount == true ? "${dynamicData.discountType}: ${dynamicData.discountValue}" : "None"}'
            );
          }
          
          // Use RTDB price if available
          if (dynamicData.price > 0) {
            finalPrice = dynamicData.finalPrice;
          } else {
            // If price is 0 or invalid, continue showing the loading state
            // This ensures we don't display cards with zero prices
            return _buildLoadingCard(context);
          }
          
          // Use RTDB stock status
          inStock = dynamicData.inStock;
          
          // Use RTDB discount if available
          if (dynamicData.hasDiscount == true && 
              dynamicData.discountType != null && 
              dynamicData.discountValue != null) {
            hasDiscount = true;
            discountType = dynamicData.discountType;
            discountValue = dynamicData.discountValue;
          }
        } else if (snapshot.hasError) {
          LoggingService.logError(
            'BESTSELLER_CARD',
            'Error loading RTDB data for ${product.id}: ${snapshot.error}'
          );
          
          // If we have error loading RTDB data and the original price is not valid
          if (bestsellerProduct.finalPrice <= 0) {
            return _buildErrorCard(context);
          }
        } else {
          // No data yet, show loading
          return _buildLoadingCard(context);
        }
        
        // Calculate original price to show (either MRP or regular price depending on discount)
        final originalPrice = product.mrp != null && product.mrp! > finalPrice 
            ? product.mrp 
            : hasDiscount 
                ? product.price  // Original price from Firestore
                : null;
                
        // Create a modified product with real-time stock info
        final updatedProduct = product.copyWith(inStock: inStock);

        // Use the reusable product card with bestseller-specific data and real-time updates
        return ReusableProductCard(
          product: updatedProduct,
          finalPrice: finalPrice,
          originalPrice: originalPrice,
          hasDiscount: hasDiscount,
          discountType: discountType,
          discountValue: discountValue,
          backgroundColor: backgroundColor,
          onTap: _handleTap,
        );
      },
    );
  }
  
  // Build loading placeholder for the card
  Widget _buildLoadingCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
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
                
                // Bestseller badge
                Container(
                  width: 100.w,
                  height: 20.h,
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.3),
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
  Widget _buildErrorCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
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
                  bestsellerProduct.product.name,
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
                
                // Bestseller badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 2.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    'BESTSELLER #${bestsellerProduct.rank}',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.7),
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
