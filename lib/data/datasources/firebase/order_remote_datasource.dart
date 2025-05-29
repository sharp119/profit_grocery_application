// lib/data/datasources/firebase/order_remote_datasource.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:profit_grocery_application/domain/entities/order.dart';

abstract class OrderRemoteDataSource {
  Future<String> createOrderInFirestore(OrderEntity order);
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final FirebaseFirestore _firestore;

  OrderRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<String> createOrderInFirestore(OrderEntity order) async {
    try {
      final userOrdersCollectionRef = _firestore
          .collection('orders') // Top-level 'orders' collection
          .doc(order.userId)      // Document for the specific user
          .collection('user_orders'); // Subcollection for this user's orders

      DocumentReference orderDocRef;

      if (order.id != null && order.id!.isNotEmpty) {
        // If an ID is provided in OrderEntity (e.g., pre-generated client-side)
        orderDocRef = userOrdersCollectionRef.doc(order.id);
      } else {
        // Let Firestore generate a new document ID
        orderDocRef = userOrdersCollectionRef.doc();
      }

      // The OrderEntity.toJson() method should correctly serialize the order data.
      // Ensure OrderEntity.id is not part of toJson() as it's the document name.
      await orderDocRef.set(order.toJson());

      return orderDocRef.id; // Return the actual Firestore document ID
    } catch (e) {
      print('Firestore Error - createOrderInFirestore: $e');
      // Re-throw as a custom exception if you have an error handling framework
      throw Exception('Could not create order in Firestore: $e');
    }
  }
}