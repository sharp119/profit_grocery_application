import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../blocs/checkout/checkout_bloc.dart';
import '../../blocs/checkout/checkout_event.dart';
import '../../blocs/checkout/checkout_state.dart';
import '../../widgets/base_layout.dart';
import '../../widgets/loaders/shimmer_loader.dart';
import '../coupon/coupon_page.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CheckoutBloc()..add(const LoadCheckout()),
      child: const _CheckoutPageContent(),
    );
  }
}

class _CheckoutPageContent extends StatelessWidget {
  const _CheckoutPageContent();

  void _selectAddress(BuildContext context, String addressId) {
    context.read<CheckoutBloc>().add(SelectAddress(addressId));
  }

  void _selectPaymentMethod(BuildContext context, int paymentMethodId) {
    context.read<CheckoutBloc>().add(SelectPaymentMethod(paymentMethodId));
  }

  void _applyCoupon(BuildContext context, String code) {
    context.read<CheckoutBloc>().add(ApplyCoupon(code));
  }

  void _removeCoupon(BuildContext context) {
    context.read<CheckoutBloc>().add(const RemoveCoupon());
  }

  void _navigateToCoupons(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CouponPage()),
    ).then((couponCode) {
      if (couponCode != null && couponCode is String && couponCode.isNotEmpty) {
        _applyCoupon(context, couponCode);
      }
    });
  }

  void _placeOrder(BuildContext context) {
    context.read<CheckoutBloc>().add(const PlaceOrder());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CheckoutBloc, CheckoutState>(
      listener: (context, state) {
        if (state.status == CheckoutStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'An error occurred'),
              backgroundColor: Colors.red,
            ),
          );
        }
        
        if (state.status == CheckoutStatus.orderSuccess) {
          _showOrderSuccessDialog(context, state.orderId ?? 'Unknown');
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            title: const Text('Checkout'),
            elevation: 0,
          ),
          body: state.status == CheckoutStatus.loading
              ? _buildLoadingState()
              : _buildCheckoutContent(context, state),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Delivery address shimmer
          ShimmerLoader.customContainer(
            height: 150.h,
            width: double.infinity,
            borderRadius: 12.r,
          ),
          
          SizedBox(height: 24.h),
          
          // Payment method shimmer
          ShimmerLoader.customContainer(
            height: 180.h,
            width: double.infinity,
            borderRadius: 12.r,
          ),
          
          SizedBox(height: 24.h),
          
          // Coupon shimmer
          ShimmerLoader.customContainer(
            height: 80.h,
            width: double.infinity,
            borderRadius: 12.r,
          ),
          
          SizedBox(height: 24.h),
          
          // Order summary shimmer
          ShimmerLoader.customContainer(
            height: 180.h,
            width: double.infinity,
            borderRadius: 12.r,
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutContent(BuildContext context, CheckoutState state) {
    return Stack(
      children: [
        // Main content
        SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Delivery address
              _buildSectionHeading(
                'Delivery Address',
                onActionTap: () {
                  // Navigate to address selection screen
                },
              ),
              
              SizedBox(height: 12.h),
              
              _buildAddressCard(context, state),
              
              SizedBox(height: 24.h),
              
              // Payment method
              _buildSectionHeading(
                'Payment Method',
                actionText: 'Add New',
                onActionTap: () {
                  // Navigate to add payment method screen
                },
              ),
              
              SizedBox(height: 12.h),
              
              _buildPaymentMethodCard(context, state),
              
              SizedBox(height: 24.h),
              
              // Coupon section
              _buildSectionHeading(
                'Apply Coupon',
                actionText: 'View All',
                onActionTap: () => _navigateToCoupons(context),
              ),
              
              SizedBox(height: 12.h),
              
              _buildCouponCard(context, state),
              
              SizedBox(height: 24.h),
              
              // Order summary
              _buildSectionHeading('Order Summary'),
              
              SizedBox(height: 12.h),
              
              _buildOrderSummaryCard(context, state),
              
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
              border: Border(
                top: BorderSide(
                  color: AppTheme.accentColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                onPressed: state.status == CheckoutStatus.placingOrder
                    ? null
                    : () => _placeOrder(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: state.status == CheckoutStatus.placingOrder
                    ? const CircularProgressIndicator(
                        color: Colors.black,
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'PLACE ORDER',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            '•',
                            style: TextStyle(
                              fontSize: 16.sp,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            '${AppConstants.currencySymbol}${state.total.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeading(
    String title, {
    String actionText = 'Change',
    VoidCallback? onActionTap,
  }) {
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
        if (onActionTap != null)
          TextButton(
            onPressed: onActionTap,
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: 8.w,
                vertical: 4.h,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
            child: Text(
              actionText,
              style: TextStyle(
                color: AppTheme.accentColor,
                fontSize: 14.sp,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddressCard(BuildContext context, CheckoutState state) {
    final selectedAddress = state.selectedAddress;
    
    if (selectedAddress == null) {
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppTheme.secondaryColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppTheme.accentColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.location_off,
              color: Colors.grey,
              size: 40.sp,
            ),
            SizedBox(height: 12.h),
            Text(
              'No delivery address found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Please add a delivery address to continue',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to add address screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
                child: Text(
                  'Add Address',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.3),
          width: 1,
        ),
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
                'Deliver to:',
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
                  color: selectedAddress.type == 'home'
                      ? Colors.green.withOpacity(0.2)
                      : selectedAddress.type == 'work'
                          ? Colors.blue.withOpacity(0.2)
                          : Colors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  selectedAddress.type.toUpperCase(),
                  style: TextStyle(
                    color: selectedAddress.type == 'home'
                        ? Colors.green
                        : selectedAddress.type == 'work'
                            ? Colors.blue
                            : Colors.purple,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12.h),
          
          // User name
          Text(
            selectedAddress.name,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          SizedBox(height: 4.h),
          
          // Address
          Text(
            selectedAddress.address,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14.sp,
            ),
          ),
          
          SizedBox(height: 4.h),
          
          // Pincode
          Text(
            'PIN: ${selectedAddress.pincode}',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14.sp,
            ),
          ),
          
          SizedBox(height: 4.h),
          
          // Phone number
          Row(
            children: [
              Icon(
                Icons.phone,
                color: Colors.grey,
                size: 16.sp,
              ),
              SizedBox(width: 4.w),
              Text(
                '+91 ${selectedAddress.phone}',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
          
          // Show multiple addresses if available
          if (state.addresses.length > 1) ...[
            SizedBox(height: 16.h),
            const Divider(color: Colors.grey),
            SizedBox(height: 16.h),
            
            Text(
              'Other Addresses',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            SizedBox(height: 12.h),
            
            SizedBox(
              height: 40.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: state.addresses.length,
                itemBuilder: (context, index) {
                  final address = state.addresses[index];
                  final isSelected = address.id == selectedAddress.id;
                  
                  return GestureDetector(
                    onTap: () => _selectAddress(context, address.id),
                    child: Container(
                      margin: EdgeInsets.only(right: 8.w),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.accentColor.withOpacity(0.2)
                            : AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.accentColor
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            address.type == 'home'
                                ? Icons.home
                                : address.type == 'work'
                                    ? Icons.business
                                    : Icons.location_on,
                            color: isSelected ? AppTheme.accentColor : Colors.grey,
                            size: 16.sp,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            address.type.toUpperCase(),
                            style: TextStyle(
                              color: isSelected ? AppTheme.accentColor : Colors.white,
                              fontSize: 12.sp,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(BuildContext context, CheckoutState state) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: state.paymentMethods.map((method) {
          final isSelected = method.id == state.selectedPaymentMethodId;
          
          return InkWell(
            onTap: () => _selectPaymentMethod(context, method.id),
            borderRadius: BorderRadius.circular(8.r),
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: 12.h,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.withOpacity(0.3),
                    width: method.id == state.paymentMethods.last.id ? 0 : 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Radio button
                  Container(
                    width: 20.w,
                    height: 20.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppTheme.accentColor : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Center(
                            child: Container(
                              width: 10.w,
                              height: 10.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.accentColor,
                              ),
                            ),
                          )
                        : null,
                  ),
                  
                  SizedBox(width: 16.w),
                  
                  // Payment method icon
                  Container(
                    width: 32.w,
                    height: 32.w,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Center(
                      child: method.id == 0
                          ? Icon(
                              Icons.money,
                              color: isSelected ? AppTheme.accentColor : Colors.grey,
                              size: 20.sp,
                            )
                          : method.id == 1
                              ? Icon(
                                  Icons.credit_card,
                                  color: isSelected ? AppTheme.accentColor : Colors.grey,
                                  size: 20.sp,
                                )
                              : Icon(
                                  Icons.account_balance,
                                  color: isSelected ? AppTheme.accentColor : Colors.grey,
                                  size: 20.sp,
                                ),
                    ),
                  ),
                  
                  SizedBox(width: 16.w),
                  
                  // Payment method name
                  Text(
                    method.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontSize: 16.sp,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCouponCard(BuildContext context, CheckoutState state) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: state.couponCode != null
          ? Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20.sp,
                  ),
                ),
                
                SizedBox(width: 12.w),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Coupon Applied: ${state.couponCode}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      SizedBox(height: 4.h),
                      
                      Text(
                        'You are saving ${AppConstants.currencySymbol}${state.discount.toStringAsFixed(2)} with this coupon!',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                
                IconButton(
                  onPressed: () => _removeCoupon(context),
                  icon: Icon(
                    Icons.close,
                    color: Colors.grey,
                    size: 20.sp,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            )
          : Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Enter coupon code',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 14.sp,
                          ),
                          prefixIcon: Icon(
                            Icons.local_offer_outlined,
                            color: Colors.grey,
                            size: 20.sp,
                          ),
                          filled: true,
                          fillColor: AppTheme.primaryColor,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 12.h,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(
                              color: AppTheme.accentColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(
                              color: AppTheme.accentColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(
                              color: AppTheme.accentColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                        ),
                        onSubmitted: (code) {
                          if (code.isNotEmpty) {
                            _applyCoupon(context, code);
                          }
                        },
                      ),
                    ),
                    
                    SizedBox(width: 12.w),
                    
                    ElevatedButton(
                      onPressed: () {
                        // Get coupon code from text field
                        final textField = context.findRenderObject() as RenderBox?;
                        if (textField != null) {
                          final controller = (textField.parent as EditableText).controller;
                          final code = controller.text;
                          
                          if (code.isNotEmpty) {
                            _applyCoupon(context, code);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                      ),
                      child: Text(
                        'APPLY',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 16.h),
                
                Row(
                  children: [
                    Icon(
                      Icons.local_offer_outlined,
                      color: AppTheme.accentColor,
                      size: 16.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Tap on "View All" to see available coupons',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildOrderSummaryCard(BuildContext context, CheckoutState state) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${state.itemCount} Items',
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
                  'View Cart',
                  style: TextStyle(
                    color: AppTheme.accentColor,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16.h),
          
          _buildSummaryRow('Subtotal', '${AppConstants.currencySymbol}${state.subtotal.toStringAsFixed(2)}'),
          
          SizedBox(height: 8.h),
          
          if (state.discount > 0) ...[
            _buildSummaryRow(
              'Discount',
              '- ${AppConstants.currencySymbol}${state.discount.toStringAsFixed(2)}',
              isDiscount: true,
            ),
            
            SizedBox(height: 8.h),
          ],
          
          _buildSummaryRow(
            'Delivery Fee',
            state.deliveryFee > 0
                ? '${AppConstants.currencySymbol}${state.deliveryFee.toStringAsFixed(2)}'
                : 'FREE',
            isFree: state.deliveryFee == 0,
          ),
          
          SizedBox(height: 16.h),
          
          Divider(color: Colors.grey.withOpacity(0.3)),
          
          SizedBox(height: 16.h),
          
          _buildSummaryRow(
            'Total Amount',
            '${AppConstants.currencySymbol}${state.total.toStringAsFixed(2)}',
            isTotal: true,
          ),
          
          if (state.discount > 0) ...[
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.savings_outlined,
                    color: Colors.green,
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'You are saving ${AppConstants.currencySymbol}${state.discount.toStringAsFixed(2)} on this order',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isDiscount = false,
    bool isTotal = false,
    bool isFree = false,
  }) {
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
            fontSize: isTotal ? 16.sp : 14.sp,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isDiscount
                ? Colors.green
                : isFree
                    ? Colors.green
                    : isTotal
                        ? AppTheme.accentColor
                        : Colors.white,
            fontSize: isTotal ? 16.sp : 14.sp,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  void _showOrderSuccessDialog(BuildContext context, String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: AppTheme.secondaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success icon
                Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 48.sp,
                  ),
                ),
                
                SizedBox(height: 24.h),
                
                // Success message
                Text(
                  'Order Placed Successfully!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 12.h),
                
                // Order ID
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    'Order ID: $orderId',
                    style: TextStyle(
                      color: AppTheme.accentColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                SizedBox(height: 16.h),
                
                // Description
                Text(
                  'Your order has been placed successfully. You can track your order in the Orders section.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14.sp,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 24.h),
                
                // Continue shopping button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Close all screens and go to home
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      'CONTINUE SHOPPING',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: 12.h),
                
                // Track order button
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      // Navigate to orders page with current orders tab selected
                      Navigator.popUntil(context, (route) => route.isFirst);
                      Navigator.pushNamed(context, AppConstants.ordersRoute, arguments: {'initialTab': 0});
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                    ),
                    child: Text(
                      'TRACK ORDER',
                      style: TextStyle(
                        color: AppTheme.accentColor,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}