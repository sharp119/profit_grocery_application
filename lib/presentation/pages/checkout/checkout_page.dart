import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/user.dart';
import '../../blocs/checkout/checkout_bloc.dart';
import '../../blocs/checkout/checkout_event.dart';
import '../../blocs/checkout/checkout_state.dart';
import '../../widgets/base_layout.dart';
import '../../widgets/loaders/shimmer_loader.dart';
import '../coupon/coupon_page.dart';
import '../../../services/cart_provider.dart';
import '../profile/address_form_page.dart';

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

class _CheckoutPageContent extends StatefulWidget {
  const _CheckoutPageContent();

  @override
  State<_CheckoutPageContent> createState() => _CheckoutPageContentState();
}

class _CheckoutPageContentState extends State<_CheckoutPageContent> {
  final TextEditingController _couponController = TextEditingController();
  final CartProvider _cartProvider = CartProvider();
  
  // Cart information to display
  int _itemCount = 0;
  double _subtotal = 0.0;
  double _discount = 0.0;
  double _total = 0.0;
  bool _freeDelivery = true;
  
  // Address information
  Map<String, dynamic>? _addressData;
  bool _loadingAddress = true;

  @override
  void initState() {
    super.initState();
    _getCartInformation();
    _loadAddressFromPrefs();
    
    // Listen for cart changes
    _cartProvider.addListener(_getCartInformation);
  }

  @override
  void dispose() {
    _couponController.dispose();
    _cartProvider.removeListener(_getCartInformation);
    super.dispose();
  }
  
  Future<void> _getCartInformation() async {
    try {
      // Get cart items count
      final cartItems = _cartProvider.cartItems;
      final itemCount = cartItems.length;
      
      // Try to retrieve cart total values from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final cartTotalsJson = prefs.getString('cart_totals');
      
      double subtotal = 0.0;
      double discount = 0.0;
      double total = 0.0;
      
      if (cartTotalsJson != null) {
        // Parse cart totals from SharedPreferences
        final cartTotals = jsonDecode(cartTotalsJson);
        subtotal = (cartTotals['subtotal'] as num).toDouble();
        discount = (cartTotals['discount'] as num).toDouble();
        total = (cartTotals['total'] as num).toDouble();
      } else {
        // If cart totals not found in SharedPreferences, use hardcoded values
        // In a real app, you would calculate these values
        subtotal = 798.0;
        discount = 79.8; // 10% discount
        total = subtotal - discount; // Free delivery already applied
      }
      
      setState(() {
        _itemCount = itemCount;
        _subtotal = subtotal;
        _discount = discount;
        _total = total;
      });
      
      // Save cart totals for next time
      _saveCartTotals(subtotal, discount, total);
    } catch (e) {
      print('Error getting cart information: $e');
    }
  }
  
  // Save cart totals to SharedPreferences
  Future<void> _saveCartTotals(double subtotal, double discount, double total) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartTotals = {
        'subtotal': subtotal,
        'discount': discount,
        'total': total,
      };
      await prefs.setString('cart_totals', jsonEncode(cartTotals));
    } catch (e) {
      print('Error saving cart totals: $e');
    }
  }

  // Load selected address from SharedPreferences
  Future<void> _loadAddressFromPrefs() async {
    setState(() {
      _loadingAddress = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final addressJson = prefs.getString('selected_address');
      
      if (addressJson != null) {
        setState(() {
          _addressData = jsonDecode(addressJson);
          _loadingAddress = false;
        });
        print('Loaded address from SharedPreferences');
      } else {
        setState(() {
          _addressData = null;
          _loadingAddress = false;
        });
        print('No saved address found in SharedPreferences');
      }
    } catch (e) {
      print('Error loading address from SharedPreferences: $e');
      setState(() {
        _addressData = null;
        _loadingAddress = false;
      });
    }
  }

  void _selectAddress(BuildContext context, String addressId) {
    context.read<CheckoutBloc>().add(SelectAddress(addressId));
  }

  void _selectPaymentMethod(BuildContext context, int paymentMethodId) {
    context.read<CheckoutBloc>().add(SelectPaymentMethod(paymentMethodId));
  }

  void _applyCoupon(BuildContext context, String code) {
    context.read<CheckoutBloc>().add(ApplyCouponCO(code));
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
          // Order summary shimmer (moved to top)
          ShimmerLoader.customContainer(
            height: 180.h,
            width: double.infinity,
            borderRadius: 12.r,
          ),
          
          SizedBox(height: 24.h),
          
          // Coupon shimmer (moved to second)
          ShimmerLoader.customContainer(
            height: 80.h,
            width: double.infinity,
            borderRadius: 12.r,
          ),
          
          SizedBox(height: 24.h),
          
          // Payment method shimmer (moved to third)
          ShimmerLoader.customContainer(
            height: 180.h,
            width: double.infinity,
            borderRadius: 12.r,
          ),
          
          SizedBox(height: 24.h),
          
          // Delivery address shimmer (moved to bottom)
          ShimmerLoader.customContainer(
            height: 150.h,
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
              // Order summary (moved to top)
              _buildSectionHeading('Order Summary'),
              
              SizedBox(height: 12.h),
              
              _buildOrderSummaryCard(context, state),
              
              SizedBox(height: 24.h),
              
              // Coupon section (moved to second)
              _buildSectionHeading(
                'Apply Coupon',
                actionText: 'View All',
                onActionTap: () => _navigateToCoupons(context),
              ),
              
              SizedBox(height: 12.h),
              
              _buildCouponCard(context, state),
              
              SizedBox(height: 24.h),
              
              // Payment method (moved to third)
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
              
              // Delivery address (moved to last)
              _buildSectionHeading('Delivery Address'),
              
              SizedBox(height: 12.h),
              
              _buildAddressCard(context, state),
              
              // Extra space at bottom for the fixed button
              SizedBox(height: 110.h),
            ],
          ),
        ),
        
        // Place order button (fixed at bottom)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.black,
            child: Container(
              margin: EdgeInsets.fromLTRB(20.r, 20.h, 20.r, 30.h),
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: state.status == CheckoutStatus.placingOrder
                    ? null
                    : () => _placeOrder(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFFC107), // More vibrant amber
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  'PLACE ORDER',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
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
    // Don't show action text for Delivery Address section
    final bool showAction = title != 'Delivery Address' && onActionTap != null;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
        if (showAction)
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
    if (_loadingAddress) {
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
        child: Center(
          child: CircularProgressIndicator(
            color: AppTheme.accentColor,
          ),
        ),
      );
    }
    
    if (_addressData == null) {
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
          ],
        ),
      );
    }

    // We have address data
    final addressType = _addressData!['addressType'] ?? 'home';
    
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side with icon and title
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.amber,
                    size: 24.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Delivery Address:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              // Right side with address type badge and edit button
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: addressType == 'home'
                          ? Colors.green.withOpacity(0.2)
                          : addressType == 'work'
                              ? Colors.blue.withOpacity(0.2)
                              : Colors.purple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      addressType.toUpperCase(),
                      style: TextStyle(
                        color: addressType == 'home'
                            ? Colors.green
                            : addressType == 'work'
                                ? Colors.blue
                                : Colors.purple,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  InkWell(
                    onTap: () {
                      // Create an Address object from the address data
                      final address = Address(
                        id: _addressData!['id'] ?? '',
                        name: _addressData!['name'] ?? '',
                        addressLine: _addressData!['addressLine'] ?? '',
                        city: _addressData!['city'] ?? '',
                        state: _addressData!['state'] ?? '',
                        pincode: _addressData!['pincode'] ?? '',
                        landmark: _addressData!['landmark'],
                        addressType: _addressData!['addressType'] ?? 'home',
                        isDefault: true,
                        phone: _addressData!['phone'],
                      );
                      
                      // Navigate to address edit page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddressFormPage(
                            address: address,
                            isEditing: true,
                          ),
                        ),
                      ).then((_) {
                        // Reload address data when returning from edit page
                        _loadAddressFromPrefs();
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: Colors.amber,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit,
                            color: Colors.amber,
                            size: 16.sp,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Edit',
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // User name - with more prominent styling
          Text(
            _addressData!['name'] ?? 'No Name',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),

          SizedBox(height: 8.h),

          // Full address
          Text(
            _addressData!['addressLine'] ?? 'No Address',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 15.sp,
            ),
          ),

          SizedBox(height: 4.h),

          // City & State
          Text(
            '${_addressData!['city'] ?? ''}, ${_addressData!['state'] ?? ''}',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 15.sp,
            ),
          ),

          SizedBox(height: 4.h),

          // Pincode with more consistent styling
          Row(
            children: [
              Text(
                'PIN: ',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 15.sp,
                ),
              ),
              Text(
                '${_addressData!['pincode'] ?? 'Not Available'}',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // Phone number with icon alignment similar to the screenshot
          if (_addressData!['phone'] != null && _addressData!['phone'].toString().isNotEmpty) ...[
            SizedBox(height: 8.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.phone,
                  color: Colors.grey.shade400,
                  size: 16.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Phone: ${_addressData!['phone']}',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 15.sp,
                  ),
                ),
              ],
            ),
          ],

          // Landmark if available - with matching styling
          if (_addressData!['landmark'] != null && _addressData!['landmark'].toString().isNotEmpty) ...[
            SizedBox(height: 8.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Landmark: ',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 15.sp,
                  ),
                ),
                Expanded(
                  child: Text(
                    '${_addressData!['landmark']}',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 15.sp,
                    ),
                  ),
                ),
              ],
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
                        'You are saving ${AppConstants.currencySymbol}${state.discount.toInt()} with this coupon!',
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
                        controller: _couponController,
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
                        final code = _couponController.text;
                        if (code.isNotEmpty) {
                          _applyCoupon(context, code);
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
                '$_itemCount Items',
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
          
          _buildSummaryRow('Subtotal', '${AppConstants.currencySymbol}${_subtotal.toInt()}'),
          
          SizedBox(height: 8.h),
          
          if (_discount > 0) ...[
            _buildSummaryRow(
              'Discount',
              '- ${AppConstants.currencySymbol}${_discount.toInt()}',
              isDiscount: true,
            ),
            
            SizedBox(height: 8.h),
          ],
          
          _buildSummaryRow(
            'Delivery Fee',
            'FREE',
            isFree: true,
          ),
          
          SizedBox(height: 16.h),
          
          Divider(color: Colors.grey.withOpacity(0.3)),
          
          SizedBox(height: 16.h),
          
          _buildSummaryRow(
            'Total Amount',
            '${AppConstants.currencySymbol}${_total.toInt()}',
            isTotal: true,
          ),
          
          if (_discount > 0) ...[
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
                      'You are saving ${AppConstants.currencySymbol}${_discount.toInt()} on this order',
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