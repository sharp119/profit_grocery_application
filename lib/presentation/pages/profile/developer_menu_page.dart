import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/base_layout.dart';
import '../test/image_test_page.dart';
import '../test/product_card_test_page.dart';

/// A page with developer tools and options for debugging
class DeveloperMenuPage extends StatelessWidget {
  const DeveloperMenuPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      title: 'Developer Menu',
      showBackButton: true,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Debugging Tools'),
            _buildDevOption(
              context,
              title: 'Image Loading Test',
              icon: Icons.image,
              description: 'Test image loading from network and assets',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ImageTestPage()),
                );
              },
            ),
            _buildDevOption(
              context,
              title: 'Product Card Test',
              icon: Icons.shopping_cart,
              description: 'Test enhanced product card appearance',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProductCardTestPage()),
                );
              },
            ),
            
            _buildSectionHeader('Database Tools'),
            _buildDevOption(
              context,
              title: 'Firebase Console',
              icon: Icons.storage,
              description: 'Open Firebase Console (external)',
              onTap: () {
                // TODO: Implement deep link to Firebase Console
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Would open Firebase Console'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
            ),
            _buildDevOption(
              context,
              title: 'Local Data Viewer',
              icon: Icons.data_usage,
              description: 'View and manage local data (SharedPreferences)',
              onTap: () {
                // TODO: Implement local data viewer
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Coming soon'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
            _buildDevOption(
              context,
              title: 'Firestore Sync Tool',
              icon: Icons.cloud_upload,
              description: 'Sync test data to Firestore for development',
              onTap: () {
                Navigator.pushNamed(context, AppConstants.firestoreSyncRoute);
              },
            ),
            
            _buildSectionHeader('Network Tools'),
            _buildDevOption(
              context,
              title: 'Network Monitor',
              icon: Icons.network_check,
              description: 'Monitor network requests and responses',
              onTap: () {
                // TODO: Implement network monitor
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Coming soon'),
                    backgroundColor: Colors.purple,
                  ),
                );
              },
            ),
            
            _buildSectionHeader('Visual Tools'),
            _buildDevOption(
              context,
              title: 'Grid Overlay',
              icon: Icons.grid_on,
              description: 'Toggle layout grid for UI alignment',
              onTap: () {
                // TODO: Implement grid overlay
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Coming soon'),
                    backgroundColor: Colors.teal,
                  ),
                );
              },
            ),
            _buildDevOption(
              context,
              title: 'Theme Explorer',
              icon: Icons.color_lens,
              description: 'Explore and modify theme colors',
              onTap: () {
                // TODO: Implement theme explorer
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Coming soon'),
                    backgroundColor: Colors.indigo,
                  ),
                );
              },
            ),
            
            SizedBox(height: 40.h),
            Center(
              child: Text(
                'Build: DEV-${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12.sp,
                ),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppTheme.accentColor,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Container(
            height: 1.h,
            width: 160.w,
            color: AppTheme.accentColor.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildDevOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      color: AppTheme.secondaryColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(
          color: AppTheme.accentColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        splashColor: AppTheme.accentColor.withOpacity(0.1),
        highlightColor: AppTheme.accentColor.withOpacity(0.05),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: AppTheme.accentColor,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.accentColor,
                size: 16.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}