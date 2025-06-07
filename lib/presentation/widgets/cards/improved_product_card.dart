import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/product.dart';
import '../../../services/logging_service.dart';
import '../../../services/product/shared_product_service.dart';
import '../../../services/category/shared_category_service.dart';
import '../../../data/inventory/similar_products.dart';
import '../../../data/models/product_model.dart';
import '../../../utils/product_card_utils.dart';
import '../../widgets/buttons/add_button.dart';
import '../../pages/product_details/product_details_page.dart'; // Import the new page
import 'dart:math' as math;
import 'package:get_it/get_it.dart';

/**
 * ImprovedProductCard
 *
 * A highly optimized product card that can work with any product ID and follows
 * the specified layout structure for consistent display across the app.
 *
 * Layout Structure:
 * - Image Section (~60% height) with bookmark-style savings indicator
 * - Product Name (up to 2 lines with ellipsis)
 * - Brand and Weight Row (split layout)
 * - Empty Spacer Row (visual separation)
 * - Price Row (final price + original price with strikethrough)
 * - Add to Cart Button (centered at bottom)
 *
 * Key Features:
 * - Works with Product object OR productId string
 * - Fixed width for horizontal scrolling grids
 * - Automatic product resolution from ID
 * - Category-based background colors
 * - Discount display (₹X off / X% off)
 * - Smart pricing (MRP vs discounted price)
 * - Optimized performance with caching
 *
 * Usage Examples:
 * ```dart
 * // With Product object
 * ImprovedProductCard(
 * product: product,
 * onTap: () => someOtherAction(), // onTap is now optional and for secondary actions
 * )
 *
 * // With product ID (will auto-resolve)
 * ImprovedProductCard(
 * productId: "product_123",
 * )
 *
 * // Fixed width for horizontal scrolling
 * ImprovedProductCard(
 * product: product,
 * width: 180.w,
 * )
 * ```
 */

class ImprovedProductCard extends StatefulWidget {
  // Product can be provided directly or by ID
  final Product? product;
  final String? productId;

  // Card configuration
  final double? width; // Fixed width for horizontal scrolling
  final double? height; // Optional height override
  final Color? backgroundColor; // Optional background color override
  final bool isLoading; // Explicit loading state

  // Pricing configuration
  final double? finalPrice; // Override final price
  final double? originalPrice; // Override original price
  final bool? hasDiscount; // Override discount status
  final String? discountType; // 'percentage' or 'flat'
  final double? discountValue; // Discount amount

  // Callbacks
  // Reverted to VoidCallback as requested, navigation is now internal
  final VoidCallback? onTap;
  final Function(Product, int)? onQuantityChanged;
  final int quantity;

  // Display options
  final bool showBrand;
  final bool showWeight;
  final bool showSavingsIndicator;
  final bool enableQuantityControls;

  const ImprovedProductCard({
    Key? key,
    this.product,
    this.productId,
    this.width,
    this.height,
    this.backgroundColor,
    this.isLoading = false,
    this.finalPrice,
    this.originalPrice,
    this.hasDiscount,
    this.discountType,
    this.discountValue,
    this.onTap,
    this.onQuantityChanged,
    this.quantity = 0,
    this.showBrand = true,
    this.showWeight = true,
    this.showSavingsIndicator = true,
    this.enableQuantityControls = true,
  }) : assert(isLoading || product != null || productId != null, "Either isLoading must be true or product/productId must be provided"),
       super(key: key);

  /// Convenience constructor for creating a loading card
  const ImprovedProductCard.loading({
    Key? key,
    double? width,
    double? height,
    Color? backgroundColor,
  }) : product = null,
       productId = null,
       isLoading = true,
       finalPrice = null,
       originalPrice = null,
       hasDiscount = null,
       discountType = null,
       discountValue = null,
       onTap = null,
       onQuantityChanged = null,
       quantity = 0,
       showBrand = true,
       showWeight = true,
       showSavingsIndicator = true,
       enableQuantityControls = true,
       width = width,
       height = height,
       backgroundColor = backgroundColor,
       super(key: key);

  @override
  State<ImprovedProductCard> createState() => _ImprovedProductCardState();
}

class _ImprovedProductCardState extends State<ImprovedProductCard> {
  // Services
  late final SharedProductService _productService;
  late final SharedCategoryService _categoryService;

  // State
  Product? _displayProduct;
  Color? _cardBackgroundColor;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  // Computed properties
  double get _finalPrice => widget.finalPrice ?? _displayProduct?.price ?? 0.0;
  double? get _originalPrice {
    if (widget.originalPrice != null) return widget.originalPrice;
    if (_displayProduct == null) return null;

    final discountInfo = _displayProduct!.discountInfo;
    return discountInfo.hasDiscount ? discountInfo.originalPrice : null;
  }
  bool get _hasDiscountInternal {
    if (widget.hasDiscount != null) return widget.hasDiscount!;
    if (_displayProduct == null) return false;

    return _displayProduct!.discountInfo.hasDiscount;
  }
  String? get _discountTypeInternal {
    if (widget.discountType != null) return widget.discountType;
    if (_displayProduct == null) return null;

    return _displayProduct!.discountInfo.discountType;
  }
  double get _discountValueInternal {
    if (widget.discountValue != null) return widget.discountValue!;
    if (_displayProduct == null) return 0.0;

    return _displayProduct!.discountInfo.discountValue;
  }

  @override
  void initState() {
    super.initState();
    _productService = GetIt.instance<SharedProductService>();
    _categoryService = GetIt.instance<SharedCategoryService>();
    _initializeProduct();
  }

  @override
  void didUpdateWidget(ImprovedProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reinitialize if product/productId changed
    if (widget.product != oldWidget.product || widget.productId != oldWidget.productId) {
      _initializeProduct();
    }
  }

  Future<void> _initializeProduct() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
      });

      // If this is explicitly a loading card, show loading state without resolution
      if (widget.isLoading) {
        // Just stay in loading state - don't try to resolve anything
        return;
      }

      // Resolve product
      Product? product;
      if (widget.product != null) {
        product = widget.product!;
        LoggingService.logFirestore('IMPROVED_CARD: Using provided product ${product.name}');
      } else if (widget.productId != null) {
        LoggingService.logFirestore('IMPROVED_CARD: Resolving product ID ${widget.productId}');
        product = await _productService.getProductById(widget.productId!);

        if (product == null) {
          throw Exception('Product not found with ID: ${widget.productId}');
        }
        LoggingService.logFirestore('IMPROVED_CARD: Resolved product ${product.name}');
      }

      if (product == null) {
        throw Exception('No product provided');
      }

      // Get background color
      Color backgroundColor = widget.backgroundColor ?? await _getBackgroundColor(product);

      if (mounted) {
        setState(() {
          _displayProduct = product;
          _cardBackgroundColor = backgroundColor;
          _isLoading = false;
        });
      }

    } catch (e) {
      LoggingService.logError('IMPROVED_CARD', 'Error initializing product: $e');

      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<Color> _getBackgroundColor(Product product) async {
    try {
      // First check if the product has itemBackgroundColor in customProperties
      if (product.customProperties != null) {
        final itemBgColor = product.customProperties!['itemBackgroundColor'];
        if (itemBgColor is Color) {
          LoggingService.logFirestore('IMPROVED_CARD: Using itemBackgroundColor from product: $itemBgColor');
          return itemBgColor;
        }
        // Also check for string representation of color
        if (itemBgColor is String) {
          try {
            final colorValue = int.parse(itemBgColor.replaceAll('#', ''), radix: 16);
            final color = Color(colorValue).withOpacity(1.0);
            LoggingService.logFirestore('IMPROVED_CARD: Using itemBackgroundColor from string: $color');
            return color;
          } catch (e) {
            LoggingService.logError('IMPROVED_CARD', 'Error parsing color string: $e');
          }
        }
      }

      // Fallback to SimilarProducts color system
      final productModel = _convertToProductModel(product);
      return SimilarProducts.getColorForProduct(productModel) ?? AppTheme.secondaryColor;
    } catch (e) {
      LoggingService.logError('IMPROVED_CARD', 'Error getting background color: $e');
      return AppTheme.secondaryColor;
    }
  }

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
      brand: product.brand,
      weight: product.weight,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_hasError || _displayProduct == null) {
      return _buildErrorState();
    }

    return _buildProductCard(context); // Pass context to _buildProductCard
  }

  Widget _buildLoadingState() {
    final cardHeight = widget.height ?? 280.h;

    return Container(
      width: widget.width, // Let parent control width if null
      height: cardHeight,
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          // Image placeholder (~60% height)
          Container(
            height: cardHeight * 0.6,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey.shade700, Colors.grey.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            child: Center(
              child: CircularProgressIndicator(
                color: AppTheme.accentColor,
                strokeWidth: 2.w,
              ),
            ),
          ),

          // Content placeholder
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(12.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name placeholder
                  Container(
                    width: double.infinity,
                    height: 16.h,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade700,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SizedBox(height: 8.h),

                  // Brand/weight placeholder
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 60.w,
                        height: 12.h,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade700,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      Container(
                        width: 40.w,
                        height: 12.h,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade700,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ],
                  ),

                  Spacer(),

                  // Price placeholder
                  Container(
                    width: 80.w,
                    height: 14.h,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade700,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SizedBox(height: 8.h),

                  // Button placeholder
                  Container(
                    width: double.infinity,
                    height: 32.h,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade700,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final cardHeight = widget.height ?? 280.h;

    return Container(
      width: widget.width, // Let parent control width if null
      height: cardHeight,
      decoration: BoxDecoration(
        color: Colors.red.shade900.withOpacity(0.1),
        border: Border.all(color: Colors.red.shade700, width: 1),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 32.r,
              ),
              SizedBox(height: 8.h),
              Text(
                'Product not found',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (_errorMessage != null) ...[
                SizedBox(height: 4.h),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Colors.red.shade400,
                    fontSize: 12.sp,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context) { // Accept context
    final product = _displayProduct!;
    final backgroundColor = _cardBackgroundColor ?? AppTheme.secondaryColor;

    return GestureDetector(
      onTap: () {
        // Navigate to ProductDetailsPage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsPage(productId: product.id),
          ),
        );
        // Call any additional onTap callback if provided
        widget.onTap?.call();
      },
      child: Container(
        width: widget.width, // Let GridView or parent control width if widget.width is null
        height: widget.height, // Use widget.height directly, allows null for auto-sizing
        decoration: BoxDecoration(
          color: AppTheme.secondaryColor,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            _buildImageSection(product, backgroundColor, widget.height),

            // Content Section
            _buildContentSection(product, widget.height),
          ],
        ),
      ),
    );
  }

   Widget _buildImageSection(Product product, Color backgroundColor, double? explicitHeight) {
    final double imageHeight;
    if (explicitHeight != null) {
      imageHeight = explicitHeight * 0.50;
    } else {
      imageHeight = 125.h;
    }

    return Stack(
      children: [
        // Product Image
        ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
          ),
          child: Container(
            height: imageHeight,
            width: double.infinity,
            color: backgroundColor,
            padding: EdgeInsets.all(18.r),
            child: CachedNetworkImage(
              imageUrl: product.image,
              fit: BoxFit.contain,
              placeholder: (context, url) => Center(
                child: CircularProgressIndicator(
                  color: AppTheme.accentColor,
                  strokeWidth: 2.w,
                ),
              ),
              errorWidget: (context, url, error) {
                LoggingService.logError('IMPROVED_CARD', 'Error loading image for ${product.name}: $error');
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.image_not_supported,
                        color: Colors.white70,
                        size: 32.r,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Image not available',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),

        // Savings Indicator
        if (widget.showSavingsIndicator && _hasDiscountInternal && _discountValueInternal > 0)
          _buildSavingsIndicator(),

        // Out of Stock Overlay
        if (!product.inStock)
          _buildOutOfStockOverlay(imageHeight),

        // Add to Cart Button (Added Here)
        if (widget.enableQuantityControls && product.inStock)
          Positioned(
            bottom: 4.h,
            right: 4.w,
            left: 4.w, // Use left and right for responsive width
            child: SizedBox(
              height: 28.h,
              child: AddButton(
                productId: product.id,
                sourceCardType: ProductCardType.improved,
                inStock: product.inStock,
                height: 28.h,
                onQuantityChanged: widget.onQuantityChanged != null
                  ? (qty) => widget.onQuantityChanged!(product, qty)
                  : null,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSavingsIndicator() {
    return Positioned(
      top: 0,
      left: 0,
      child: Container(
        constraints: BoxConstraints(
          minWidth: 20.w,
          maxWidth: 50.w,
        ),
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 6.w),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.only(
            // topRight: Radius.circular(12.r),
            bottomRight: Radius.circular(12.r),
            topLeft: Radius.circular(16.r),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Discount value
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
              child: Text(
                _discountTypeInternal == 'percentage'
                  ? '${_discountValueInternal.toInt()}%'
                  : '₹${_discountValueInternal.toInt()}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13.sp,
                  height: 1.0,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            SizedBox(height: 8.h),
            // "OFF" text
            Text(
              'OFF',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 10.sp,
                height: 1.0,
              ),
              textAlign: TextAlign.left,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutOfStockOverlay(double imageHeight) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
          ),
        ),
        child: Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.blueGrey.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              'OUT OF STOCK',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
              ),
            ),
          ),
        ),
      ),
    );
  }

 Widget _buildContentSection(Product product, double? explicitHeight) {
    Widget contentWidget = Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.r, vertical: 6.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 6.h),
          _buildProductName(product),
          SizedBox(height: 4.h),
          if (widget.showBrand) ...[
            _buildProductBrand(product),
            SizedBox(height: 6.h),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 0, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Price Column (Left)
                Expanded(
                  flex: 60,
                  child: _buildPriceColumn(),
                ),
                // Weight Text (Right)
                if (widget.showWeight && product.weight != null)
                  Expanded(
                    flex: 40,
                    child: Text(
                      product.weight!,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12.sp,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
              ],
            ),
          ),
          // SizedBox(height: 1.h), // Space between price/weight row and bottom
          // Removed SizedBox(height: 10.h) and Add to Cart Button
        ],
      ),
    );

    if (explicitHeight != null) {
      return Expanded(child: contentWidget);
    } else {
      return contentWidget;
    }
  }

  Widget _buildProductName(Product product) {
    return Text(
      product.name,
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 14.sp, // Reduced from 14.sp to 13.sp
        height: 1.1, // Reduced line height
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildProductBrand(Product product) {
    return Text(
      product.brand ?? '',
      style: TextStyle(
        color: Colors.white70,
        fontSize: 10.sp,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildPriceColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Final Price (Current selling price) or MRP if no discount
        Text(
          '${AppConstants.currencySymbol}${_finalPrice.toStringAsFixed(0)}',
          style: TextStyle(
            color: _hasDiscountInternal ? Colors.green : AppTheme.accentColor,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // Original Price (MRP - strikethrough) - only if discounted
        if (_originalPrice != null && _originalPrice! > _finalPrice)
          Text(
              '${AppConstants.currencySymbol}${_originalPrice!.toStringAsFixed(0)}',
              style: TextStyle(
                color: Colors.white60,
                decoration: TextDecoration.lineThrough,
                fontSize: 13.sp,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ), // Empty space if no original price
      ],
    );
  }

  Widget _buildAddToCartButton(Product product) {
    return SizedBox(
      width: double.infinity,
      height: 28.h,
      child: AddButton(
        productId: product.id,
        sourceCardType: ProductCardType.improved,
        inStock: product.inStock,
        height: 28.h,
        onQuantityChanged: widget.onQuantityChanged != null
          ? (qty) => widget.onQuantityChanged!(product, qty)
          : null,
      ),
    );
  }
}