/// Utility class for discount calculations
/// Contains pure functions with no dependencies on Firestore or other services
/// Can be used independently in any context
class DiscountCalculator {
  /// Calculate final price after applying a percentage discount
  static double calculatePercentageDiscount({
    required double originalPrice,
    required double percentageValue,
  }) {
    if (percentageValue <= 0) return originalPrice;
    
    final discount = originalPrice * (percentageValue / 100);
    return originalPrice - discount;
  }
  
  /// Calculate final price after applying a flat discount
  static double calculateFlatDiscount({
    required double originalPrice,
    required double flatValue,
  }) {
    if (flatValue <= 0) return originalPrice;
    
    // Ensure discount doesn't make price negative
    return (originalPrice > flatValue) ? originalPrice - flatValue : 0;
  }
  
  /// Calculate final price based on discount type and value
  static double calculateDiscountedPrice({
    required double originalPrice,
    required String? discountType,
    required double? discountValue,
  }) {
    // Return original price if discount information is missing
    if (discountType == null || discountValue == null || discountValue <= 0) {
      return originalPrice;
    }
    
    // Apply appropriate discount calculation based on type
    switch (discountType) {
      case 'percentage':
        return calculatePercentageDiscount(
          originalPrice: originalPrice,
          percentageValue: discountValue,
        );
      case 'flat':
        return calculateFlatDiscount(
          originalPrice: originalPrice,
          flatValue: discountValue,
        );
      default:
        return originalPrice;
    }
  }
  
  /// Calculate discount percentage between original and final price
  static double calculateDiscountPercentage({
    required double originalPrice,
    required double finalPrice,
  }) {
    if (originalPrice <= 0 || finalPrice >= originalPrice) return 0;
    
    return ((originalPrice - finalPrice) / originalPrice * 100).roundToDouble();
  }
  
  /// Calculate discount amount (difference between original and final price)
  static double calculateDiscountAmount({
    required double originalPrice,
    required double finalPrice,
  }) {
    if (originalPrice <= 0 || finalPrice >= originalPrice) return 0;
    
    return originalPrice - finalPrice;
  }
  
  /// Determine if a price has a significant discount (greater than threshold)
  static bool hasSignificantDiscount({
    required double originalPrice,
    required double finalPrice,
    double thresholdPercentage = 1.0, // Default 1% threshold
  }) {
    final discountPercentage = calculateDiscountPercentage(
      originalPrice: originalPrice, 
      finalPrice: finalPrice,
    );
    
    return discountPercentage >= thresholdPercentage;
  }
  
  /// Format discount for display
  /// Returns formatted string like "10% OFF" or "₹100 OFF"
  static String formatDiscountForDisplay({
    required String? discountType,
    required double? discountValue,
    String currencySymbol = '₹',
  }) {
    if (discountType == null || discountValue == null || discountValue <= 0) {
      return '';
    }
    
    switch (discountType) {
      case 'percentage':
        return '${discountValue.round()}% OFF';
      case 'flat':
        return '$currencySymbol${discountValue.round()} OFF';
      default:
        return '';
    }
  }
}