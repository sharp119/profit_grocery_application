// TODO Implement this library.import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:profit_grocery_application/core/constants/app_theme.dart';

class ProductDescriptionSection extends StatelessWidget {
  final String productDescription;

  const ProductDescriptionSection({
    Key? key,
    required this.productDescription,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (productDescription.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About this item',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          productDescription,
          style: TextStyle(
            fontSize: 14.sp,
            color: AppTheme.textSecondaryColor,
            height: 1.5,
          ),
        ),
        SizedBox(height: 20.h),
      ],
    );
  }
}