import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math' as math;

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/category.dart';

/// A reusable widget for displaying category cards
/// 
/// Supports different card styles based on category type:
/// - Regular: Standard category card with image and name
/// - Store: Store category card with circle image and name
/// - Promotional: Banner-style card with background image, tag, and CTA
class CategoryCard extends StatelessWidget {
  final String name;
  final String image;
  final String type;
  final String? tag;
  final VoidCallback onTap;
  final double? height;  // Optional custom height

  const CategoryCard({
    Key? key,
    required this.name,
    required this.image,
    required this.type,
    this.tag,
    required this.onTap,
    this.height,
  }) : super(key: key);

  /// Create a CategoryCard from a Category entity
  factory CategoryCard.fromEntity({
    required Category category,
    required VoidCallback onTap,
    double? height,
  }) {
    return CategoryCard(
      name: category.name,
      image: category.image,
      type: category.type,
      tag: category.tag,
      onTap: onTap,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use different card designs based on category type
    switch (type) {
      case AppConstants.promotionalCategoryType:
        return _buildPromotionalCard();
      case AppConstants.storeCategoryType:
        return _buildStoreCard();
      default:
        return _buildRegularCard();
    }
  }

  /// Regular category card with image and name
  Widget _buildRegularCard() {
    return GestureDetector(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Apply a safe height based on constraints
          final safeHeight = height != null ? 
              height! : constraints.maxWidth * 1.2;
          
          return Container(
            height: math.min(safeHeight, 180.0),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              children: [
                // Category image
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.r),
                      topRight: Radius.circular(16.r),
                    ),
                    child: Container(
                      color: Colors.white.withOpacity(0.1),
                      width: double.infinity,
                      child: Padding(
                        padding: EdgeInsets.all(8.w),
                        child: Image.asset(
                          image,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Category name
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16.r),
                      bottomRight: Radius.circular(16.r),
                    ),
                  ),
                  child: Text(
                    name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  /// Store category card with circular icon
  Widget _buildStoreCard() {
    return GestureDetector(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final safeHeight = height != null ? 
              height! : math.min(140.h, constraints.maxWidth * 1.1);
          
          return Container(
            height: safeHeight,
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: AppTheme.accentColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Store image
                CircleAvatar(
                  radius: math.min(40.r, constraints.maxWidth / 4),
                  backgroundColor: Colors.white.withOpacity(0.1),
                  child: Padding(
                    padding: EdgeInsets.all(8.w),
                    child: Image.asset(
                      image,
                      height: math.min(50.h, constraints.maxWidth / 3),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                
                SizedBox(height: 8.h),
                
                // Store name
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Text(
                    name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  /// Promotional banner-style card
  Widget _buildPromotionalCard() {
    return GestureDetector(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final safeHeight = height != null ? 
              height! : math.min(180.h, constraints.maxWidth * 1.3);
          
          return Container(
            height: safeHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF8A2387),
                  Color(0xFFE94057),
                  Color(0xFFF27121),
                ],
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: Stack(
                children: [
                  // Background image
                  Positioned.fill(
                    child: Image.asset(
                      image,
                      fit: BoxFit.cover,
                      opacity: const AlwaysStoppedAnimation(0.7),
                    ),
                  ),
                  
                  // Content
                  Padding(
                    padding: EdgeInsets.all(8.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tag label
                        if (tag != null)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 3.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              tag!,
                              style: TextStyle(
                                color: AppTheme.accentColor,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        
                        const Spacer(),
                        
                        // Category name
                        Text(
                          name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: const Offset(1, 1),
                                blurRadius: 3,
                                color: Colors.black.withOpacity(0.7),
                              ),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        
                        SizedBox(height: 4.h),
                        
                        // Shop now button
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'SHOP NOW',
                              style: TextStyle(
                                color: AppTheme.accentColor,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Icon(
                              Icons.arrow_forward,
                              color: AppTheme.accentColor,
                              size: 14.sp,
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
      ),
    );
  }
}