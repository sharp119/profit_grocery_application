import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/entities/user.dart';
import '../../models/user_model.dart';

class UserFirestoreModel extends UserModel {
  const UserFirestoreModel({
    required super.id,
    required super.phoneNumber,
    super.name,
    super.email,
    super.addresses = const [],
    required super.createdAt,
    required super.lastLogin,
    required super.isOptedInForMarketing,
  });

  /// Convert Firestore document to UserFirestoreModel
  factory UserFirestoreModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception('Document data was null');
    }

    // Parse addresses if present
    List<Address> addresses = [];
    if (data.containsKey('addresses') && data['addresses'] is List) {
      try {
        addresses = List<Address>.from(
          (data['addresses'] as List).map(
            (addr) => AddressModel.fromJson(Map<String, dynamic>.from(addr)),
          ),
        );
      } catch (e) {
        print('Error parsing Firestore addresses: $e');
      }
    }

    // Safely handle Timestamp fields
    DateTime createdAt = DateTime.now();
    DateTime lastLogin = DateTime.now();
    
    try {
      if (data['createdAt'] is Timestamp) {
        createdAt = (data['createdAt'] as Timestamp).toDate();
      }
    } catch (e) {
      print('Error parsing createdAt timestamp: $e');
    }
    
    try {
      if (data['lastLogin'] is Timestamp) {
        lastLogin = (data['lastLogin'] as Timestamp).toDate();
      }
    } catch (e) {
      print('Error parsing lastLogin timestamp: $e');
    }

    return UserFirestoreModel(
      id: snapshot.id,
      phoneNumber: data['phoneNumber'] ?? '',
      name: data['name'],
      email: data['email'],
      addresses: addresses,
      createdAt: createdAt,
      lastLogin: lastLogin,
      isOptedInForMarketing: data['isOptedInForMarketing'] ?? true,
    );
  }

  /// Convert UserFirestoreModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'phoneNumber': phoneNumber,
      'name': name,
      'email': email,
      'addresses': addresses.isEmpty
          ? []
          : addresses.map((addr) {
              if (addr is AddressModel) {
                return addr.toJson();
              } else {
                return {
                  'id': addr.id,
                  'name': addr.name,
                  'addressLine': addr.addressLine,
                  'city': addr.city,
                  'state': addr.state,
                  'pincode': addr.pincode,
                  'landmark': addr.landmark,
                  'isDefault': addr.isDefault,
                  'addressType': addr.addressType,
                };
              }
            }).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': Timestamp.fromDate(lastLogin),
      'isOptedInForMarketing': isOptedInForMarketing,
    };
  }
}
