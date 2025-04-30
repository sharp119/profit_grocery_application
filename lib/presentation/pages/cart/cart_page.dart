import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../services/cart_provider.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CartProvider _cartProvider = CartProvider();
  int _totalItems = 0;

  @override
  void initState() {
    super.initState();
    _logCartItems();
  }

  void _logCartItems() {
    final cartItems = _cartProvider.cartItems;
    int totalCount = 0;
    
    print('--- Cart Items Log ---');
    
    if (cartItems.isEmpty) {
      print('Cart is empty');
    } else {
      cartItems.forEach((productId, itemData) {
        final quantity = itemData['quantity'] as int? ?? 0;
        totalCount += quantity;
        print('Product ID: $productId, Quantity: $quantity');
      });
      
      print('Total number of items: $totalCount');
    }
    
    print('---------------------');
    
    setState(() {
      _totalItems = totalCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),  
      ),
      body: Center(
        child: Text(
          _totalItems > 0 
              ? 'Cart contains $_totalItems items' 
              : 'Cart is empty',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

