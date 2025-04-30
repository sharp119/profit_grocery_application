import '../../../services/discount/discount_service.dart';

/// A utility class that provides discount information for product cards
/// This class retrieves discount information directly from Firestore through the DiscountService
class DiscountProvider {
  /// Get discount percentage for a product by ID
  /// Returns 0 if there's no discount
  /// This method attempts to get cached info first, and if not available,
  /// returns 0 (expecting that the async getProductDiscountInfo was called elsewhere)
  static int getDiscountPercentage(String productId) {
    final discountInfo = DiscountService.getCachedDiscountInfo(productId);
    if (discountInfo != null && discountInfo['hasDiscount'] == true) {
      return discountInfo['discountPercentage'] as int;
    }
    return 0;
  }
  
  /// Check if a product has a discount
  static bool hasDiscount(String productId) {
    final discountInfo = DiscountService.getCachedDiscountInfo(productId);
    return discountInfo != null && discountInfo['hasDiscount'] == true;
  }
  
  /// Get original price for a product
  static double? getOriginalPrice(String productId) {
    final discountInfo = DiscountService.getCachedDiscountInfo(productId);
    if (discountInfo != null) {
      return discountInfo['originalPrice'] as double;
    }
    return null;
  }
  
  /// Get final price for a product
  static double? getFinalPrice(String productId) {
    final discountInfo = DiscountService.getCachedDiscountInfo(productId);
    if (discountInfo != null) {
      return discountInfo['finalPrice'] as double;
    }
    return null;
  }
  
  /// Get discount type for a product (percentage or flat)
  static String? getDiscountType(String productId) {
    final discountInfo = DiscountService.getCachedDiscountInfo(productId);
    if (discountInfo != null && discountInfo['hasDiscount'] == true) {
      return discountInfo['discountType'] as String?;
    }
    return null;
  }
  
  /// Get discount value for a product (percentage amount or flat amount)
  static double? getDiscountValue(String productId) {
    final discountInfo = DiscountService.getCachedDiscountInfo(productId);
    if (discountInfo != null && discountInfo['hasDiscount'] == true) {
      return discountInfo['discountValue'] as double?;
    }
    return null;
  }
  
  /// Check if a discount is active (within date range and is marked as active)
  static bool isDiscountActive(String productId) {
    final discountInfo = DiscountService.getCachedDiscountInfo(productId);
    if (discountInfo != null && discountInfo['hasDiscount'] == true) {
      return discountInfo['isActive'] as bool? ?? true;
    }
    return false;
  }
  
  /// Preload discount information for a product from Firestore
  /// This is useful for ensuring discount info is available synchronously later
  static Future<void> preloadDiscountInfo(String productId) async {
    await DiscountService.getProductDiscountInfo(productId);
  }
  
  /// Preload discount information for multiple products from Firestore
  /// More efficient than loading products one by one
  static Future<void> preloadDiscountInfoBatch(List<String> productIds) async {
    if (productIds.isEmpty) return;
    
    // Use the batch method for better performance
    await DiscountService.getBatchProductDiscountInfo(productIds);
  }
} 