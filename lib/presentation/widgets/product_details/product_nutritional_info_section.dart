import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:profit_grocery_application/core/constants/app_theme.dart';

class ProductNutritionalInfoSection extends StatelessWidget {
  final String? nutritionalInfo;

  const ProductNutritionalInfoSection({
    Key? key,
    this.nutritionalInfo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (nutritionalInfo == null || nutritionalInfo!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nutritional Information',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          nutritionalInfo!,
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