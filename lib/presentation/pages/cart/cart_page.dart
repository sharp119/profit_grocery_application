import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/product.dart';
import '../../../services/cart_provider.dart';
import '../../../services/product/shared_product_service.dart';
import '../../../services/simple_cart_service.dart';
import '../../widgets/loaders/shimmer_loader.dart';
import '../../widgets/image_loader.dart';

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
  
  int _totalItems = 0;
  int _removedItemsCount = 0;
  bool _allItemsLoaded = false;
  bool _showRemovedMessage = true;
  bool _productsRemoved = false;
  
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
  }
  
  @override
  void dispose() {
    // Dispose all animation controllers
    _itemAnimationControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
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
      
      // Calculate total items
      cartItems.forEach((_, item) {
        totalCount += (item['quantity'] as int? ?? 0);
      });
      
      setState(() {
        _totalItems = totalCount;
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
        title: const Text('Cart'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: cartItems.isEmpty
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
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Cart Items',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.r, vertical: 6.r),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor,
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Text(
                          '$_totalItems items',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Show removed items message if any items were removed and loading is complete
                if (_allItemsLoaded && _removedItemsCount > 0 && _showRemovedMessage)
                  AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(horizontal: 16.r, vertical: 8.r),
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: Colors.red.shade800,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.white,
                            size: 20.r,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              '${_removedItemsCount} ${_removedItemsCount == 1 ? 'item' : 'items'} unavailable and ${_productsRemoved ? 'removed from cart' : 'not shown'}',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _showRemovedMessage = false;
                              });
                            },
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20.r,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
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
                      : AnimatedList(
                          key: GlobalKey<AnimatedListState>(),
                          initialItemCount: _cartEntries.length,
                          padding: EdgeInsets.symmetric(horizontal: 16.r, vertical: 16.r),
                          itemBuilder: (context, index, animation) {
                            if (index >= _cartEntries.length) {
                              return const SizedBox.shrink();
                            }

                            final entry = _cartEntries[index];
                            final productId = entry.key;
                            final quantity = entry.value['quantity'] as int? ?? 0;
                            final isLoading = _loadingState[productId] ?? true;
                            final product = _productDetails[productId];
                            
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(1, 0),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOut,
                                ),
                              ),
                              child: FadeTransition(
                                opacity: animation,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: isLoading
                                      ? _buildLoadingCartItem()
                                      : (product != null)
                                          ? _buildCartItem(productId, product, quantity)
                                          : const SizedBox.shrink(),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildLoadingCartItem() {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: ShimmerLoader.cartItem(
        height: 120.h,
      ),
    );
  }

  Widget _buildCartItem(String productId, Product product, int quantity) {
    return Container(
      key: ValueKey('cartItem_$productId'),
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image with background color
          Container(
            width: 80.w,
            height: 80.h,
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: _buildProductImage(product),
          ),
          SizedBox(width: 12.w),
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                if (product.categoryName != null)
                  Text(
                    product.categoryName!,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Text(
                      '₹${product.price}',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentColor,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    if (product.mrp != null && product.mrp! > product.price)
                      Text(
                        '₹${product.mrp}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppTheme.textSecondaryColor,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Quantity Badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.r, vertical: 6.r),
            decoration: BoxDecoration(
              color: AppTheme.accentColor,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Text(
              'Qty: $quantity',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
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

