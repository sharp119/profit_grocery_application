import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:badges/badges.dart' as badges;
import 'package:profit_grocery_application/core/constants/app_theme.dart';
import 'package:profit_grocery_application/presentation/blocs/navigation/navigation_bloc.dart';
import 'package:profit_grocery_application/presentation/blocs/navigation/navigation_event.dart';
import 'package:profit_grocery_application/presentation/blocs/navigation/navigation_state.dart';
import 'package:profit_grocery_application/presentation/blocs/cart/cart_bloc.dart';
import 'package:profit_grocery_application/presentation/blocs/cart/cart_state.dart';
import 'package:profit_grocery_application/presentation/pages/cart/cart_page.dart';
import 'package:profit_grocery_application/presentation/pages/home/home_page.dart';
import 'package:profit_grocery_application/presentation/pages/orders/orders_page.dart';
import 'package:profit_grocery_application/presentation/pages/profile/profile_page.dart';

class MainNavigation extends StatelessWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('Building MainNavigation with bottom navigation bar');
    return BlocProvider(
      create: (context) => NavigationBloc(),
      child: const _MainNavigationContent(),
    );
  }
}

class _MainNavigationContent extends StatefulWidget {
  const _MainNavigationContent();

  @override
  State<_MainNavigationContent> createState() => _MainNavigationContentState();
}

class _MainNavigationContentState extends State<_MainNavigationContent> {
  // Keep track of page history for back navigation
  final List<int> _pageHistory = [0];
  // Track last back press time for double-back-to-exit
  DateTime? _lastBackPressTime;

  // The currently displayed tab bodies
  late final List<Widget> _tabBodies;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize tab bodies - will be maintained across tab switches
    _tabBodies = [
      const HomePage(),
      const OrdersPage(),
      const CartPage(),
      const ProfilePage(),
    ];
    
    // Log to verify initialization
    print('MainNavigation initialized with bottom bar');
  }
  
  // Handle Android back button to navigate through tab history or exit app
  Future<bool> _onWillPop() async {
    // If we're not on the home tab, go back to home first
    if (_pageHistory.last != 0) {
      // Navigate to home tab (index 0)
      context.read<NavigationBloc>().add(const NavigateToTabEvent(0));
      return false;
    }
    
    // We're on the home tab, implement double tap to exit
    final now = DateTime.now();
    if (_lastBackPressTime == null || 
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      // First back press - show toast
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Press back again to exit', 
                    style: TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.primaryColor,
          duration: const Duration(seconds: 2),
        ),
      );
      return false;
    }
    
    // Second back press within 2 seconds - exit app
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationBloc, NavigationState>(
      builder: (context, state) {
        // Add new page to history only if it's different from the current one
        final currentIndex = state.currentTabIndex;
        
        if (_pageHistory.isEmpty || _pageHistory.last != currentIndex) {
          // If going back to a previous tab, remove until we find that tab
          // This prevents history build-up when navigating back and forth
          if (_pageHistory.contains(currentIndex)) {
            while (_pageHistory.isNotEmpty && _pageHistory.last != currentIndex) {
              _pageHistory.removeLast();
            }
          } else {
            // This is a new destination, add it to history
            _pageHistory.add(currentIndex);
          }
          
          // Limit history size to prevent memory issues
          if (_pageHistory.length > 10) {
            _pageHistory.removeAt(0);
          }
        }
        
        return WillPopScope(
          onWillPop: _onWillPop,
          child: Scaffold(
            extendBody: false, // Important: ensures content doesn't go underneath the bottom nav
            body: IndexedStack(
              index: state.currentTabIndex,
              children: _tabBodies,
            ),
            bottomNavigationBar: BlocBuilder<CartBloc, CartState>(
              builder: (context, cartState) {
                final int cartItemCount = cartState.itemCount;
                
                return BottomNavigationBar(
                  currentIndex: state.currentTabIndex,
                  onTap: (index) {
                    context.read<NavigationBloc>().add(NavigateToTabEvent(index));
                  },
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: AppTheme.primaryColor,
                  selectedItemColor: AppTheme.accentColor,
                  unselectedItemColor: Colors.white54,
                  elevation: 12,
                  showUnselectedLabels: true,
                  selectedLabelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontSize: 12.sp,
                  ),
                  items: [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home_outlined),
                      activeIcon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.shopping_bag_outlined),
                      activeIcon: Icon(Icons.shopping_bag),
                      label: 'Orders',
                    ),
                    BottomNavigationBarItem(
                      icon: cartItemCount > 0
                        ? badges.Badge(
                            badgeContent: Text(
                              cartItemCount.toString(),
                              style: TextStyle(color: Colors.black, fontSize: 10.sp),
                            ),
                            badgeStyle: const badges.BadgeStyle(
                              badgeColor: AppTheme.accentColor,
                              padding: EdgeInsets.all(5),
                            ),
                            child: const Icon(Icons.shopping_cart_outlined),
                          )
                        : const Icon(Icons.shopping_cart_outlined),
                      activeIcon: cartItemCount > 0
                        ? badges.Badge(
                            badgeContent: Text(
                              cartItemCount.toString(),
                              style: TextStyle(color: Colors.black, fontSize: 10.sp),
                            ),
                            badgeStyle: const badges.BadgeStyle(
                              badgeColor: AppTheme.accentColor,
                              padding: EdgeInsets.all(5),
                            ),
                            child: const Icon(Icons.shopping_cart),
                          )
                        : const Icon(Icons.shopping_cart),
                      label: 'Cart',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.settings_outlined),
                      activeIcon: Icon(Icons.settings),
                      label: 'Settings',
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
