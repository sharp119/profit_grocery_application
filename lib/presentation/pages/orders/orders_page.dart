import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:profit_grocery_application/data/inventory/product_inventory.dart';

import '../../../core/constants/app_theme.dart';
import '../../../data/inventory/order_inventory.dart';
import '../../../data/repositories/firestore/order_repository_impl.dart';
import '../../../domain/entities/order.dart';
import '../../blocs/orders/orders_bloc.dart';
import '../../blocs/orders/orders_event.dart';
import '../../blocs/orders/orders_state.dart';
import '../../widgets/base_layout.dart';
import '../../widgets/cards/product_card.dart';
import 'order_details_page.dart';

class OrdersPage extends StatelessWidget {
  final int initialTab;
  
  const OrdersPage({Key? key, this.initialTab = 0}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrdersBloc(
        orderRepository: OrderRepositoryImpl(),
      ),
      child: OrdersView(initialTab: initialTab),
    );
  }
}

class OrdersView extends StatefulWidget {
  final int initialTab;
  
  const OrdersView({Key? key, this.initialTab = 0}) : super(key: key);

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _refreshKey = GlobalKey<RefreshIndicatorState>();

  void _refreshOrders() {
    context.read<OrdersBloc>().add(
          const RefreshOrders(userId: 'current_user'),
        );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
    
    // Force refresh of orders when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshOrders());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      title: 'My Orders',
      showBackButton: true,
      body: BlocBuilder<OrdersBloc, OrdersState>(
        builder: (context, state) {
          if (state is OrdersLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is OrdersError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 60.sp,
                    color: AppTheme.errorColor,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Error',
                    style: TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.w),
                    child: Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                  SizedBox(height: 32.h),
                  ElevatedButton(
                    onPressed: () {
                      context.read<OrdersBloc>().add(
                            const RefreshOrders(userId: 'current_user'),
                          );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (state is OrdersLoaded) {
            // Check if there are any orders including current order
            final hasOrders = state.orders.isNotEmpty || state.currentOrder != null;
            
            if (!hasOrders) {
              return _buildEmptyOrdersView();
            }
            
            return Column(
              children: [
                // Tab bar for Current and Past orders
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Current Order'),
                    Tab(text: 'Past Orders'),
                  ],
                  labelColor: AppTheme.accentColor,
                  unselectedLabelColor: AppTheme.textSecondaryColor,
                  indicatorColor: AppTheme.accentColor,
                ),
                // Tab bar view
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Current order view
                      _buildCurrentOrderView(state),
                      // Past orders view
                      _buildPastOrdersView(state),
                    ],
                  ),
                ),
              ],
            );
          }
          
          // Default empty state
          return _buildEmptyOrdersView();
        },
      ),
    );
  }
  
  Widget _buildEmptyOrdersView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 80.sp,
            color: AppTheme.accentColor,
          ),
          SizedBox(height: 16.h),
          Text(
            'Order History',
            style: TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Text(
              'Your order history will appear here once you place orders',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 14.sp,
              ),
            ),
          ),
          SizedBox(height: 32.h),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/home');
            },
            child: const Text('Start Shopping'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCurrentOrderView(OrdersLoaded state) {
    if (state.currentOrder == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 60.sp,
              color: AppTheme.textSecondaryColor,
            ),
            SizedBox(height: 16.h),
            Text(
              'No Current Orders',
              style: TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Text(
                'You don\'t have any ongoing orders at the moment',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 14.sp,
                ),
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/home');
              },
              child: const Text('Browse Products'),
            ),
          ],
        ),
      );
    }
    
    // Calculate estimated delivery time
    final estimatedTime = state.estimatedDeliveryTime ?? DateTime.now().add(const Duration(minutes: 45));
    final timeFormatter = DateFormat('h:mm a');
    final formattedTime = timeFormatter.format(estimatedTime);
    
    // Get status
    final statusMap = {
      'processing': 'Order Processing',
      'packed': 'Order Packed',
      'out_for_delivery': 'Out for Delivery',
      'delivered': 'Delivered',
    };
    
    final statusText = statusMap[state.currentOrderStatus] ?? 'Processing';
    
    // Get delivery person
    final deliveryPerson = state.deliveryPersonDetails ?? {};
    
    return RefreshIndicator(
      key: _refreshKey,
      onRefresh: () async {
        context.read<OrdersBloc>().add(
              const RefreshOrders(userId: 'current_user'),
            );
        await Future.delayed(const Duration(milliseconds: 300)); // Small delay for UX
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order status card
            Padding(
              padding: EdgeInsets.all(16.h),
              child: Container(
                width: double.infinity,
                decoration: AppTheme.goldBorderedDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order status header
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.h),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16.r),
                          topRight: Radius.circular(16.r),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                statusText,
                                style: TextStyle(
                                  color: AppTheme.accentColor,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentColor,
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Text(
                                  'Order #${state.currentOrder!.id.substring(0, 6)}',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Estimated delivery by $formattedTime',
                            style: TextStyle(
                              color: AppTheme.textPrimaryColor,
                              fontSize: 14.sp,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          // Add spacing instead of the Track Live Order Status button
                          SizedBox(height: 12.h),
                        ],
                      ),
                    ),
                    
                    // Vertical order tracking
                    Padding(
                      padding: EdgeInsets.all(16.h),
                      child: _buildAnimatedProgressBar(state.currentOrderStatus ?? 'out_for_delivery'),
                    ),
                    
                    // Delivery person info
                    if (state.currentOrderStatus == 'out_for_delivery' || state.currentOrderStatus == 'reached_doorstep')
                      Padding(
                        padding: EdgeInsets.all(16.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delivery Partner',
                              style: TextStyle(
                                color: AppTheme.textSecondaryColor,
                                fontSize: 12.sp,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Row(
                              children: [
                                Container(
                                  width: 40.w,
                                  height: 40.h,
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentColor.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.person,
                                      color: AppTheme.accentColor,
                                      size: 24.sp,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        deliveryPerson['name'] ?? 'Delivery Partner',
                                        style: TextStyle(
                                          color: AppTheme.textPrimaryColor,
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.star,
                                            color: AppTheme.accentColor,
                                            size: 14.sp,
                                          ),
                                          SizedBox(width: 4.w),
                                          Text(
                                            deliveryPerson['rating'] ?? '4.8',
                                            style: TextStyle(
                                              color: AppTheme.textSecondaryColor,
                                              fontSize: 12.sp,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16.r),
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.phone,
                                      color: AppTheme.accentColor,
                                      size: 20.sp,
                                    ),
                                    onPressed: () {
                                      // Call delivery person
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    
                    // Order details
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order Summary',
                            style: TextStyle(
                              color: AppTheme.textPrimaryColor,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          // Order items
                          ...state.currentOrder!.items.take(3).map((item) => _buildOrderItemRow(item)),
                          
                          // Show more items if there are more than 3
                          if (state.currentOrder!.items.length > 3)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                              child: InkWell(
                                onTap: () {
                                  // Navigate to order details
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OrderDetailsPage(
                                        order: state.currentOrder!,
                                      ),
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    Text(
                                      '+${state.currentOrder!.items.length - 3} more items',
                                      style: TextStyle(
                                        color: AppTheme.accentColor,
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 4.w),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      color: AppTheme.accentColor,
                                      size: 12.sp,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          
                          SizedBox(height: 16.h),
                          // Price summary
                          _buildPriceSummary(state.currentOrder!),
                          
                          SizedBox(height: 16.h),
                          // Actions
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    // Cancel order
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Cancel Order?'),
                                        content: const Text(
                                          'Are you sure you want to cancel this order?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text('No'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              context.read<OrdersBloc>().add(
                                                    CancelOrder(
                                                      userId: 'current_user',
                                                      orderId: state.currentOrder!.id,
                                                    ),
                                                  );
                                            },
                                            child: const Text('Yes'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: AppTheme.accentColor),
                                  ),
                                  child: Text(
                                    'Cancel Order',
                                    style: TextStyle(
                                      color: AppTheme.accentColor,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    // View detailed tracking
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => OrderDetailsPage(
                                          order: state.currentOrder!,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'View Details',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                    ),
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
              ),
            ),
            
            // Similar Products section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Frequently Bought Together',
                    style: TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  SizedBox(
                    height: 220.h,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        // Get random products from inventory
                        final allProducts = ProductInventory.getAllProducts();
                        final randomIndex = DateTime.now().millisecondsSinceEpoch % allProducts.length;
                        final product = allProducts[(randomIndex + index) % allProducts.length];
                        
                        return Container(
                          width: 150.w,
                          margin: EdgeInsets.only(right: 12.w),
                          child: ProductCard(
                            id: product.id,
                            name: product.name,
                            image: product.image,
                            price: product.price,
                            mrp: product.mrp,
                            inStock: product.inStock,
                            onTap: () {
                              // Navigate to product details
                              Navigator.pushNamed(
                                context,
                                '/product-details',
                                arguments: product.id,
                              );
                            },
                            onQuantityChanged: (quantity) {
                              // Add to cart
                            },
                            backgroundColor: AppTheme.secondaryColor,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPastOrdersView(OrdersLoaded state) {
    if (state.orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 60.sp,
              color: AppTheme.textSecondaryColor,
            ),
            SizedBox(height: 16.h),
            Text(
              'No Past Orders',
              style: TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Text(
                'You haven\'t placed any orders yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 14.sp,
                ),
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/home');
              },
              child: const Text('Start Shopping'),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        context.read<OrdersBloc>().add(
              const RefreshOrders(userId: 'current_user'),
            );
      },
      child: ListView.builder(
        padding: EdgeInsets.all(16.h),
        itemCount: state.orders.length,
        itemBuilder: (context, index) {
          final order = state.orders[index];
          return _buildPastOrderCard(order);
        },
      ),
    );
  }
  
  Widget _buildAnimatedProgressBar(String status) {
    // Use newer status steps for more detailed tracking
    final statusSteps = [
      'order_accepted', 
      'getting_packed', 
      'out_for_delivery', 
      'reached_doorstep',
      'delivered'
    ];
    final statusLabels = [
      'Order Accepted', 
      'Getting Packed', 
      'Out for Delivery', 
      'Reached Doorstep',
      'Delivered'
    ];
    final statusIcons = [
      Icons.check_circle_outline,
      Icons.inventory_2_outlined,
      Icons.local_shipping_outlined,
      Icons.home_outlined,
      Icons.celebration_outlined
    ];
    
    // For demo purposes, if status is not in the list, use out_for_delivery
    int currentStep = statusSteps.indexOf(status);
    if (currentStep < 0) currentStep = 2; // Default to out_for_delivery
    
    return Column(
      children: [
        for (int i = 0; i < statusSteps.length; i++)
          _buildVerticalProgressStep(
            icon: statusIcons[i],
            label: statusLabels[i],
            isActive: i <= currentStep,
            isLast: i == statusSteps.length - 1,
            timeInfo: i < currentStep ? 'Completed' : 
                     i == currentStep ? 'In progress' : 
                     'Pending',
          ),
      ],
    );
  }
  
  Widget _buildProgressStep({
    required IconData icon,
    required String label,
    required bool isActive,
    required bool showLine,
  }) {
    return Expanded(
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 32.w,
                height: 32.h,
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.accentColor : AppTheme.accentColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: isActive ? Colors.black : AppTheme.textSecondaryColor,
                    size: 16.sp,
                  ),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? AppTheme.accentColor : AppTheme.textSecondaryColor,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          if (showLine)
            Expanded(
              child: Container(
                height: 2.h,
                color: isActive ? AppTheme.accentColor : AppTheme.accentColor.withOpacity(0.2),
              ),
            ),
        ],
      ),
    );
  }
  
  // Vertical progress step for more detailed order tracking
  Widget _buildVerticalProgressStep({
    required IconData icon,
    required String label,
    required bool isActive,
    required bool isLast,
    required String timeInfo,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline column with icon and connecting line
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status icon
            Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: isActive ? AppTheme.accentColor : AppTheme.accentColor.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? AppTheme.accentColor : AppTheme.accentColor.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: isActive ? Colors.black : AppTheme.textSecondaryColor,
                  size: 20.sp,
                ),
              ),
            ),
            // Connecting line
            if (!isLast)
              Container(
                width: 2.w,
                height: 50.h,
                color: isActive ? AppTheme.accentColor : AppTheme.accentColor.withOpacity(0.2),
              ),
          ],
        ),
        SizedBox(width: 16.w),
        // Status details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isActive ? AppTheme.accentColor : AppTheme.textSecondaryColor,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                timeInfo,
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildOrderItemRow(OrderItem item) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            padding: EdgeInsets.all(4.h),
            child: Image.asset(
              item.productImage,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.image_not_supported,
                  color: AppTheme.accentColor.withOpacity(0.5),
                  size: 20.sp,
                );
              },
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.productName,
                  style: TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  '${item.quantity} × ₹${item.price.toInt()}',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            '₹${item.total.toInt()}',
            style: TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPriceSummary(Order order) {
    return Container(
      padding: EdgeInsets.all(12.h),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          _buildPriceRow('Subtotal', '₹${order.subtotal.toInt()}'),
          SizedBox(height: 4.h),
          if (order.discount > 0) ...[
            _buildPriceRow(
              'Discount',
              '-₹${order.discount.toInt()}',
              valueColor: Colors.green,
            ),
            SizedBox(height: 4.h),
          ],
          _buildPriceRow('Delivery Fee', '₹${order.deliveryFee.toInt()}'),
          SizedBox(height: 8.h),
          Divider(color: AppTheme.accentColor.withOpacity(0.2)),
          SizedBox(height: 8.h),
          _buildPriceRow(
            'Total',
            '₹${order.total.toInt()}',
            isBold: true,
          ),
        ],
      ),
    );
  }
  
  Widget _buildPriceRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondaryColor,
            fontSize: 14.sp,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppTheme.textPrimaryColor,
            fontSize: 14.sp,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
  
  Widget _buildPastOrderCard(Order order) {
    // Format date
    final dateFormatter = DateFormat('MMM dd, yyyy');
    final formattedDate = dateFormatter.format(order.createdAt);
    
    // Get status color
    Color statusColor;
    switch (order.status) {
      case 'delivered':
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = AppTheme.accentColor;
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: AppTheme.goldBorderedDecoration(
        borderRadius: 12.r,
        borderWidth: 1,
      ),
      child: InkWell(
        onTap: () {
          // Navigate to order details
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailsPage(
                order: order,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Column(
          children: [
            // Order header
            Container(
              padding: EdgeInsets.all(12.h),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.05),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12.r),
                  topRight: Radius.circular(12.r),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.id.substring(0, 6)}',
                        style: TextStyle(
                          color: AppTheme.textPrimaryColor,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      order.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Order items
            Padding(
              padding: EdgeInsets.all(12.h),
              child: Column(
                children: [
                  // Show first 2 items
                  ...order.items.take(2).map((item) => _buildOrderItemRow(item)),
                  
                  // Show more items if there are more than 2
                  if (order.items.length > 2)
                    Padding(
                      padding: EdgeInsets.only(top: 8.h, bottom: 4.h),
                      child: Row(
                        children: [
                          Text(
                            '+${order.items.length - 2} more items',
                            style: TextStyle(
                              color: AppTheme.accentColor,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  SizedBox(height: 8.h),
                  // Order total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total:',
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 14.sp,
                        ),
                      ),
                      Text(
                        '₹${order.total.toInt()}',
                        style: TextStyle(
                          color: AppTheme.accentColor,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 12.h),
                  // Action buttons
                  Row(
                    children: [
                      if (order.status == 'delivered')
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              // Reorder functionality
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppTheme.accentColor),
                              padding: EdgeInsets.symmetric(
                                vertical: 6.h,
                              ),
                            ),
                            child: Text(
                              'Reorder',
                              style: TextStyle(
                                color: AppTheme.accentColor,
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                        ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // View order details
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OrderDetailsPage(
                                  order: order,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: 6.h,
                            ),
                          ),
                          child: Text(
                            'View Details',
                            style: TextStyle(
                              fontSize: 12.sp,
                            ),
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
      ),
    );
  }
}
