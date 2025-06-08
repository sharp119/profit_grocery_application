// lib/presentation/pages/orders/orders_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:profit_grocery_application/core/constants/app_theme.dart';
import 'package:profit_grocery_application/presentation/blocs/orders/orders_bloc.dart';
import 'package:profit_grocery_application/presentation/blocs/orders/orders_event.dart';
import 'package:profit_grocery_application/presentation/blocs/orders/orders_state.dart';
import 'package:profit_grocery_application/domain/entities/order.dart'; // Import OrderEntity
import 'package:shared_preferences/shared_preferences.dart'; // Ensure this is imported
import 'package:profit_grocery_application/core/constants/app_constants.dart'; // Ensure this is imported



class OrdersPage extends StatefulWidget {
  // You might want to pass an initial tab index if you have multiple tabs
  // for "Current Orders" and "Past Orders". For now, we'll keep it simple.
  final int initialTab;

  const OrdersPage({Key? key, this.initialTab = 0}) : super(key: key);

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);

    // Fetch orders when the page initializes
    // You'll need to get the user ID from SharedPreferences or a UserBloc
    // For now, we'll assume a dummy userId or fetch it directly.
    // In a real app, this userId would come from a UserBloc state.
    _fetchOrders();
  }

void _fetchOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(AppConstants.userTokenKey); // This is how your app gets user ID

    if (userId == null || userId.isEmpty) {
      if (mounted) {
        context.read<OrdersBloc>().add(
          LoadOrders(userId: '', limit: 0) // Pass empty userId to trigger error handling in Bloc
        );
      }
      return;
    }

    if (mounted) {
      context.read<OrdersBloc>().add(LoadOrders(userId: userId));
    }
}

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('My Orders', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.accentColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.accentColor,
          unselectedLabelColor: Colors.grey.shade400,
          indicatorColor: AppTheme.accentColor,
          labelStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontSize: 14.sp),
          tabs: const [
            Tab(text: 'Current Orders'),
            Tab(text: 'Past Orders'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCurrentOrdersTab(),
          _buildPastOrdersTab(),
        ],
      ),
    );
  }

  Widget _buildCurrentOrdersTab() {
    return BlocConsumer<OrdersBloc, OrdersState>(
      listener: (context, state) {
        // You can add listeners for error messages or other side effects here
        if (state.status == OrdersStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'An unknown error occurred')),
          );
        }
      },
      builder: (context, state) {
        if (state.status == OrdersStatus.loading) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.accentColor));
        } else if (state.orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment, size: 64.r, color: AppTheme.accentColor),
                SizedBox(height: 16.h),
                Text(
                  'No current orders found.',
                  style: TextStyle(fontSize: 18.sp, color: AppTheme.textPrimaryColor),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Place an order and it will appear here.',
                  style: TextStyle(fontSize: 14.sp, color: AppTheme.textSecondaryColor),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to home or product page to encourage ordering
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    'START SHOPPING',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        } else {
          // Display the orders fetched. For now, it will just print to console
          // as requested, but a UI to display them would go here.
          // For demonstration, let's create a simple list view.
          return ListView.builder(
            padding: EdgeInsets.all(16.r),
            itemCount: state.orders.length,
            itemBuilder: (context, index) {
              final order = state.orders[index];
              return Card(
                color: AppTheme.secondaryColor,
                margin: EdgeInsets.only(bottom: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order ID: ${order.id}',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentColor,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Status: ${order.status.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: _getOrderStatusColor(order.status),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Order Date: ${order.orderTimestamp.toDate().toLocal().toString().split(' ')[0]}',
                        style: TextStyle(fontSize: 12.sp, color: AppTheme.textSecondaryColor),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Total: ₹${order.pricingSummary.grandTotal.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 14.sp, color: AppTheme.textPrimaryColor),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Items:',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      ...order.items.map((item) => Text(
                        '  - ${item.name} x${item.quantity} (₹${item.buyingPrice.toStringAsFixed(2)} each)',
                        style: TextStyle(fontSize: 12.sp, color: AppTheme.textSecondaryColor),
                      )).toList(),
                      // Add more order details here if needed
                    ],
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }

  // Placeholder for past orders tab
  Widget _buildPastOrdersTab() {
    return const Center(
      child: Text(
        'Past orders will appear here.',
        style: TextStyle(color: AppTheme.textSecondaryColor),
      ),
    );
  }

  Color _getOrderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'pending_confirmation':
      case 'processing':
        return Colors.orange;
      case 'shipped':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
      case 'refunded':
        return Colors.red;
      default:
        return AppTheme.textSecondaryColor;
    }
  }
}