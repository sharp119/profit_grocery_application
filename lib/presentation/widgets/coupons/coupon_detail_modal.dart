import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_theme.dart';
import '../../../data/samples/sample_coupons.dart';

class CouponDetailModal extends StatelessWidget {
  final SampleCoupon coupon;
  final Function(String) onApply;

  const CouponDetailModal({
    Key? key,
    required this.coupon,
    required this.onApply,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.r),
          topRight: Radius.circular(16.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Modal handle
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          
          SizedBox(height: 16.h),
          
          // Modal content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Coupon image if available
                  if (coupon.imageAsset != null)
                    Container(
                      width: double.infinity,
                      height: 180.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16.r),
                          topRight: Radius.circular(16.r),
                        ),
                        image: DecorationImage(
                          image: AssetImage(coupon.imageAsset!),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Gradient overlay
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16.r),
                                topRight: Radius.circular(16.r),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                          
                          // Coupon code at bottom
                          Positioned(
                            bottom: 16.h,
                            left: 16.w,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                coupon.code,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
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
                        // Title
                        if (coupon.imageAsset == null) ...[
                          Row(
                            children: [
                              // Coupon code
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 6.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentColor,
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: Text(
                                  coupon.code,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              
                              SizedBox(width: 12.w),
                              
                              // Copy button
                              IconButton(
                                onPressed: () {
                                  _copyCouponCode(context, coupon.code);
                                },
                                icon: Icon(
                                  Icons.copy_outlined,
                                  color: Colors.grey,
                                  size: 20.sp,
                                ),
                                tooltip: 'Copy code',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: 16.h),
                        ],
                        
                        Text(
                          coupon.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        SizedBox(height: 8.h),
                        
                        // Description
                        Text(
                          coupon.description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14.sp,
                          ),
                        ),
                        
                        SizedBox(height: 24.h),
                        
                        // Coupon details section
                        _buildCouponDetailsSection(),
                        
                        SizedBox(height: 24.h),
                        
                        // Coupon conditions
                        if (coupon.conditions != null)
                          ..._buildConditionsSection(),
                        
                        // Free product details
                        if (coupon.freeProductName != null && coupon.freeProductImage != null)
                          ..._buildFreeProductSection(),
                        
                        SizedBox(height: 24.h),
                        
                        // Terms and validity
                        Text(
                          'Terms & Validity',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        SizedBox(height: 12.h),
                        
                        // Validity period
                        _buildInfoRow(
                          Icons.date_range_outlined,
                          'Valid from ${_formatDate(coupon.startDate)} to ${_formatDate(coupon.endDate)}',
                        ),
                        
                        SizedBox(height: 8.h),
                        
                        // Minimum purchase
                        if (coupon.minPurchase != null)
                          _buildInfoRow(
                            Icons.shopping_bag_outlined,
                            'Minimum order value: ₹${coupon.minPurchase!.toStringAsFixed(0)}',
                          ),
                        
                        SizedBox(height: 8.h),
                        
                        // Usage limit
                        if (coupon.usageLimit != null)
                          _buildInfoRow(
                            Icons.repeat,
                            'Usage limit: ${coupon.usageLimit} times per user',
                          ),
                        
                        SizedBox(height: 8.h),
                        
                        // Applicable categories
                        if (coupon.applicableCategories != null && coupon.applicableCategories!.isNotEmpty)
                          _buildInfoRow(
                            Icons.category_outlined,
                            'Applicable on: ${coupon.applicableCategories!.join(', ')}',
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Apply button
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onApply(coupon.code);
                },
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
          ),
        ],
      ),
    );
  }

  Widget _buildCouponDetailsSection() {
    // Different sections based on coupon type
    switch (coupon.type) {
      case 'percentage':
        return _buildDetailCard(
          '${coupon.value.toStringAsFixed(0)}% OFF',
          'Get ${coupon.value.toStringAsFixed(0)}% discount on your purchase',
          Icons.percent,
        );
      
      case 'fixed':
        return _buildDetailCard(
          '₹${coupon.value.toStringAsFixed(0)} OFF',
          'Get flat ₹${coupon.value.toStringAsFixed(0)} discount on your purchase',
          Icons.local_offer_outlined,
        );
      
      case 'free_delivery':
        return _buildDetailCard(
          'FREE DELIVERY',
          'No delivery charges will be applied to your order',
          Icons.delivery_dining_outlined,
        );
      
      case 'free_product':
        return _buildDetailCard(
          'FREE PRODUCT',
          'Get a free product with your purchase',
          Icons.card_giftcard_outlined,
        );
      
      case 'conditional':
        String title = 'SPECIAL OFFER';
        String subtitle = 'Special conditions apply';
        
        if (coupon.conditions != null) {
          if (coupon.conditions!.containsKey('buyQuantity') && coupon.conditions!.containsKey('getQuantity')) {
            title = 'BUY ${coupon.conditions!['buyQuantity']} GET ${coupon.conditions!['getQuantity']}';
            subtitle = 'Buy ${coupon.conditions!['buyQuantity']} items and get ${coupon.conditions!['getQuantity']} free';
          } else if (coupon.conditions!.containsKey('requiredProducts')) {
            title = 'COMBO OFFER';
            subtitle = 'Save when you buy specific products together';
          } else if (coupon.conditions!.containsKey('triggerProductId') && coupon.conditions!.containsKey('discountProductId')) {
            title = 'BUNDLE DISCOUNT';
            subtitle = 'Get discount on one product when buying another';
          }
        }
        
        return _buildDetailCard(
          title,
          subtitle,
          Icons.local_offer_outlined,
        );
      
      default:
        return _buildDetailCard(
          'SPECIAL OFFER',
          'Enjoy special discount on your purchase',
          Icons.discount_outlined,
        );
    }
  }

  List<Widget> _buildConditionsSection() {
    final List<Widget> widgets = [];
    
    widgets.add(
      Text(
        'Coupon Conditions',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    
    widgets.add(SizedBox(height: 12.h));
    
    // Buy X Get Y
    if (coupon.conditions!.containsKey('buyQuantity') && coupon.conditions!.containsKey('getQuantity')) {
      final buyQuantity = coupon.conditions!['buyQuantity'];
      final getQuantity = coupon.conditions!['getQuantity'];
      final sameProduct = coupon.conditions!['sameProduct'] ?? false;
      final sameCategory = coupon.conditions!['sameCategory'] ?? false;
      final categoryId = coupon.conditions!['categoryId'];
      
      String conditionText = 'Buy $buyQuantity items';
      
      if (sameProduct) {
        conditionText += ' of the same product';
      } else if (sameCategory && categoryId != null) {
        conditionText += ' from $categoryId category';
      }
      
      conditionText += ' and get $getQuantity';
      
      if (getQuantity == 1) {
        conditionText += ' free';
      } else {
        conditionText += ' items free';
      }
      
      widgets.add(_buildInfoRow(Icons.shopping_basket_outlined, conditionText));
      
      if (sameCategory && categoryId != null) {
        widgets.add(SizedBox(height: 8.h));
        widgets.add(_buildInfoRow(Icons.category_outlined, 'Applicable on: $categoryId category'));
      }
    }
    
    // Required products combo
    else if (coupon.conditions!.containsKey('requiredProducts')) {
      final requiredProducts = coupon.conditions!['requiredProducts'] as List<dynamic>;
      final requiredQuantities = coupon.conditions!['requiredQuantities'] as List<dynamic>? ?? [];
      
      for (int i = 0; i < requiredProducts.length; i++) {
        final productId = requiredProducts[i];
        final quantity = i < requiredQuantities.length ? requiredQuantities[i] : 1;
        
        widgets.add(_buildInfoRow(
          Icons.check_circle_outline,
          'Add $quantity ${_getReadableProductId(productId)} to cart',
        ));
        
        widgets.add(SizedBox(height: 8.h));
      }
      
      widgets.add(_buildInfoRow(
        Icons.local_offer_outlined,
        'Get ₹${coupon.value.toStringAsFixed(0)} discount when all products are in cart',
      ));
    }
    
    // Trigger and discount products
    else if (coupon.conditions!.containsKey('triggerProductId') && coupon.conditions!.containsKey('discountProductId')) {
      final triggerProductId = coupon.conditions!['triggerProductId'];
      final discountProductId = coupon.conditions!['discountProductId'];
      final triggerQuantity = coupon.conditions!['triggerQuantity'] ?? 1;
      
      widgets.add(_buildInfoRow(
        Icons.shopping_basket_outlined,
        'Add $triggerQuantity ${_getReadableProductId(triggerProductId)} to cart',
      ));
      
      widgets.add(SizedBox(height: 8.h));
      
      widgets.add(_buildInfoRow(
        Icons.local_offer_outlined,
        'Get ₹${coupon.value.toStringAsFixed(0)} off on ${_getReadableProductId(discountProductId)}',
      ));
    }
    
    widgets.add(SizedBox(height: 24.h));
    
    return widgets;
  }

  List<Widget> _buildFreeProductSection() {
    return [
      Text(
        'Free Product',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
      
      SizedBox(height: 16.h),
      
      Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppTheme.secondaryColor,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            // Product image
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                image: DecorationImage(
                  image: AssetImage(coupon.freeProductImage!),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            
            SizedBox(width: 16.w),
            
            // Product details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coupon.freeProductName!,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  SizedBox(height: 4.h),
                  
                  Text(
                    'FREE with your purchase',
                    style: TextStyle(
                      color: AppTheme.accentColor,
                      fontSize: 14.sp,
                    ),
                  ),
                  
                  SizedBox(height: 8.h),
                  
                  Text(
                    'Added automatically when coupon conditions are met',
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
    ];
  }

  Widget _buildDetailCard(String title, String subtitle, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: coupon.backgroundColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24.sp,
            ),
          ),
          
          SizedBox(width: 16.w),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                SizedBox(height: 4.h),
                
                Text(
                  subtitle,
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
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Colors.grey,
          size: 18.sp,
        ),
        
        SizedBox(width: 8.w),
        
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14.sp,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getReadableProductId(String id) {
    // Convert product IDs to readable format
    // e.g., prod_rice_01 -> Rice, prod_bread_category -> Bread
    final parts = id.split('_');
    
    if (parts.length > 1) {
      String name = parts[1];
      // Capitalize first letter
      name = name[0].toUpperCase() + name.substring(1);
      return name;
    }
    
    return id;
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
