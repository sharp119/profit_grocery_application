import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_theme.dart';
import '../../../data/models/category_group_model.dart';
import '../section_header.dart';

/// A 4x2 grid widget for displaying categories
/// 
/// This widget creates a 4x2 grid layout (4 items per row, 2 rows)
/// that accepts images, labels, and a header/title for the group.
/// 
/// The grid is wrapped in a container with a customizable background color.
class CategoryGrid4x2 extends StatelessWidget {
  final String title;
  final List<String> images;
  final List<String> labels;
  final Color backgroundColor;
  final Color itemBackgroundColor; // Add color for all items
  final Function(int) onItemTap;
  final double spacing;

  const CategoryGrid4x2({
    Key? key,
    required this.title,
    required this.images,
    required this.labels,
    required this.backgroundColor,
    required this.itemBackgroundColor,
    required this.onItemTap,
    this.spacing = 8.0,
  }) : assert(images.length == 8, 'Must provide exactly 8 images'),
       assert(labels.length == 8, 'Must provide exactly 8 labels'),
       super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header - match reference style
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        // Grid container
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: backgroundColor.withOpacity(0), // Transparent background as shown in reference
            borderRadius: BorderRadius.circular(0), // No border radius
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 4x2 Grid
              GridView.count(
                crossAxisCount: 4,
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
                shrinkWrap: true,
                childAspectRatio: 0.7, // Decreased aspect ratio to allow more vertical space
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(8, (index) => _buildGridItem(index)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds an individual grid item
  // Return the consistent category color for all items
  Color _getCategoryColor(int index) {
    return itemBackgroundColor;
  }
  
  Widget _buildGridItem(int index) {
  return GestureDetector(
  onTap: () => onItemTap(index),
  child: Column(
  mainAxisSize: MainAxisSize.min, // Use minimum space needed
  children: [
  // Image container
  Flexible(
  child: AspectRatio(
  aspectRatio: 1.0, // Square aspect ratio
  child: Container(
  decoration: BoxDecoration(
      color: _getCategoryColor(index),
      borderRadius: BorderRadius.circular(8.r),
    ),
  padding: EdgeInsets.all(10.w),
  child: Image.asset(
    images[index],
  fit: BoxFit.contain,
  errorBuilder: (context, error, stackTrace) {
  // Try alternative path or show placeholder on error
  return Image.asset(
    images[index].replaceFirst('assets/images/categories/', 'assets/categories/'),
  fit: BoxFit.contain,
  errorBuilder: (context, error, stackTrace) {
  // If both paths fail, show a placeholder
  return Container(
  color: Colors.transparent,
  child: Icon(
    Icons.image_not_supported,
      color: Colors.white,
        size: 24.sp,
        ),
        );
        },
        );
        },
        ),
      ),
    ),
  ),
  SizedBox(height: 4.h), // Reduced vertical spacing
  
  // Label - Contained in a SizedBox to constrain height
  Container(
  height: 32.h, // Fixed height for text
  alignment: Alignment.center,
  child: Text(
    labels[index],
    style: TextStyle(
      color: Colors.white,
        fontSize: 11.sp,
          fontWeight: FontWeight.w500,
          ),
            textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}