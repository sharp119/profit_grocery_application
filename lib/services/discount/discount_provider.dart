import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/product.dart';
import '../../models/discount_model.dart';
import 'discount_service.dart';
import 'discount_info.dart';

/// Provider class for accessing discount functionality throughout the app
/// Acts as a facade for the discount service
class DiscountProvider {
  DiscountService _discountService;
  
  // Cache for discount information
  final Map<String, DiscountModel> _discountCache = {};
  
  // Singleton pattern
  static final DiscountProvider _instance = DiscountProvider._internal();
  factory DiscountProvider({FirebaseFirestore? firestore}) {
    _instance._discountService = DiscountService(firestore: firestore);
    return _instance;
  }
  DiscountProvider._internal() : _discountService = DiscountService();
  
  /// Get discount for a product
  /// Uses cache if available, otherwise fetches from service
  Future<DiscountModel> getDiscount(Product product) async {
    final String productId = product.id;
    
    // Check cache first
    if (_discountCache.containsKey(productId)) {
      return _discountCache[productId]!;
    }
    
    // Get discount from service
    final discountInfo = await _discountService.getDiscountForProduct(product);
    
    // Convert to model
    final discountModel = _convertToModel(discountInfo);
    
    // Cache the result
    _discountCache[productId] = discountModel;
    
    return discountModel;
  }
  
  /// Get discounts for multiple products at once
  /// Optimized for batch processing
  Future<Map<String, DiscountModel>> getDiscounts(List<Product> products) async {
    // First check which products need to be fetched
    final List<Product> productsToFetch = [];
    final Map<String, DiscountModel> result = {};
    
    for (final product in products) {
      final String productId = product.id;
      
      // Use cache if available
      if (_discountCache.containsKey(productId)) {
        result[productId] = _discountCache[productId]!;
      } else {
        productsToFetch.add(product);
      }
    }
    
    // Fetch discounts for remaining products
    if (productsToFetch.isNotEmpty) {
      final discountInfoMap = await _discountService.getDiscountsForProducts(productsToFetch);
      
      // Convert to models and add to result
      for (final product in productsToFetch) {
        final String productId = product.id;
        
        if (discountInfoMap.containsKey(productId)) {
          final discountInfo = discountInfoMap[productId]!;
          
          // Convert to model
          final discountModel = _convertToModel(discountInfo);
          
          // Update cache
          _discountCache[productId] = discountModel;
          
          // Add to result
          result[productId] = discountModel;
        } else {
          // Create a no-discount model
          final noDiscountModel = DiscountModel.noDiscount(
            productId: productId,
            price: product.price,
          );
          
          // Update cache
          _discountCache[productId] = noDiscountModel;
          
          // Add to result
          result[productId] = noDiscountModel;
        }
      }
    }
    
    return result;
  }
  
  /// Helper method to convert DiscountInfo to DiscountModel
  DiscountModel _convertToModel(DiscountInfo info) {
    return DiscountModel(
      productId: info.productId,
      discountType: info.discountType,
      discountValue: info.discountValue,
      source: info.source,
      originalPrice: info.originalPrice,
      finalPrice: info.finalPrice,
    );
  }
  
  /// Check if a product has any discount
  Future<bool> hasDiscount(Product product) async {
    final discount = await getDiscount(product);
    return discount.hasDiscount;
  }
  
  /// Get the final price for a product after all applicable discounts
  Future<double> getFinalPrice(Product product) async {
    final discount = await getDiscount(product);
    return discount.finalPrice;
  }
  
  /// Clear discount cache for a specific product or all products
  void clearCache({String? productId}) {
    if (productId != null) {
      _discountCache.remove(productId);
    } else {
      _discountCache.clear();
    }
  }
  
  /// Apply a custom discount to a product
  /// Useful for promotions, coupons, etc.
  DiscountModel applyCustomDiscount({
    required Product product,
    required String discountType,
    required double discountValue,
    String source = 'custom',
  }) {
    final discountModel = discountType == 'percentage'
        ? DiscountModel.percentage(
            productId: product.id,
            originalPrice: product.price,
            percentageValue: discountValue,
            source: source,
          )
        : DiscountModel.flat(
            productId: product.id,
            originalPrice: product.price,
            flatValue: discountValue,
            source: source,
          );
    
    // Update cache
    _discountCache[product.id] = discountModel;
    
    return discountModel;
  }
}