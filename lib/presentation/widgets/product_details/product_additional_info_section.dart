import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:profit_grocery_application/core/constants/app_theme.dart';
import 'package:profit_grocery_application/presentation/widgets/product_details/product_info_row_widget.dart';

class ProductAdditionalInfoSection extends StatelessWidget {
  final Map<String, dynamic>? additionalInfoData;
  final String? productSku;
  final String? productType;
  final List<String> productTags;

  const ProductAdditionalInfoSection({
    Key? key,
    this.additionalInfoData,
    this.productSku,
    this.productType,
    required this.productTags,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (additionalInfoData == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Details',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        SizedBox(height: 10.h),
        ProductInfoRow(title: 'Category', value: additionalInfoData!['category'] as String?),
        ProductInfoRow(title: 'Subcategory', value: additionalInfoData!['subCategory'] as String?),
        ProductInfoRow(title: 'SKU', value: productSku),
        ProductInfoRow(title: 'Product Type', value: productType),
        if (productTags.isNotEmpty)
          ProductInfoRow(title: 'Tags', value: productTags.join(', ')),
        SizedBox(height: 20.h),
      ],
    );
  }
}