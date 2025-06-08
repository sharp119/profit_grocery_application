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
    return Card(
      elevation: 12,
      margin: EdgeInsets.symmetric(horizontal: 0.w, vertical: 12.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Carousel
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.45,
                    width: double.infinity,
                    color: itemBackgroundColor ?? AppTheme.secondaryColor,
                    child: (productImages.isNotEmpty)
                        ? PageView.builder(
                            controller: pageController,
                            itemCount: productImages.length,
                            onPageChanged: onImagePageChanged,
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

                // Discount Badge (angled ribbon)
                if (dynamicHasDiscount && dynamicDiscountValue != null && dynamicDiscountValue! > 0)
                  Positioned(
                    top: 25,
                    left: -60,
                    child: Transform.rotate(
                      angle: -0.6,
                      child: Container(
                        width: 220.w,
                        padding: EdgeInsets.symmetric(vertical: 4.h),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.red.shade700, Colors.red.shade400],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4.r,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            dynamicDiscountType == 'percentage'
                                ? '${dynamicDiscountValue!.toInt()}% OFF'
                                : '₹${dynamicDiscountValue!.toInt()} OFF',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
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
                          duration: Duration(milliseconds: 200),
                          margin: EdgeInsets.symmetric(horizontal: 4.w),
                          height: 8.h,
                          width: currentPage == index ? 20.w : 8.w,
                          decoration: BoxDecoration(
                            color: currentPage == index
                                ? AppTheme.accentColor
                                : Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        );
                      }),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 20.h),

            // Product Name & Rating
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    productName,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
                if (productRating != null && productRating! > 0)
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16.sp),
                      SizedBox(width: 4.w),
                      Text(
                        productRating!.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (productReviewCount != null)
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

            // Brand & Type/Weight
            Row(
              children: [
                if (productBrand != null && productBrand!.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
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
                if ((productWeight != null || productType != null) && productBrand != null)
                  SizedBox(width: 10.w),
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
            SizedBox(height: 35.h),

            // Price & Add Button
            Row(
              children: [
                Text(
                  '${AppConstants.currencySymbol}${displayPrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 26.sp,
                    fontWeight: FontWeight.bold,
                    color: dynamicHasDiscount ? Colors.green.shade700 : AppTheme.accentColor,
                  ),
                ),
                if (showDiscountStrikethrough) ...[
                  SizedBox(width: 10.w),
                  Text(
                    '${AppConstants.currencySymbol}${displayMrp?.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 16.sp,
                      decoration: TextDecoration.lineThrough,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  SizedBox(width: 6.w),

                ],
                Spacer(),
                displayInStock
                    ? SizedBox(
                        width: 100.w,
                        height: 40.h,
                        child: AddButton(
                          productId: productId,
                          sourceCardType: ProductCardType.productDetails,
                          inStock: true,
                        ),
                      )
                    : Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: Colors.red.shade700,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          'SOLD OUT',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
