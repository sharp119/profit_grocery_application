import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_theme.dart';

/// A reusable shimmer loader widget for showing loading states
class ShimmerLoader extends StatelessWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;

  const ShimmerLoader({
    Key? key,
    required this.child,
    this.baseColor = const Color(0xFF1E1E1E),
    this.highlightColor = const Color(0xFF3A3A3A),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: child,
    );
  }

  /// Create a custom container shimmer with specified dimensions
  static Widget customContainer({
    required double height,
    required double width,
    double? borderRadius,
    EdgeInsetsGeometry? margin,
  }) {
    return ShimmerLoader(
      child: Container(
        height: height,
        width: width,
        margin: margin,
        decoration: BoxDecoration(
          color: AppTheme.secondaryColor,
          borderRadius: BorderRadius.circular(borderRadius ?? 12.r),
        ),
      ),
    );
  }

  /// Create a category shimmer grid
  static Widget categoryGrid({
    int itemCount = 6,
    int crossAxisCount = 2,
    double? height,
  }) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
        childAspectRatio: 1,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return ShimmerLoader(
          child: Container(
            height: height ?? 150.h,
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor,
              borderRadius: BorderRadius.circular(16.r),
            ),
          ),
        );
      },
    );
  }

  /// Create a product shimmer grid
  static Widget productGrid({
    int itemCount = 8,
    int crossAxisCount = 2,
    double? height,
  }) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
        childAspectRatio: 0.7,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return ShimmerLoader(
          child: Container(
            height: height ?? 200.h,
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor,
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        );
      },
    );
  }

  /// Create a banner shimmer
  static Widget banner({
    double? height,
    EdgeInsetsGeometry? margin,
  }) {
    return ShimmerLoader(
      child: Container(
        height: height ?? 180.h,
        margin: margin ?? EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: AppTheme.secondaryColor,
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),
    );
  }

  /// Create a section header shimmer
  static Widget sectionHeader({
    double width = 150,
    EdgeInsetsGeometry? padding,
  }) {
    return Padding(
      padding: padding ?? EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ShimmerLoader(
            child: Container(
              width: width.w,
              height: 20.h,
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
          ShimmerLoader(
            child: Container(
              width: 60.w,
              height: 16.h,
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Create a cart item shimmer
  static Widget cartItem({
    double? height,
    EdgeInsetsGeometry? margin,
  }) {
    return ShimmerLoader(
      child: Container(
        height: height ?? 100.h,
        margin: margin ?? EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          color: AppTheme.secondaryColor,
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }
  
  /// Create a generic shimmer container with custom child
  static Widget withChild(Widget child) {
    return ShimmerLoader(child: child);
  }
}