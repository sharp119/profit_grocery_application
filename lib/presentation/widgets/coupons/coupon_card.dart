import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_theme.dart';
import '../../../data/samples/sample_coupons.dart';
import 'coupon_detail_modal.dart';

class CouponCard extends StatelessWidget {
  final SampleCoupon coupon;
  final Function(String) onApply;
  final bool isHighlighted;

  const CouponCard({
    Key? key,
    required this.coupon,
    required this.onApply,
    this.isHighlighted = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showCouponDetails(context),
      child: Container(
        decoration: BoxDecoration(
          color: isHighlighted
              ? AppTheme.accentColor.withOpacity(0.1)
              : AppTheme.secondaryColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isHighlighted
                ? AppTheme.accentColor
                : Colors.transparent,
            width: isHighlighted ? 1.5 : 0,
          ),
        ),
        child: Column(
          children: [
            // Coupon header
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: isHighlighted
                    ? AppTheme.accentColor.withOpacity(0.2)
                    : coupon.backgroundColor.withOpacity(0.8),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12.r),
                  topRight: Radius.circular(12.r),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: isHighlighted
                        ? AppTheme.accentColor.withOpacity(0.5)
                        : Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Coupon icon based on type
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getCouponIcon(),
                      color: Colors.white,
                      size: 20.sp,
                    ),
                  ),
                  
                  SizedBox(width: 12.w),
                  
                  // Coupon title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          coupon.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        if (coupon.minPurchase != null) ...[
                          SizedBox(height: 4.h),
                          Text(
                            'Min. order: ₹${coupon.minPurchase!.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Coupon code and details
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Coupon code
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppTheme.accentColor.withOpacity(0.5),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          coupon.code,
                          style: TextStyle(
                            color: AppTheme.accentColor,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        InkWell(
                          onTap: () => _copyCouponCode(context, coupon.code),
                          child: Icon(
                            Icons.copy_outlined,
                            color: AppTheme.accentColor,
                            size: 16.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(width: 12.w),
                  
                  // Validity
                  Expanded(
                    child: Text(
                      'Valid till: ${_formatDate(coupon.endDate)}',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // View details button
                  InkWell(
                    onTap: () => _showCouponDetails(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'DETAILS',
                            style: TextStyle(
                              color: AppTheme.accentColor,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: AppTheme.accentColor,
                            size: 12.sp,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCouponIcon() {
    switch (coupon.type) {
      case 'percentage':
        return Icons.percent;
      case 'fixed':
        return Icons.local_offer_outlined;
      case 'free_delivery':
        return Icons.delivery_dining_outlined;
      case 'free_product':
        return Icons.card_giftcard_outlined;
      case 'conditional':
        if (coupon.conditions != null) {
          if (coupon.conditions!.containsKey('buyQuantity') && coupon.conditions!.containsKey('getQuantity')) {
            return Icons.add_shopping_cart_outlined;
          } else if (coupon.conditions!.containsKey('requiredProducts')) {
            return Icons.category_outlined;
          }
        }
        return Icons.local_offer_outlined;
      default:
        return Icons.discount_outlined;
    }
  }

  void _showCouponDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return CouponDetailModal(
            coupon: coupon,
            onApply: onApply,
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _copyCouponCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Coupon code $code copied to clipboard'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
