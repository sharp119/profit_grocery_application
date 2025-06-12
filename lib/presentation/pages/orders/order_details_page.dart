// lib/presentation/pages/orders/order_details_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:profit_grocery_application/core/constants/app_theme.dart';
import 'package:profit_grocery_application/domain/entities/order.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:profit_grocery_application/core/constants/app_constants.dart';
import 'package:profit_grocery_application/presentation/widgets/image_loader.dart';

class OrderDetailsPage extends StatefulWidget {
  final String orderId;
  const OrderDetailsPage({Key? key, required this.orderId}) : super(key: key);

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  OrderEntity? _order;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOrder();
  }

  Future<void> _fetchOrder() async {
    setState(() { _loading = true; _error = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userTokenKey);
      if (userId == null || userId.isEmpty) {
        setState(() { _error = 'User not authenticated.'; _loading = false; });
        return;
      }
      final doc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(userId)
          .collection('user_orders')
          .doc(widget.orderId)
          .get();
      if (!doc.exists) {
        setState(() { _error = 'Order not found.'; _loading = false; });
        return;
      }
      setState(() {
        _order = OrderEntity.fromSnapshot(doc);
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = 'Failed to load order details.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Order Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.accentColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: Colors.red, fontSize: 16.sp)))
              : _order == null
                  ? Center(child: Text('Order not found.', style: TextStyle(color: Colors.red, fontSize: 16.sp)))
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(16.r),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Order status, ID, date/time
                          _buildOrderHeader(_order!),
                          SizedBox(height: 18.h),
                          // Product list
                          _buildProductList(_order!),
                          SizedBox(height: 18.h),
                          // Pricing summary
                          _buildPricingSummary(_order!),
                          SizedBox(height: 18.h),
                          // Shipping address
                          _buildShippingAddress(_order!),
                          SizedBox(height: 18.h),
                          // Payment details
                          _buildPaymentDetails(_order!),
                          SizedBox(height: 24.h),
                          // Action button
                          _buildActionButton(_order!),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildOrderHeader(OrderEntity order) {
    IconData icon;
    Color iconColor;
    switch (order.status.toLowerCase()) {
      case 'pending':
        icon = Icons.hourglass_empty;
        iconColor = Colors.orange;
        break;
      case 'confirmed':
        icon = Icons.task_alt;
        iconColor = Colors.blueAccent;
        break;
      case 'shipped':
        icon = Icons.local_shipping;
        iconColor = Colors.deepPurple;
        break;
      case 'out for delivery':
        icon = Icons.delivery_dining;
        iconColor = Colors.teal;
        break;
      case 'delivered':
        icon = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case 'cancelled':
        icon = Icons.cancel;
        iconColor = Colors.red;
        break;
      case 'failed':
        icon = Icons.warning;
        iconColor = Colors.redAccent;
        break;
      default:
        icon = Icons.help_outline;
        iconColor = Colors.grey;
        break;
    }
    return Card(
      color: AppTheme.secondaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 28.r),
                SizedBox(width: 10.w),
                Text(
                  order.status[0].toUpperCase() + order.status.substring(1),
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: iconColor),
                ),
                const Spacer(),
                Text(
                  '#${order.id ?? ''}',
                  style: TextStyle(fontSize: 13.sp, color: AppTheme.textSecondaryColor),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              'Placed: ${order.orderTimestamp.toDate().toLocal().toString().split(".")[0]}',
              style: TextStyle(fontSize: 13.sp, color: AppTheme.textSecondaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList(OrderEntity order) {
    return Card(
      color: AppTheme.secondaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Items', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 10.h),
            ...order.items.map((item) => Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6.r),
                        child: ImageLoader.network(
                          item.image,
                          fit: BoxFit.contain,
                          width: 48.w,
                          height: 48.h,
                          errorWidget: Center(
                            child: Icon(Icons.image_not_supported_outlined, color: AppTheme.textSecondaryColor, size: 18.sp),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: Colors.white)),
                            SizedBox(height: 2.h),
                            Text('Qty: ${item.quantity}', style: TextStyle(fontSize: 12.sp, color: AppTheme.textSecondaryColor)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('₹${item.buyingPrice.toStringAsFixed(2)}', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
                          if (item.mrp > item.buyingPrice)
                            Text('₹${item.mrp.toStringAsFixed(2)}', style: TextStyle(fontSize: 12.sp, color: AppTheme.textSecondaryColor, decoration: TextDecoration.lineThrough)),
                        ],
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingSummary(OrderEntity order) {
    final ps = order.pricingSummary;
    return Card(
      color: AppTheme.secondaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pricing Summary', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 10.h),
            _buildSummaryRow('Subtotal', '₹${ps.subtotal.toStringAsFixed(2)}'),
            _buildSummaryRow('Item Discounts', '-₹${ps.itemDiscountsTotal.toStringAsFixed(2)}', color: Colors.green),
            if (ps.couponCodeApplied != null && ps.couponCodeApplied!.isNotEmpty)
              _buildSummaryRow('Coupon (${ps.couponCodeApplied})', '-₹${ps.couponDiscountAmount.toStringAsFixed(2)}', color: Colors.green),
            _buildSummaryRow('Delivery Fee', ps.deliveryFee == 0 ? 'Free' : '₹${ps.deliveryFee.toStringAsFixed(2)}'),
            if (ps.packagingFee > 0)
              _buildSummaryRow('Packaging Fee', '₹${ps.packagingFee.toStringAsFixed(2)}'),
            Divider(color: AppTheme.textSecondaryColor.withOpacity(0.3)),
            _buildSummaryRow('Grand Total', '₹${ps.grandTotal.toStringAsFixed(2)}', isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color, bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13.sp, color: AppTheme.textSecondaryColor)),
          Text(value, style: TextStyle(fontSize: 13.sp, color: color ?? Colors.white, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildShippingAddress(OrderEntity order) {
    final sa = order.shippingAddress;
    return Card(
      color: AppTheme.secondaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Shipping Address', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 10.h),
            Text(sa.name, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: Colors.white)),
            SizedBox(height: 2.h),
            Text('${sa.addressLine}, ${sa.city}, ${sa.state} - ${sa.pincode}', style: TextStyle(fontSize: 13.sp, color: AppTheme.textSecondaryColor)),
            if (sa.phone != null && sa.phone!.isNotEmpty)
              Text('Phone: ${sa.phone}', style: TextStyle(fontSize: 13.sp, color: AppTheme.textSecondaryColor)),
            if (sa.landmark != null && sa.landmark!.isNotEmpty)
              Text('Landmark: ${sa.landmark}', style: TextStyle(fontSize: 13.sp, color: AppTheme.textSecondaryColor)),
            if (sa.addressType != null && sa.addressType!.isNotEmpty)
              Text('Type: ${sa.addressType}', style: TextStyle(fontSize: 13.sp, color: AppTheme.textSecondaryColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetails(OrderEntity order) {
    final pd = order.paymentDetails;
    return Card(
      color: AppTheme.secondaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment Details', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 10.h),
            _buildSummaryRow('Method', pd.method),
            _buildSummaryRow('Payment ID', pd.paymentId),
            _buildSummaryRow('Paid Amount', '₹${pd.amountPaid.toStringAsFixed(2)}'),
            _buildSummaryRow('Currency', pd.currency),
            if (pd.payerName != null && pd.payerName!.isNotEmpty)
              _buildSummaryRow('Payer', pd.payerName!),
            _buildSummaryRow('Paid At', pd.successTime.toDate().toLocal().toString().split(".")[0]),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(OrderEntity order) {
    final isFinal = order.status.toLowerCase() == 'delivered' || order.status.toLowerCase() == 'cancelled' || order.status.toLowerCase() == 'failed';
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // TODO: Implement order again/cancel logic
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isFinal ? AppTheme.accentColor : Colors.redAccent,
          padding: EdgeInsets.symmetric(vertical: 14.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        ),
        child: Text(
          isFinal ? 'Order Again' : 'Cancel Order',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
    );
  }
}