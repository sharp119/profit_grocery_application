import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/product.dart';
import '../../../services/cart_provider.dart';
import '../../../services/product/shared_product_service.dart';
import '../../../services/simple_cart_service.dart';
import '../../../services/discount/discount_service.dart';
import '../../widgets/loaders/shimmer_loader.dart';
import '../../widgets/image_loader.dart';
import '../../widgets/buttons/add_button.dart';

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
  
  // Final list of products after filtering out unavailable ones
  late List<MapEntry<String, dynamic>> _cartEntries = [];

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

  @override
  Widget build(BuildContext context) {
    final cartItems = _cartProvider.cartItems;
    
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
                  // Savings banner if cart has items
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 16.r, vertical: 10.r),
                    color: AppTheme.accentColor.withOpacity(0.8),
                    child: Row(
                      children: [
                        Text(
                          '₹${(_getTotalSavings() > 0 ? _getTotalSavings() : 0).toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'SAVINGS ON THIS ORDER',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Cart items list (takes remaining space minus the button height)
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
                      : ListView.separated(
                          padding: EdgeInsets.only(bottom: 80.h, top: 10.h), // Added top padding
                          itemCount: _showAllItems ? _cartEntries.length : 
                            (_cartEntries.length > 4 ? 5 : _cartEntries.length),
                          separatorBuilder: (context, index) => SizedBox(height: 8.h), // Gap between elevated cards
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
                              margin: EdgeInsets.symmetric(horizontal: 10.r),
                              color: AppTheme.secondaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
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
                ],
              ),
          
          // Fixed "Select Address" button at the bottom
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
                  'Select Address',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
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
    double savings = 0;
    
    for (var entry in _cartEntries) {
      final productId = entry.key;
      final quantity = entry.value['quantity'] as int? ?? 0;
      final product = _productDetails[productId];
      
      if (product != null) {
        final hasDiscount = _discountDetails.containsKey(productId) && 
                            _discountDetails[productId]?['hasDiscount'] == true;
        final originalPrice = product.mrp ?? product.price;
        
        if (hasDiscount) {
          final discountInfo = _discountDetails[productId]!;
          
          // Calculate the final price with discount
          double finalPrice = product.price;
          final discountType = discountInfo['discountType'];
          final discountValue = discountInfo['discountValue'];
          
          if (discountType == 'percentage' && discountValue is num) {
            finalPrice = product.price - (product.price * (discountValue / 100));
          } else if (discountType == 'flat' && discountValue is num) {
            finalPrice = product.price - discountValue;
          }
          
          savings += (originalPrice - finalPrice) * quantity;
        } else if (product.mrp != null && product.mrp! > product.price) {
          savings += (product.mrp! - product.price) * quantity;
        }
      }
    }
    
    return savings;
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
      padding: EdgeInsets.symmetric(horizontal: 8.r, vertical: 12.r), // Adjusted padding
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Section 1: 70% - Image and product details
          Row(
            children: [
              // Product image (approximately 25% of total)
              SizedBox(
                width: 75.w,
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: SizedBox(
                      width: 55.w,
                      height: 55.h,
                      child: _buildProductImage(product),
                    ),
                  ),
                ),
              ),
              
              // Product details (approximately 45% of total)
              SizedBox(
                width: 140.w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Product name
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: 4.h),
                    
                    // Product quantity
                    if (quantityInfo.isNotEmpty)
                      Text(
                        quantityInfo,
                        style: TextStyle(
                          fontSize: 11.sp,
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
                width: 68.w,
                height: 28.h,
                child: AddButton(
                  productId: productId,
                  sourceCardType: ProductCardType.productDetails,
                  inStock: product.inStock,
                  fontSize: 11.sp,
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
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: hasDiscount && finalPrice < product.price ? Colors.green[700] : AppTheme.accentColor,
                    ),
                    textAlign: TextAlign.right, // Ensure text is right-aligned
                  ),
                  
                  SizedBox(height: 2.h),
                  
                  if (hasDiscount && finalPrice < product.price || (product.mrp != null && product.mrp! > finalPrice))
                    Text(
                      '₹${hasDiscount && finalPrice < product.price ? product.price.toStringAsFixed(0) : product.mrp!.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12.sp,
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
      margin: EdgeInsets.symmetric(horizontal: 10.r),
      color: AppTheme.secondaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
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
            borderRadius: BorderRadius.circular(8.r),
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
      padding: EdgeInsets.all(12.h),
      child: ShimmerLoader.cartItem(
        height: 80.h,
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
      borderRadius: BorderRadius.circular(8.r),
      child: ImageLoader.network(
        imageUrl,
        fit: BoxFit.contain,
        width: 80.w,
        height: 80.h,
        errorWidget: _buildImageErrorWidget(),
      ),
    );
  }
  
  Widget _buildImageErrorWidget() {
    return Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        color: AppTheme.textSecondaryColor,
        size: 24.sp,
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

