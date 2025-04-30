import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:convert';
import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/product.dart';
import '../../../services/cart_provider.dart';
import '../../../services/product/shared_product_service.dart';
import '../../../services/simple_cart_service.dart';
import '../../../services/discount/discount_service.dart';
import '../../widgets/loaders/shimmer_loader.dart';
import '../../widgets/image_loader.dart';
import '../../widgets/buttons/add_button.dart';
import '../../../domain/entities/user.dart';
import '../../../services/cart_provider.dart';
import '../../../services/product/shared_product_service.dart';
import '../../../services/simple_cart_service.dart';
import '../../../services/discount/discount_service.dart';
import '../../widgets/loaders/shimmer_loader.dart';
import '../../widgets/image_loader.dart';
import '../../widgets/buttons/add_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../blocs/user/user_bloc.dart';
import '../../blocs/user/user_event.dart';
import 'package:provider/provider.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> with TickerProviderStateMixin {
  final CartProvider _cartProvider = CartProvider();
  final SharedProductService _productService = SharedProductService();
  final SimpleCartService _cartService = SimpleCartService();
  
  // Map to track loading and animation states
  final Map<String, bool> _loadingState = {};
  final Map<String, Product?> _productDetails = {};
  final Map<String, AnimationController> _itemAnimationControllers = {};
  final Map<String, Map<String, dynamic>> _discountDetails = {};
  
  int _totalItems = 0;
  int _removedItemsCount = 0;
  bool _allItemsLoaded = false;
  bool _showRemovedMessage = true;
  bool _productsRemoved = false;
  bool _showAllItems = false;
  bool _isPaymentExpanded = false;
  
  // Final list of products after filtering out unavailable ones
  late List<MapEntry<String, dynamic>> _cartEntries = [];
  
  // Address and total payment information
  Address? _defaultAddress;
  bool _addressLoading = true;
  double _totalCartValue = 0;
  double _totalSavings = 0;

  @override
  void initState() {
    super.initState();
    _setupItemsList();
    _loadCartItems().then((_) {
      if (_removedItemsCount > 0) {
        _removeUnavailableProducts();
      }
    });

    // Listen for cart changes to update the UI
    _cartProvider.addListener(_onCartChanged);
    
    // Load user's default address
    _loadDefaultAddress();
  }
  
  @override
  void dispose() {
    // Dispose all animation controllers
    _itemAnimationControllers.forEach((_, controller) => controller.dispose());
    
    // Remove the cart listener
    _cartProvider.removeListener(_onCartChanged);
    
    super.dispose();
  }

  // Called when the cart is updated (like when quantity changes)
  void _onCartChanged() {
    if (mounted) {
      setState(() {
        // Update the total items count
        _totalItems = _cartProvider.cartItems.length;
        
        // Update the cart entries if needed
        final currentCartItems = _cartProvider.cartItems;
        
        // Check if any items were removed from the cart
        final updatedEntries = _cartEntries.where((entry) {
          return currentCartItems.containsKey(entry.key);
        }).toList();
        
        // Check if any quantities were changed
        for (var i = 0; i < updatedEntries.length; i++) {
          final productId = updatedEntries[i].key;
          final currentQuantity = currentCartItems[productId]?['quantity'] ?? 0;
          
          // Update the quantity in our cached entries
          if (updatedEntries[i].value['quantity'] != currentQuantity) {
            updatedEntries[i] = MapEntry(
              productId, 
              {...updatedEntries[i].value, 'quantity': currentQuantity}
            );
          }
        }
        
        _cartEntries = updatedEntries;
      });
    }
  }

  // Setup initial list of cart items with placeholders
  void _setupItemsList() {
    final cartItems = _cartProvider.cartItems;
    
    if (cartItems.isNotEmpty) {
      setState(() {
        // Create the initial list with all cart items
        _cartEntries = cartItems.entries.toList();
        
        // Setup animations for all items
        for (var entry in _cartEntries) {
          final productId = entry.key;
          
          // Initialize loading state
          _loadingState[productId] = true;
          
          // Create animation controller for this item
          _itemAnimationControllers[productId] = AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 300),
          );
        }
      });
    }
  }

  Future<void> _loadCartItems() async {
    final cartItems = _cartProvider.cartItems;
    int totalCount = 0;
    int removedCount = 0;
    int loadedItemsCount = 0;
    
    print('--- Cart Items Log ---');
    
    if (cartItems.isEmpty) {
      print('Cart is empty');
      setState(() {
        _allItemsLoaded = true;
      });
    } else {
      print('Total unique products in cart: ${cartItems.length}');
      
      // Calculate total quantity (all items)
      cartItems.forEach((_, item) {
        totalCount += (item['quantity'] as int? ?? 0);
      });
      
      // Set the total items to the unique item count
      setState(() {
        _totalItems = cartItems.length;
      });
      
      // Load product details for each item
      for (final entry in cartItems.entries) {
        final productId = entry.key;
        final quantity = entry.value['quantity'] as int? ?? 0;
        
        // Fetch product details from Firestore
        try {
          final product = await _productService.getProductById(productId);
          
          // Log product details
          print('\nProduct ID: $productId, Quantity: $quantity');
          if (product != null) {
            print('  Product name: ${product.name}');
            print('  Price: ${product.price}');
            print('  MRP: ${product.mrp ?? 'N/A'}');
            print('  Category: ${product.categoryName ?? 'N/A'}');
            
            // Fetch discount information
            try {
              final discountInfo = await DiscountService.getProductDiscountInfo(productId);
              if (discountInfo['hasDiscount'] == true) {
                print('  Discount: ${discountInfo['discountType']} - ${discountInfo['discountValue']}');
                print('  Final price after discount: ${discountInfo['finalPrice']}');
                setState(() {
                  _discountDetails[productId] = discountInfo;
                });
              }
            } catch (discountError) {
              print('  Error fetching discount information: $discountError');
            }
          } else {
            print('  Product details not found in Firestore');
            removedCount += quantity;
          }
          
          // Update this specific product's state
          setState(() {
            _productDetails[productId] = product;
            _loadingState[productId] = false;
            _removedItemsCount = removedCount;
          });
          
          // Increment loaded items count
          loadedItemsCount++;
          
          // Check if all items are loaded
          if (loadedItemsCount == cartItems.length) {
            await _handleAllItemsLoaded();
          }
        } catch (e) {
          print('  Error fetching product details: $e');
          setState(() {
            _loadingState[productId] = false;
          });
          
          // Increment loaded items count
          loadedItemsCount++;
          
          // Check if all items are loaded
          if (loadedItemsCount == cartItems.length) {
            await _handleAllItemsLoaded();
          }
        }
      }
      
      print('\nTotal number of items: $totalCount');
      print('\nRemoved items: $removedCount');
    }
    
    print('---------------------');
  }
  
  Future<void> _handleAllItemsLoaded() async {
    final unavailableProductIds = _productDetails.entries
        .where((entry) => entry.value == null)
        .map((entry) => entry.key)
        .toList();
    
    // Start animations for items to be removed
    for (var productId in unavailableProductIds) {
      if (_itemAnimationControllers.containsKey(productId)) {
        _itemAnimationControllers[productId]!.reverse();
      }
    }
    
    // Wait for animations to complete
    await Future.delayed(const Duration(milliseconds: 350));
    
    setState(() {
      // Filter out unavailable products
      _cartEntries = _cartEntries
          .where((entry) => _productDetails[entry.key] != null)
          .toList();
      
      _allItemsLoaded = true;
    });
  }

  // Remove unavailable products from both cache and Firebase
  Future<void> _removeUnavailableProducts() async {
    try {
      final unavailableProductIds = _productDetails.entries
          .where((entry) => entry.value == null)
          .map((entry) => entry.key)
          .toList();
      
      if (unavailableProductIds.isEmpty) return;
      
      // Calculate new total after removing unavailable items
      int newTotal = _totalItems - _removedItemsCount;
      
      // Remove each unavailable product
      for (var productId in unavailableProductIds) {
        await _cartService.removeItem(productId: productId);
        print('Removed unavailable product: $productId');
      }
      
      // Update total items count
      setState(() {
        _totalItems = newTotal;
        _productsRemoved = true;
        _showRemovedMessage = false; // Hide the removed message since we've cleaned up
      });
      
      // Reload cart items from provider to ensure UI is synced
      await _cartProvider.loadCartItems();
      
      print('Removed ${unavailableProductIds.length} unavailable products from cart');
    } catch (e) {
      print('Error removing unavailable products: $e');
    }
  }

  // Load the default address for the user
  Future<void> _loadDefaultAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_token');
      
      if (userId != null && userId.isNotEmpty) {
        // Check if we need to fetch user data from Firebase
        final cachedAddressData = prefs.getString('default_address');
        
        if (cachedAddressData != null) {
          // Use cached address data if available
          final addressData = Map<String, dynamic>.from(
            Map<String, dynamic>.from(
              jsonDecode(cachedAddressData)
            )
          );
          
          setState(() {
            _defaultAddress = Address(
              id: addressData['id'] ?? '',
              name: addressData['name'] ?? '',
              addressLine: addressData['addressLine'] ?? '',
              city: addressData['city'] ?? '',
              state: addressData['state'] ?? '',
              pincode: addressData['pincode'] ?? '',
              landmark: addressData['landmark'],
              isDefault: true,
              addressType: addressData['addressType'] ?? 'home',
            );
            _addressLoading = false;
          });
        } else {
          // Trigger user data loading if needed
          if (mounted && context.read<UserBloc>().state.user == null) {
            context.read<UserBloc>().add(LoadUserProfileEvent(userId));
          }
          
          // Listen to user bloc state changes
          Future.delayed(Duration.zero, () {
            final userState = context.read<UserBloc>().state;
            if (userState.user != null) {
              _updateAddressFromUserState(userState.user!);
            }
          });
        }
      }
    } catch (e) {
      print('Error loading default address: $e');
      setState(() {
        _addressLoading = false;
      });
    }
  }
  
  // Update address from user state
  void _updateAddressFromUserState(User user) {
    if (user.addresses.isNotEmpty) {
      // Find default address or use the first one
      final defaultAddress = user.addresses.firstWhere(
        (address) => address.isDefault,
        orElse: () => user.addresses.first,
      );
      
      setState(() {
        _defaultAddress = defaultAddress;
        _addressLoading = false;
      });
      
      // Cache the default address
      _cacheDefaultAddress(defaultAddress);
    } else {
      setState(() {
        _addressLoading = false;
      });
    }
  }
  
  // Cache the default address in SharedPreferences
  Future<void> _cacheDefaultAddress(Address address) async {
    try {
      final addressData = {
        'id': address.id,
        'name': address.name,
        'addressLine': address.addressLine,
        'city': address.city,
        'state': address.state,
        'pincode': address.pincode,
        'landmark': address.landmark,
        'addressType': address.addressType,
      };
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('default_address', jsonEncode(addressData));
    } catch (e) {
      print('Error caching default address: $e');
    }
  }

  // Calculate total cart value
  double _calculateTotalCartValue() {
    double total = 0.0;
    
    for (var entry in _cartEntries) {
      final productId = entry.key;
      final quantity = entry.value['quantity'] as int? ?? 0;
      final product = _productDetails[productId];
      
      if (product != null) {
        // Get the final price after discount
        double finalPrice = product.price;
        
        // Apply discount if available
        final hasDiscount = _discountDetails.containsKey(productId) && 
                          _discountDetails[productId]?['hasDiscount'] == true;
        
        if (hasDiscount) {
          final discountInfo = _discountDetails[productId]!;
          final discountType = discountInfo['discountType'];
          final discountValue = discountInfo['discountValue'];
          
          // Convert discount value to double
          double discountValueDouble = 0;
          if (discountValue is int) {
            discountValueDouble = discountValue.toDouble();
          } else if (discountValue is double) {
            discountValueDouble = discountValue;
          } else if (discountValue is String && double.tryParse(discountValue) != null) {
            discountValueDouble = double.parse(discountValue);
          }
          
          // Apply discount to the regular price
          if (discountType == 'percentage' && discountValueDouble > 0) {
            finalPrice = product.price - (product.price * (discountValueDouble / 100.0));
          } else if (discountType == 'flat' && discountValueDouble > 0) {
            finalPrice = product.price - discountValueDouble;
          }
          
          // Ensure price doesn't go negative
          if (finalPrice < 0) finalPrice = 0;
        }
        
        // Add to total (price multiplied by quantity)
        total += finalPrice * quantity;
      }
    }
    
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = _cartProvider.cartItems;
    
    // Calculate total values when rendering
    _totalCartValue = _calculateTotalCartValue();
    _totalSavings = _getTotalSavings();
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Your Cart', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.accentColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // Main content with cart items
          cartItems.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 64.r,
                      color: AppTheme.accentColor,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Your cart is empty',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  // Savings banner if cart has items and there are savings
                  if (_getTotalSavings() > 0)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 16.r, vertical: 10.r),
                      color: Colors.green.shade700,
                      child: Row(
                        children: [
                          Text(
                            '₹${_getTotalSavings().toInt()}',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'TOTAL SAVINGS',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Cart items list (takes remaining space minus the button height and bottom sections)
                  Expanded(
                    child: _cartEntries.isEmpty && _allItemsLoaded
                      ? Center(
                          child: Text(
                            'All items in your cart are unavailable',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: ListView.separated(
                                padding: EdgeInsets.only(bottom: 10.h, top: 10.h),
                                itemCount: _showAllItems ? _cartEntries.length : 
                                  (_cartEntries.length > 4 ? 5 : _cartEntries.length),
                                separatorBuilder: (context, index) => SizedBox(height: 1.h), // Reduced gap to 1 value
                                itemBuilder: (context, index) {
                                  // Handle "show more" button
                                  if (!_showAllItems && index == 4 && _cartEntries.length > 4) {
                                    return _buildShowMoreButton();
                                  }
                                  
                                  if (index >= (_showAllItems ? _cartEntries.length : 
                                      (_cartEntries.length > 4 ? 4 : _cartEntries.length))) {
                                    return const SizedBox.shrink();
                                  }
                                  
                                  final entry = _cartEntries[index];
                                  final productId = entry.key;
                                  final quantity = entry.value['quantity'] as int? ?? 0;
                                  final isLoading = _loadingState[productId] ?? true;
                                  final product = _productDetails[productId];
                                  
                                  // Wrap both loading and product cards in an elevated container
                                  return Card(
                                    elevation: 2.0,
                                    margin: EdgeInsets.symmetric(horizontal: 20.r), // Increased horizontal margin to 20
                                    color: AppTheme.secondaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.r), // Reduced border radius from 8.r to 4.r
                                    ),
                                    child: isLoading
                                        ? _buildLoadingCartItem()
                                        : (product != null)
                                            ? _buildCartItemCompact(productId, product, quantity)
                                            : const SizedBox.shrink(),
                                  );
                                },
                              ),
                            ),
                            
                            // Bottom sections for address and payment info
                            if (_cartEntries.isNotEmpty)
                              _buildBottomSections(),
                          ],
                        ),
                  ),
                ],
              ),
          
          // Remove the fixed button at the bottom since we now have the bottom sections
          /*
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: EdgeInsets.all(16.r),
              child: ElevatedButton(
                onPressed: () {
                  // No functionality for now
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
                child: Text(
                  'Click to Pay',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
          ),
          */
        ],
      ),
    );
  }

  // Build bottom sections for address and payment info
  Widget _buildBottomSections() {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          // Delivering to section
          Container(
            margin: EdgeInsets.only(left: 20.r, right: 20.r, bottom: 1.h, top: 10.h),
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: _buildDeliveryAddressSection(),
          ),
          
          // To Pay section
          Container(
            margin: EdgeInsets.only(left: 20.r, right: 20.r, bottom: 10.h),
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: _buildPaymentSummarySection(),
          ),
          
          // Click to Pay button
          Container(
            margin: EdgeInsets.fromLTRB(20.r, 5.h, 20.r, 30.h),
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton(
              onPressed: () {
                // No functionality for now
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFFC107), // More vibrant amber
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'Click to Pay',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Build the delivery address section
  Widget _buildDeliveryAddressSection() {
    return InkWell(
      onTap: () {
        // Navigate to address selection
        // This will be implemented later to select from existing addresses
        print('Navigate to address selection');
      },
      child: Padding(
        padding: EdgeInsets.all(12.r),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Icon(
                Icons.location_on_outlined,
                color: Color(0xFFFFC107), // More vibrant amber
                size: 22.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivering to ${_defaultAddress?.addressType.capitalize() ?? 'Other'}',
                    style: TextStyle(
                      fontSize: 14.sp, // Match product name size
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2.h), // Match product card spacing
                  if (_addressLoading)
                    ShimmerLoader(child: Container(
                      height: 10.h, // Smaller height to match product weight
                      width: 250.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ))
                  else if (_defaultAddress != null)
                    Text(
                      '${_defaultAddress!.addressLine.split(',').first}, ${_defaultAddress!.city}',
                      style: TextStyle(
                        fontSize: 10.sp, // Match product weight/quantity size
                        color: Colors.grey.shade400,
                        overflow: TextOverflow.ellipsis,
                      ),
                      maxLines: 1,
                    )
                  else
                    Text(
                      'No address found. Add an address to proceed.',
                      style: TextStyle(
                        fontSize: 10.sp, // Match product weight/quantity size
                        color: Colors.grey.shade400,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
              size: 22.sp,
            ),
          ],
        ),
      ),
    );
  }
  
  // Build the payment summary section
  Widget _buildPaymentSummarySection() {
    return InkWell(
      onTap: () {
        setState(() {
          _isPaymentExpanded = !_isPaymentExpanded;
        });
      },
      child: Column(
        children: [
          // To Pay summary row
          Padding(
            padding: EdgeInsets.all(12.r),
            child: Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Icon(
                    Icons.receipt_long_outlined,
                    color: Color(0xFFFFC107), // More vibrant amber
                    size: 22.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'To Pay',
                        style: TextStyle(
                          fontSize: 14.sp, // Match product name size
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2.h), // Match product card spacing
                      Text(
                        'Incl. all taxes and charges',
                        style: TextStyle(
                          fontSize: 10.sp, // Match product weight/quantity size
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        if (_totalSavings > 0)
                          Text(
                            '₹${(_totalCartValue + _totalSavings).toInt()}',
                            style: TextStyle(
                              fontSize: 11.sp, // Match strikethrough price in cart item
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        if (_totalSavings > 0)
                          SizedBox(width: 6.w),
                        Text(
                          '₹${_totalCartValue.toInt()}',
                          style: TextStyle(
                            fontSize: 14.sp, // Match price font size in cart item
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFC107), // More vibrant amber
                          ),
                        ),
                      ],
                    ),
                    if (_totalSavings > 0)
                      Text(
                        'SAVING ₹${_totalSavings.toInt()}',
                        style: TextStyle(
                          fontSize: 10.sp, // Match product weight/quantity size
                          fontWeight: FontWeight.w500,
                          color: Colors.green.shade400,
                        ),
                      ),
                  ],
                ),
                SizedBox(width: 8.w),
                Icon(
                  _isPaymentExpanded ? Icons.keyboard_arrow_up : Icons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 22.sp,
                ),
              ],
            ),
          ),
          
          // Expandable bill summary
          if (_isPaymentExpanded)
            _buildExpandedBillSummary(),
        ],
      ),
    );
  }
  
  // Build expanded bill summary section
  Widget _buildExpandedBillSummary() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.r, vertical: 10.r),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade800, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bill Summary header
          Padding(
            padding: EdgeInsets.only(bottom: 10.r),
            child: Row(
              children: [
                Icon(
                  Icons.receipt_outlined,
                  color: Colors.grey.shade400,
                  size: 18.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Bill Summary',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // Item Total & GST
          Padding(
            padding: EdgeInsets.symmetric(vertical: 6.r),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Item Total & GST',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(
                      Icons.info_outline,
                      color: Colors.grey.shade400,
                      size: 14.sp,
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (_totalSavings > 0)
                      Text(
                        '₹${(_totalCartValue + _totalSavings).toInt()}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    if (_totalSavings > 0)
                      SizedBox(width: 6.w),
                    Text(
                      '₹${_totalCartValue.toInt()}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Delivery Fee
          Padding(
            padding: EdgeInsets.symmetric(vertical: 6.r),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Delivery Fee',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '₹30',
                      style: TextStyle(
                        fontSize: 11.sp,
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      '₹0',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Free Delivery applied
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 8.r),
            child: Text(
              'Free Delivery applied!',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.green.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          // Divider
          Divider(color: Colors.grey.shade800, height: 1),
          
          // To Pay (Total)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10.r),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'To Pay',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Incl. all taxes and charges',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${_totalCartValue.toInt()}',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFC107),
                      ),
                    ),
                    if (_totalSavings > 0)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.r, vertical: 2.r),
                        decoration: BoxDecoration(
                          color: Colors.green.shade900.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                        child: Text(
                          'SAVING ₹${_totalSavings.toInt()}',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.green.shade400,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Dashed divider between cart items - no longer needed with card-based layout
  Widget _buildDashedDivider() {
    return SizedBox(height: 1.h);
  }
  
  // Calculate total savings (original price minus discounted price)
  double _getTotalSavings() {
    double totalOriginalCost = 0;
    double totalDiscountedCost = 0;
    
    for (var entry in _cartEntries) {
      final productId = entry.key;
      final quantity = entry.value['quantity'] as int? ?? 0;
      final product = _productDetails[productId];
      
      if (product != null) {
        // Get the original price (MRP if available, otherwise regular price)
        double originalPrice = product.price;
        
        // Start with regular price as the final price
        double finalPrice = product.price;
        
        // Apply discount if available
        final hasDiscount = _discountDetails.containsKey(productId) && 
                          _discountDetails[productId]?['hasDiscount'] == true;
        
        if (hasDiscount) {
          final discountInfo = _discountDetails[productId]!;
          final discountType = discountInfo['discountType'];
          final discountValue = discountInfo['discountValue'];
          
          // Convert discount value to double
          double discountValueDouble = 0;
          if (discountValue is int) {
            discountValueDouble = discountValue.toDouble();
          } else if (discountValue is double) {
            discountValueDouble = discountValue;
          } else if (discountValue is String && double.tryParse(discountValue) != null) {
            discountValueDouble = double.parse(discountValue);
          }
          
          // Apply discount to the regular price (not MRP)
          if (discountType == 'percentage' && discountValueDouble > 0) {
            finalPrice = product.price - (product.price * (discountValueDouble / 100.0));
          } else if (discountType == 'flat' && discountValueDouble > 0) {
            finalPrice = product.price - discountValueDouble;
          }
          
          // Ensure price doesn't go negative
          if (finalPrice < 0) finalPrice = 0;
        }
        
        // Add to running totals (multiplied by quantity)
        totalOriginalCost += originalPrice * quantity;
        totalDiscountedCost += finalPrice * quantity;
        
        print('Product: ${product.name}, Quantity: $quantity');
        print('  Original price: ₹$originalPrice x $quantity = ₹${(originalPrice * quantity).toStringAsFixed(2)}');
        print('  Final price: ₹$finalPrice x $quantity = ₹${(finalPrice * quantity).toStringAsFixed(2)}');
      }
    }
    
    // Calculate total savings as the difference
    double totalSavings = totalOriginalCost - totalDiscountedCost;
    
    print('SAVINGS CALCULATION:');
    print('  Total original cost: ₹${totalOriginalCost.toStringAsFixed(2)}');
    print('  Total discounted cost: ₹${totalDiscountedCost.toStringAsFixed(2)}');
    print('  Total savings: ₹${totalSavings.toStringAsFixed(2)}');
    
    return totalSavings;
  }
  
  // New compact cart item design
  Widget _buildCartItemCompact(String productId, Product product, int quantity) {
    // Calculate the final price with discount if applicable
    final discountInfo = _discountDetails[productId];
    final bool hasDiscount = discountInfo != null && discountInfo['hasDiscount'] == true;
    
    // Calculate the discounted price directly
    double finalPrice = product.price;
    double originalPrice = product.mrp ?? product.price;
    
    if (hasDiscount) {
      // Get discount type and value
      final discountType = discountInfo['discountType'];
      final discountValue = discountInfo['discountValue'];
      
      // Convert discount value to double
      double discountValueDouble = 0;
      if (discountValue is int) {
        discountValueDouble = discountValue.toDouble();
      } else if (discountValue is double) {
        discountValueDouble = discountValue;
      } else if (discountValue is String && double.tryParse(discountValue) != null) {
        discountValueDouble = double.parse(discountValue);
      }
      
      // Apply discount based on type
      if (discountType == 'percentage' && discountValueDouble > 0) {
        // Calculate percentage discount
        final discount = product.price * (discountValueDouble / 100.0);
        finalPrice = product.price - discount;
      } else if (discountType == 'flat' && discountValueDouble > 0) {
        // Apply flat discount
        finalPrice = product.price - discountValueDouble;
      }
    }
    
    // Format product weight/quantity info
    String quantityInfo = product.weight ?? '';
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.r, vertical: 8.r), // Reduced vertical padding
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Section 1: 70% - Image and product details
          Row(
            children: [
              // Product image (approximately 25% of total)
              SizedBox(
                width: 65.w, // Reduced width
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2.r), // Reduced border radius from 4.r to 2.r
                    child: SizedBox(
                      width: 45.w, // Reduced image size
                      height: 45.h, // Reduced image size
                      child: _buildProductImage(product),
                    ),
                  ),
                ),
              ),
              
              // Product details (approximately 45% of total)
              SizedBox(
                width: 130.w, // Reduced width
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Product name
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 12.sp, // Reduced font size
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: 2.h), // Reduced spacing
                    
                    // Product quantity
                    if (quantityInfo.isNotEmpty)
                      Text(
                        quantityInfo,
                        style: TextStyle(
                          fontSize: 10.sp, // Reduced font size
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          
          // Section 2: 20% - Add button
          SizedBox(
            width: 75.w,
            child: Center(
              child: SizedBox(
                width: 65.w, // Slightly reduced
                height: 25.h, // Reduced height
                child: AddButton(
                  productId: productId,
                  sourceCardType: ProductCardType.productDetails,
                  inStock: product.inStock,
                  fontSize: 10.sp, // Reduced font size
                ),
              ),
            ),
          ),
          
          // Section 3: 10% - Price information
          SizedBox(
            width: 55.w,
            child: Padding(
              padding: EdgeInsets.only(right: 1.w), // Add right padding
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end, // Align to the right side
                children: [
                  Text(
                    '₹${finalPrice.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 14.sp, // Reduced font size
                      fontWeight: FontWeight.bold,
                      color: hasDiscount && finalPrice < product.price ? Colors.green[700] : AppTheme.accentColor,
                    ),
                    textAlign: TextAlign.right, // Ensure text is right-aligned
                  ),
                  
                  SizedBox(height: 1.h), // Reduced spacing
                  
                  if (hasDiscount && finalPrice < product.price || (product.mrp != null && product.mrp! > finalPrice))
                    Text(
                      '₹${hasDiscount && finalPrice < product.price ? product.price.toStringAsFixed(0) : product.mrp!.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 11.sp, // Reduced font size
                        color: AppTheme.textSecondaryColor,
                        decoration: TextDecoration.lineThrough,
                      ),
                      textAlign: TextAlign.right, // Ensure text is right-aligned
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildShowMoreButton() {
    final remainingItems = _cartEntries.length - 4;
    
    return Card(
      elevation: 2.0,
      margin: EdgeInsets.symmetric(horizontal: 20.r), // Increased horizontal margin to 20
      color: AppTheme.secondaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4.r), // Reduced border radius from 8.r to 4.r
      ),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showAllItems = true;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16.r),
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor,
            borderRadius: BorderRadius.circular(4.r), // Reduced border radius from 8.r to 4.r
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '+ $remainingItems more ${remainingItems == 1 ? 'item' : 'items'}',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.accentColor,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: AppTheme.accentColor,
                  size: 20.r,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCartItem() {
    return Padding(
      padding: EdgeInsets.all(8.h), // Reduced padding
      child: ShimmerLoader.cartItem(
        height: 60.h, // Reduced height
      ),
    );
  }

  Widget _buildProductImage(Product product) {
    final imageUrl = product.image;
    
    // Check for Firebase Storage URLs that cause errors (gs:// format)
    if (imageUrl.startsWith('gs://')) {
      return _buildImageErrorWidget();
    }
    
    // Check if URL is valid
    if (!imageUrl.startsWith('http')) {
      return _buildImageErrorWidget();
    }
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(4.r), // Reduced border radius from 8.r to 4.r
      child: ImageLoader.network(
        imageUrl,
        fit: BoxFit.contain,
        width: 65.w, // Reduced size
        height: 65.h, // Reduced size
        errorWidget: _buildImageErrorWidget(),
      ),
    );
  }
  
  Widget _buildImageErrorWidget() {
    return Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        color: AppTheme.textSecondaryColor,
        size: 20.sp, // Reduced size
      ),
    );
  }
}

// Add DashedLinePainter class below the CartPage class
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.accentColor.withOpacity(0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 5;
    const dashSpace = 3;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Extension method to capitalize the first letter of a string
extension StringExtension on String {
  String capitalize() {
    return this.isNotEmpty ? '${this[0].toUpperCase()}${this.substring(1)}' : '';
  }
}

