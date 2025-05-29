// lib/data/repositories/order_repository_impl.dart
import 'package:profit_grocery_application/data/datasources/firebase/order_remote_datasource.dart';
import 'package:profit_grocery_application/domain/entities/order.dart';
import 'package:profit_grocery_application/domain/repositories/order_repository.dart';
// import 'package:profit_grocery_application/core/network/network_info.dart'; // If you check network status

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource remoteDataSource;
  // final NetworkInfo networkInfo; // Optional: for checking network connectivity

  OrderRepositoryImpl({
    required this.remoteDataSource,
    // this.networkInfo,
  });

  @override
  Future<String> createOrder(OrderEntity order) async {
    // Example: if (networkInfo != null && !await networkInfo.isConnected) {
    //   throw NetworkException('No internet connection');
    // }
    try {
      return await remoteDataSource.createOrderInFirestore(order);
    } catch (e) {
      // Log or convert to a domain-specific Failure if using that pattern
      print('OrderRepositoryImpl Error: $e');
      rethrow;
    }
  }
}