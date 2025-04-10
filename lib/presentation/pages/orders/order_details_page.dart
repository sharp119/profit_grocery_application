import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/order.dart';
import '../../widgets/base_layout.dart';

class OrderDetailsPage extends StatelessWidget {
  final Order order;

  const OrderDetailsPage({
    Key? key,
    required this.order,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Format date
    final dateFormatter = DateFormat('MMMM dd, yyyy');
    final timeFormatter = DateFormat('h:mm a');
    final formattedDate = dateFormatter.format(order.createdAt);
    final formattedTime = timeFormatter.format(order.createdAt);
    
    // Get status color
    Color statusColor;
    switch (order.status) {
      case 'delivered':
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = AppTheme.accentColor;
    }
    
    return BaseLayout(
      title: 'Order Details',
      showBackButton: true,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.h),
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width - 32.w,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Order ID and Status
            Container(
              padding: EdgeInsets.all(16.h),
              decoration: AppTheme.goldBorderedDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order #${order.id.substring(0, 6)}',
                              style: TextStyle(
                                color: AppTheme.textPrimaryColor,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Placed on $formattedDate at $formattedTime',
                              style: TextStyle(
                                color: AppTheme.textSecondaryColor,
                                fontSize: 12.sp,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          order.status.toUpperCase().replaceAll('_', ' '),
                          softWrap: true,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 16.h),
            
            // Delivery Address
            Container(
              padding: EdgeInsets.all(16.h),
              decoration: AppTheme.goldBorderedDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivery Address',
                    style: TextStyle(
                      color: AppTheme.accentColor,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: AppTheme.accentColor,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.deliveryInfo.name,
                              style: TextStyle(
                                color: AppTheme.textPrimaryColor,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              order.deliveryInfo.phoneNumber,
                              style: TextStyle(
                                color: AppTheme.textPrimaryColor,
                                fontSize: 12.sp,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              '${order.deliveryInfo.addressLine}, ${order.deliveryInfo.landmark != null ? order.deliveryInfo.landmark! + ', ' : ''}${order.deliveryInfo.city}, ${order.deliveryInfo.state} - ${order.deliveryInfo.pincode}',
                              style: TextStyle(
                                color: AppTheme.textSecondaryColor,
                                fontSize: 12.sp,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 16.h),
            
            // Order Items
            Container(
              decoration: AppTheme.goldBorderedDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(16.h),
                    child: Text(
                      'Order Items',
                      style: TextStyle(
                        color: AppTheme.accentColor,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: order.items.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = order.items[index];
                      return Padding(
                        padding: EdgeInsets.all(12.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 60.w,
                              height: 60.h,
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              padding: EdgeInsets.all(8.h),
                              child: Image.asset(
                                item.productImage,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.image_not_supported,
                                    color: AppTheme.accentColor.withOpacity(0.5),
                                    size: 30.sp,
                                  );
                                },
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    item.productName,
                                    style: TextStyle(
                                      color: AppTheme.textPrimaryColor,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    '₹${item.price.toInt()} × ${item.quantity}',
                                    style: TextStyle(
                                      color: AppTheme.textSecondaryColor,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Text(
                              '₹${item.total.toInt()}',
                              style: TextStyle(
                                color: AppTheme.textPrimaryColor,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 16.h),
            
            // Payment Details
            Container(
              padding: EdgeInsets.all(16.h),
              decoration: AppTheme.goldBorderedDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Details',
                    style: TextStyle(
                      color: AppTheme.accentColor,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _buildPaymentRow(
                    'Payment Method',
                    _formatPaymentMethod(order.paymentInfo.method),
                  ),
                  SizedBox(height: 8.h),
                  _buildPaymentRow(
                    'Payment Status',
                    order.paymentInfo.status.toUpperCase(),
                  ),
                  if (order.paymentInfo.transactionId != null) ...[
                    SizedBox(height: 8.h),
                    _buildPaymentRow(
                      'Transaction ID',
                      order.paymentInfo.transactionId!,
                    ),
                  ],
                  SizedBox(height: 16.h),
                  const Divider(),
                  SizedBox(height: 12.h),
                  _buildPaymentRow(
                    'Items Total',
                    '₹${order.subtotal.toInt()}',
                  ),
                  if (order.discount > 0) ...[
                    SizedBox(height: 8.h),
                    _buildPaymentRow(
                      'Discount',
                      '-₹${order.discount.toInt()}',
                      valueColor: Colors.green,
                    ),
                    if (order.couponId != null) ...[
                      SizedBox(height: 4.h),
                      Padding(
                        padding: EdgeInsets.only(left: 110.w),
                        child: Text(
                          'Coupon: ${order.couponId}',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12.sp,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                  SizedBox(height: 8.h),
                  _buildPaymentRow(
                    'Delivery Fee',
                    '₹${order.deliveryFee.toInt()}',
                  ),
                  SizedBox(height: 12.h),
                  const Divider(),
                  SizedBox(height: 12.h),
                  _buildPaymentRow(
                    'Total Amount',
                    '₹${order.total.toInt()}',
                    isBold: true,
                    valueColor: AppTheme.accentColor,
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24.h),
            
            // Actions
            if (order.status == 'delivered') ...[
              // Reorder button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Reorder functionality
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.refresh),
                      SizedBox(width: 8.w),
                      const Text('Reorder'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
            ],
            
            SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPaymentRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 110.w, // Reduced width to prevent overflow
          child: Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 14.sp,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppTheme.textPrimaryColor,
              fontSize: 14.sp,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
  
  String _formatPaymentMethod(String method) {
    switch (method) {
      case 'cash_on_delivery':
        return 'Cash on Delivery';
      case 'card':
        return 'Credit/Debit Card';
      case 'upi':
        return 'UPI';
      default:
        return method;
    }
  }
}
