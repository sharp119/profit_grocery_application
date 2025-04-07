import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/user_repository.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/user_repository_impl.dart';
import '../data/repositories/firestore/auth_repository_firestore_impl.dart';
import '../data/repositories/firestore/user_repository_firestore_impl.dart';
import 'otp_service.dart';
import 'session_manager.dart';
import 'session_manager_firestore.dart';
import 'session_manager_interface.dart';
import 'user_service.dart';
import 'user_service_hybrid.dart';
import 'user_service_interface.dart';
import 'logging_service.dart';

/// Factory for creating repository instances based on database preference
class RepositoryFactory {
  final FirebaseFirestore _firestore;
  final FirebaseDatabase _realtimeDatabase;
  final SharedPreferences _sharedPreferences;
  final OTPService _otpService;
  final bool _preferFirestore;

  RepositoryFactory({
    required FirebaseFirestore firestore,
    required FirebaseDatabase realtimeDatabase,
    required SharedPreferences sharedPreferences,
    required OTPService otpService,
    bool preferFirestore = true,
  })  : _firestore = firestore,
        _realtimeDatabase = realtimeDatabase,
        _sharedPreferences = sharedPreferences,
        _otpService = otpService,
        _preferFirestore = preferFirestore;

  /// Create an appropriate AuthRepository implementation
  Future<AuthRepository> createAuthRepository() async {
    if (_preferFirestore) {
      LoggingService.logFirestore('RepositoryFactory: Creating FirestoreAuthRepository');
      
      // Initialize SessionManagerFirestore
      final ISessionManager sessionManager = SessionManagerFirestore();
      if (sessionManager is SessionManagerFirestore) {
        sessionManager.setSharedPreferences(_sharedPreferences);
        sessionManager.setFirestore(_firestore);
      }
      await sessionManager.init();
      
      return AuthRepositoryFirestoreImpl(
        otpService: _otpService,
        sharedPreferences: _sharedPreferences,
        firestore: _firestore,
        realtimeDatabase: _realtimeDatabase, // For backward compatibility
        sessionManager: sessionManager,
      );
    } else {
      LoggingService.logFirestore('RepositoryFactory: Creating RealtimeDBAuthRepository');
      
      // Initialize SessionManager
      final ISessionManager sessionManager = SessionManager();
      if (sessionManager is SessionManager) {
        sessionManager.setSharedPreferences(_sharedPreferences);
        sessionManager.setFirebaseDatabase(_realtimeDatabase);
      }
      await sessionManager.init();
      
      return AuthRepositoryImpl(
        otpService: _otpService,
        sharedPreferences: _sharedPreferences,
        firebaseDatabase: _realtimeDatabase,
        sessionManager: sessionManager as SessionManager,
      );
    }
  }

  /// Create an appropriate UserRepository implementation
  Future<UserRepository> createUserRepository() async {
    if (_preferFirestore) {
      LoggingService.logFirestore('RepositoryFactory: Creating FirestoreUserRepository');
      
      // Initialize SessionManagerFirestore
      final ISessionManager sessionManager = SessionManagerFirestore();
      if (sessionManager is SessionManagerFirestore) {
        sessionManager.setSharedPreferences(_sharedPreferences);
        sessionManager.setFirestore(_firestore);
      }
      await sessionManager.init();
      
      return UserRepositoryFirestoreImpl(
        firestore: _firestore,
        sharedPreferences: _sharedPreferences,
        sessionManager: sessionManager,
      );
    } else {
      LoggingService.logFirestore('RepositoryFactory: Creating RealtimeDBUserRepository');
      
      // Initialize SessionManager
      final ISessionManager sessionManager = SessionManager();
      if (sessionManager is SessionManager) {
        sessionManager.setSharedPreferences(_sharedPreferences);
        sessionManager.setFirebaseDatabase(_realtimeDatabase);
      }
      await sessionManager.init();
      
      return UserRepositoryImpl(
        firebaseDatabase: _realtimeDatabase,
        sharedPreferences: _sharedPreferences,
        sessionManager: sessionManager as SessionManager,
      );
    }
  }

  /// Create an appropriate UserService implementation
  Future<IUserService> createUserService() async {
    // If we prefer hybrid approach, use UserServiceHybrid
    if (true) { // Always use hybrid for now as it's more robust
      LoggingService.logFirestore('RepositoryFactory: Creating UserServiceHybrid');
      
      final userService = UserServiceHybrid();
      await userService.init(
        firestore: _firestore,
        realtimeDatabase: _realtimeDatabase,
        sharedPreferences: _sharedPreferences,
        preferFirestore: _preferFirestore,
      );
      
      return userService;
    } else {
      // Legacy option - use only RTDB implementation
      LoggingService.logFirestore('RepositoryFactory: Creating UserService (RTDB)');
      
      final userService = UserService();
      await userService.init(
        firebaseDatabase: _realtimeDatabase,
        sharedPreferences: _sharedPreferences,
      );
      
      return userService;
    }
  }
}
