import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/cart/cart_event.dart';
import '../../blocs/cart/cart_state.dart';
import '../../widgets/base_layout.dart';
import '../../widgets/cards/cart_item_card.dart';
import '../../widgets/loaders/shimmer_loader.dart';
import '../checkout/checkout_page.dart';
import '../coupon/coupon_page.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CartBloc()..add(LoadCart()),
      child: const _CartPageContent(),
    );
  }
}

class _CartPageContent extends StatefulWidget {
  const _CartPageContent();

  @override
  State<_CartPageContent> createState() => _CartPageContentState();
}

class _CartPageContentState extends State<_CartPageContent> {
  final TextEditingController _couponController = TextEditingController();
  
  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _updateCartItemQuantity(String productId, int quantity) {
    context.read<CartBloc>().add(UpdateCartItemQuantity(productId, quantity));
  }

  void _removeCartItem(String productId) {
    context.read<CartBloc>().add(RemoveFromCart(productId));
  }

  void _clearCart() {
    context.read<CartBloc>().add(ClearCart());
  }

  void _applyCoupon(String code) {
    if (code.isNotEmpty) {
      context.read<CartBloc>().add(ApplyCoupon(code));
      _couponController.clear();
    }
  }

  void _removeCoupon() {
    context.read<CartBloc>().add(RemoveCoupon());
  }
  
  void _navigateToCheckout() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CheckoutPage()),
    );
  }
  
  void _navigateToCoupons() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CouponPage()),
    ).then((couponCode) {
      if (couponCode != null && couponCode is String && couponCode.isNotEmpty) {
        _applyCoupon(couponCode);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CartBloc, CartState>(
      listener: (context, state) {
        if (state.status == CartStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'An error occurred'),
              backgroundColor: Colors.red,
            ),
          );
        }
        
        if (state.status == CartStatus.couponApplied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Coupon applied! You saved ${AppConstants.currencySymbol}${state.discount.toStringAsFixed(2)}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        if (state.status == CartStatus.couponError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Invalid coupon code'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        return BaseLayout(
          title: 'My Cart',
          actions: [
            if (state.items.isNotEmpty)
              TextButton.icon(
                onPressed: _clearCart,
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
                label: const Text(
                  'Clear',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
          body: state.status == CartStatus.loading
              ? _buildLoadingState()
              : state.items.isEmpty
                  ? _buildEmptyCart()
                  : _buildCartWithItems(state),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Shimmer for cart items
          for (int i = 0; i < 3; i++) ...[
            ShimmerLoader.customContainer(
              height: 120,
              width: double.infinity,
              borderRadius: 12,
            ),
            const SizedBox(height: 16),
          ],
          
          // Shimmer for coupon section
          ShimmerLoader.customContainer(
            height: 80,
            width: double.infinity,
            borderRadius: 12,
          ),
          
          const SizedBox(height: 16),
          
          // Shimmer for price summary
          ShimmerLoader.customContainer(
            height: 120,
            width: double.infinity,
            borderRadius: 12,
          ),
          
          const SizedBox(height: 16),
          
          // Shimmer for checkout button
          ShimmerLoader.customContainer(
            height: 56,
            width: double.infinity,
            borderRadius: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = screenWidth * 0.15; // Responsive icon size
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: screenWidth * 0.3,
              height: screenWidth * 0.3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.secondaryColor,
                border: Border.all(
                  color: AppTheme.accentColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: iconSize,
                color: AppTheme.accentColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your cart is empty',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Add items to your cart to start shopping',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: screenWidth * 0.5,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate back to home
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Start Shopping',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartWithItems(CartState state) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Calculate responsive dimensions
    final padding = (screenWidth / 50).clamp(8.0, 16.0);
    final spacing = (screenWidth / 75).clamp(6.0, 12.0);
    final buttonHeight = (screenHeight / 18).clamp(42.0, 50.0);
    final offerCardWidth = screenWidth * 0.6;
    final offerSectionHeight = (screenHeight / 10).clamp(70.0, 100.0);
    
    // Calculate font sizes based on screen width
    final largeFontSize = (screenWidth / 26).clamp(14.0, 18.0);
    final mediumFontSize = (screenWidth / 30).clamp(12.0, 16.0);
    final smallFontSize = (screenWidth / 35).clamp(10.0, 14.0);
    
    return Stack(
      children: [
        // Cart items list - use Padding + ListView instead of Expanded to ensure proper layout
        Padding(
          padding: EdgeInsets.only(bottom: 
              state.items.isEmpty ? 0 : screenHeight * 0.35), // Allow space for the bottom sheet
          child: ListView.builder(
            itemCount: state.items.length,
            padding: EdgeInsets.all(padding),
            itemBuilder: (context, index) {
              final item = state.items[index];
              
              return Padding(
                padding: EdgeInsets.only(bottom: spacing),
                child: CartItemCard.fromEntity(
                  item: item,
                  onQuantityChanged: (newQuantity) {
                    _updateCartItemQuantity(item.productId, newQuantity);
                  },
                  onRemove: () {
                    _removeCartItem(item.productId);
                  },
                ),
              );
            },
          ),
        ),
        
        // Cart summary and checkout - draggable bottom sheet
        if (state.items.isNotEmpty)
          DraggableScrollableSheet(
            initialChildSize: 0.35,
            minChildSize: 0.25,
            maxChildSize: 0.8,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
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
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    // Drag indicator
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Container(
                        width: screenWidth * 0.1,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    // Sheet content
                    ListView(
                      controller: scrollController,
                      padding: EdgeInsets.fromLTRB(padding, padding * 1.5, padding, padding),
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Coupon section
                            _buildCouponSection(state),
                            
                            SizedBox(height: spacing * 1.5),
                            
                            // Price summary - with larger font sizes
                            _buildPriceSummary(
                              state, 
                              fontSize: mediumFontSize,
                              totalFontSize: largeFontSize,
                            ),
                            
                            SizedBox(height: spacing * 1.5),
                            
                            // Checkout button - responsive height
                            SizedBox(
                              width: double.infinity,
                              height: buttonHeight,
                              child: ElevatedButton(
                                onPressed: _navigateToCheckout,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accentColor,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'PROCEED TO CHECKOUT',
                                  style: TextStyle(
                                    fontSize: mediumFontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            
                            SizedBox(height: spacing),
                            
                            // Divider
                            Divider(color: Colors.grey.withOpacity(0.3)),
                            
                            // Available offers label
                            Row(
                              children: [
                                Icon(
                                  Icons.local_offer_outlined,
                                  color: AppTheme.accentColor,
                                  size: (screenWidth / 25).clamp(16.0, 20.0),
                                ),
                                SizedBox(width: spacing / 2),
                                Text(
                                  'Available offers',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: mediumFontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: _navigateToCoupons,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(horizontal: spacing / 2),
                                  ),
                                  child: Text(
                                    'View All',
                                    style: TextStyle(
                                      color: AppTheme.accentColor,
                                      fontSize: smallFontSize,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            // Offers list - scrollable horizontally
                            SizedBox(
                              height: offerSectionHeight,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: 3, // Mock data
                                itemBuilder: (context, index) {
                                  final cardWidth = offerCardWidth.clamp(150.0, 200.0);
                                  return Container(
                                    width: cardWidth,
                                    margin: EdgeInsets.only(right: spacing),
                                    padding: EdgeInsets.all(spacing),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppTheme.accentColor.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.discount,
                                              color: AppTheme.accentColor,
                                              size: (screenWidth / 30).clamp(12.0, 16.0),
                                            ),
                                            SizedBox(width: spacing / 3),
                                            Text(
                                              ['WELCOME10', 'SAVE15', 'FIRST20'][index],
                                              style: TextStyle(
                                                color: AppTheme.accentColor,
                                                fontSize: smallFontSize,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: spacing / 2),
                                        Text(
                                          [
                                            '10% off on your first order',
                                            '15% off on orders above ₹500',
                                            '20% off on selected items'
                                          ][index],
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: smallFontSize,
                                            height: 1.3,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const Spacer(),
                                        Text(
                                          'Tap to apply',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: smallFontSize * 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildCouponSection(CartState state) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Calculate responsive dimensions - larger for better visibility
    final spacing = (screenWidth / 60).clamp(8.0, 16.0);
    final fontSize = (screenWidth / 28).clamp(14.0, 18.0);
    final smallFontSize = (screenWidth / 32).clamp(12.0, 16.0);
    final iconSize = (screenWidth / 20).clamp(18.0, 24.0);
    final inputHeight = (screenHeight / 18).clamp(44.0, 52.0);
    
    return !state.couponApplied
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.confirmation_number_outlined,
                    color: AppTheme.accentColor,
                    size: iconSize,
                  ),
                  SizedBox(width: spacing / 2),
                  Text(
                    'Apply Coupon',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: spacing),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SizedBox(
                      height: inputHeight,
                      child: TextField(
                        controller: _couponController,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: smallFontSize,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter coupon code',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: smallFontSize,
                          ),
                          // Use dynamic ContentPadding
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: spacing,
                            vertical: spacing / 4,
                          ),
                          filled: true,
                          fillColor: AppTheme.primaryColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppTheme.accentColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppTheme.accentColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppTheme.accentColor,
                              width: 1.5,
                            ),
                          ),
                          prefixIcon: Icon(
                            Icons.receipt_outlined,
                            color: Colors.grey,
                            size: iconSize * 0.9,
                          ),
                          isDense: true, // Important to reduce vertical spacing
                        ),
                        onSubmitted: _applyCoupon,
                      ),
                    ),
                  ),
                  
                  SizedBox(width: spacing),
                  
                  // Match height with TextField
                  SizedBox(
                    height: inputHeight,
                    child: ElevatedButton(
                      onPressed: () => _applyCoupon(_couponController.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: spacing),
                      ),
                      child: state.status == CartStatus.applyingCoupon
                          ? SizedBox(
                              width: iconSize,
                              height: iconSize,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : Text(
                              'APPLY',
                              style: TextStyle(
                                fontSize: smallFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          )
        : Container(
            padding: EdgeInsets.all(spacing),
            margin: EdgeInsets.symmetric(vertical: spacing / 2),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.green,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(spacing / 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: iconSize,
                  ),
                ),
                
                SizedBox(width: spacing),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Coupon Applied: ${state.couponCode}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      
                      SizedBox(height: spacing / 2),
                      
                      Text(
                        'You saved ${AppConstants.currencySymbol}${state.discount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: smallFontSize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _removeCoupon,
                    borderRadius: BorderRadius.circular(50),
                    child: Padding(
                      padding: EdgeInsets.all(spacing / 2),
                      child: Icon(
                        Icons.close,
                        color: Colors.grey,
                        size: iconSize * 0.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildPriceSummary(
    CartState state, {
    double? fontSize,
    double? totalFontSize,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calculate responsive dimensions or use provided values
    final spacing = (screenWidth / 75).clamp(6.0, 12.0);
    final actualFontSize = fontSize ?? (screenWidth / 32).clamp(12.0, 16.0);
    final smallFontSize = (actualFontSize * 0.9).clamp(10.0, 14.0);
    final iconSize = (screenWidth / 25).clamp(16.0, 20.0);
    final actualTotalFontSize = totalFontSize ?? (screenWidth / 28).clamp(14.0, 18.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              color: AppTheme.accentColor,
              size: iconSize,
            ),
            SizedBox(width: spacing / 2),
            Text(
              'Price Details',
              style: TextStyle(
                color: Colors.white,
                fontSize: actualFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        
        SizedBox(height: spacing),
        
        _buildPriceRow(
          'Subtotal (${state.itemCount} ${state.itemCount == 1 ? 'item' : 'items'})',
          '${AppConstants.currencySymbol}${state.subtotal.toStringAsFixed(2)}',
          fontSize: smallFontSize,
          totalFontSize: actualTotalFontSize,
        ),
        
        SizedBox(height: spacing / 2),
        
        if (state.discount > 0) ...[
          _buildPriceRow(
            'Discount',
            '- ${AppConstants.currencySymbol}${state.discount.toStringAsFixed(2)}',
            isDiscount: true,
            fontSize: smallFontSize,
            totalFontSize: actualTotalFontSize,
          ),
          
          SizedBox(height: spacing / 2),
        ],
        
        _buildPriceRow(
          'Delivery Fee',
          state.deliveryFee > 0
              ? '${AppConstants.currencySymbol}${state.deliveryFee.toStringAsFixed(2)}'
              : 'FREE',
          isFree: state.deliveryFee == 0,
          fontSize: smallFontSize,
          totalFontSize: actualTotalFontSize,
        ),
        
        SizedBox(height: spacing),
        
        Divider(color: Colors.grey.withOpacity(0.3)),
        
        SizedBox(height: spacing / 2),
        
        _buildPriceRow(
          'Total Amount',
          '${AppConstants.currencySymbol}${state.total.toStringAsFixed(2)}',
          isTotal: true,
          fontSize: smallFontSize,
          totalFontSize: actualTotalFontSize,
        ),
        
        if (state.discount > 0) ...[
          SizedBox(height: spacing / 2),
          Text(
            'You will save ${AppConstants.currencySymbol}${state.discount.toStringAsFixed(2)} on this order',
            style: TextStyle(
              color: Colors.green,
              fontSize: smallFontSize * 0.9,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPriceRow(String label, String value, {
    bool isDiscount = false,
    bool isTotal = false,
    bool isFree = false,
    required double fontSize,
    required double totalFontSize,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                color: isDiscount
                    ? Colors.green
                    : isTotal
                        ? Colors.white
                        : Colors.grey,
                fontSize: isTotal ? fontSize * 1.1 : fontSize,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Flexible(
            flex: 2,
            child: Text(
              value,
              style: TextStyle(
                color: isDiscount
                    ? Colors.green
                    : isFree
                        ? Colors.green
                        : isTotal
                            ? AppTheme.accentColor
                            : Colors.white,
                fontSize: isTotal ? totalFontSize : fontSize,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}