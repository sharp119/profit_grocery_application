import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_theme.dart';

/// A reusable section header widget with optional "View All" button
class SectionHeader extends StatelessWidget {
  final String title;
  final String? viewAllText;
  final VoidCallback? onViewAllTap;
  final TextStyle? titleStyle;
  final TextStyle? viewAllStyle;
  final EdgeInsetsGeometry? padding;

  const SectionHeader({
    Key? key,
    required this.title,
    this.viewAllText,
    this.onViewAllTap,
    this.titleStyle,
    this.viewAllStyle,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: titleStyle ?? 
                TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (viewAllText != null && onViewAllTap != null)
            GestureDetector(
              onTap: onViewAllTap,
              child: Row(
                children: [
                  Text(
                    viewAllText!,
                    style: viewAllStyle ?? 
                        TextStyle(
                          color: AppTheme.accentColor,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12.sp,
                    color: AppTheme.accentColor,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}