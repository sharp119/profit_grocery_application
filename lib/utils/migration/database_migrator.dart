import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../core/constants/app_constants.dart';
import '../../services/logging_service.dart';

/// Utility class for migrating data between Firebase Realtime Database and Firestore
class DatabaseMigrator {
  final FirebaseDatabase _realtimeDatabase;
  final FirebaseFirestore _firestore;

  DatabaseMigrator({
    required FirebaseDatabase realtimeDatabase,
    required FirebaseFirestore firestore,
  })  : _realtimeDatabase = realtimeDatabase,
        _firestore = firestore;

  /// Migrate users from Realtime Database to Firestore
  Future<MigrationResult> migrateUsers() async {
    try {
      final usersRef = _realtimeDatabase.ref().child(AppConstants.usersCollection);
      final snapshot = await usersRef.get();
      
      if (!snapshot.exists || snapshot.value == null) {
        return MigrationResult(
          successful: false,
          itemsProcessed: 0,
          itemsMigrated: 0,
          errorMessage: 'No users found in Realtime Database',
        );
      }
      
      final usersMap = snapshot.value as Map<dynamic, dynamic>;
      int total = usersMap.length;
      int migrated = 0;
      
      for (var entry in usersMap.entries) {
        final userId = entry.key as String;
        final userData = Map<String, dynamic>.from(entry.value as Map);
        
        // Check if user already exists in Firestore
        final firestoreUserDoc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .get();
        
        if (!firestoreUserDoc.exists) {
          // Convert timestamps to Firestore Timestamps
          if (userData.containsKey('createdAt') && userData['createdAt'] is String) {
            userData['createdAt'] = Timestamp.fromDate(
              DateTime.parse(userData['createdAt'])
            );
          } else {
            userData['createdAt'] = Timestamp.now();
          }
          
          if (userData.containsKey('lastLogin') && userData['lastLogin'] is String) {
            userData['lastLogin'] = Timestamp.fromDate(
              DateTime.parse(userData['lastLogin'])
            );
          } else {
            userData['lastLogin'] = Timestamp.now();
          }
          
          // Create user in Firestore with the same ID
          await _firestore
              .collection(AppConstants.usersCollection)
              .doc(userId)
              .set(userData);
          
          migrated++;
        }
      }
      
      LoggingService.logFirestore('Migration: Migrated $migrated users out of $total');
      
      return MigrationResult(
        successful: true,
        itemsProcessed: total,
        itemsMigrated: migrated,
      );
    } catch (e) {
      LoggingService.logError('Migration', 'Error migrating users: $e');
      return MigrationResult(
        successful: false,
        itemsProcessed: 0,
        itemsMigrated: 0,
        errorMessage: 'Error migrating users: $e',
      );
    }
  }

  /// Migrate sessions from Realtime Database to Firestore
  Future<MigrationResult> migrateSessions() async {
    try {
      final sessionsRef = _realtimeDatabase.ref().child('sessions');
      final snapshot = await sessionsRef.get();
      
      if (!snapshot.exists || snapshot.value == null) {
        return MigrationResult(
          successful: false,
          itemsProcessed: 0,
          itemsMigrated: 0,
          errorMessage: 'No sessions found in Realtime Database',
        );
      }
      
      final sessionsMap = snapshot.value as Map<dynamic, dynamic>;
      int total = sessionsMap.length;
      int migrated = 0;
      
      for (var entry in sessionsMap.entries) {
        final userId = entry.key as String;
        final sessionData = Map<String, dynamic>.from(entry.value as Map);
        
        // Convert timestamps to Firestore Timestamps
        if (sessionData.containsKey('createdAt') && sessionData['createdAt'] is String) {
          sessionData['createdAt'] = Timestamp.fromDate(
            DateTime.parse(sessionData['createdAt'])
          );
        } else {
          sessionData['createdAt'] = Timestamp.now();
        }
        
        if (sessionData.containsKey('expiresAt') && sessionData['expiresAt'] is String) {
          sessionData['expiresAt'] = Timestamp.fromDate(
            DateTime.parse(sessionData['expiresAt'])
          );
        } else {
          sessionData['expiresAt'] = Timestamp.fromDate(
            DateTime.now().add(Duration(minutes: AppConstants.sessionTimeoutMinutes))
          );
        }
        
        if (sessionData.containsKey('lastActive') && sessionData['lastActive'] is String) {
          sessionData['lastActive'] = Timestamp.fromDate(
            DateTime.parse(sessionData['lastActive'])
          );
        } else {
          sessionData['lastActive'] = Timestamp.now();
        }
        
        // Create session in Firestore with the same ID
        await _firestore
            .collection('sessions')
            .doc(userId)
            .set(sessionData);
        
        migrated++;
      }
      
      LoggingService.logFirestore('Migration: Migrated $migrated sessions out of $total');
      
      return MigrationResult(
        successful: true,
        itemsProcessed: total,
        itemsMigrated: migrated,
      );
    } catch (e) {
      LoggingService.logError('Migration', 'Error migrating sessions: $e');
      return MigrationResult(
        successful: false,
        itemsProcessed: 0,
        itemsMigrated: 0,
        errorMessage: 'Error migrating sessions: $e',
      );
    }
  }

  /// Migrate products from Realtime Database to Firestore
  Future<MigrationResult> migrateProducts() async {
    try {
      final productsRef = _realtimeDatabase.ref().child(AppConstants.productsCollection);
      final snapshot = await productsRef.get();
      
      if (!snapshot.exists || snapshot.value == null) {
        return MigrationResult(
          successful: false,
          itemsProcessed: 0,
          itemsMigrated: 0,
          errorMessage: 'No products found in Realtime Database',
        );
      }
      
      final productsMap = snapshot.value as Map<dynamic, dynamic>;
      int total = productsMap.length;
      int migrated = 0;
      
      for (var entry in productsMap.entries) {
        final productId = entry.key as String;
        final productData = Map<String, dynamic>.from(entry.value as Map);
        
        // Convert timestamps if any
        if (productData.containsKey('updatedAt') && productData['updatedAt'] is String) {
          productData['updatedAt'] = Timestamp.fromDate(
            DateTime.parse(productData['updatedAt'])
          );
        }
        
        // Create product in Firestore with the same ID
        await _firestore
            .collection(AppConstants.productsCollection)
            .doc(productId)
            .set(productData);
        
        migrated++;
      }
      
      LoggingService.logFirestore('Migration: Migrated $migrated products out of $total');
      
      return MigrationResult(
        successful: true,
        itemsProcessed: total,
        itemsMigrated: migrated,
      );
    } catch (e) {
      LoggingService.logError('Migration', 'Error migrating products: $e');
      return MigrationResult(
        successful: false,
        itemsProcessed: 0,
        itemsMigrated: 0,
        errorMessage: 'Error migrating products: $e',
      );
    }
  }

  /// Migrate categories from Realtime Database to Firestore
  Future<MigrationResult> migrateCategories() async {
    try {
      final categoriesRef = _realtimeDatabase.ref().child(AppConstants.categoriesCollection);
      final snapshot = await categoriesRef.get();
      
      if (!snapshot.exists || snapshot.value == null) {
        return MigrationResult(
          successful: false,
          itemsProcessed: 0,
          itemsMigrated: 0,
          errorMessage: 'No categories found in Realtime Database',
        );
      }
      
      final categoriesMap = snapshot.value as Map<dynamic, dynamic>;
      int total = categoriesMap.length;
      int migrated = 0;
      
      for (var entry in categoriesMap.entries) {
        final categoryId = entry.key as String;
        final categoryData = Map<String, dynamic>.from(entry.value as Map);
        
        // Create category in Firestore with the same ID
        await _firestore
            .collection(AppConstants.categoriesCollection)
            .doc(categoryId)
            .set(categoryData);
        
        migrated++;
      }
      
      LoggingService.logFirestore('Migration: Migrated $migrated categories out of $total');
      
      return MigrationResult(
        successful: true,
        itemsProcessed: total,
        itemsMigrated: migrated,
      );
    } catch (e) {
      LoggingService.logError('Migration', 'Error migrating categories: $e');
      return MigrationResult(
        successful: false,
        itemsProcessed: 0,
        itemsMigrated: 0,
        errorMessage: 'Error migrating categories: $e',
      );
    }
  }

  /// Migrate orders from Realtime Database to Firestore
  Future<MigrationResult> migrateOrders() async {
    try {
      final ordersRef = _realtimeDatabase.ref().child(AppConstants.ordersCollection);
      final snapshot = await ordersRef.get();
      
      if (!snapshot.exists || snapshot.value == null) {
        return MigrationResult(
          successful: false,
          itemsProcessed: 0,
          itemsMigrated: 0,
          errorMessage: 'No orders found in Realtime Database',
        );
      }
      
      final ordersMap = snapshot.value as Map<dynamic, dynamic>;
      int total = ordersMap.length;
      int migrated = 0;
      
      for (var entry in ordersMap.entries) {
        final orderId = entry.key as String;
        final orderData = Map<String, dynamic>.from(entry.value as Map);
        
        // Convert timestamps to Firestore Timestamps
        if (orderData.containsKey('createdAt') && orderData['createdAt'] is String) {
          orderData['createdAt'] = Timestamp.fromDate(
            DateTime.parse(orderData['createdAt'])
          );
        }
        
        if (orderData.containsKey('updatedAt') && orderData['updatedAt'] is String) {
          orderData['updatedAt'] = Timestamp.fromDate(
            DateTime.parse(orderData['updatedAt'])
          );
        }
        
        // Process items subcollection if it exists
        if (orderData.containsKey('items') && orderData['items'] is Map) {
          final itemsMap = orderData['items'] as Map;
          final batch = _firestore.batch();
          
          // Create order document without items
          orderData.remove('items');
          await _firestore
              .collection(AppConstants.ordersCollection)
              .doc(orderId)
              .set(orderData);
          
          // Add items as subcollection
          for (var itemEntry in itemsMap.entries) {
            final itemId = itemEntry.key as String;
            final itemData = Map<String, dynamic>.from(itemEntry.value as Map);
            
            final itemRef = _firestore
                .collection(AppConstants.ordersCollection)
                .doc(orderId)
                .collection('items')
                .doc(itemId);
            
            batch.set(itemRef, itemData);
          }
          
          await batch.commit();
        } else {
          // Create order in Firestore with the same ID
          await _firestore
              .collection(AppConstants.ordersCollection)
              .doc(orderId)
              .set(orderData);
        }
        
        migrated++;
      }
      
      LoggingService.logFirestore('Migration: Migrated $migrated orders out of $total');
      
      return MigrationResult(
        successful: true,
        itemsProcessed: total,
        itemsMigrated: migrated,
      );
    } catch (e) {
      LoggingService.logError('Migration', 'Error migrating orders: $e');
      return MigrationResult(
        successful: false,
        itemsProcessed: 0,
        itemsMigrated: 0,
        errorMessage: 'Error migrating orders: $e',
      );
    }
  }

  /// Migrate all data from Realtime Database to Firestore
  Future<Map<String, MigrationResult>> migrateAllData() async {
    final results = <String, MigrationResult>{};
    
    results['users'] = await migrateUsers();
    results['sessions'] = await migrateSessions();
    results['products'] = await migrateProducts();
    results['categories'] = await migrateCategories();
    results['orders'] = await migrateOrders();
    
    return results;
  }
}

/// Result of a migration operation
class MigrationResult {
  final bool successful;
  final int itemsProcessed;
  final int itemsMigrated;
  final String? errorMessage;

  MigrationResult({
    required this.successful,
    required this.itemsProcessed,
    required this.itemsMigrated,
    this.errorMessage,
  });

  @override
  String toString() {
    if (successful) {
      return 'Migrated $itemsMigrated out of $itemsProcessed items';
    } else {
      return 'Migration failed: $errorMessage';
    }
  }
}