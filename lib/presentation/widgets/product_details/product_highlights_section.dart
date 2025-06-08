// TODO Implement this library.import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:profit_grocery_application/core/constants/app_theme.dart';

class ProductHighlightsSection extends StatelessWidget {
  final Map<String, dynamic>? highlightsData;

  const ProductHighlightsSection({
    Key? key,
    this.highlightsData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (highlightsData == null || highlightsData!['highlights'] is! Map) {
      return const SizedBox.shrink();
    }
    final Map<String, dynamic> highlights = highlightsData!['highlights'] as Map<String, dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Highlights',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        SizedBox(height: 10.h),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: highlights.entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade400, size: 16.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      '${entry.key}: ${entry.value}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 20.h),
      ],
    );
  }
}