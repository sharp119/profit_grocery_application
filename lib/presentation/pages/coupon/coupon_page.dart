import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_theme.dart';
import '../../blocs/coupon/coupon_bloc.dart';
import '../../blocs/coupon/coupon_event.dart';
import '../../blocs/coupon/coupon_state.dart';
import '../../widgets/base_layout.dart';
import '../../widgets/loaders/shimmer_loader.dart';

class CouponPage extends StatelessWidget {
  final String? deepLinkCoupon;

  const CouponPage({
    Key? key,
    this.deepLinkCoupon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CouponBloc()..add(LoadCoupons(deepLinkCoupon)),
      child: const _CouponPageContent(),
    );
  }
}

class _CouponPageContent extends StatelessWidget {
  const _CouponPageContent();

  void _applyCoupon(BuildContext context, String code) {
    // Return coupon code to previous screen
    Navigator.pop(context, code);
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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CouponBloc, CouponState>(
      listener: (context, state) {
        if (state.status == CouponStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'An error occurred'),
              backgroundColor: Colors.red,
            ),
          );
        }
        
        // Auto-apply deep link coupon if valid
        if (state.status == CouponStatus.deepLinkCouponValid) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _applyCoupon(context, state.deepLinkCoupon!);
          });
        }
      },
      builder: (context, state) {
        return BaseLayout(
          title: state.deepLinkCoupon != null ? 'Apply Coupon' : 'Available Coupons',
          showCartIcon: false,
          body: state.status == CouponStatus.loading
              ? _buildLoadingState()
              : _buildCouponList(context, state),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shimmer for header
          ShimmerLoader.customContainer(
            height: 80.h,
            width: double.infinity,
            borderRadius: 12.r,
          ),
          
          SizedBox(height: 24.h),
          
          // Shimmer for coupon cards
          for (int i = 0; i < 5; i++) ...[
            ShimmerLoader.customContainer(
              height: 150.h,
              width: double.infinity,
              borderRadius: 12.r,
            ),
            SizedBox(height: 16.h),
          ],
        ],
      ),
    );
  }

  Widget _buildCouponList(BuildContext context, CouponState state) {
    // Show deep link coupon if available
    if (state.deepLinkCoupon != null) {
      final deepLinkCouponInfo = state.deepLinkCouponInfo;
      
      return SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header for deep link coupon
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppTheme.accentColor,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.local_offer,
                    color: AppTheme.accentColor,
                    size: 24.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Special Offer For You!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Use this coupon to get amazing discounts on your purchase.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24.h),
            
            // Deep link coupon card
            _buildCouponCard(
              context,
              code: state.deepLinkCoupon!,
              discount: deepLinkCouponInfo?.discount ?? 'Special Discount',
              minOrderValue: deepLinkCouponInfo?.minOrderValue,
              expiryDate: deepLinkCouponInfo?.expiryDate,
              description: deepLinkCouponInfo?.description ?? 'Special offer just for you!',
              isHighlighted: true,
            ),
            
            SizedBox(height: 24.h),
            
            // Apply button
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                onPressed: () => _applyCoupon(context, state.deepLinkCoupon!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  'APPLY COUPON',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            if (state.coupons.isNotEmpty) ...[
              SizedBox(height: 32.h),
              
              Divider(color: Colors.grey.withOpacity(0.3)),
              
              SizedBox(height: 16.h),
              
              Text(
                'More Coupons',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              SizedBox(height: 16.h),
              
              // List of other available coupons
              for (final coupon in state.coupons) ...[
                if (coupon.code != state.deepLinkCoupon)
                  _buildCouponCard(
                    context,
                    code: coupon.code,
                    discount: coupon.discount,
                    minOrderValue: coupon.minOrderValue,
                    expiryDate: coupon.expiryDate,
                    description: coupon.description,
                  ),
                SizedBox(height: 16.h),
              ],
            ],
          ],
        ),
      );
    }
    
    // Show all available coupons
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.discount_outlined,
                    color: AppTheme.accentColor,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Coupons',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Apply these coupons to get discounts on your orders',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24.h),
          
          // Manual coupon entry
          TextField(
            decoration: InputDecoration(
              hintText: 'Enter coupon code',
              prefixIcon: Icon(
                Icons.confirmation_number_outlined,
                color: Colors.grey,
                size: 20.sp,
              ),
              suffixIcon: TextButton(
                onPressed: () {
                  // Get coupon code from text field
                  final textField = context.findRenderObject() as RenderBox?;
                  if (textField != null) {
                    final controller = (textField.parent as EditableText).controller;
                    final code = controller.text;
                    
                    if (code.isNotEmpty) {
                      _applyCoupon(context, code);
                    }
                  }
                },
                child: Text(
                  'APPLY',
                  style: TextStyle(
                    color: AppTheme.accentColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              filled: true,
              fillColor: AppTheme.primaryColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(
                  color: AppTheme.accentColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(
                  color: AppTheme.accentColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(
                  color: AppTheme.accentColor,
                  width: 1.5,
                ),
              ),
            ),
            onSubmitted: (code) {
              if (code.isNotEmpty) {
                _applyCoupon(context, code);
              }
            },
          ),
          
          SizedBox(height: 24.h),
          
          Text(
            'Available Coupons',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          SizedBox(height: 16.h),
          
          if (state.coupons.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32.h),
                child: Column(
                  children: [
                    Icon(
                      Icons.local_offer_outlined,
                      color: Colors.grey,
                      size: 48.sp,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'No coupons available at the moment',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16.sp,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            // List of available coupons
            for (final coupon in state.coupons) ...[
              _buildCouponCard(
                context,
                code: coupon.code,
                discount: coupon.discount,
                minOrderValue: coupon.minOrderValue,
                expiryDate: coupon.expiryDate,
                description: coupon.description,
              ),
              SizedBox(height: 16.h),
            ],
        ],
      ),
    );
  }

  Widget _buildCouponCard(
    BuildContext context, {
    required String code,
    required String discount,
    String? minOrderValue,
    String? expiryDate,
    required String description,
    bool isHighlighted = false,
  }) {
    return Container(
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
                  : AppTheme.secondaryColor.withOpacity(0.5),
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
                // Coupon code
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: isHighlighted
                        ? AppTheme.accentColor
                        : AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(4.r),
                    border: Border.all(
                      color: isHighlighted
                          ? Colors.transparent
                          : AppTheme.accentColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    code,
                    style: TextStyle(
                      color: isHighlighted
                          ? Colors.black
                          : AppTheme.accentColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                
                SizedBox(width: 12.w),
                
                // Coupon discount
                Expanded(
                  child: Text(
                    discount,
                    style: TextStyle(
                      color: isHighlighted
                          ? AppTheme.accentColor
                          : Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // Copy button
                IconButton(
                  onPressed: () => _copyCouponCode(context, code),
                  icon: Icon(
                    Icons.copy,
                    color: Colors.grey,
                    size: 20.sp,
                  ),
                  tooltip: 'Copy code',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          
          // Coupon details
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                  ),
                ),
                
                SizedBox(height: 12.h),
                
                // Minimum order value and expiry date
                Row(
                  children: [
                    if (minOrderValue != null) ...[
                      Icon(
                        Icons.shopping_bag_outlined,
                        color: Colors.grey,
                        size: 16.sp,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Min. Order: $minOrderValue',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12.sp,
                        ),
                      ),
                      SizedBox(width: 16.w),
                    ],
                    
                    if (expiryDate != null) ...[
                      Icon(
                        Icons.access_time,
                        color: Colors.grey,
                        size: 16.sp,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Valid till: $expiryDate',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ],
                ),
                
                SizedBox(height: 16.h),
                
                // Apply button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _applyCoupon(context, code),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isHighlighted
                          ? AppTheme.accentColor
                          : AppTheme.accentColor.withOpacity(0.2),
                      foregroundColor: isHighlighted
                          ? Colors.black
                          : AppTheme.accentColor,
                      padding: EdgeInsets.symmetric(
                        vertical: 10.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                    child: Text(
                      'APPLY',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}