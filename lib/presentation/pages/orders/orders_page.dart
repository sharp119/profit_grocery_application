import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_theme.dart';
import '../../widgets/base_layout.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      title: 'My Orders',
      showBackButton: true,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 80.sp,
              color: AppTheme.accentColor,
            ),
            SizedBox(height: 16.h),
            Text(
              'Order History',
              style: TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Text(
                'Your order history will appear here once you place orders',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 14.sp,
                ),
              ),
            ),
            SizedBox(height: 32.h),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/home');
              },
              child: const Text('Start Shopping'),
            ),
          ],
        ),
      ),
    );
  }
}
