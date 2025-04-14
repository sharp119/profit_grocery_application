import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/inventory/product_inventory.dart';
import '../../../data/inventory/similar_products.dart';
import '../../../data/models/product_model.dart';
import '../../../domain/entities/cart.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/repositories/cart_repository.dart';
import '../../../presentation/blocs/cart/cart_bloc.dart';
import '../../../presentation/blocs/cart/cart_event.dart';
import '../../../presentation/blocs/cart/cart_state.dart';
import '../../../services/cart/unified_cart_service.dart';
import '../../../utils/cart_logger.dart';
import 'product_card.dart';

/// A universal product card that works consistently across all screens
class UniversalProductCard extends StatefulWidget {
  // Product can be provided directly or by ID
  final Product? product;
  final String? productId;
  final VoidCallback onTap;
  final int quantity;
  final Color? backgroundColor;
  final bool useBackgroundColor;

  const UniversalProductCard({
    Key? key,
    this.product,
    this.productId,
    required this.onTap,
    this.quantity = 0,
    this.backgroundColor,
    this.useBackgroundColor = true,
  }) : assert(product != null || productId != null, "Either product or productId must be provided"),
       super(key: key);

  @override
  State<UniversalProductCard> createState() => _UniversalProductCardState();
}

class _UniversalProductCardState extends State<UniversalProductCard> {
  // Services and repositories
  late final UnifiedCartService _cartService = UnifiedCartService();
  
  // Local state
  late Product _displayProduct;
  String? _userId;
  int _currentQuantity = 0;
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _resolveProduct();
    _fetchUserId();
  }
  
  @override
  void didUpdateWidget(UniversalProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If widget properties changed, update the display product
    if (widget.product != oldWidget.product || widget.productId != oldWidget.productId) {
      _resolveProduct();
    }
    
    // If quantity explicitly changed from outside, update current quantity
    if (widget.quantity != oldWidget.quantity) {
      _currentQuantity = widget.quantity;
    }
  }
  
  // Resolve the product from either direct product or product ID
  void _resolveProduct() {
    try {
      if (widget.product != null) {
        _displayProduct = widget.product!;
        _isInitialized = true;
        
        // Once we have a product, fetch its quantity in cart
        _fetchProductQuantity();
      } else if (widget.productId != null) {
        // Get product from product inventory
        final products = ProductInventory.getAllProducts();
        try {
          final fetchedProduct = products.firstWhere((p) => p.id == widget.productId);
          _displayProduct = fetchedProduct;
          _isInitialized = true;
          
          // Once we have a product, fetch its quantity in cart
          _fetchProductQuantity();
        } catch (e) {
          // Product not found
          CartLogger.error('UNIVERSAL_PRODUCT_CARD', 'Product not found with ID: ${widget.productId}');
        }
      }
    } catch (e) {
      CartLogger.error('UNIVERSAL_PRODUCT_CARD', 'Error resolving product', e);
    }
  }
  
  // Fetch the user ID from SharedPreferences
  Future<void> _fetchUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userTokenKey);
      
      if (userId != null && userId.isNotEmpty) {
        _userId = userId;
        
        // Once we have a user ID, fetch product quantity
        _fetchProductQuantity();
      }
    } catch (e) {
      CartLogger.error('UNIVERSAL_PRODUCT_CARD', 'Error getting user ID', e);
    }
  }
  
  // Fetch the current quantity of this product in the cart
  Future<void> _fetchProductQuantity() async {
    if (!_isInitialized || !mounted) return;
    
    try {
      if (widget.quantity > 0) {
        // If quantity is provided and > 0, use it
        setState(() {
          _currentQuantity = widget.quantity;
        });
        return;
      }
      
      // Try to get quantity from cart bloc first (for reactivity)
      try {
        final cartBloc = BlocProvider.of<CartBloc>(context);
        final cartState = cartBloc.state;
        
        if (cartState.status == CartStatus.loaded) {
          final cartItem = cartState.items.where((item) => 
              item.productId == _displayProduct.id).toList();
          
          if (cartItem.isNotEmpty) {
            setState(() {
              _currentQuantity = cartItem.first.quantity;
            });
            return;
          }
        }
      } catch (_) {
        // CartBloc not available, continue to repository
      }
      
      // If we have the user ID, try to get quantity from repository
      if (_userId != null && _userId!.isNotEmpty) {
        final quantity = await _cartService.getProductQuantity(_userId!, _displayProduct.id);
        
        if (mounted) {
          setState(() {
            _currentQuantity = quantity;
          });
        }
      }
    } catch (e) {
      CartLogger.error('UNIVERSAL_PRODUCT_CARD', 'Error fetching product quantity', e);
    }
  }
  
  // Handle quantity changes
  void _handleQuantityChanged(int newQuantity) {
    try {
      if (_userId == null || _userId!.isEmpty) {
        CartLogger.error('UNIVERSAL_PRODUCT_CARD', 'User ID not available for updating cart');
        return;
      }
      
      CartLogger.log('UNIVERSAL_PRODUCT_CARD', 'Quantity changed: ${_displayProduct.name} from $_currentQuantity to $newQuantity');
      
      // Update local state immediately for responsive UI
      setState(() {
        _currentQuantity = newQuantity;
      });
      
      // Update cart using the unified cart service
      _cartService.updateCartQuantity(
        context: context,
        userId: _userId!,
        product: _displayProduct,
        quantity: newQuantity,
      );
      
      // Also update CartBloc directly if available
      try {
        final cartBloc = BlocProvider.of<CartBloc>(context);
        
        if (newQuantity <= 0) {
          cartBloc.add(RemoveFromCart(_displayProduct.id));
        } else {
          // First check if item exists in cart
          final cartState = cartBloc.state;
          final existingItem = cartState.items.where((item) => 
              item.productId == _displayProduct.id).toList();
          
          if (existingItem.isEmpty) {
            // Add to cart
            cartBloc.add(AddToCart(_displayProduct, newQuantity));
          } else {
            // Update quantity
            cartBloc.add(UpdateCartItemQuantity(_displayProduct.id, newQuantity));
          }
        }
      } catch (_) {
        // CartBloc not available, already handled by unified cart service
      }
    } catch (e) {
      CartLogger.error('UNIVERSAL_PRODUCT_CARD', 'Error handling quantity change', e);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      // Not initialized yet
      return const SizedBox.shrink();
    }
    
    // Get background color if needed
    Color? cardBackgroundColor;
    if (widget.useBackgroundColor) {
      cardBackgroundColor = widget.backgroundColor ?? _getBackgroundColor(_displayProduct);
    }
    
    // Main widget with bloc listener to keep in sync with cart changes
    return BlocListener<CartBloc, CartState>(
      listener: (context, state) {
        if (state.status == CartStatus.loaded) {
          // Update product quantity when cart changes
          final cartItem = state.items.where((item) => 
              item.productId == _displayProduct.id).toList();
          
          final newQuantity = cartItem.isEmpty ? 0 : cartItem.first.quantity;
          
          if (_currentQuantity != newQuantity) {
            setState(() {
              _currentQuantity = newQuantity;
            });
          }
        }
      },
      listenWhen: (previous, current) => true, // Always listen for changes
      child: ProductCard.fromEntity(
        product: _displayProduct,
        onTap: widget.onTap,
        onQuantityChanged: _handleQuantityChanged,
        quantity: _currentQuantity,
        backgroundColor: cardBackgroundColor,
      ),
    );
  }
  
  // Helper to get background color for product
  Color? _getBackgroundColor(Product product) {
    try {
      // Convert Product to ProductModel since SimilarProducts expects ProductModel
      final productModel = _convertToProductModel(product);
      return SimilarProducts.getColorForProduct(productModel);
    } catch (e) {
      return Colors.blueGrey.shade100; // Default fallback
    }
  }
  
  // Convert Product to ProductModel for compatibility
  ProductModel _convertToProductModel(Product product) {
    return ProductModel(
      id: product.id,
      name: product.name,
      image: product.image,
      description: product.description,
      price: product.price,
      mrp: product.mrp,
      inStock: product.inStock,
      categoryId: product.categoryId,
      subcategoryId: product.subcategoryId,
      tags: product.tags,
      isFeatured: product.isFeatured,
      isActive: product.isActive,
    );
  }
}
