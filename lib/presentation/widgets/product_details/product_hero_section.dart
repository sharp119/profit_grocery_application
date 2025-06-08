import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:profit_grocery_application/core/constants/app_constants.dart';
import 'package:profit_grocery_application/core/constants/app_theme.dart';
import 'package:profit_grocery_application/presentation/widgets/buttons/add_button.dart';
import 'package:profit_grocery_application/presentation/widgets/image_loader.dart';

class ProductDetailHeroSection extends StatelessWidget {
  final List<dynamic> productImages;
  final PageController pageController;
  final int currentPage;
  final ValueChanged<int> onImagePageChanged;
  final Color? itemBackgroundColor;
  final bool dynamicHasDiscount;
  final double? dynamicDiscountValue;
  final String? dynamicDiscountType;
  final String productName;
  final double? productRating;
  final int? productReviewCount;
  final String? productBrand;
  final String? productWeight;
  final String? productType;
  final double displayPrice;
  final bool showDiscountStrikethrough;
  final double? displayMrp;
  final bool displayInStock;
  final String productId;

  const ProductDetailHeroSection({
    Key? key,
    required this.productImages,
    required this.pageController,
    required this.currentPage,
    required this.onImagePageChanged,
    this.itemBackgroundColor,
    required this.dynamicHasDiscount,
    this.dynamicDiscountValue,
    this.dynamicDiscountType,
    required this.productName,
    this.productRating,
    this.productReviewCount,
    this.productBrand,
    this.productWeight,
    this.productType,
    required this.displayPrice,
    required this.showDiscountStrikethrough,
    this.displayMrp,
    required this.displayInStock,
    required this.productId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container( // Wrapped in a Container as requested
      child: Column( // Use a Column to arrange the sections vertically
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image Carousel (Hero Section Visual)
          Stack(
            children: [
              Center(
                child: Container(
                  height: 350.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                    color: itemBackgroundColor ?? AppTheme.secondaryColor,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: (productImages.isNotEmpty)
                        ? PageView.builder(
                            controller: pageController,
                            itemCount: productImages.length,
                            onPageChanged: onImagePageChanged, // Use the passed callback
                            itemBuilder: (context, index) {
                              return ImageLoader.network(
                                productImages[index],
                                fit: BoxFit.contain,
                                errorWidget: Center(
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    color: AppTheme.textSecondaryColor,
                                    size: 60.r,
                                  ),
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: AppTheme.textSecondaryColor,
                              size: 60.r,
                            ),
                          ),
                  ),
                ),
              ),
              // Discount Badge (on image)
              if (dynamicHasDiscount && dynamicDiscountValue != null && dynamicDiscountValue! > 0)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    constraints: BoxConstraints(
                      minWidth: 20.w,
                      maxWidth: 60.w,
                    ),
                    padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 6.w),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(12.r),
                        topLeft: Radius.circular(8.r),
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
                        Text(
                          dynamicDiscountType == 'percentage'
                              ? '${dynamicDiscountValue!.toInt()}%'
                              : '₹${dynamicDiscountValue!.toInt()}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13.sp,
                            height: 1.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'OFF',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 10.sp,
                            height: 1.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              // Page Indicator
              if (productImages.length > 1)
                Positioned(
                  bottom: 10.h,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(productImages.length, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: EdgeInsets.symmetric(horizontal: 4.w),
                        height: 8.h,
                        width: currentPage == index ? 24.w : 8.w,
                        decoration: BoxDecoration(
                          color: currentPage == index ? AppTheme.accentColor : Colors.grey.shade600,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
          SizedBox(height: 20.h), // This SizedBox is included in the new widget

          // Product Name and Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  productName,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
              if (productRating != null && productRating! > 0)
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 18.sp),
                    SizedBox(width: 4.w),
                    Text(
                      productRating!.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    if (productReviewCount != null && productReviewCount! > 0)
                      Text(
                        ' (${productReviewCount} reviews)',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                  ],
                ),
            ],
          ),
          SizedBox(height: 8.h),

          // Brand and Weight/Product Type
          Row(
            children: [
              if (productBrand != null && productBrand!.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    productBrand!,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppTheme.accentColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              if (productBrand != null && productBrand!.isNotEmpty && (productWeight != null || productType != null))
                SizedBox(width: 8.w),
              if (productWeight != null && productWeight!.isNotEmpty)
                Text(
                  productWeight!,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              if (productWeight == null && productType != null && productType!.isNotEmpty)
                Text(
                  productType!,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
            ],
          ),
          SizedBox(height: 16.h),

          // Price Section (using dynamic pricing from RTDB) with Add Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              // Price Display
              Text(
                '${AppConstants.currencySymbol}${displayPrice.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: dynamicHasDiscount ? Colors.green[700] : AppTheme.accentColor,
                ),
              ),
              if (showDiscountStrikethrough) ...[
                SizedBox(width: 10.w),
                Text(
                  '${AppConstants.currencySymbol}${displayMrp!.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 18.sp,
                    color: AppTheme.textSecondaryColor,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                SizedBox(width: 10.w),
                if (dynamicDiscountValue != null)
                  Text(
                    dynamicDiscountType == 'percentage'
                        ? '${dynamicDiscountValue!.toInt()}% OFF'
                        : '₹${dynamicDiscountValue!.toInt()} OFF',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
              ],
              Spacer(),
              // Add to Cart Button
              if (displayInStock)
                SizedBox(
                  width: 100.w,
                  height: 40.h,
                  child: AddButton(
                    productId: productId,
                    sourceCardType: ProductCardType.productDetails,
                    inStock: displayInStock,
                  ),
                )
              else
                Container(
                  width: 100.w,
                  height: 40.h,
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  decoration: BoxDecoration(
                    color: Colors.red.shade700,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'SOLD OUT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}