import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math' as math;

import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/category.dart';

/// A specialized card for promotional banners
/// Used for featured items, new launches, and special collections
class PromotionalCategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;
  final double? height;

  const PromotionalCategoryCard({
    Key? key,
    required this.category,
    required this.onTap,
    this.height,
  }) : super(key: key);

  // Get background gradient based on category tag
  List<Color> _getGradientColors() {
    final tag = category.tag?.toLowerCase() ?? '';
    
    if (tag.contains('new')) {
      return [
        const Color(0xFF5E35B1),
        const Color(0xFF1976D2),
      ];
    } else if (tag.contains('festive')) {
      return [
        const Color(0xFFC62828),
        const Color(0xFFAD1457),
      ];
    } else {
      // Default gradient for Featured
      return [
        const Color(0xFF1E88E5),
        const Color(0xFF0D47A1),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = _getGradientColors();
    
    return GestureDetector(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate safe height based on available width
          final calculatedHeight = constraints.maxWidth * 1.2;
          final safeHeight = height != null ? 
              math.min(height!, calculatedHeight) : 
              math.min(180.h, calculatedHeight);
              
          return Container(
            height: safeHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Stack(
              children: [
                // Background image with overlay
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Gradient background
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16.r),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: gradientColors,
                            ),
                          ),
                        ),
                        // Product image (sized appropriately)
                        Padding(
                          padding: EdgeInsets.all(8.r),
                          child: Image.asset(
                            category.image,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                        // Dark overlay for better text readability
                        Container(
                          color: Colors.black.withOpacity(0.2),
                        )
                      ],
                    ),
                  ),
                ),
                
                // Content overlay
                Padding(
                  padding: EdgeInsets.all(8.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tag (Featured, New Launch, etc.)
                      if (category.tag != null)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            category.tag!,
                            style: TextStyle(
                              color: gradientColors[0],
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      
                      const Spacer(),
                      
                      // Category name
                      Text(
                        category.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 4,
                              offset: const Offset(1, 1),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      SizedBox(height: 4.h),
                      
                      // Shop now button
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'SHOP NOW',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.black,
                              size: 10.sp,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }
}