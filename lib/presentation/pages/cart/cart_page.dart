import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:profit_grocery_application/presentation/widgets/coupons/animated_coupon_error.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/cart.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/repositories/product_repository.dart';
import '../../../main.dart';
import '../../../services/asset_cache_service.dart';
import '../../../services/simple_cart_service.dart';
import '../../widgets/base_layout.dart';
import '../../widgets/cards/cart_item_card.dart';
import '../../widgets/loaders/shimmer_loader.dart';
import '../checkout/checkout_page.dart';
import '../coupon/coupon_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final TextEditingController _couponController = TextEditingController();
  final SimpleCartService _cartService = SimpleCartService();
  final AssetCacheService _assetCacheService = AssetCacheService();
  
  bool _isLoading = true;
  List<CartItem> _cartItems = [];
  double _subtotal = 0.0;
  double _discount = 0.0;
  double _deliveryFee = 0.0;
  double _total = 0.0;
  int _itemCount = 0;
  String? _couponCode;
  bool _couponApplied = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }
  
  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }
  
  Future<void> _loadCartItems() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get cart items from SimpleCartService
      final cartItems = await _cartService.getCartItemsFromFirestore();
      
      if (cartItems.isEmpty) {
        if (!mounted) return;
        setState(() {
          _cartItems = [];
          _subtotal = 0.0;
          _discount = 0.0;
          _deliveryFee = 0.0;
          _total = 0.0;
          _itemCount = 0;
          _isLoading = false;
        });
        return;
      }
      
      // Convert to CartItem objects
      final productRepository = sl<ProductRepository>();
      final List<CartItem> items = [];
      double subtotal = 0.0;
      int itemCount = 0;
      
      // Process each cart item - limit concurrent operations
      for (final entry in cartItems.entries) {
        final productId = entry.key;
        final itemData = entry.value as Map<String, dynamic>;
        final quantity = itemData['quantity'] as int;
        
        try {
          // Get product details from product repository
          final product = await productRepository.getProductById(productId);
          
          if (product != null) {
            // Add to cart items
            final cartItem = CartItem(
              productId: product.id,
              name: product.name,
              image: product.image,
              price: product.price,
              mrp: product.mrp,
              quantity: quantity,
              categoryId: product.categoryId,
              categoryName: product.categoryName ?? '',
            );
            
            items.add(cartItem);
            subtotal += product.price * quantity;
            itemCount += quantity;
            
            // Don't preload images during cart loading - this will be done by the image widget itself
            // This prevents excessive logging and slowdowns
          }
        } catch (e) {
          print('Error loading product $productId: $e');
        }
      }
      
      // Calculate total
      final deliveryFee = 0.0; // Default delivery fee
      final total = subtotal - _discount + deliveryFee;
      
      if (!mounted) return;
      setState(() {
        _cartItems = items;
        _subtotal = subtotal;
        _deliveryFee = deliveryFee;
        _total = total;
        _itemCount = itemCount;
        _isLoading = false;
      });

      // Now that the cart is displayed, preload images in the background (optional)
      _preloadImagesInBackground(items);
    } catch (e) {
      print('Error loading cart items: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load cart items';
        _isLoading = false;
      });
    }
  }

  // Preload images in the background with rate limiting
  Future<void> _preloadImagesInBackground(List<CartItem> items) async {
    if (!mounted) return;
    
    // Set a limit to how many images we preload
    const maxImagesToPreload = 5;
    final imagesToPreload = items.take(maxImagesToPreload).map((item) => item.image).toList();
    
    for (final image in imagesToPreload) {
      if (!mounted) return;
      if (image.isNotEmpty) {
        try {
          // Use a very short delay between image preloads to prevent resource overload
          await Future.delayed(const Duration(milliseconds: 100));
          _assetCacheService.cacheAsset(image);
        } catch (e) {
          // Silently ignore errors during background preloading
        }
      }
    }
  }
  
  void _updateCartItemQuantity(String productId, int quantity) async {
    try {
      await _cartService.addOrUpdateItem(
        productId: productId, 
        quantity: quantity,
      );
      
      // Reload cart items
      if (mounted) {
        _loadCartItems();
      }
    } catch (e) {
      print('Error updating cart item quantity: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to update cart item';
      });
    }
  }

  void _removeCartItem(String productId) async {
    try {
      await _cartService.removeItem(productId: productId);
      
      // Reload cart items
      if (mounted) {
        _loadCartItems();
      }
    } catch (e) {
      print('Error removing cart item: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to remove cart item';
      });
    }
  }

  void _clearCart() async {
    try {
      // Get all cart items
      final cartItems = await _cartService.getCartItemsFromFirestore();
      
      // Remove each item
      for (final productId in cartItems.keys) {
        await _cartService.removeItem(productId: productId);
      }
      
      // Reload cart items
      if (mounted) {
        _loadCartItems();
      }
    } catch (e) {
      print('Error clearing cart: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to clear cart';
      });
    }
  }

  void _applyCoupon(String code) {
    if (code.isNotEmpty) {
      // TODO: Implement coupon application with SimpleCartService
      _couponController.clear();
      
      // Mock coupon application
      if (!mounted) return;
      setState(() {
        _couponCode = code;
        _couponApplied = true;
        _discount = _subtotal * 0.1; // 10% discount as a placeholder
        _total = _subtotal - _discount + _deliveryFee;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Coupon applied! You saved ${AppConstants.currencySymbol}${_discount.toStringAsFixed(2)}',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _removeCoupon() {
    if (!mounted) return;
    setState(() {
      _couponCode = null;
      _couponApplied = false;
      _discount = 0.0;
      _total = _subtotal - _discount + _deliveryFee;
    });
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
    return BaseLayout(
      title: 'My Cart',
      actions: [
        if (_cartItems.isNotEmpty)
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
      body: _isLoading
          ? _buildLoadingState()
          : _cartItems.isEmpty
              ? _buildEmptyCart()
              : _buildCartWithItems(),
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

  Widget _buildCartWithItems() {
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
              _cartItems.isEmpty ? 0 : screenHeight * 0.35), // Allow space for the bottom sheet
          child: ListView.builder(
            itemCount: _cartItems.length,
            padding: EdgeInsets.all(padding),
            itemBuilder: (context, index) {
              final item = _cartItems[index];
              
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
        if (_cartItems.isNotEmpty)
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
                            _buildCouponSection(spacing, smallFontSize, (screenWidth / 25).clamp(16.0, 20.0)),
                            
                            SizedBox(height: spacing * 1.5),
                            
                            // Price summary - with larger font sizes
                            _buildPriceSummary(
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
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          index == 0 ? 'FIRST10' : (index == 1 ? 'BUNDLE20' : 'SPECIAL15'),
                                          style: TextStyle(
                                            color: AppTheme.accentColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: smallFontSize * 1.1,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          index == 0 
                                            ? '10% off on your first order' 
                                            : (index == 1 
                                                ? '20% off on bundle purchases' 
                                                : '15% off on special items'),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: smallFontSize * 0.9,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
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

  Widget _buildCouponSection(double spacing, double smallFontSize, double iconSize) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Show coupon error animation if there's an error
          if (_errorMessage != null && _errorMessage!.contains('coupon'))
            AnimatedCouponError(
              errorMessage: _errorMessage!,
              spacing: spacing,
              smallFontSize: smallFontSize,
              iconSize: iconSize,
            ),
          
          // Coupon input row
          Row(
            children: [
              Icon(
                Icons.local_offer_outlined,
                color: AppTheme.accentColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _couponApplied
                    ? _buildAppliedCoupon()
                    : TextField(
                        controller: _couponController,
                        decoration: InputDecoration(
                          hintText: 'Enter coupon code',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 8,
                          ),
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
              ),
              if (!_couponApplied) 
                TextButton(
                  onPressed: () => _applyCoupon(_couponController.text),
                  style: TextButton.styleFrom(
                    backgroundColor: AppTheme.accentColor.withOpacity(0.2),
                    foregroundColor: AppTheme.accentColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  child: const Text(
                    'APPLY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppliedCoupon() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            _couponCode ?? '',
            style: TextStyle(
              color: AppTheme.accentColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Applied',
          style: TextStyle(
            color: Colors.green.shade300,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        InkWell(
          onTap: _removeCoupon,
          child: const Icon(
            Icons.close,
            color: Colors.grey,
            size: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSummary({
    required double fontSize,
    required double totalFontSize,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildPriceSummaryRow(
            label: 'Subtotal',
            value: _subtotal,
            fontSize: fontSize,
          ),
          if (_couponApplied && _discount > 0)
            _buildPriceSummaryRow(
              label: 'Discount',
              value: -_discount,
              fontSize: fontSize,
              valueColor: Colors.green.shade300,
              showNegativeSign: true,
            ),
          _buildPriceSummaryRow(
            label: 'Delivery',
            value: _deliveryFee,
            fontSize: fontSize,
          ),
          const Divider(color: Colors.grey),
          _buildPriceSummaryRow(
            label: 'Total',
            value: _total,
            fontSize: totalFontSize,
            isBold: true,
          ),
        ],
      ),
    );
  }
  
  Widget _buildPriceSummaryRow({
    required String label,
    required double value,
    required double fontSize,
    Color? valueColor,
    bool isBold = false,
    bool showNegativeSign = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            showNegativeSign
                ? '-${AppConstants.currencySymbol}${value.abs().toStringAsFixed(2)}'
                : '${AppConstants.currencySymbol}${value.toStringAsFixed(2)}',
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}