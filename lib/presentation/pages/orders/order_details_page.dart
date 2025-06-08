// lib/presentation/pages/orders/order_details_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:profit_grocery_application/core/constants/app_theme.dart';

class OrderDetailsPage extends StatelessWidget {
  final String orderId; // We'll pass the order ID

  const OrderDetailsPage({Key? key, required this.orderId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Order Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.accentColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 80.r, color: AppTheme.accentColor),
            SizedBox(height: 20.h),
            Text(
              'Order ID:',
              style: TextStyle(fontSize: 20.sp, color: AppTheme.textPrimaryColor),
            ),
            Text(
              orderId,
              style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: AppTheme.accentColor),
            ),
            SizedBox(height: 20.h),
            Text(
              'Full order details will be displayed here.',
              style: TextStyle(fontSize: 16.sp, color: AppTheme.textSecondaryColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}