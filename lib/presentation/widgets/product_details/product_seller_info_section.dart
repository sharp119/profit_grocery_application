import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:profit_grocery_application/core/constants/app_theme.dart';
import 'package:profit_grocery_application/presentation/widgets/product_details/product_info_row_widget.dart';

class ProductSellerInfoSection extends StatelessWidget {
  final Map<String, dynamic>? sellerInfoData;
  final String? sellerName;

  const ProductSellerInfoSection({
    Key? key,
    this.sellerInfoData,
    this.sellerName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (sellerInfoData == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 1.w, vertical: 12.h),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Seller Information',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              SizedBox(height: 10.h),
              ProductInfoRow(title: 'Seller Name', value: sellerName),
              ProductInfoRow(title: 'Source of Origin', value: sellerInfoData!['sourceOfOrigin'] as String?),
              ProductInfoRow(title: 'FSSAI', value: sellerInfoData!['fssai'] as String?),
              ProductInfoRow(title: 'Address', value: sellerInfoData!['address'] as String?),
              ProductInfoRow(title: 'Customer Care', value: sellerInfoData!['customerCare'] as String?),
              ProductInfoRow(title: 'Email', value: sellerInfoData!['email'] as String?),
              ProductInfoRow(title: 'Certifications', value: sellerInfoData!['certifications'] as String?),
            ],
          ),
        ),
      ),
    );
  }
}
