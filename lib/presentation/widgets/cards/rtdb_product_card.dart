import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../domain/entities/product.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/logging_service.dart';

/**
 * RTDBProductCard
 * 
 * A redesigned product card with proper spacing and padding to prevent overflow.
 * Based on the UI requirements shown in the design mockup.
 * 
 * Layout Structure:
 * - Image section with background color (90h)
 * - Product info section with proper spacing (flexible)
 * - Pricing section with smart layout
 * - Quantity selector at bottom (28h)
 */

class RTDBProductCard extends StatelessWidget {
  final Product product;
  final Function(Product)? onTap;
  final Function(Product, int)? onQuantityChanged;
  final int quantity;
  final bool showBestsellerBadge;

  const RTDBProductCard({
    Key? key,
    required this.product,
    this.onTap,
    this.onQuantityChanged,
    this.quantity = 0,
    this.showBestsellerBadge = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap?.call(product),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section - Fixed height
            _buildImageSection(),
            
            // Product Info Section - Flexible but controlled
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(8.w, 6.h, 8.w, 4.h), // Reduced padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name - Fixed height to prevent overflow
                    _buildProductName(),
                    
                    SizedBox(height: 1.h), // Reduced spacing
                    
                    // Brand and Weight - Fixed height
                    _buildBrandAndWeight(),
                    
                    // Spacer to push pricing to bottom of this section
                    Expanded(child: SizedBox(height: 2.h)), // Reduced spacing
                    
                    // Pricing Section - Fixed height
                    _buildPricingSection(),
                  ],
                ),
              ),
            ),
            
            // Quantity Selector - Fixed height at bottom
            Padding(
              padding: EdgeInsets.fromLTRB(8.w, 0, 8.w, 6.h), // Reduced bottom padding
              child: _buildQuantitySelector(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    // Get background color from product custom properties
    Color backgroundColor = AppTheme.secondaryColor;
    final itemBackgroundColor = product.customProperties?['itemBackgroundColor'] as Color?;
    if (itemBackgroundColor != null) {
      backgroundColor = itemBackgroundColor;
    }

    return Container(
      height: 90.h, // Reduced from 100.h to 90.h
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12.r),
          topRight: Radius.circular(12.r),
        ),
      ),
      child: Stack(
        children: [
          // Product Image
          Center(
            child: _buildProductImage(),
          ),
          
          // Badges Row at top
          Positioned(
            top: 4.h, // Reduced from 6.h
            left: 4.w, // Reduced from 6.w
            right: 4.w, // Reduced from 6.w
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Bestseller Badge
                if (showBestsellerBadge)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h), // Reduced padding
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(3.r), // Reduced radius
                    ),
                    child: Text(
                      'BESTSELLER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 6.sp, // Reduced from 7.sp
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  SizedBox.shrink(),
                
                // Discount Badge
                if (_hasDiscount())
                  _buildDiscountBadge(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage() {
    if (product.image.isEmpty) {
      return Icon(
        Icons.image,
        size: 45.r, // Reduced from 50.r
        color: Colors.white54,
      );
    }

    return CachedNetworkImage(
      imageUrl: product.image,
      width: 65.w, // Reduced from 70.w
      height: 65.h, // Reduced from 70.h
      fit: BoxFit.contain,
      placeholder: (context, url) => Container(
        width: 65.w,
        height: 65.h,
        child: Center(
          child: CircularProgressIndicator(
            color: AppTheme.accentColor,
            strokeWidth: 2.w,
          ),
        ),
      ),
      errorWidget: (context, url, error) {
        LoggingService.logFirestore('RTDB_CARD: Image load error for ${product.name}: $error');
        return Icon(
          Icons.image_not_supported,
          size: 45.r, // Reduced from 50.r
          color: Colors.white54,
        );
      },
    );
  }

  Widget _buildProductName() {
    return Container(
      height: 24.h, // Reduced from 28.h
      child: Text(
        product.name,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12.sp, // Reduced from 13.sp
          fontWeight: FontWeight.w600,
          height: 1.1, // Reduced line height
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildBrandAndWeight() {
    final brand = product.brand ?? '';
    final weight = product.weight ?? '';
    final displayText = '$brand ${weight}'.trim();

    if (displayText.isEmpty) return SizedBox(height: 12.h); // Reduced from 14.h

    return Container(
      height: 12.h, // Reduced from 14.h
      child: Text(
        displayText,
        style: TextStyle(
          color: Colors.white70,
          fontSize: 10.sp, // Reduced from 11.sp
          height: 1.0, // Reduced line height
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildPricingSection() {
    final finalPrice = product.price;
    final mrp = product.mrp;
    final hasDiscount = _hasDiscount();

    return Container(
      height: 26.h, // Reduced from 30.h
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Final Price
          Text(
            '${AppConstants.currencySymbol}${finalPrice.toStringAsFixed(2)}',
            style: TextStyle(
              color: AppTheme.accentColor,
              fontSize: 14.sp, // Reduced from 15.sp
              fontWeight: FontWeight.bold,
              height: 1.1, // Reduced line height
            ),
          ),
          
          // MRP (if different from final price)
          if (hasDiscount && mrp != null && mrp > finalPrice) ...[
            SizedBox(height: 0.5.h), // Reduced spacing
            Text(
              '${AppConstants.currencySymbol}${mrp.toStringAsFixed(2)}',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 10.sp, // Reduced from 11.sp
                decoration: TextDecoration.lineThrough,
                decorationColor: Colors.white60,
                height: 1.0, // Reduced line height
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDiscountBadge() {
    if (!_hasDiscount()) return SizedBox.shrink();

    final discountText = _getDiscountText();
    if (discountText.isEmpty) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(3.r), // Reduced radius
      ),
      child: Text(
        discountText,
        style: TextStyle(
          color: Colors.white,
          fontSize: 6.sp, // Reduced from 7.sp
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildQuantitySelector(BuildContext context) {
    if (quantity <= 0) {
      return SizedBox(
        width: double.infinity,
        height: 28.h, // Reduced from 30.h
        child: ElevatedButton(
          onPressed: product.inStock ? () => onQuantityChanged?.call(product, 1) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: product.inStock ? AppTheme.accentColor : Colors.grey,
            foregroundColor: Colors.black,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.r), // Reduced radius
            ),
            elevation: 0,
          ),
          child: Text(
            product.inStock ? 'ADD' : 'OUT OF STOCK',
            style: TextStyle(
              fontSize: 10.sp, // Reduced from 11.sp
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Container(
      height: 28.h, // Reduced from 30.h
      decoration: BoxDecoration(
        color: AppTheme.accentColor,
        borderRadius: BorderRadius.circular(5.r), // Reduced radius
      ),
      child: Row(
        children: [
          // Decrease Button
          Expanded(
            child: GestureDetector(
              onTap: () => onQuantityChanged?.call(product, quantity - 1),
              child: Container(
                height: 28.h,
                child: Center(
                  child: Icon(
                    Icons.remove,
                    color: Colors.black,
                    size: 13.r, // Reduced from 14.r
                  ),
                ),
              ),
            ),
          ),
          
          // Quantity Display
          Expanded(
            flex: 2,
            child: Container(
              height: 24.h, // Reduced from 26.h
              margin: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2.r), // Reduced radius
              ),
              child: Center(
                child: Text(
                  quantity.toString(),
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 11.sp, // Reduced from 12.sp
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          
          // Increase Button
          Expanded(
            child: GestureDetector(
              onTap: () => onQuantityChanged?.call(product, quantity + 1),
              child: Container(
                height: 28.h,
                child: Center(
                  child: Icon(
                    Icons.add,
                    color: Colors.black,
                    size: 13.r, // Reduced from 14.r
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Check if product has any discount
  bool _hasDiscount() {
    final hasDiscount = product.customProperties?['hasDiscount'] as bool? ?? false;
    final mrp = product.mrp;
    final finalPrice = product.price;
    
    return hasDiscount && mrp != null && mrp > finalPrice;
  }

  /// Get discount text in "₹X off" or "X% off" format
  String _getDiscountText() {
    if (!_hasDiscount()) return '';

    final discountType = product.customProperties?['discountType'] as String?;
    final discountValue = product.customProperties?['discountValue'] as double?;
    final mrp = product.mrp;
    final finalPrice = product.price;

    if (discountType == null || discountValue == null || mrp == null) return '';

    if (discountType.toLowerCase() == 'percentage') {
      return '${discountValue.round()}% off';
    } else if (discountType.toLowerCase() == 'flat') {
      return '${AppConstants.currencySymbol}${discountValue.round()} off';
    } else {
      // Calculate percentage based on actual price difference
      final actualDiscount = ((mrp - finalPrice) / mrp * 100);
      if (actualDiscount > 0) {
        return '${actualDiscount.round()}% off';
      }
    }

    return '';
  }
}
