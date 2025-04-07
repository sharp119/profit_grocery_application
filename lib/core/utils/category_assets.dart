import 'dart:math';

/// Utility class for managing category and product assets
class CategoryAssets {
  static final Random _random = Random();
  
  /// List of mock product images to use for demo purposes
  static final List<String> mockProductImages = [
    'assets/products/1.png',
    'assets/products/2.png',
    'assets/products/3.png',
    'assets/products/4.png',
    'assets/products/5.png',
    'assets/products/6.png',
  ];
  
  /// Returns a random product image from the mock list
  static String getRandomProductImage() {
    return mockProductImages[_random.nextInt(mockProductImages.length)];
  }
  
  /// Returns a placeholder image for out-of-stock products
  static String getOutOfStockImage() {
    return 'assets/images/out_of_stock.png';
  }
}
