import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  int _selectedPaymentMethod = 0;
  bool _isPlacingOrder = false;
  
  // Placeholder user information (would come from user repository in a real app)
  final Map<String, dynamic> _userInfo = {
    'name': 'Ajay Kumar',
    'phone': '9876543210',
    'address': '123, Green Avenue, Sector 14, Delhi',
    'pincode': '110001',
  };
  
  // Placeholder cart summary (would come from cart repository in a real app)
  final Map<String, dynamic> _cartSummary = {
    'subtotal': 798.0,
    'discount': 79.8, // 10% discount
    'deliveryFee': 40.0,
    'total': 758.2,
    'itemCount': 4,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Delivery address
                _buildSectionHeading('Delivery Address'),
                
                SizedBox(height: 8.h),
                
                _buildAddressCard(),
                
                SizedBox(height: 24.h),
                
                // Payment method
                _buildSectionHeading('Payment Method'),
                
                SizedBox(height: 8.h),
                
                _buildPaymentMethodCard(),
                
                SizedBox(height: 24.h),
                
                // Order summary
                _buildSectionHeading('Order Summary'),
                
                SizedBox(height: 8.h),
                
                _buildOrderSummaryCard(),
                
                // Extra space at bottom for the fixed button
                SizedBox(height: 80.h),
              ],
            ),
          ),
          
          // Place order button (fixed at bottom)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: _isPlacingOrder
                      ? null
                      : () async {
                          setState(() {
                            _isPlacingOrder = true;
                          });
                          
                          // Simulate order placement
                          await Future.delayed(const Duration(seconds: 2));
                          
                          setState(() {
                            _isPlacingOrder = false;
                          });
                          
                          if (mounted) {
                            // Show success dialog
                            _showOrderSuccessDialog();
                          }
                        },
                  child: _isPlacingOrder
                      ? const CircularProgressIndicator()
                      : Text(
                          'Place Order • ${AppConstants.currencySymbol}${_cartSummary['total'].toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize:
                            16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeading(String title) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        if (title == 'Delivery Address' || title == 'Payment Method')
          TextButton(
            onPressed: () {
              // Navigate to edit screen
            },
            child: Text(
              'Change',
              style: TextStyle(
                color: AppTheme.accentColor,
                fontSize: 14.sp,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddressCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: AppTheme.accentColor,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Delivery Location',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8.w,
                  vertical: 2.h,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  'Home',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12.h),
          
          Text(
            _userInfo['name'],
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          SizedBox(height: 4.h),
          
          Text(
            _userInfo['address'],
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14.sp,
            ),
          ),
          
          SizedBox(height: 4.h),
          
          Text(
            'PIN: ${_userInfo['pincode']}',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14.sp,
            ),
          ),
          
          SizedBox(height: 4.h),
          
          Row(
            children: [
              Icon(
                Icons.phone,
                color: Colors.grey,
                size: 16.sp,
              ),
              SizedBox(width: 4.w),
              Text(
                '+91 ${_userInfo['phone']}',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    List<Map<String, dynamic>> paymentMethods = [
      {
        'id': 0,
        'name': 'Cash on Delivery',
        'icon': Icons.money,
      },
      {
        'id': 1,
        'name': 'Credit/Debit Card',
        'icon': Icons.credit_card,
      },
      {
        'id': 2,
        'name': 'UPI',
        'icon': Icons.account_balance,
      },
    ];

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: paymentMethods.map((method) {
          return RadioListTile<int>(
            value: method['id'],
            groupValue: _selectedPaymentMethod,
            onChanged: (value) {
              setState(() {
                _selectedPaymentMethod = value!;
              });
            },
            title: Row(
              children: [
                Icon(
                  method['icon'],
                  color: _selectedPaymentMethod == method['id']
                      ? AppTheme.accentColor
                      : Colors.grey,
                  size: 24.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  method['name'],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: _selectedPaymentMethod == method['id']
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
            activeColor: AppTheme.accentColor,
            contentPadding: EdgeInsets.zero,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_cartSummary['itemCount']} Items',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate back to cart
                  Navigator.pop(context);
                },
                child: Text(
                  'View Details',
                  style: TextStyle(
                    color: AppTheme.accentColor,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16.h),
          
          _buildSummaryRow('Subtotal', '${AppConstants.currencySymbol}${_cartSummary['subtotal'].toStringAsFixed(2)}'),
          
          SizedBox(height: 8.h),
          
          _buildSummaryRow(
            'Discount',
            '- ${AppConstants.currencySymbol}${_cartSummary['discount'].toStringAsFixed(2)}',
            isDiscount: true,
          ),
          
          SizedBox(height: 8.h),
          
          _buildSummaryRow('Delivery Fee', '${AppConstants.currencySymbol}${_cartSummary['deliveryFee'].toStringAsFixed(2)}'),
          
          SizedBox(height: 16.h),
          
          const Divider(color: Colors.grey),
          
          SizedBox(height: 16.h),
          
          _buildSummaryRow(
            'Total',
            '${AppConstants.currencySymbol}${_cartSummary['total'].toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isDiscount = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDiscount
                ? Colors.green
                : isTotal
                    ? Colors.white
                    : Colors.grey,
            fontSize: isTotal ? 18.sp : 14.sp,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isDiscount
                ? Colors.green
                : isTotal
                    ? AppTheme.accentColor
                    : Colors.white,
            fontSize: isTotal ? 18.sp : 14.sp,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  void _showOrderSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.secondaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64.sp,
              ),
              
              SizedBox(height: 16.h),
              
              Text(
                'Order Placed Successfully!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 8.h),
              
              Text(
                'Your order has been placed successfully. You can track your order in the Orders section.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14.sp,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 24.h),
              
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Close all screens and go to home
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: const Text('Continue Shopping'),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 8.h),
              
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        // Navigate to orders page
                        Navigator.popUntil(context, (route) => route.isFirst);
                        // TODO: Add navigation to orders page
                      },
                      child: Text(
                        'Track Order',
                        style: TextStyle(
                          color: AppTheme.accentColor,
                          fontSize: 16.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}