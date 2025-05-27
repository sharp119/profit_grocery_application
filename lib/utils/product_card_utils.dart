import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/app_theme.dart';
import '../domain/entities/product.dart';

/**
 * ProductCardUtils
 * 
 * Utility functions for product cards and horizontal grids.
 * Provides common calculations, layout helpers, and configuration presets
 * to ensure consistency across different product display implementations.
 */

class ProductCardUtils {
  // Private constructor to prevent instantiation
  ProductCardUtils._();

  /// Standard card dimensions for horizontal grids
  static double get standardCardWidth => AppConstants.horizontalCardWidth.w;
  static double get standardCardHeight => AppConstants.horizontalCardHeight.h;
  static double get standardCardSpacing => AppConstants.horizontalCardSpacing.w;

  /// Calculate how many cards fit in the viewport width
  static int calculateVisibleCards(double viewportWidth) {
    final cardWidth = standardCardWidth;
    final spacing = standardCardSpacing;
    final padding = 32.w; // 16.w on each side
    
    final availableWidth = viewportWidth - padding;
    final cardWithSpacing = cardWidth + spacing;
    
    return (availableWidth / cardWithSpacing).floor();
  }

  /// Calculate the optimal viewport width to show exactly n cards
  static double calculateViewportWidth(int numberOfCards) {
    final cardWidth = standardCardWidth;
    final spacing = standardCardSpacing;
    final padding = 32.w; // 16.w on each side
    
    return (numberOfCards * cardWidth) + 
           ((numberOfCards - 1) * spacing) + 
           padding;
  }

  /// Get the standard ListView padding for horizontal grids with left and right padding
  static EdgeInsets get horizontalListPadding => EdgeInsets.symmetric(horizontal: 16.w);

  /// Get the standard margin for cards in horizontal grids
  static EdgeInsets getCardMargin(int index, int totalItems, {double? spacing}) {
    final cardSpacing = spacing ?? standardCardSpacing;
    return EdgeInsets.only(
      right: index < totalItems - 1 ? cardSpacing : 0,
    );
  }

  /// Calculate discount information from product
  static DiscountInfo calculateDiscount(Product product) {
    final mrp = product.mrp;
    final price = product.price;
    
    if (mrp == null || mrp <= price) {
      return DiscountInfo(
        hasDiscount: false,
        discountType: null,
        discountValue: 0.0,
        originalPrice: null,
      );
    }
    
    final discountAmount = mrp - price;
    final discountPercentage = (discountAmount / mrp) * 100;
    
    // Use percentage if it's a round number, otherwise use flat discount
    final usePercentage = discountPercentage == discountPercentage.round();
    
    return DiscountInfo(
      hasDiscount: true,
      discountType: usePercentage ? 'percentage' : 'flat',
      discountValue: usePercentage ? discountPercentage : discountAmount,
      originalPrice: mrp,
    );
  }

  /// Format price for display
  static String formatPrice(double price) {
    return '${AppConstants.currencySymbol}${price.toStringAsFixed(0)}';
  }

  /// Format discount text for display
  static String formatDiscountText(String discountType, double discountValue) {
    if (discountType == 'percentage') {
      return '${discountValue.toInt()}%';
    } else {
      return '₹${discountValue.toInt()}';
    }
  }

  /// Check if product image URL is valid
  static bool isValidImageUrl(String imageUrl) {
    if (imageUrl.isEmpty) return false;
    
    // Check if the URL has a valid scheme
    if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
      return false;
    }
    
    try {
      Uri.parse(imageUrl);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get placeholder image widget
  static Widget getPlaceholderImage({
    required double width,
    required double height,
    Color? backgroundColor,
    IconData? icon,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.shade700,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Center(
        child: Icon(
          icon ?? Icons.image_not_supported,
          color: Colors.white70,
          size: 32.r,
        ),
      ),
    );
  }

  /// Get error image widget
  static Widget getErrorImage({
    required double width,
    required double height,
    String? errorMessage,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.red.shade900.withOpacity(0.1),
        border: Border.all(color: Colors.red.shade700, width: 1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.broken_image,
              color: Colors.red,
              size: 32.r,
            ),
            if (errorMessage != null) ...[
              SizedBox(height: 4.h),
              Text(
                errorMessage,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 10.sp,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Get loading shimmer widget
  static Widget getLoadingShimmer({
    required double width,
    required double height,
    BorderRadius? borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade800,
            Colors.grey.shade700,
            Colors.grey.shade800,
          ],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: borderRadius ?? BorderRadius.circular(8.r),
      ),
    );
  }

  /// Create a horizontal scroll physics configuration
  static ScrollPhysics get horizontalScrollPhysics => const ClampingScrollPhysics();

  /// Create scroll controller with optimal configuration
  static ScrollController createOptimizedScrollController() {
    return ScrollController();
  }

  /// Get optimal item extent for horizontal lists
  static double get horizontalItemExtent => standardCardWidth + standardCardSpacing;

  /// Configuration presets for different grid types
  static HorizontalGridConfig get bestsellerGridConfig => HorizontalGridConfig(
    cardWidth: standardCardWidth,
    cardHeight: standardCardHeight,
    spacing: standardCardSpacing,
    padding: horizontalListPadding,
    pageSize: AppConstants.horizontalGridPageSize,
    physics: horizontalScrollPhysics,
  );

  static HorizontalGridConfig get featuredGridConfig => HorizontalGridConfig(
    cardWidth: standardCardWidth * 1.1, // Slightly larger for featured
    cardHeight: standardCardHeight * 1.1,
    spacing: standardCardSpacing,
    padding: horizontalListPadding,
    pageSize: AppConstants.horizontalGridPageSize,
    physics: horizontalScrollPhysics,
  );

  static HorizontalGridConfig get compactGridConfig => HorizontalGridConfig(
    cardWidth: standardCardWidth * 0.8, // Smaller for compact view
    cardHeight: standardCardHeight * 0.8,
    spacing: standardCardSpacing * 0.8,
    padding: EdgeInsets.symmetric(horizontal: 12.w),
    pageSize: AppConstants.horizontalGridPageSize + 2, // More items per page
    physics: horizontalScrollPhysics,
  );
}

/// Configuration class for horizontal grids
class HorizontalGridConfig {
  final double cardWidth;
  final double cardHeight;
  final double spacing;
  final EdgeInsets padding;
  final int pageSize;
  final ScrollPhysics physics;

  const HorizontalGridConfig({
    required this.cardWidth,
    required this.cardHeight,
    required this.spacing,
    required this.padding,
    required this.pageSize,
    required this.physics,
  });

  HorizontalGridConfig copyWith({
    double? cardWidth,
    double? cardHeight,
    double? spacing,
    EdgeInsets? padding,
    int? pageSize,
    ScrollPhysics? physics,
  }) {
    return HorizontalGridConfig(
      cardWidth: cardWidth ?? this.cardWidth,
      cardHeight: cardHeight ?? this.cardHeight,
      spacing: spacing ?? this.spacing,
      padding: padding ?? this.padding,
      pageSize: pageSize ?? this.pageSize,
      physics: physics ?? this.physics,
    );
  }
}

/// Discount information calculated from product data
class DiscountInfo {
  final bool hasDiscount;
  final String? discountType;
  final double discountValue;
  final double? originalPrice;

  const DiscountInfo({
    required this.hasDiscount,
    required this.discountType,
    required this.discountValue,
    required this.originalPrice,
  });

  @override
  String toString() {
    if (!hasDiscount) return 'No discount';
    return '${discountType == 'percentage' ? '${discountValue.toInt()}%' : '₹${discountValue.toInt()}'} off';
  }
}

/// Extension methods for Product to make working with cards easier
extension ProductCardExtensions on Product {
  /// Get discount information for this product
  DiscountInfo get discountInfo => ProductCardUtils.calculateDiscount(this);

  /// Get formatted final price
  String get formattedPrice => ProductCardUtils.formatPrice(price);

  /// Get formatted MRP (original price)
  String? get formattedMRP => mrp != null ? ProductCardUtils.formatPrice(mrp!) : null;

  /// Check if product has a valid image
  bool get hasValidImage => ProductCardUtils.isValidImageUrl(image);

  /// Get display name (truncated if too long)
  String getDisplayName({int maxLength = 50}) {
    if (name.length <= maxLength) return name;
    return '${name.substring(0, maxLength - 3)}...';
  }

  /// Check if product is on sale
  bool get isOnSale => discountInfo.hasDiscount;

  /// Get savings amount
  double get savingsAmount {
    final discount = discountInfo;
    if (!discount.hasDiscount || discount.originalPrice == null) return 0.0;
    return discount.originalPrice! - price;
  }

  /// Get savings percentage
  double get savingsPercentage {
    if (mrp == null || mrp! <= price) return 0.0;
    return ((mrp! - price) / mrp!) * 100;
  }
}

/// Mixin for widgets that use horizontal product grids
mixin HorizontalGridMixin<T extends StatefulWidget> on State<T> {
  ScrollController? _scrollController;

  ScrollController get scrollController {
    _scrollController ??= ProductCardUtils.createOptimizedScrollController();
    return _scrollController!;
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }

  /// Add scroll listener for pagination
  void addPaginationListener(VoidCallback onLoadMore) {
    scrollController.addListener(() {
      if (scrollController.position.pixels >= 
          scrollController.position.maxScrollExtent - 200) {
        onLoadMore();
      }
    });
  }

  /// Scroll to beginning of list
  void scrollToStart({Duration? duration}) {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        0,
        duration: duration ?? const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Scroll to end of list
  void scrollToEnd({Duration? duration}) {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: duration ?? const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
}
