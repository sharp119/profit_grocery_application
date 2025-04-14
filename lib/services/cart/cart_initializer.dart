import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../presentation/blocs/cart/cart_bloc.dart';
import '../../presentation/blocs/cart/cart_event.dart';
import '../../utils/cart_logger.dart';

/// Service to ensure cart is initialized at app startup
class CartInitializer {
  final CartBloc _cartBloc;
  final SharedPreferences _sharedPreferences;

  CartInitializer({
    required CartBloc cartBloc,
    required SharedPreferences sharedPreferences,
  })  : _cartBloc = cartBloc,
        _sharedPreferences = sharedPreferences;

  Future<void> initialize() async {
    try {
      CartLogger.log('INITIALIZER', 'Initializing cart');
      
      // Get user ID from shared preferences
      final userId = _sharedPreferences.getString(AppConstants.userTokenKey);
      
      if (userId != null && userId.isNotEmpty) {
        // Load cart if user is logged in
        CartLogger.info('INITIALIZER', 'User $userId is logged in, loading cart');
        _cartBloc.add(const LoadCart());
      } else {
        CartLogger.info('INITIALIZER', 'No user logged in, skipping cart initialization');
      }
      
      CartLogger.success('INITIALIZER', 'Cart initialization completed');
    } catch (e) {
      CartLogger.error('INITIALIZER', 'Error initializing cart', e);
    }
  }
}