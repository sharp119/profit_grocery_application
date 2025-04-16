import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../core/constants/app_theme.dart';
import '../../../data/samples/sample_coupons.dart';
import '../../../domain/repositories/coupon_repository.dart';
import '../../blocs/coupon/coupon_bloc.dart';
import '../../blocs/coupon/coupon_event.dart';
import '../../blocs/coupon/coupon_state.dart';
import '../../widgets/base_layout.dart';
import '../../widgets/coupons/coupon_card.dart';
import '../../widgets/coupons/coupon_detail_modal.dart';
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
      create: (context) => CouponBloc(
        couponRepository: GetIt.I<CouponRepository>(),
      )..add(LoadCoupons(deepLinkCoupon)),
      child: const _CouponPageContent(),
    );
  }
}

class _CouponPageContent extends StatefulWidget {
  const _CouponPageContent();

  @override
  State<_CouponPageContent> createState() => _CouponPageContentState();
}

class _CouponPageContentState extends State<_CouponPageContent> {
  final TextEditingController _couponController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

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
        if (state.status == CouponStatus.deepLinkCouponValid && state.deepLinkCoupon != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _applyCoupon(context, state.deepLinkCoupon!);
          });
        }
        
        // Show feedback for sample coupon upload
        if (state.status == CouponStatus.uploadSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sample coupons uploaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state.status == CouponStatus.uploadFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Failed to upload sample coupons'),
              backgroundColor: Colors.red,
            ),
          );
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
    // Get sample coupons from our mock data
    final sampleCoupons = getSampleCoupons();
    
    // Show deep link coupon if available
    if (state.deepLinkCoupon != null && state.deepLinkCouponInfo != null) {
      // Find the sample coupon that matches the deep link code or create a new one
      final deepLinkSampleCoupon = sampleCoupons.firstWhere(
        (coupon) => coupon.code == state.deepLinkCoupon,
        orElse: () => SampleCoupon(
          id: 'deeplink_coupon',
          code: state.deepLinkCoupon!,
          type: 'percentage',
          value: 10.0, // Default value
          title: state.deepLinkCouponInfo!.discount ?? 'Special Discount',
          description: state.deepLinkCouponInfo!.description ?? 'Special offer just for you!',
          startDate: DateTime.now(),
          endDate: state.deepLinkCouponInfo!.expiryDate != null
              ? DateTime.parse(state.deepLinkCouponInfo!.expiryDate!)
              : DateTime.now().add(const Duration(days: 30)),
          minPurchase: state.deepLinkCouponInfo!.minOrderValue != null
              ? double.tryParse(state.deepLinkCouponInfo!.minOrderValue!.replaceAll('₹', '')) ?? 0.0
              : null,
          backgroundColor: Colors.deepPurple.shade800,
        ),
      );
      
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
            CouponCard(
              coupon: deepLinkSampleCoupon,
              onApply: (code) => _applyCoupon(context, code),
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
            
            if (sampleCoupons.isNotEmpty) ...[
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
              for (final coupon in sampleCoupons) ...[
                if (coupon.code != state.deepLinkCoupon)
                  CouponCard(
                    coupon: coupon,
                    onApply: (code) => _applyCoupon(context, code),
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
          
          // Admin button to upload sample coupons to Firebase
          Container(
            margin: EdgeInsets.only(top: 16.h),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade800.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: Colors.grey.shade700,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      color: Colors.amber,
                      size: 18.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Admin Actions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Text(
                  'Upload all sample coupons to different databases',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<CouponBloc>().add(const UploadSampleCoupons());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade700,
                      foregroundColor: Colors.white,
                    ),
                    child: BlocBuilder<CouponBloc, CouponState>(
                      builder: (context, state) {
                        if (state.status == CouponStatus.uploading) {
                          return const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.amber,
                            ),
                          );
                        }
                        return const Text('Upload to Realtime DB');
                      },
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<CouponBloc>().add(const UploadSampleCouponsToFirestore());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade800,
                      foregroundColor: Colors.white,
                    ),
                    child: BlocBuilder<CouponBloc, CouponState>(
                      builder: (context, state) {
                        if (state.status == CouponStatus.uploading) {
                          return const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.amber,
                            ),
                          );
                        }
                        return const Text('Upload to Firestore');
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24.h),
          
          // Manual coupon entry
          TextField(
            controller: _couponController,
            decoration: InputDecoration(
              hintText: 'Enter coupon code',
              prefixIcon: Icon(
                Icons.confirmation_number_outlined,
                color: Colors.grey,
                size: 20.sp,
              ),
              suffixIcon: TextButton(
                onPressed: () {
                  final code = _couponController.text;
                  if (code.isNotEmpty) {
                    _applyCoupon(context, code);
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
          
          if (sampleCoupons.isEmpty)
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
            for (final coupon in sampleCoupons) ...[
              CouponCard(
                coupon: coupon,
                onApply: (code) => _applyCoupon(context, code),
              ),
              SizedBox(height: 16.h),
            ],
        ],
      ),
    );
  }
}
