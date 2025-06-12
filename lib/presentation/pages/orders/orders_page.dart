import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:profit_grocery_application/core/constants/app_theme.dart';
import 'package:profit_grocery_application/presentation/blocs/orders/orders_bloc.dart';
import 'package:profit_grocery_application/presentation/blocs/orders/orders_event.dart';
import 'package:profit_grocery_application/presentation/blocs/orders/orders_state.dart';
import 'package:profit_grocery_application/domain/entities/order.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:profit_grocery_application/core/constants/app_constants.dart';
import 'package:profit_grocery_application/presentation/pages/orders/order_details_page.dart';
import 'package:profit_grocery_application/presentation/widgets/image_loader.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({Key? key}) : super(key: key);

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> with SingleTickerProviderStateMixin {
  int _ordersLimit = 5;
  bool _isLoadingMore = false;
  bool _noMoreOrders = false;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  void _fetchOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(AppConstants.userTokenKey);

    if (userId == null || userId.isEmpty) {
      if (mounted) {
        context.read<OrdersBloc>().add(LoadOrders(userId: '', limit: 0));
      }
      return;
    }

    if (mounted) {
      context.read<OrdersBloc>().add(LoadOrders(userId: userId, limit: _ordersLimit));
    }
  }

  void _loadMoreOrders() async {
    setState(() {
      _isLoadingMore = true;
      _ordersLimit += 5;
    });
    await Future.delayed(Duration(milliseconds: 300)); // Simulate loading
    _fetchOrders();
    setState(() {
      _isLoadingMore = false;
    });
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
      ),
      body: BlocConsumer<OrdersBloc, OrdersState>(
        listener: (context, state) {
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
                    'No orders found.',
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
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(16.r),
                    itemCount: state.orders.length + 1, // +1 for load more/message
                    itemBuilder: (context, index) {
                      if (index < state.orders.length) {
                        final order = state.orders[index];
                        final status = order.status.toLowerCase();
                        IconData icon;
                        Color iconColor;
                        String actionLabel;
                        bool isFinal = false;

                        switch (status) {
                          case 'pending':
                            icon = Icons.hourglass_empty;
                            iconColor = Colors.orange;
                            actionLabel = 'Cancel Order';
                            break;
                          case 'confirmed':
                            icon = Icons.task_alt;
                            iconColor = Colors.blueAccent;
                            actionLabel = 'Cancel Order';
                            break;
                          case 'shipped':
                            icon = Icons.local_shipping;
                            iconColor = Colors.deepPurple;
                            actionLabel = 'Cancel Order';
                            break;
                          case 'out for delivery':
                            icon = Icons.delivery_dining;
                            iconColor = Colors.teal;
                            actionLabel = 'Cancel Order';
                            break;
                          case 'delivered':
                            icon = Icons.check_circle;
                            iconColor = Colors.green;
                            actionLabel = 'Order Again';
                            isFinal = true;
                            break;
                          case 'cancelled':
                            icon = Icons.cancel;
                            iconColor = Colors.red;
                            actionLabel = 'Order Again';
                            isFinal = true;
                            break;
                          case 'failed':
                            icon = Icons.warning;
                            iconColor = Colors.redAccent;
                            actionLabel = 'Order Again';
                            isFinal = true;
                            break;
                          default:
                            icon = Icons.help_outline;
                            iconColor = Colors.grey;
                            actionLabel = 'View Details';
                            break;
                        }

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OrderDetailsPage(orderId: order.id!),
                              ),
                            );
                          },
                          child: Container(
                            margin: EdgeInsets.only(bottom: 12.h),
                            padding: EdgeInsets.all(16.r),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryColor,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Product images row (now above status row, smaller size)
                                if (order.items.isNotEmpty)
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 8.h),
                                    child: Row(
                                      children: [
                                        for (int i = 0; i < (order.items.length > 5 ? 4 : order.items.length); i++)
                                          Padding(
                                            padding: EdgeInsets.only(right: 4.w),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(6.r),
                                              child: ImageLoader.network(
                                                order.items[i].image,
                                                fit: BoxFit.contain,
                                                width: 36.w,
                                                height: 36.h,
                                                errorWidget: Center(
                                                  child: Icon(
                                                    Icons.image_not_supported_outlined,
                                                    color: AppTheme.textSecondaryColor,
                                                    size: 14.sp,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        if (order.items.length > 5)
                                          Padding(
                                            padding: EdgeInsets.only(right: 4.w),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(6.r),
                                              child: Container(
                                                width: 36.w,
                                                height: 36.h,
                                                color: Colors.grey.shade300,
                                                alignment: Alignment.center,
                                                child: Text(
                                                  "+${order.items.length - 4}",
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13.sp,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                // Row 1: Status text + icon beside
                                Row(
                                  children: [
                                    Text(
                                      'Order (${order.status[0].toUpperCase()}${order.status.substring(1)})',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimaryColor,
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Icon(icon, color: iconColor, size: 20.r),
                                  ],
                                ),

                                SizedBox(height: 8.h),

                                // Row 2: Time & Price
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Placed: ${order.orderTimestamp.toDate().toLocal().toString().split(".")[0]}',
                                      style: TextStyle(fontSize: 13.sp, color: AppTheme.textSecondaryColor),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          '₹${order.pricingSummary.grandTotal.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimaryColor,
                                          ),
                                        ),
                                        Icon(Icons.arrow_forward_ios, size: 14.r, color: AppTheme.textSecondaryColor),
                                      ],
                                    ),
                                  ],
                                ),

                                SizedBox(height: 12.h),
                                Divider(color: AppTheme.textSecondaryColor.withOpacity(0.3)),
                                SizedBox(height: 12.h),

                                // Row 3: Centered Action
                                Center(
                                  child: Center(
                                    child: Text(
                                      isFinal ? 'Order Again' : 'Cancel Order',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                        color: isFinal ? AppTheme.accentColor : Colors.redAccent,
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      } else {
                        // After last order card
                        if (state.orders.length >= _ordersLimit && !_noMoreOrders) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 12.h, bottom: 24.h),
                              child: GestureDetector(
                                onTap: _isLoadingMore ? null : () async {
                                  setState(() { _isLoadingMore = true; });
                                  int prevCount = state.orders.length;
                                  _ordersLimit += 5;
                                  await Future.delayed(Duration(milliseconds: 300));
                                  _fetchOrders();
                                  setState(() {
                                    _isLoadingMore = false;
                                    // If no new orders were fetched, set flag
                                    if (context.read<OrdersBloc>().state.orders.length == prevCount) {
                                      _noMoreOrders = true;
                                    }
                                  });
                                },
                                child: _isLoadingMore
                                    ? SizedBox(
                                        width: 20.w,
                                        height: 20.w,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                      )
                                    : Text(
                                        '+ Load More',
                                        style: TextStyle(
                                          color: AppTheme.accentColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15.sp,
                                        ),
                                      ),
                              ),
                            ),
                          );
                        } else if (_noMoreOrders) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 12.h, bottom: 24.h),
                              child: Text(
                                'No more orders to load.',
                                style: TextStyle(
                                  color: AppTheme.textSecondaryColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                          );
                        } else {
                          return SizedBox.shrink();
                        }
                      }
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
