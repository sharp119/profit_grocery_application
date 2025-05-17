import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../domain/entities/bestseller_product.dart';
import '../../../services/logging_service.dart';
import '../../../services/discount/discount_service.dart';
import '../../../services/product/product_dynamic_data_provider.dart';
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
        // Default to original values if no RTDB data
        double finalPrice = bestsellerProduct.finalPrice;
        bool inStock = product.inStock;
        bool hasDiscount = bestsellerProduct.hasSpecialDiscount;
        String? discountType = bestsellerProduct.discountType;
        double? discountValue = bestsellerProduct.discountValue;
        
        // Update with real-time values when available
        if (snapshot.hasData && snapshot.data != null) {
          final dynamicData = snapshot.data!;
          
          // Log all RTDB data for this product with a specific tag
          print('RTDB_PRODUCT_DATA: Product ID: $productId');
          print('RTDB_PRODUCT_DATA: Price: ${dynamicData.price}');
          print('RTDB_PRODUCT_DATA: InStock: ${dynamicData.inStock}');
          print('RTDB_PRODUCT_DATA: Quantity: ${dynamicData.quantity}');
          print('RTDB_PRODUCT_DATA: HasDiscount: ${dynamicData.hasDiscount}');
          print('RTDB_PRODUCT_DATA: DiscountType: ${dynamicData.discountType}');
          print('RTDB_PRODUCT_DATA: DiscountValue: ${dynamicData.discountValue}');
          print('RTDB_PRODUCT_DATA: UpdatedAt: ${dynamicData.updatedAt}');
          print('RTDB_PRODUCT_DATA: FinalPrice: ${dynamicData.finalPrice}');
          
          // Use RTDB price if available
          if (dynamicData.price > 0) {
            finalPrice = dynamicData.finalPrice;
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
          
          LoggingService.logFirestore(
            'BESTSELLER_CARD: Using RTDB data for ${product.name} - '
            'Price: ${dynamicData.price}, FinalPrice: $finalPrice, '
            'InStock: $inStock, Discount: ${hasDiscount ? "$discountType: $discountValue" : "None"}'
          );
        } else if (snapshot.hasError) {
          LoggingService.logError(
            'BESTSELLER_CARD',
            'Error loading RTDB data for ${product.id}: ${snapshot.error}'
          );
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
}
