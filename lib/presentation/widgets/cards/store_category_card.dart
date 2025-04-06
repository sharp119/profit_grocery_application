import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/category.dart';

/// A specialized card for displaying store categories with pastel backgrounds
/// Used primarily in the "Shop by store" section
class StoreCategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;
  final bool showLabel;
  final double? height;

  const StoreCategoryCard({
    Key? key,
    required this.category,
    required this.onTap,
    this.showLabel = true,
    this.height,
  }) : super(key: key);

  // Get pastel background color based on category name
  Color _getPastelColor() {
    // Return different pastel colors based on name to ensure consistency
    final colorSeed = category.name.hashCode;
    
    switch (colorSeed % 6) {
      case 0:
        return const Color(0xFFFFC3A0); // Soft peach
      case 1:
        return const Color(0xFFFFD8A8); // Pastel yellow
      case 2:
        return const Color(0xFFD0F0C0); // Tea green
      case 3:
        return const Color(0xFFC4E0F9); // Light blue
      case 4:
        return const Color(0xFFF4D2F4); // Soft lavender
      case 5:
        return const Color(0xFFE6D2AA); // Sand
      default:
        return const Color(0xFFE0F4FF); // Light sky blue
    }
  }

  @override
  Widget build(BuildContext context) {
    final pastelColor = _getPastelColor();
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height ?? 150.h,
        decoration: BoxDecoration(
          color: pastelColor,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Store image
            CircleAvatar(
              radius: 40.r,
              backgroundColor: Colors.white.withOpacity(0.7),
              child: Padding(
                padding: EdgeInsets.all(10.w),
                child: Image.asset(
                  category.image,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            
            if (showLabel) SizedBox(height: 12.h),
            
            // Store name
            if (showLabel)
              Text(
                '${category.name} Store',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}