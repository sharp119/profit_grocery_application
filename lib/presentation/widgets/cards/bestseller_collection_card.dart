import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/category.dart';

/// A specialized card for displaying bestseller collections with grid thumbnails
/// Shows a preview of top products in a category with a "+X more" counter
class BestsellerCollectionCard extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;
  final int productCount;
  final double? height;

  const BestsellerCollectionCard({
    Key? key,
    required this.category,
    required this.onTap,
    required this.productCount,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Parse product thumbnails from category
    final thumbnails = category.productThumbnails ?? [];
    
    // We'll show up to 6 thumbnails in a grid
    final displayCount = thumbnails.length > 6 ? 6 : thumbnails.length;
    final moreCount = productCount - displayCount;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height ?? 190.h,
        decoration: BoxDecoration(
          color: AppTheme.secondaryColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppTheme.accentColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grid of product thumbnails
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(10.r),
                child: Stack(
                  children: [
                    // Product grid
                    GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8.h,
                      crossAxisSpacing: 8.w,
                      childAspectRatio: 1.0,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        // Display available thumbnails
                        for (int i = 0; i < displayCount; i++)
                          _buildThumbnail(thumbnails[i]),
                            
                        // Fill remaining slots with empty containers
                        for (int i = displayCount; i < 6; i++)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                      ],
                    ),
                    
                    // "+X more" overlay
                    if (moreCount > 0)
                      Positioned(
                        right: 4.w,
                        bottom: 4.h,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            '+$moreCount more',
                            style: TextStyle(
                              color: AppTheme.accentColor,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Category name
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16.r),
                  bottomRight: Radius.circular(16.r),
                ),
                border: Border(
                  top: BorderSide(
                    color: AppTheme.accentColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                category.name,
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
      ),
    );
  }
  
  Widget _buildThumbnail(String imagePath) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: Image.asset(
          imagePath,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}