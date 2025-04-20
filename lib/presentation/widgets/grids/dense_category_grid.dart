import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'dart:math' as math;

import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/category.dart';
import '../cards/category_card.dart';
import '../cards/store_category_card.dart';
import '../cards/promotional_category_card.dart';
import '../cards/bestseller_collection_card.dart';

/// A dense grid view for categories that creates a rich, full-screen appearance
/// Supports different card types and layouts for an information-dense UI
class DenseCategoryGrid extends StatelessWidget {
  final List<Category> categories;
  final Function(Category) onCategoryTap;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final int crossAxisCount;
  final double spacing;
  final bool showLabels;

  const DenseCategoryGrid({
    Key? key,
    required this.categories,
    required this.onCategoryTap,
    this.padding,
    this.physics,
    this.crossAxisCount = 2,
    this.spacing = 8.0,
    this.showLabels = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Wrap in a container with constraints to prevent overflow
    return LayoutBuilder(
      builder: (context, constraints) {
        return MasonryGridView.count(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          shrinkWrap: true,
          physics: physics ?? const NeverScrollableScrollPhysics(),
          padding: padding ?? EdgeInsets.all(spacing),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            
            // Calculate adaptive heights based on available width
            final maxItemWidth = (constraints.maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;
            
            // Determine grid layout based on category type
            switch (category.type) {
              case 'store':
                return StoreCategoryCard(
                  category: category,
                  onTap: () => onCategoryTap(category),
                  showLabel: showLabels,
                );
                
              case 'promotional':
                return SizedBox(
                  width: maxItemWidth,
                  child: PromotionalCategoryCard(
                    category: category,
                    onTap: () => onCategoryTap(category),
                  ),
                );
                
              case 'bestseller':
                return SizedBox(
                  width: maxItemWidth,
                  child: BestsellerCollectionCard(
                    category: category,
                    onTap: () => onCategoryTap(category),
                    productCount: category.productCount ?? 0,
                  ),
                );
                
              default:
                // Use adaptive heights with constraints
                final height = (index % 5 == 0 || index % 5 == 3) 
                    ? math.min(160.h, maxItemWidth * 1.2) 
                    : math.min(130.h, maxItemWidth);
                
                return SizedBox(
                  width: maxItemWidth,
                  child: CategoryCard.fromEntity(
                    category: category,
                    onTap: () => onCategoryTap(category),
                    height: height,
                  ),
                );
            }
          },
        );
      },
    );
  }
  
  /// Create a section of dense grid categories with header
  static Widget withHeader({
    required String title,
    required List<Category> categories,
    required Function(Category) onCategoryTap,
    VoidCallback? onViewAllTap,
    EdgeInsetsGeometry? padding,
    ScrollPhysics? physics,
    int crossAxisCount = 2,
    double spacing = 8.0,
    bool showLabels = true,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onViewAllTap != null)
                    GestureDetector(
                      onTap: onViewAllTap,
                      child: Text(
                        'View All',
                        style: TextStyle(
                          color: AppTheme.accentColor,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Category grid
            DenseCategoryGrid(
              categories: categories,
              onCategoryTap: onCategoryTap,
              padding: padding,
              physics: physics,
              crossAxisCount: crossAxisCount,
              spacing: spacing,
              showLabels: showLabels,
            ),
          ],
        );
      },
    );
  }
}