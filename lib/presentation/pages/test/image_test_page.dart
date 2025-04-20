import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_theme.dart';
import '../../widgets/image_loader.dart';

class ImageTestPage extends StatelessWidget {
  const ImageTestPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Loading Test'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.r),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Network Images'),
              _buildGridView(
                children: [
                  _buildTestItem(
                    title: 'Loading Firebase URL (Zucchini)',
                    child: ImageLoader.network(
                      'https://firebasestorage.googleapis.com/v0/b/profit-grocery.firestorage.app/o/products/fruits_vegetables/exotic_vegetables/products/fjVKtTrytyzem9yK5qVK/alt-media',
                      width: 100.w,
                      height: 100.w,
                    ),
                    description: 'Actual Firebase URL from database',
                  ),
                  _buildTestItem(
                    title: 'Test Image URL',
                    child: ImageLoader.network(
                      'https://via.placeholder.com/150',
                      width: 100.w,
                      height: 100.w,
                    ),
                    description: 'External placeholder image',
                  ),
                ],
              ),
              
              _buildSectionTitle('Asset Images'),
              _buildGridView(
                children: [
                  for (int i = 1; i <= 5; i++)
                    _buildTestItem(
                      title: 'Product $i.png',
                      child: ImageLoader.asset(
                        'assets/products/$i.png',
                        width: 100.w,
                        height: 100.w,
                      ),
                      description: 'From assets/products/',
                    ),
                ],
              ),
              
              _buildSectionTitle('Direct Image Widget Tests'),
              _buildGridView(
                children: [
                  _buildTestItem(
                    title: 'Direct Asset Image',
                    child: Image.asset(
                      'assets/products/1.png',
                      width: 100.w,
                      height: 100.w,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 100.w,
                          height: 100.w,
                          color: Colors.red.withOpacity(0.3),
                          child: Center(
                            child: Icon(
                              Icons.error,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                    description: 'Using Image.asset directly',
                  ),
                  _buildTestItem(
                    title: 'Asset without prefix',
                    child: Image.asset(
                      'products/2.png',
                      width: 100.w,
                      height: 100.w,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 100.w,
                          height: 100.w,
                          color: Colors.red.withOpacity(0.3),
                          child: Center(
                            child: Icon(
                              Icons.error,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                    description: 'Without assets/ prefix',
                  ),
                ],
              ),
              
              _buildSectionTitle('Image Paths Debug Information'),
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: AppTheme.accentColor.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configured Asset Paths:',
                      style: TextStyle(
                        color: AppTheme.accentColor,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    _buildPathItem('assets/images/'),
                    _buildPathItem('assets/images/categories/'),
                    _buildPathItem('assets/categories/'),
                    _buildPathItem('assets/subcategories/'),
                    _buildPathItem('assets/products/'),
                    _buildPathItem('assets/cimgs/'),
                  ],
                ),
              ),
              
              SizedBox(height: 100.h), // Space at bottom
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Text(
        title,
        style: TextStyle(
          color: AppTheme.accentColor,
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildGridView({required List<Widget> children}) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 0.8,
      crossAxisSpacing: 16.w,
      mainAxisSpacing: 16.h,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: children,
    );
  }

  Widget _buildTestItem({
    required String title,
    required Widget child,
    required String description,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppTheme.accentColor.withOpacity(0.3)),
      ),
      padding: EdgeInsets.all(8.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8.h),
          Center(
            child: Container(
              width: 100.w,
              height: 100.w,
              color: Colors.black,
              child: child,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 10.sp,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPathItem(String path) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Icon(
            Icons.folder,
            color: AppTheme.accentColor.withOpacity(0.7),
            size: 16.sp,
          ),
          SizedBox(width: 8.w),
          Text(
            path,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }
}
