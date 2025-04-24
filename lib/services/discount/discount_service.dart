import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/product.dart';
import '../../services/logging_service.dart';
import 'discount_calculator.dart';
import 'discount_info.dart';

/// Service responsible for all discount-related operations
/// Completely decoupled from bestseller, product, or any other business logic
class DiscountService {
  // Using late to properly initialize the Firestore instance
  late FirebaseFirestore _firestore;
  
  // Singleton pattern
  static final DiscountService _instance = DiscountService._internal();
  
  factory DiscountService({FirebaseFirestore? firestore}) {
    if (firestore != null) {
      _instance._firestore = firestore;
    }
    return _instance;
  }
  
  DiscountService._internal() {
    _firestore = FirebaseFirestore.instance;
  }
  
  /// Get discount information for a product by its ID
  /// Checks all possible discount sources (bestseller, regular discounts)
  /// Returns complete discount information with original and final prices
  Future<DiscountInfo> getDiscountForProduct(Product product) async {
    final String productId = product.id;
    final double originalPrice = product.price;
    
    try {
      LoggingService.logFirestore('DISCOUNT_SERVICE: Getting discount for product $productId');
      
      // Priority 1: Check bestseller discounts
      final bestsellerDiscount = await _getBestsellerDiscount(productId);
      
      if (bestsellerDiscount != null) {
        LoggingService.logFirestore('DISCOUNT_SERVICE: Found bestseller discount for $productId');
        
        // Calculate price with bestseller discount
        final finalPrice = _calculateDiscountedPrice(
          originalPrice: originalPrice,
          discountType: bestsellerDiscount['discountType'],
          discountValue: bestsellerDiscount['discountValue'],
        );
        
        return DiscountInfo(
          productId: productId,
          hasDiscount: true,
          discountType: bestsellerDiscount['discountType'],
          discountValue: bestsellerDiscount['discountValue'],
          originalPrice: originalPrice,
          finalPrice: finalPrice,
          source: 'bestseller',
        );
      }
      
      // Priority 2: Check regular discounts
      final regularDiscount = await _getRegularDiscount(productId);
      
      if (regularDiscount != null) {
        LoggingService.logFirestore('DISCOUNT_SERVICE: Found regular discount for $productId');
        
        // Calculate price with regular discount
        final finalPrice = _calculateDiscountedPrice(
          originalPrice: originalPrice,
          discountType: regularDiscount['discountType'],
          discountValue: regularDiscount['discountValue'],
        );
        
        return DiscountInfo(
          productId: productId,
          hasDiscount: true,
          discountType: regularDiscount['discountType'],
          discountValue: regularDiscount['discountValue'],
          originalPrice: originalPrice,
          finalPrice: finalPrice,
          source: 'regular',
        );
      }
      
      // No discount found
      LoggingService.logFirestore('DISCOUNT_SERVICE: No discount found for $productId');
      return DiscountInfo(
        productId: productId,
        hasDiscount: false,
        originalPrice: originalPrice,
        finalPrice: originalPrice,
      );
    } catch (e) {
      LoggingService.logError('DISCOUNT_SERVICE', 'Error getting discount for $productId: $e');
      // Return no discount on error
      return DiscountInfo(
        productId: productId,
        hasDiscount: false,
        originalPrice: originalPrice,
        finalPrice: originalPrice,
      );
    }
  }
  
  /// Get discount information for multiple products at once
  /// Optimized for batch processing
  Future<Map<String, DiscountInfo>> getDiscountsForProducts(List<Product> products) async {
    try {
      // Create a map to store discount information for each product
      final Map<String, DiscountInfo> discountMap = {};
      
      // Get all bestseller discounts in one batch
      final bestsellerDiscounts = await _getAllBestsellerDiscounts();
      
      // Get all regular discounts in one batch
      final regularDiscounts = await _getAllRegularDiscounts();
      
      // Process each product
      for (final product in products) {
        final String productId = product.id;
        final double originalPrice = product.price;
        
        // Check if product has a bestseller discount
        if (bestsellerDiscounts.containsKey(productId)) {
          final bestsellerDiscount = bestsellerDiscounts[productId]!;
          
          // Calculate price with bestseller discount
          final finalPrice = _calculateDiscountedPrice(
            originalPrice: originalPrice,
            discountType: bestsellerDiscount['discountType'],
            discountValue: bestsellerDiscount['discountValue'],
          );
          
          discountMap[productId] = DiscountInfo(
            productId: productId,
            hasDiscount: true,
            discountType: bestsellerDiscount['discountType'],
            discountValue: bestsellerDiscount['discountValue'],
            originalPrice: originalPrice,
            finalPrice: finalPrice,
            source: 'bestseller',
          );
          continue;
        }
        
        // Check if product has a regular discount
        if (regularDiscounts.containsKey(productId)) {
          final regularDiscount = regularDiscounts[productId]!;
          
          // Calculate price with regular discount
          final finalPrice = _calculateDiscountedPrice(
            originalPrice: originalPrice,
            discountType: regularDiscount['discountType'],
            discountValue: regularDiscount['discountValue'],
          );
          
          discountMap[productId] = DiscountInfo(
            productId: productId,
            hasDiscount: true,
            discountType: regularDiscount['discountType'],
            discountValue: regularDiscount['discountValue'],
            originalPrice: originalPrice,
            finalPrice: finalPrice,
            source: 'regular',
          );
          continue;
        }
        
        // No discount found for this product
        discountMap[productId] = DiscountInfo(
          productId: productId,
          hasDiscount: false,
          originalPrice: originalPrice,
          finalPrice: originalPrice,
        );
      }
      
      return discountMap;
    } catch (e) {
      LoggingService.logError('DISCOUNT_SERVICE', 'Error getting discounts for multiple products: $e');
      
      // Return empty map on error
      return {};
    }
  }
  
  /// Calculate final price after applying a discount
  /// Now uses the DiscountCalculator for calculations
  double _calculateDiscountedPrice({
    required double originalPrice,
    required String? discountType,
    required double? discountValue,
  }) {
    return DiscountCalculator.calculateDiscountedPrice(
      originalPrice: originalPrice,
      discountType: discountType,
      discountValue: discountValue,
    );
  }
  
  /// Check if a product has a bestseller discount
  Future<Map<String, dynamic>?> _getBestsellerDiscount(String productId) async {
    try {
      final docSnapshot = await _firestore.collection('bestsellers').doc(productId).get();
      
      if (!docSnapshot.exists) {
        return null;
      }
      
      final data = docSnapshot.data();
      
      // Check if data is null (for safety)
      if (data == null) {
        return null;
      }
      
      // Extract discount information
      final discountType = data['discountType'] as String?;
      final discountValue = _parseDiscountValue(data['discountValue']);
      
      // Return null if discount information is incomplete
      if (discountType == null || discountValue == null || discountValue <= 0) {
        return null;
      }
      
      return {
        'discountType': discountType,
        'discountValue': discountValue,
      };
    } catch (e) {
      LoggingService.logError('DISCOUNT_SERVICE', 'Error checking bestseller discount: $e');
      return null;
    }
  }
  
  /// Check if a product has a regular discount
  Future<Map<String, dynamic>?> _getRegularDiscount(String productId) async {
    try {
      final docSnapshot = await _firestore.collection('discounts').doc(productId).get();
      
      if (!docSnapshot.exists) {
        return null;
      }
      
      final data = docSnapshot.data();
      
      // Check if data is null (for safety)
      if (data == null) {
        return null;
      }
      
      // Extract discount information
      final isActive = data['active'] as bool? ?? false;
      final discountType = data['discountType'] as String?;
      final discountValue = _parseDiscountValue(data['discountValue']);
      
      // Check if discount is active and time-valid
      bool isTimeValid = true;
      if (data.containsKey('startTimestamp') && data.containsKey('endTimestamp')) {
        isTimeValid = _checkTimeValidity(data['startTimestamp'], data['endTimestamp']);
      }
      
      // Return null if discount is inactive, time-invalid, or information is incomplete
      if (!isActive || !isTimeValid || discountType == null || discountValue == null || discountValue <= 0) {
        return null;
      }
      
      return {
        'discountType': discountType,
        'discountValue': discountValue,
      };
    } catch (e) {
      LoggingService.logError('DISCOUNT_SERVICE', 'Error checking regular discount: $e');
      return null;
    }
  }
  
  /// Get all bestseller discounts at once (for batch processing)
  Future<Map<String, Map<String, dynamic>>> _getAllBestsellerDiscounts() async {
    try {
      final Map<String, Map<String, dynamic>> discounts = {};
      
      final querySnapshot = await _firestore.collection('bestsellers').get();
      
      for (final doc in querySnapshot.docs) {
        final productId = doc.id;
        final data = doc.data();
        
        // Extract discount information
        final discountType = data['discountType'] as String?;
        final discountValue = _parseDiscountValue(data['discountValue']);
        
        // Add valid discounts to the map
        if (discountType != null && discountValue != null && discountValue > 0) {
          discounts[productId] = {
            'discountType': discountType,
            'discountValue': discountValue,
          };
        }
      }
      
      return discounts;
    } catch (e) {
      LoggingService.logError('DISCOUNT_SERVICE', 'Error getting all bestseller discounts: $e');
      return {};
    }
  }
  
  /// Get all regular discounts at once (for batch processing)
  Future<Map<String, Map<String, dynamic>>> _getAllRegularDiscounts() async {
    try {
      final Map<String, Map<String, dynamic>> discounts = {};
      
      final querySnapshot = await _firestore.collection('discounts')
          .where('active', isEqualTo: true).get();
      
      for (final doc in querySnapshot.docs) {
        final productId = doc.id;
        final data = doc.data();
        
        // Extract discount information
        final discountType = data['discountType'] as String?;
        final discountValue = _parseDiscountValue(data['discountValue']);
        
        // Check time validity
        bool isTimeValid = true;
        if (data.containsKey('startTimestamp') && data.containsKey('endTimestamp')) {
          isTimeValid = _checkTimeValidity(data['startTimestamp'], data['endTimestamp']);
        }
        
        // Add valid discounts to the map
        if (isTimeValid && discountType != null && discountValue != null && discountValue > 0) {
          discounts[productId] = {
            'discountType': discountType,
            'discountValue': discountValue,
          };
        }
      }
      
      return discounts;
    } catch (e) {
      LoggingService.logError('DISCOUNT_SERVICE', 'Error getting all regular discounts: $e');
      return {};
    }
  }
  
  /// Helper method to safely parse discount value from various types
  double? _parseDiscountValue(dynamic value) {
    if (value == null) return null;
    
    if (value is int) {
      return value.toDouble();
    } else if (value is double) {
      return value;
    } else if (value is String) {
      // Try to parse string to double
      try {
        return double.parse(value);
      } catch (_) {
        return null;
      }
    }
    
    return null;
  }
  
  /// Helper method to check if a discount is time-valid
  bool _checkTimeValidity(dynamic startTimestamp, dynamic endTimestamp) {
    final now = DateTime.now();
    
    // Extract timestamps
    DateTime? startDate;
    DateTime? endDate;
    
    // Handle Timestamp objects
    if (startTimestamp is Timestamp) {
      startDate = startTimestamp.toDate();
    } 
    // Handle String timestamps
    else if (startTimestamp is String) {
      try {
        startDate = DateTime.parse(startTimestamp);
      } catch (_) {
        // Invalid timestamp format
      }
    }
    
    // Handle Timestamp objects
    if (endTimestamp is Timestamp) {
      endDate = endTimestamp.toDate();
    } 
    // Handle String timestamps
    else if (endTimestamp is String) {
      try {
        endDate = DateTime.parse(endTimestamp);
      } catch (_) {
        // Invalid timestamp format
      }
    }
    
    // Check time validity
    if (startDate != null && endDate != null) {
      return now.isAfter(startDate) && now.isBefore(endDate);
    }
    
    // If there's an issue with the timestamps, default to valid
    return true;
  }
}