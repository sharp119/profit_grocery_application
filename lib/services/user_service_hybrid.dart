import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../data/models/firestore/user_firestore_model.dart';
import '../data/models/user_model.dart';
import '../domain/entities/user.dart';
import 'logging_service.dart';

/// A singleton service that provides access to the current user data
/// throughout the application. Supports both Firestore and Realtime Database.
class UserServiceHybrid {
  // Singleton pattern
  static final UserServiceHybrid _instance = UserServiceHybrid._internal();
  factory UserServiceHybrid() => _instance;
  UserServiceHybrid._internal();

  // User data
  User? _currentUser;
  final _userStreamController = StreamController<User?>.broadcast();

  // Dependencies
  late FirebaseFirestore _firestore;
  late FirebaseDatabase _realtimeDatabase;
  late SharedPreferences _sharedPreferences;
  bool _isInitialized = false;
  bool _preferFirestore = true;  // Flag to indicate preference for Firestore

  // User data stream
  Stream<User?> get userStream => _userStreamController.stream;

  /// Initialize the user service
  Future<void> init({
    required FirebaseFirestore firestore,
    required FirebaseDatabase realtimeDatabase,
    required SharedPreferences sharedPreferences,
    bool preferFirestore = true,
  }) async {
    if (_isInitialized) return;
    
    _firestore = firestore;
    _realtimeDatabase = realtimeDatabase;
    _sharedPreferences = sharedPreferences;
    _preferFirestore = preferFirestore;
    _isInitialized = true;

    LoggingService.logFirestore('UserServiceHybrid: Initialized with preferFirestore=$preferFirestore');
    
    try {
      // Check if there's a userId stored
      final userId = _sharedPreferences.getString(AppConstants.userTokenKey);
      if (userId != null) {
        await loadUserData(userId);
      }
    } catch (e) {
      LoggingService.logError('UserServiceHybrid', 'Error during initialization: $e');
    }
  }

  /// Ensure the service is initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw Exception('UserServiceHybrid not initialized. Call init() first.');
    }
  }

  /// Load user data from Firestore first, with fallback to Realtime Database
  Future<void> loadUserData(String userId) async {
    _ensureInitialized();
    
    try {
      LoggingService.logFirestore('UserServiceHybrid: Loading user data for userId: $userId');

      User? user;
      
      // Try Firestore first if preferred
      if (_preferFirestore) {
        try {
          user = await _loadUserFromFirestore(userId);
        } catch (e) {
          LoggingService.logError('UserServiceHybrid', 'Error loading user from Firestore, falling back to RTDB: $e');
        }
      }
      
      // If Firestore failed or not preferred, try Realtime Database
      if (user == null) {
        try {
          user = await _loadUserFromRealtimeDB(userId);
        } catch (e) {
          LoggingService.logError('UserServiceHybrid', 'Error loading user from Realtime Database: $e');
        }
      }
      
      if (user == null) {
        LoggingService.logFirestore('UserServiceHybrid: User not found in either database for userId: $userId');
        return;
      }
      
      // Update current user
      _currentUser = user;
      _userStreamController.add(user);
      
      LoggingService.logFirestore('UserServiceHybrid: User loaded successfully: ${user.name ?? "unnamed"}');
      
      // Also listen for changes to the user data
      if (_preferFirestore) {
        _setupFirestoreUserListener(userId);
      } else {
        _setupRealtimeDBUserListener(userId);
      }
    } catch (e) {
      LoggingService.logError('UserServiceHybrid', 'Error loading user data: $e');
    }
  }
  
  /// Load a user from Firestore
  Future<User?> _loadUserFromFirestore(String userId) async {
    // Get user from Firestore
    final docSnapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .get();
    
    if (!docSnapshot.exists) {
      return null;
    }
    
    // Convert to UserFirestoreModel
    return UserFirestoreModel.fromFirestore(
      docSnapshot as DocumentSnapshot<Map<String, dynamic>>,
      null,
    );
  }
  
  /// Load a user from Realtime Database
  Future<User?> _loadUserFromRealtimeDB(String userId) async {
    // Get user from Realtime Database
    final userRef = _realtimeDatabase
        .ref()
        .child(AppConstants.usersCollection)
        .child(userId);
    
    final snapshot = await userRef.get();
    
    if (!snapshot.exists) {
      return null;
    }
    
    // Parse user data
    final userData = Map<String, dynamic>.from(snapshot.value as Map);
    
    // Create user model
    return UserModel.fromJson(userData);
  }
  
  /// Setup a listener for real-time updates to user data in Firestore
  void _setupFirestoreUserListener(String userId) {
    try {
      final userRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId);
      
      userRef.snapshots().listen((docSnapshot) {
        if (!docSnapshot.exists) return;
        
        try {
          final user = UserFirestoreModel.fromFirestore(
            docSnapshot as DocumentSnapshot<Map<String, dynamic>>,
            null,
          );
          
          // Update current user
          _currentUser = user;
          _userStreamController.add(user);
          
          LoggingService.logFirestore('UserServiceHybrid: User data updated from Firestore: ${user.name ?? "unnamed"}');
        } catch (e) {
          LoggingService.logError('UserServiceHybrid', 'Error parsing Firestore user data update: $e');
        }
      });
      
      LoggingService.logFirestore('UserServiceHybrid: Firestore user data listener set up');
    } catch (e) {
      LoggingService.logError('UserServiceHybrid', 'Error setting up Firestore user data listener: $e');
    }
  }
  
  /// Setup a listener for real-time updates to user data in Realtime Database
  void _setupRealtimeDBUserListener(String userId) {
    try {
      final userRef = _realtimeDatabase
          .ref()
          .child(AppConstants.usersCollection)
          .child(userId);
      
      userRef.onValue.listen((event) {
        if (!event.snapshot.exists) return;
        
        try {
          final userData = Map<String, dynamic>.from(event.snapshot.value as Map);
          final user = UserModel.fromJson(userData);
          
          // Update current user
          _currentUser = user;
          _userStreamController.add(user);
          
          LoggingService.logFirestore('UserServiceHybrid: User data updated from RTDB: ${user.name ?? "unnamed"}');
        } catch (e) {
          LoggingService.logError('UserServiceHybrid', 'Error parsing RTDB user data update: $e');
        }
      });
      
      LoggingService.logFirestore('UserServiceHybrid: RTDB user data listener set up');
    } catch (e) {
      LoggingService.logError('UserServiceHybrid', 'Error setting up RTDB user data listener: $e');
    }
  }

  /// Get the current user data (null if not logged in)
  User? getCurrentUser() {
    return _currentUser;
  }

  /// Get the current user ID (null if not logged in)
  String? getCurrentUserId() {
    return _currentUser?.id;
  }

  /// Get the user's name (or null if not available)
  String? getUserName() {
    return _currentUser?.name;
  }

  /// Get the user's phone number (or null if not available)
  String? getUserPhone() {
    return _currentUser?.phoneNumber;
  }

  /// Clear the current user data (logout)
  void clearCurrentUser() {
    _currentUser = null;
    _userStreamController.add(null);
    LoggingService.logFirestore('UserServiceHybrid: User data cleared');
  }
  
  /// Check if the user is logged in
  bool isLoggedIn() {
    return _currentUser != null;
  }
  
  /// Listen to user data changes
  StreamSubscription<User?> listenToUserChanges(void Function(User?) onUserChanged) {
    return _userStreamController.stream.listen(onUserChanged);
  }
  
  /// Dispose the service
  void dispose() {
    _userStreamController.close();
  }
}
