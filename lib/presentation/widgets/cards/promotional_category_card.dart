import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
      child: Container(
        height: height ?? 180.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
        ),
        child: Stack(
          children: [
            // Background image with overlay
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: Image.asset(
                  category.image,
                  fit: BoxFit.cover,
                  colorBlendMode: BlendMode.multiply,
                  color: Colors.black.withOpacity(0.3),
                ),
              ),
            ),
            
            // Content overlay
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tag (Featured, New Launch, etc.)
                  if (category.tag != null)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        category.tag!,
                        style: TextStyle(
                          color: gradientColors[0],
                          fontSize: 12.sp,
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
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 4,
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 8.h),
                  
                  // Shop now button
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
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
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.black,
                              size: 12.sp,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}