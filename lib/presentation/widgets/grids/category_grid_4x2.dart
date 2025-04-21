import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/firestore/category_group_firestore_model.dart';
import '../../../services/logging_service.dart';

import '../../../core/constants/app_theme.dart';
import '../section_header.dart';

/// A 4x2 grid widget for displaying categories
/// 
/// This widget creates a 4x2 grid layout (4 items per row, 2 rows)
/// that accepts images, labels, and a header/title for the group.
/// 
/// The grid is wrapped in a container with a customizable background color.
class CategoryGrid4x2 extends StatelessWidget {
  final CategoryGroupFirestore categoryGroup;
  final Function(CategoryItemFirestore) onItemTap;
  final double spacing;

  const CategoryGrid4x2({
    Key? key,
    required this.categoryGroup,
    required this.onItemTap,
    this.spacing = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Log when a category grid is being built
    LoggingService.logFirestore('CAT_GRID_4X2: Building grid for category group: ${categoryGroup.title} (${categoryGroup.id})');
    print('CAT_GRID_4X2: Building grid for category group: ${categoryGroup.title} (${categoryGroup.id})');
    
    // Log number of items in this category group
    LoggingService.logFirestore('CAT_GRID_4X2: Category group contains ${categoryGroup.items.length} items');
    print('CAT_GRID_4X2: Category group contains ${categoryGroup.items.length} items');
    
    // Log background colors
    LoggingService.logFirestore('CAT_GRID_4X2: Group background color: ${categoryGroup.backgroundColor}, Item background color: ${categoryGroup.itemBackgroundColor}');
    print('CAT_GRID_4X2: Group background color: ${categoryGroup.backgroundColor}, Item background color: ${categoryGroup.itemBackgroundColor}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Text(
            categoryGroup.title,
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
            color: categoryGroup.backgroundColor.withOpacity(0),
            borderRadius: BorderRadius.circular(0),
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
                childAspectRatio: 0.7,
                physics: const NeverScrollableScrollPhysics(),
                children: categoryGroup.items.map((item) => _buildGridItem(item)).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGridItem(CategoryItemFirestore item) {
    // Log when a grid item is being built
    LoggingService.logFirestore('CAT_GRID_4X2: Building grid item for: ${item.label} (${item.id})');
    print('CAT_GRID_4X2: Building grid item for: ${item.label} (${item.id})');
    
    // Log image path
    LoggingService.logFirestore('CAT_GRID_4X2: Item image path: ${item.imagePath}');
    print('CAT_GRID_4X2: Item image path: ${item.imagePath}');

    return GestureDetector(
      onTap: () {
        // Log when a grid item is tapped
        LoggingService.logFirestore('CAT_GRID_4X2: Grid item tapped: ${item.label} (${item.id})');
        print('CAT_GRID_4X2: Grid item tapped: ${item.label} (${item.id})');
        onItemTap(item);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image container
          Flexible(
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: categoryGroup.itemBackgroundColor,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                padding: EdgeInsets.all(10.w),
                child: CachedNetworkImage(
                  imageUrl: item.imagePath,
                  fit: BoxFit.contain,
                  placeholder: (context, url) {
                    // Log when an image is loading
                    LoggingService.logFirestore('CAT_GRID_4X2: Loading image for: ${item.label}');
                    print('CAT_GRID_4X2: Loading image for: ${item.label}');
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                  errorWidget: (context, url, error) {
                    // Log when an image fails to load
                    LoggingService.logFirestore('CAT_GRID_4X2: Error loading image for: ${item.label} - $error');
                    print('CAT_GRID_4X2: Error loading image for: ${item.label} - $error');
                    return Icon(
                      Icons.image_not_supported,
                      color: Colors.white,
                      size: 24.sp,
                    );
                  },
                ),
              ),
            ),
          ),
          SizedBox(height: 4.h),
          
          // Label
          Container(
            height: 32.h,
            alignment: Alignment.center,
            child: Text(
              item.label,
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