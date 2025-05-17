import 'package:flutter/material.dart';
import '../../../domain/entities/product.dart';
import '../../../data/inventory/product_inventory.dart';
import '../../../data/inventory/similar_products.dart';
import '../../../data/models/product_model.dart';
import 'enhanced_product_card.dart';

/**
 * UniversalProductCard
 * 
 * A universal product card that works consistently across all screens.
 * This card can be initialized with either a Product object or a productId.
 * 
 * Usage:
 * - Used across different screens for consistent product display
 * - Can work with either Product object or productId
 * - Provides consistent UI and behavior
 * - Handles product resolution automatically
 * 
 * Key Features:
 * - Flexible initialization (Product or productId)
 * - Automatic product resolution
 * - Consistent UI across screens
 * - Background color handling
 * 
 * Where Used:
 * - TwoPanelCategoryProductView: Main product listing in category view
 * - Category Products Page: Standard product display
 * - Search Results: Consistent product display
 * - Product Collections: When uniform product display is needed
 * 
 * Example Usage:
 * ```dart
 * UniversalProductCard(
 *   product: product, // or productId: productId
 *   onTap: () => navigateToDetails(product),
 *   backgroundColor: categoryColor,
 *   useBackgroundColor: true,
 * )
 * ```
 */

/// A universal product card that works consistently across all screens
class UniversalProductCard extends StatefulWidget {
  // Product can be provided directly or by ID
  final Product? product;
  final String? productId;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final bool useBackgroundColor;

  const UniversalProductCard({
    Key? key,
    this.product,
    this.productId,
    required this.onTap,
    this.backgroundColor,
    this.useBackgroundColor = true,
  }) : assert(product != null || productId != null, "Either product or productId must be provided"),
       super(key: key);

  @override
  State<UniversalProductCard> createState() => _UniversalProductCardState();
}

class _UniversalProductCardState extends State<UniversalProductCard> {
  // Local state
  late Product _displayProduct;
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _resolveProduct();
  }
  
  @override
  void didUpdateWidget(UniversalProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If widget properties changed, update the display product
    if (widget.product != oldWidget.product || widget.productId != oldWidget.productId) {
      _resolveProduct();
    }
  }
  
  // Resolve the product from either direct product or product ID
  void _resolveProduct() {
    try {
      if (widget.product != null) {
        _displayProduct = widget.product!;
        _isInitialized = true;
      } else if (widget.productId != null) {
        // Get product from product inventory
        final products = ProductInventory.getAllProducts();
        try {
          final fetchedProduct = products.firstWhere((p) => p.id == widget.productId);
          _displayProduct = fetchedProduct;
          _isInitialized = true;
        } catch (e) {
          print('Product not found with ID: ${widget.productId}');
        }
      }
    } catch (e) {
      print('Error resolving product: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      // Not initialized yet
      return const SizedBox.shrink();
    }
    
    // Get background color if needed
    Color? cardBackgroundColor;
    if (widget.useBackgroundColor) {
      cardBackgroundColor = widget.backgroundColor ?? _getBackgroundColor(_displayProduct);
    }
    
    // Simple card without cart functionality 
    return EnhancedProductCard.fromEntity(
      product: _displayProduct,
      onTap: widget.onTap,
      backgroundColor: cardBackgroundColor,
    );
  }
  
  // Helper to get background color for product
  Color? _getBackgroundColor(Product product) {
    try {
      // Convert Product to ProductModel since SimilarProducts expects ProductModel
      final productModel = _convertToProductModel(product);
      return SimilarProducts.getColorForProduct(productModel);
    } catch (e) {
      return Colors.blueGrey.shade100; // Default fallback
    }
  }
  
  // Convert Product to ProductModel for compatibility
  ProductModel _convertToProductModel(Product product) {
    return ProductModel(
      id: product.id,
      name: product.name,
      image: product.image,
      description: product.description,
      price: product.price,
      mrp: product.mrp,
      inStock: product.inStock,
      categoryId: product.categoryId,
      subcategoryId: product.subcategoryId,
      tags: product.tags,
      isFeatured: product.isFeatured,
      isActive: product.isActive,
      categoryGroup: product.categoryGroup,
    );
  }
}
