import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:convert';
import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/product.dart';
import '../../../services/cart_provider.dart';
import '../../../services/simple_cart_service.dart';
import '../../widgets/loaders/shimmer_loader.dart';
import '../../widgets/image_loader.dart';
import '../../widgets/buttons/add_button.dart';
import '../../../domain/entities/user.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../../blocs/user/user_bloc.dart';
import '../../blocs/user/user_event.dart';
import 'package:provider/provider.dart';
import '../profile/address_form_page.dart';
import '../checkout/checkout_page.dart';
import '../../../services/rtdb_product_service.dart'; // Your new service


class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> with TickerProviderStateMixin {
  final CartProvider _cartProvider = CartProvider();
  // final SharedProductService _productService = SharedProductService();

  final RTDBProductService _rtdbProductService = RTDBProductService();
final FirebaseDatabase _database = FirebaseDatabase.instance;
  
  

  bool _showAllItems = false;
  bool _isPaymentExpanded = false;
  
  // Final list of products after filtering out unavailable ones
  // late List<MapEntry<String, dynamic>> _cartEntries = [];
  
  // Address and total payment information
  Address? _defaultAddress;
  bool _addressLoading = true;
  double _totalCartValue = 0;
  double _totalSavings = 0;

  // Add this variable to track if all products are loaded

  List<String> _cartProductIds = [];
Map<String, int> _cartQuantities = {}; // Key: ProductID, Value: Quantity in cart

// For storing the fully parsed Product objects fetched from RTDB:
List<Product> _rtdbProductDetails = []; // This replaces the old _productDetails map

// Stream subscriptions:
StreamSubscription? _rtdbStreamSubscription;
// StreamSubscription? _cartProviderListenerSubscription; // For CartProvider listener

// UI and general loading states:
// Remove: final Map<String, bool> _loadingState = {}; // Individual loading state
// Remove: final Map<String, Product?> _productDetails = {}; // Replaced by _rtdbProductDetails
bool _isProductDataLoading = true; // True while initially fetching cart product details

// Keep other relevant UI state variables:
final Map<String, AnimationController> _itemAnimationControllers = {}; // Keep if animations are used
int _totalItemsInCartProvider = 0; // Keep or derive from _cartProductIds.length
// int _removedItemsCount = 0; // Logic for this will change
// bool _showRemovedMessage = true; // Logic for this will change
// bool _productsRemoved = false; // Logic for this will change


  @override
  void initState() {
    super.initState();

  _cartProvider.addListener(_onCartProviderChanged); // for addListener method
  _initializeCartDataAndSetupRTDBStream();
    
    // Load user's default address
    _loadDefaultAddress();
  }
  
  @override
void dispose() {
  _cartProvider.removeListener(_onCartProviderChanged);
  _rtdbStreamSubscription?.cancel();
  _itemAnimationControllers.forEach((_, controller) => controller.dispose());
  super.dispose();
}

// In _CartPageState
void _updateLocalCartIdsAndQuantities() {
  final cartItemsFromProvider = _cartProvider.cartItems; // Assuming Map<String, dynamic>
                                                      // where dynamic might be a Map {'quantity': int}
                                                      // or just int for quantity. Adjust parsing accordingly.
  _cartProductIds = cartItemsFromProvider.keys.toList();
  _cartQuantities = cartItemsFromProvider.map((productId, itemData) {
    int quantity = 0;
    if (itemData is Map && itemData['quantity'] is int) {
      quantity = itemData['quantity'];
    } else if (itemData is int) { // If CartProvider stores quantity directly
      quantity = itemData;
    }
    // Ensure animation controller exists if product is in cart
    if (!_itemAnimationControllers.containsKey(productId)) {
        _itemAnimationControllers[productId] = AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 300),
        );
    }
    return MapEntry(productId, quantity);
  });
  _totalItemsInCartProvider = _cartProductIds.length; // Number of unique product types
}

// In _CartPageState
Future<void> _fetchAndMergeProductDetails(List<String> productIdsToFetch) async {
  if (productIdsToFetch.isEmpty || !mounted) return;

  if (mounted) setState(() => _isProductDataLoading = true);

  try {
    final fetchedProducts = await _rtdbProductService.getProductsDetails(productIdsToFetch);
    if (!mounted) return;

    setState(() {
      for (var newProduct in fetchedProducts) {
        // Only add/update if the product is still meant to be in the cart
        if (_cartProductIds.contains(newProduct.id)) {
          final index = _rtdbProductDetails.indexWhere((p) => p.id == newProduct.id);
          if (index != -1) {
            _rtdbProductDetails[index] = newProduct; // Update
          } else {
            _rtdbProductDetails.add(newProduct); // Add new
          }
        }
      }
      // Clean up: ensure _rtdbProductDetails only contains products currently in _cartProductIds
      _rtdbProductDetails.retainWhere((p) => _cartProductIds.contains(p.id));
      _isProductDataLoading = false;
      _recalculateCartTotals();
    });
  } catch (e) {
    print("CartPage Error: _fetchAndMergeProductDetails failed: $e");
    if (mounted) setState(() => _isProductDataLoading = false);
  }
}

// In _CartPageState
void _setupRTDBProductStream() {
  _rtdbStreamSubscription?.cancel(); // Cancel any existing subscription

  if (_cartProductIds.isEmpty) {
    if (mounted) {
      setState(() {
        _rtdbProductDetails = [];
        _isProductDataLoading = false; // Cart is empty, so data loading is "complete"
        _recalculateCartTotals();
      });
    }
    return;
  }

  // Perform an initial fetch for all products currently in the cart
  _fetchAndMergeProductDetails(List.from(_cartProductIds)); // Pass a copy

  // Listen for real-time updates on the entire `dynamic_product_info` node
  _rtdbStreamSubscription = _database.ref('dynamic_product_info').onValue.listen(
    (DatabaseEvent event) {
      if (!mounted || event.snapshot.value == null) return;

      final allProductsDataFromRTDB = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
      bool cartDisplayNeedsUpdate = false;
      List<Product> newListOfProductDetails = List.from(_rtdbProductDetails);

      for (String currentProductIdInCart in _cartProductIds) {
        if (allProductsDataFromRTDB.containsKey(currentProductIdInCart)) {
          final rtdbProductData = Map<dynamic, dynamic>.from(allProductsDataFromRTDB[currentProductIdInCart] as Map);
          final parsedProductFromRTDB = _rtdbProductService.parseProductFromRTDB(currentProductIdInCart, rtdbProductData);

          if (parsedProductFromRTDB != null) {
            final existingProductIndex = newListOfProductDetails.indexWhere((p) => p.id == currentProductIdInCart);
            if (existingProductIndex != -1) {
              // Check if product data actually changed (assuming Product has '==' override)
              if (newListOfProductDetails[existingProductIndex] != parsedProductFromRTDB) {
                newListOfProductDetails[existingProductIndex] = parsedProductFromRTDB;
                cartDisplayNeedsUpdate = true;
              }
            } else {
              // Product was likely just added to cart, and this is its first detailed data
              newListOfProductDetails.add(parsedProductFromRTDB);
              cartDisplayNeedsUpdate = true;
            }
          }
        } else {
          // Product is in cart, but no longer in dynamic_product_info or data is null
          // Consider it unavailable for display. Remove it from our details list.
          final int removedIndex = newListOfProductDetails.indexWhere((p) => p.id == currentProductIdInCart);
          if (removedIndex != -1) {
              newListOfProductDetails.removeAt(removedIndex);
              cartDisplayNeedsUpdate = true;
              print("Product $currentProductIdInCart (in cart) not found in RTDB stream update. Removing from display.");
              // Optionally: Trigger its removal from the actual cart via _cartService if this state persists
              // _cartService.removeItem(productId: currentProductIdInCart);
              // This could lead to loops if not handled carefully with _onCartProviderChanged
          }
        }
      }

      // Ensure the displayed products list only contains items that are currently in _cartProductIds
      // This handles cases where items were removed from cart by CartProvider between stream events.
      int listLengthBeforeRetain = newListOfProductDetails.length;
      newListOfProductDetails.retainWhere((p) => _cartProductIds.contains(p.id));
      if (newListOfProductDetails.length != listLengthBeforeRetain) {
          cartDisplayNeedsUpdate = true;
      }


      if (cartDisplayNeedsUpdate && mounted) {
        setState(() {
          _rtdbProductDetails = newListOfProductDetails;
          _recalculateCartTotals(); // Recalculate totals after any product detail update
        });
      }
    },
    onError: (error) {
      print("CartPage RTDB Stream Error: $error");
      if (mounted) setState(() => _isProductDataLoading = false); // Update loading state on error
    }
  );
}

// In _CartPageState
void _recalculateCartTotals() {
  double newTotalValue = 0.0;
  double newTotalSavings = 0.0;

  for (Product product in _rtdbProductDetails) {
    final quantity = _cartQuantities[product.id] ?? 0;
    if (quantity > 0) {
      // product.price is the final price after discounts, parsed by RTDBProductService
      newTotalValue += product.price * quantity;

      // product.mrp is set by RTDBProductService only if a discount was applied making it different from final price
      // Or, use customProperties['rawMrp'] if you stored it for a consistent original price.
      double originalPrice = product.customProperties?['rawMrp'] as double? ?? product.price;
      if (product.mrp != null) { // This means a discount was applied that made product.price < product.mrp
        originalPrice = product.mrp!; // This was the price before discount
      } else if (product.customProperties?['rawMrp'] != null) {
        originalPrice = product.customProperties!['rawMrp'];
      }
      // If neither mrp is set (because finalPrice == mrp) nor rawMrp is available,
      // then savings for this item (based on displayed strikethrough) is 0.
      // We only account for savings if product.price < originalPrice.
      if (product.price < originalPrice) {
        newTotalSavings += (originalPrice - product.price) * quantity;
      }
    }
  }

  if (mounted) { // Check if widget is still in tree
      setState(() {
        _totalCartValue = newTotalValue;
        _totalSavings = newTotalSavings;
      });
  }
  _saveCartTotals(); // Save to SharedPreferences
}

// Ensure _saveCartTotals uses the updated _totalCartValue, _totalSavings,
// and for itemCount, use _cartProductIds.length or sum of _cartQuantities.values
Future<void> _saveCartTotals() async {
    try {
        final prefs = await SharedPreferences.getInstance();
        final cartTotalsData = { // Corrected key name
            'subtotal': _totalCartValue, // Or calculate subtotal before any cart-level discounts if applicable
            'discount': _totalSavings, // This represents item-level savings
            'total': _totalCartValue,
            'itemCount': _cartQuantities.values.fold(0, (sum, q) => sum + q), // Total quantity of all items
            // 'uniqueItemCount': _cartProductIds.length, // If you need this separately
        };
        await prefs.setString('cart_totals', jsonEncode(cartTotalsData));
        // print('Saved cart totals to SharedPreferences: $cartTotalsData');
    } catch (e) {
        print('Error saving cart totals: $e');
    }
}

// In _CartPageState
void _initializeCartDataAndSetupRTDBStream() {
  _updateLocalCartIdsAndQuantities();
  _setupRTDBProductStream();
}

// In _CartPageState
void _onCartProviderChanged() {
  if (!mounted) return;

  final Set<String> oldProductIds = _cartProductIds.toSet();
  _updateLocalCartIdsAndQuantities(); // Updates _cartProductIds & _cartQuantities from _cartProvider

  final Set<String> newProductIds = _cartProductIds.toSet();

  final List<String> addedIds = newProductIds.difference(oldProductIds).toList();
  final List<String> removedIds = oldProductIds.difference(newProductIds).toList();

  setState(() {
    // 1. Remove details for products no longer in the cart
    _rtdbProductDetails.removeWhere((product) => removedIds.contains(product.id));

    // 2. Animation controllers for removed items (if you keep this logic)
    for (var id in removedIds) {
      _itemAnimationControllers[id]?.dispose();
      _itemAnimationControllers.remove(id);
    }

    // 3. Fetch details for newly added product IDs
    if (addedIds.isNotEmpty) {
      // Setup animation controllers for new items
      for (var id in addedIds) {
        _itemAnimationControllers[id] = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 300),
        );
      }
      _fetchAndMergeProductDetails(addedIds); // Fetch details for these new IDs
    }
    _recalculateCartTotals(); // Recalculate totals as items/quantities have changed
  });
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



  // Show address selection modal
  void _showAddressSelection() async {
    final userState = context.read<UserBloc>().state;
    final user = userState.user;
    
    if (user == null || user.addresses.isEmpty) {
      // If no addresses, navigate to add address page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AddressFormPage(isEditing: false),
        ),
      );
      return;
    }
    
    // Show modal bottom sheet with addresses
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      enableDrag: true,
      elevation: 20,
      transitionAnimationController: AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
        reverseDuration: const Duration(milliseconds: 200),
      ),
      builder: (context) => AddressSelectionModal(
        addresses: user.addresses,
        selectedAddressId: _defaultAddress?.id,
        onAddressSelected: (address) {
          setState(() {
            _defaultAddress = address;
          });
          _cacheDefaultAddress(address);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
@override
Widget build(BuildContext context) {
  // The totals are now recalculated in _recalculateCartTotals whenever data changes,
  // and _totalCartValue and _totalSavings are state variables.
  // So, no need to call _calculateTotalCartValue() or _getTotalSavings() directly here
  // unless _recalculateCartTotals() isn't being called at the right times (it should be).
  // However, _saveCartTotals() might still be relevant if you want to save on every build,
  // or preferably, call it only when totals actually change (e.g., inside _recalculateCartTotals).
  // For simplicity, if _recalculateCartTotals updates state, this build method will use the latest state.

  // Determine if the cart is logically empty based on product IDs from CartProvider
  final bool isCartLogicallyEmpty = _cartProductIds.isEmpty;

  // Determine if we have product details to display
  final bool hasDisplayableProductDetails = _rtdbProductDetails.isNotEmpty;

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
        if (_isProductDataLoading && !hasDisplayableProductDetails && !isCartLogicallyEmpty)
          // Show a central loader ONLY if data is loading,
          // there are no details yet to show, AND the cart isn't supposed to be empty.
          Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
        else if (isCartLogicallyEmpty)
          // Cart is empty according to CartProvider
          Center(
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
        else // Cart has items, attempt to display them
          Column(
            children: [
              // Savings banner (uses _totalSavings state variable)
              if (_totalSavings > 0)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 16.r, vertical: 10.r),
                  color: Colors.green.shade700,
                  child: Row(
                    children: [
                      Text(
                        '₹${_totalSavings.toInt()}',
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

              // Cart items list
              Expanded(
                child: !hasDisplayableProductDetails && !_isProductDataLoading
                  // This case means loading finished, but no valid product details were found
                  // for the items that are supposed to be in the cart.
                  ? Center(
                      child: Text(
                        'Items in your cart are currently unavailable.',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: AppTheme.textSecondaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            padding: EdgeInsets.only(bottom: 10.h, top: 10.h),
                            // Determine itemCount based on _rtdbProductDetails and _showAllItems
                            itemCount: _showAllItems
                                ? _rtdbProductDetails.length
                                : (_rtdbProductDetails.length > 4 ? 5 : _rtdbProductDetails.length),
                            separatorBuilder: (context, index) => SizedBox(height: 1.h),
                            itemBuilder: (context, index) {
                              // Handle "show more" button
                              if (!_showAllItems && index == 4 && _rtdbProductDetails.length > 4) {
                                // Pass the actual remaining count based on _rtdbProductDetails
                                return _buildShowMoreButton(_rtdbProductDetails.length - 4);
                              }

                              // Boundary check for the actual items
                              if (index >= _rtdbProductDetails.length) {
                                return const SizedBox.shrink(); // Should not happen if itemCount is correct
                              }

                              final product = _rtdbProductDetails[index];
                              final quantity = _cartQuantities[product.id] ?? 0;

                              // If for some reason quantity is 0, or product is not in _cartProductIds anymore, don't show
                              // (though _rtdbProductDetails should be kept in sync with _cartProductIds)
                              if (quantity == 0 || !_cartProductIds.contains(product.id)) {
                                return const SizedBox.shrink();
                              }

                              // The old `_loadingState[productId]` is no longer used.
                              // We rely on `_isProductDataLoading` for overall loading,
                              // and `_rtdbProductDetails` containing the loaded product.
                              return Card(
                                elevation: 2.0,
                                margin: EdgeInsets.symmetric(horizontal: 20.r),
                                color: AppTheme.secondaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: _buildCartItemCompact(product.id, product, quantity),
                              );
                            },
                          ),
                        ),

                        // Bottom sections for address and payment info
                        // Only show if there are items to display and product data isn't in its initial loading phase
                        // or if it is loading but we already have some items to show.
                        if (hasDisplayableProductDetails)
                          _buildBottomSections(),
                      ],
                    ),
              ),
            ],
          ),
      ],
    ),
  );
}
  // Build bottom sections for address and payment info
  // In _buildBottomSections method, update the "Click to Pay" button's onPressed condition:
Widget _buildBottomSections() {
  return Container(
    color: Colors.black,
    child: Column(
      children: [
        // ... (Delivering to section - _buildDeliveryAddressSection()) ...
        Container(
          margin: EdgeInsets.only(left: 20.r, right: 20.r, bottom: 1.h, top: 10.h),
          decoration: BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(4.r),
          ),
          child: _buildDeliveryAddressSection(),
        ),

        // ... (To Pay section - _buildPaymentSummarySection()) ...
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
            // Disable button if product data is still loading OR if the cart is logically empty
            onPressed: _isProductDataLoading || _cartProductIds.isEmpty
              ? null // Button disabled
              : () {
                  _saveAddressToPrefs(); // Ensure this is defined or uses _defaultAddress
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CheckoutPage(),
                    ),
                  );
                },
            style: ElevatedButton.styleFrom(
              backgroundColor: (_isProductDataLoading || _cartProductIds.isEmpty)
                ? Colors.grey.shade700 // Disabled color
                : Color(0xFFFFC107),  // Enabled color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: _isProductDataLoading && _cartProductIds.isNotEmpty // Show loading only if cart has items but details are loading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.w,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade400),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      'Loading prices...',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                )
              : Text(
                  'Click to Pay',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: (_cartProductIds.isEmpty) ? Colors.grey.shade400 : Colors.black,
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
        // Show address selection dialog
        _showAddressSelection();
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_defaultAddress!.addressLine.split(',').first}, ${_defaultAddress!.city}',
                          style: TextStyle(
                            fontSize: 10.sp, // Match product weight/quantity size
                            color: Colors.grey.shade400,
                            overflow: TextOverflow.ellipsis,
                          ),
                          maxLines: 1,
                        ),
                        if (_defaultAddress!.phone != null)
                          Text(
                            'Phone: ${_defaultAddress!.phone}',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.grey.shade400,
                            ),
                          ),
                      ],
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

 
  // New compact cart item design
// In _CartPageState
Widget _buildCartItemCompact(String productId, Product product, int quantityInCart) {
  // product.price IS the final price after discount application by the parser
  double displayFinalPrice = product.price;

  // product.mrp is set by the parser if a discount was applied making finalPrice < mrp
  // Or, use the 'rawMrp' from customProperties if you stored it for consistency
  double? originalPriceForStrikethrough = product.mrp ?? product.customProperties?['rawMrp'] as double?;

  bool showDiscountStrikethrough = originalPriceForStrikethrough != null &&
                                  originalPriceForStrikethrough > displayFinalPrice;

  // Check customProperties for actual discount application if needed for styling
  bool wasDiscountApplied = product.customProperties?['hasDiscount'] as bool? ?? false;

  String quantityInfo = product.weight ?? ''; // From product details

  return Container(
    padding: EdgeInsets.symmetric(horizontal: 8.r, vertical: 8.r),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Section 1: Image and product details
        Row(
          children: [
            SizedBox(
              width: 65.w,
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2.r),
                  child: SizedBox(
                    width: 45.w, height: 45.h,
                    child: _buildProductImage(product), // Pass the whole product
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 130.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: AppTheme.textPrimaryColor),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  if (quantityInfo.isNotEmpty)
                    Text(quantityInfo, style: TextStyle(fontSize: 10.sp, color: AppTheme.textSecondaryColor)),
                ],
              ),
            ),
          ],
        ),
        // Section 2: Add button
        SizedBox(
          width: 75.w,
          child: Center(
            child: SizedBox(
              width: 65.w, height: 25.h,
              child: AddButton(
                productId: productId, // ID is still used by AddButton to interact with CartProvider
                sourceCardType: ProductCardType.productDetails,
                inStock: product.inStock, // From RTDB product details
                fontSize: 10.sp,
              ),
            ),
          ),
        ),
        // Section 3: Price information
        SizedBox(
          width: 55.w,
          child: Padding(
            padding: EdgeInsets.only(right: 1.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${displayFinalPrice.toStringAsFixed(0)}', // Use the final price
                  style: TextStyle(
                    fontSize: 14.sp, fontWeight: FontWeight.bold,
                    color: wasDiscountApplied ? Colors.green[700] : AppTheme.accentColor,
                  ),
                  textAlign: TextAlign.right,
                ),
                SizedBox(height: 1.h),
                if (showDiscountStrikethrough)
                  Text(
                    '₹${originalPriceForStrikethrough.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 11.sp, color: AppTheme.textSecondaryColor,
                      decoration: TextDecoration.lineThrough,
                    ),
                    textAlign: TextAlign.right,
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
  // Modify _buildShowMoreButton to accept remaining items count
Widget _buildShowMoreButton(int remainingItems) { // Accept remainingItems
  // final remainingItems = _rtdbProductDetails.length - 4; // Calculate inside or pass as parameter

  return Card(
    elevation: 2.0,
    margin: EdgeInsets.symmetric(horizontal: 20.r),
    color: AppTheme.secondaryColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4.r),
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
          borderRadius: BorderRadius.circular(4.r),
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

  

  // Save selected address to SharedPreferences for checkout page
  Future<void> _saveAddressToPrefs() async {
    try {
      if (_defaultAddress != null) {
        final prefs = await SharedPreferences.getInstance();
        final addressData = {
          'id': _defaultAddress!.id,
          'name': _defaultAddress!.name,
          'addressLine': _defaultAddress!.addressLine,
          'city': _defaultAddress!.city,
          'state': _defaultAddress!.state,
          'pincode': _defaultAddress!.pincode,
          'landmark': _defaultAddress!.landmark,
          'addressType': _defaultAddress!.addressType,
          'phone': _defaultAddress!.phone, // Add phone field
        };
        await prefs.setString('selected_address', jsonEncode(addressData));
        print('Saved selected address to SharedPreferences');
      }
    } catch (e) {
      print('Error saving address to SharedPreferences: $e');
    }
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

// Address selection modal class
class AddressSelectionModal extends StatefulWidget {
  final List<Address> addresses;
  final String? selectedAddressId;
  final Function(Address) onAddressSelected;

  const AddressSelectionModal({
    Key? key,
    required this.addresses,
    this.selectedAddressId,
    required this.onAddressSelected,
  }) : super(key: key);

  @override
  State<AddressSelectionModal> createState() => _AddressSelectionModalState();
}

class _AddressSelectionModalState extends State<AddressSelectionModal> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1.0 - _animation.value) * 100),
          child: Opacity(
            opacity: _animation.value,
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.secondaryColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ],
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.r),
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              
              // Header
              Container(
                padding: EdgeInsets.symmetric(vertical: 16.r, horizontal: 16.r),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.arrow_back,
                        color: AppTheme.accentColor,
                        size: 24.r,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Text(
                      'Select an Address',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Add Address button
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddressFormPage(isEditing: false),
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 16.r, horizontal: 16.r),
                  child: Row(
                    children: [
                      Container(
                        width: 40.r,
                        height: 40.r,
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add,
                          color: AppTheme.accentColor,
                          size: 24.r,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Text(
                        'Add Address',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Divider
              Divider(color: Colors.grey.shade800, height: 1),
              
              // Address type label
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 10.r, horizontal: 16.r),
                color: Colors.black,
                child: Text(
                  'SAVED ADDRESSES',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
              
              // Address list - scrollable with flexible height
              widget.addresses.isEmpty
                ? Padding(
                    padding: EdgeInsets.all(16.r),
                    child: Text(
                      'No saved addresses found.',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  )
                : Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.only(bottom: 16.r),
                      itemCount: widget.addresses.length,
                      separatorBuilder: (context, index) => Divider(
                        color: Colors.grey.shade800,
                        height: 1,
                        indent: 72.r,
                      ),
                      itemBuilder: (context, index) {
                        final address = widget.addresses[index];
                        final isSelected = address.id == widget.selectedAddressId;
                        
                        // Choose icon and color based on address type
                        IconData iconData;
                        Color iconColor;
                        switch (address.addressType.toLowerCase()) {
                          case 'home':
                            iconData = Icons.home_outlined;
                            iconColor = Colors.blue;
                            break;
                          case 'work':
                            iconData = Icons.work_outline;
                            iconColor = Colors.orange;
                            break;
                          default:
                            iconData = Icons.place_outlined;
                            iconColor = Colors.purple;
                        }
                        
                        return InkWell(
                          onTap: () => widget.onAddressSelected(address),
                          child: Container(
                            height: 96.r, // Fixed height for each address
                            padding: EdgeInsets.symmetric(vertical: 12.r, horizontal: 16.r),
                            color: isSelected ? Colors.black.withOpacity(0.5) : Colors.transparent,
                            child: Row(
                              children: [
                                // Address type icon
                                Container(
                                  width: 40.r,
                                  height: 40.r,
                                  decoration: BoxDecoration(
                                    color: iconColor.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    iconData,
                                    color: iconColor,
                                    size: 20.r,
                                  ),
                                ),
                                SizedBox(width: 16.w),
                                
                                // Address details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Address type
                                      Row(
                                        children: [
                                          Text(
                                            address.addressType.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.bold,
                                              color: iconColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 4.h),
                                      
                                      // Address text
                                      Text(
                                        address.addressLine,
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          color: Colors.white,
                                          height: 1.3,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 2.h),
                                      
                                      // City, State
                                      Text(
                                        '${address.city}, ${address.state}',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Radio button
                                Radio<String>(
                                  value: address.id,
                                  groupValue: widget.selectedAddressId,
                                  onChanged: (_) => widget.onAddressSelected(address),
                                  activeColor: AppTheme.accentColor,
                                  fillColor: WidgetStateProperty.resolveWith<Color>(
                                    (Set<WidgetState> states) {
                                      if (states.contains(WidgetState.selected)) {
                                        return AppTheme.accentColor;
                                      }
                                      return Colors.grey;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              
              // Bottom padding
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }
}

