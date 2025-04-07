import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../data/models/user_model.dart';
import '../domain/entities/user.dart';
import 'logging_service.dart';

/// A singleton service that provides access to the current user data
/// throughout the application.
class UserService {
  // Singleton pattern
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  // User data
  User? _currentUser;
  final _userStreamController = StreamController<User?>.broadcast();

  // Dependencies
  late FirebaseDatabase _firebaseDatabase;
  late SharedPreferences _sharedPreferences;
  bool _isInitialized = false;

  // User data stream
  Stream<User?> get userStream => _userStreamController.stream;

  /// Initialize the user service
  Future<void> init({
    required FirebaseDatabase firebaseDatabase, 
    required SharedPreferences sharedPreferences,
  }) async {
    if (_isInitialized) return;
    
    _firebaseDatabase = firebaseDatabase;
    _sharedPreferences = sharedPreferences;
    _isInitialized = true;

    LoggingService.logFirestore('UserService: Initialized');
    
    try {
      // Check if there's a userId stored
      final userId = _sharedPreferences.getString(AppConstants.userTokenKey);
      if (userId != null) {
        await loadUserData(userId);
      }
    } catch (e) {
      LoggingService.logError('UserService', 'Error during initialization: $e');
    }
  }

  /// Ensure the service is initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw Exception('UserService not initialized. Call init() first.');
    }
  }

  /// Load user data from Firebase
  Future<void> loadUserData(String userId) async {
    _ensureInitialized();
    
    try {
      LoggingService.logFirestore('UserService: Loading user data for userId: $userId');
      
      final userRef = _firebaseDatabase
          .ref()
          .child(AppConstants.usersCollection)
          .child(userId);
      
      final snapshot = await userRef.get();
      
      if (!snapshot.exists) {
        LoggingService.logFirestore('UserService: User not found for userId: $userId');
        return;
      }
      
      // Parse user data
      final userData = Map<String, dynamic>.from(snapshot.value as Map);
      
      // Add the userId to the userData map since it's stored as the key in Firebase
      userData['id'] = userId;
      
      // Create user model from JSON data
      final user = UserModel.fromJson(userData);
      
      // Update current user (UserModel is already a subclass of User, so no need for toEntity())
      _currentUser = user;
      _userStreamController.add(user);
      
      LoggingService.logFirestore('UserService: User loaded successfully: ${user.name ?? "unnamed"}');
      
      // Also listen for changes to the user data
      _setupUserDataListener(userId);
    } catch (e) {
      LoggingService.logError('UserService', 'Error loading user data: $e');
    }
  }
  
  /// Setup a listener for real-time updates to user data
  void _setupUserDataListener(String userId) {
    try {
      final userRef = _firebaseDatabase
          .ref()
          .child(AppConstants.usersCollection)
          .child(userId);
      
      userRef.onValue.listen((event) {
        if (!event.snapshot.exists) return;
        
        try {
          final userData = Map<String, dynamic>.from(event.snapshot.value as Map);
          
          // Add the userId to the userData map
          userData['id'] = userId;
          
          // Create user model from JSON data
          final user = UserModel.fromJson(userData);
          
          // Update current user
          _currentUser = user;
          _userStreamController.add(user);
          
          LoggingService.logFirestore('UserService: User data updated: ${user.name ?? "unnamed"}');
        } catch (e) {
          LoggingService.logError('UserService', 'Error parsing user data update: $e');
        }
      });
      
      LoggingService.logFirestore('UserService: User data listener set up');
    } catch (e) {
      LoggingService.logError('UserService', 'Error setting up user data listener: $e');
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
    LoggingService.logFirestore('UserService: User data cleared');
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