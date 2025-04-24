import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/cart/improved_cart_service.dart';

/// Register dependencies for the improved cart system
Future<void> registerImprovedCartDependencies() async {
  final GetIt getIt = GetIt.instance;
  
  // Register ImprovedCartService as a singleton
  if (!getIt.isRegistered<ImprovedCartService>()) {
    getIt.registerSingleton<ImprovedCartService>(ImprovedCartService());
  }
}