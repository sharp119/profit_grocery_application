import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get_it/get_it.dart';
import 'package:profit_grocery_application/services/user_service_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../services/logging_service.dart';
import '../../../services/otp_service.dart';
import '../../../services/session_manager_interface.dart';
import '../../../services/user_service.dart';

class AuthRepositoryFirestoreImpl implements AuthRepository {
  final OTPService _otpService;
  final SharedPreferences _sharedPreferences;
  final FirebaseFirestore _firestore;
  final FirebaseDatabase _realtimeDatabase;  // For backward compatibility
  final ISessionManager _sessionManager;

  // Collection references
  late final CollectionReference<Map<String, dynamic>> _usersCollection;
  late final CollectionReference<Map<String, dynamic>> _sessionsCollection;

  // Keys for SharedPreferences
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = AppConstants.userTokenKey; // Use the same key as in UserRepository
  static const String _phoneNumberKey = AppConstants.userPhoneKey; // Use the consistent key for phone

  AuthRepositoryFirestoreImpl({
    required OTPService otpService,
    required SharedPreferences sharedPreferences,
    required FirebaseFirestore firestore,
    required FirebaseDatabase realtimeDatabase,
    required ISessionManager sessionManager,
  })  : _otpService = otpService,
        _sharedPreferences = sharedPreferences,
        _firestore = firestore,
        _realtimeDatabase = realtimeDatabase,
        _sessionManager = sessionManager {
    _usersCollection = _firestore.collection(AppConstants.usersCollection);
    _sessionsCollection = _firestore.collection('sessions');
  }

  @override
  Future<Either<Failure, String>> sendOTP(String phoneNumber) async {
    try {
      // Validate phone number
      if (phoneNumber.isEmpty || phoneNumber.length != 10) {
        LoggingService.logError('AuthRepositoryImpl', 'Invalid phone number format: $phoneNumber');
        return Left(PhoneNumberInvalidFailure());
      }

      // Check if user exists by phone number
      final userExists = await _checkUserExistsByPhone(phoneNumber);
      LoggingService.logFirestore('AuthRepositoryImpl: User exists check for ${_maskPhone(phoneNumber)}: $userExists');

      try {
        // Send OTP to the provided phone number
        final requestId = await _otpService.sendOTP(phoneNumber);
        
        // Store the phone number temporarily for the verification step
        await _sharedPreferences.setString(_phoneNumberKey, phoneNumber);
        
        // Also store whether this is a login or registration flow
        await _sharedPreferences.setBool('is_existing_user', userExists);
        
        return Right(requestId);
      } catch (e) {
        LoggingService.logError('AuthRepositoryImpl', 'Error from OTP service: ${e.toString()}');
        
        // Handle specific error cases
        final errorMsg = e.toString().toLowerCase();
        if (errorMsg.contains('too many request') || errorMsg.contains('rate limit')) {
          return Left(TooManyRequestsFailure());
        } else {
          return Left(ServerFailure(message: 'Failed to send OTP: ${e.toString()}'));
        }
      }
    } catch (e) {
      LoggingService.logError('AuthRepositoryImpl: Failed to send OTP', e.toString());
      return Left(ServerFailure(message: 'Failed to send OTP: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> verifyOTP({
    required String requestId,
    required String otp,
    required String phoneNumber,
  }) async {
    try {
      // Validate OTP
      if (otp.isEmpty || otp.length != 4) {
        return Left(ValidationFailure(
            message: 'Please enter a valid 4-digit OTP'));
      }

      // Verify OTP
      try {
        final accessToken = await _otpService.verifyOTP(requestId, otp);
        
        // Store access token in SharedPreferences
        await _sharedPreferences.setString(_tokenKey, accessToken);
      } catch (e) {
        LoggingService.logError('AuthRepositoryImpl', 'OTP verification error: ${e.toString()}');
        
        // Handle specific OTP verification failures
        final errorMsg = e.toString().toLowerCase();
        if (errorMsg.contains('invalid') || errorMsg.contains('incorrect')) {
          return Left(OtpInvalidFailure());
        } else if (errorMsg.contains('expired') || errorMsg.contains('timeout')) {
          return Left(OtpExpiredFailure());
        } else {
          return Left(AuthFailure(message: 'Failed to verify OTP: ${e.toString()}'));
        }
      }
      
      try {
        // Check if this is a login or registration
        final isExistingUser = _sharedPreferences.getBool('is_existing_user') ?? false;
        
        String userId;
        
        if (isExistingUser) {
          // If user exists, get their user ID from the database
          final userIdResult = await _getUserIdByPhone(phoneNumber);
          
          if (userIdResult == null) {
            LoggingService.logError('AuthRepositoryImpl', 'User exists but ID could not be retrieved');
            return Left(UserNotFoundFailure(message: 'User exists but ID could not be retrieved'));
          }
          
          userId = userIdResult;
          LoggingService.logFirestore('AuthRepositoryImpl: Retrieved existing user ID: $userId');
        } else {
          // For new users, generate a new ID
          userId = DateTime.now().millisecondsSinceEpoch.toString();
          LoggingService.logFirestore('AuthRepositoryImpl: Generated new user ID: $userId');
        }
        
        // Save to SharedPreferences
        await _sharedPreferences.setString(_userIdKey, userId);
        await _sharedPreferences.setString(AppConstants.userTokenKey, userId);
        
        // Store phone number for future reference
        await _sharedPreferences.setString(_phoneNumberKey, phoneNumber);
        await _sharedPreferences.setString(AppConstants.userPhoneKey, phoneNumber);
        
        // Mark authentication as completed for better persistence
        await _sharedPreferences.setBool(AppConstants.authCompletedKey, true);
        
        // Store login timestamp for reference
        await _sharedPreferences.setString('last_login_time', DateTime.now().toIso8601String());

        // Create and track session using SessionManager
        final session = await _sessionManager.createSession(userId);
        
        LoggingService.logFirestore(
          'AuthRepositoryImpl: Created session for user $userId'
        );
        
        // Get access token
        final accessToken = _sharedPreferences.getString(_tokenKey);
        if (accessToken == null) {
          return Left(AuthFailure(message: 'Access token not found after OTP verification'));
        }
        
        // Initialize UserService with user data
        final userService = GetIt.instance<IUserService>();
        await userService.loadUserData(userId);
        
        // Get the values from shared preferences to use in the log
        final currentUserId = _sharedPreferences.getString(_userIdKey) ?? 'unknown';
        final isUserExisting = _sharedPreferences.getBool('is_existing_user') ?? false;
        
        LoggingService.logFirestore('AuthRepositoryImpl: Authentication successful. UserID: $currentUserId, isExistingUser: $isUserExisting');

        return Right(accessToken);
      } catch (e) {
        LoggingService.logError('AuthRepositoryImpl', 'Error during session creation: ${e.toString()}');
        // We still want to return success even if session creation has issues
        // since the authentication itself succeeded
        
        // Get access token
        final accessToken = _sharedPreferences.getString(_tokenKey);
        if (accessToken == null) {
          return Left(AuthFailure(message: 'Access token not found after OTP verification'));
        }
        
        return Right(accessToken);
      }
    } catch (e) {
      LoggingService.logError('AuthRepositoryImpl: Failed to verify OTP', e.toString());
      return Left(AuthFailure(
          message: 'Failed to verify OTP: ${e.toString()}'));
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    LoggingService.logFirestore('AuthRepositoryImpl: Checking if user is logged in...');
    
    // First check for basic auth flags in SharedPreferences
    final token = _sharedPreferences.getString(_tokenKey);
    final userId = _sharedPreferences.getString(_userIdKey);
    final authCompleted = _sharedPreferences.getBool(AppConstants.authCompletedKey) ?? false;
    
    if (!authCompleted || token == null || token.isEmpty || userId == null || userId.isEmpty) {
      LoggingService.logFirestore('AuthRepositoryImpl: Not logged in - missing token, userId, or auth not completed');
      return false;
    }
    
    LoggingService.logFirestore('AuthRepositoryImpl: Basic auth flags found, checking session...');

    // Check if session is active using SessionManager
    final sessionActive = await _sessionManager.hasActiveSession();
    if (!sessionActive) {
      LoggingService.logFirestore('AuthRepositoryImpl: No active session found');
      
      // Try to extend the session if it might be expired
      try {
        final extended = await _sessionManager.extendSession(userId);
        if (!extended) {
          LoggingService.logFirestore('AuthRepositoryImpl: Failed to extend session');
          return false;
        } else {
          LoggingService.logFirestore('AuthRepositoryImpl: Successfully extended session');
        }
      } catch (e) {
        LoggingService.logError('AuthRepositoryImpl', 'Error extending session: $e');
        return false;
      }
    }
    
    // Verify token validity with the service - but make this optional
    // to prevent logout if the server is temporarily unavailable
    try {
      final isValid = await _otpService.verifyAccessToken(token);
      if (!isValid) {
        LoggingService.logFirestore('AuthRepositoryImpl: Invalid token - logging out');
        // If token is invalid, log out the user
        await logout();
        return false;
      }
      
      LoggingService.logFirestore('AuthRepositoryImpl: Token verified successfully');
    } catch (e) {
      // Don't fail authentication just because token validation fails
      // This makes the app more resilient to network issues
      LoggingService.logError('AuthRepositoryImpl: Token validation error, but continuing', e.toString());
    }
    
    // Make sure user data is loaded in UserService
    try {
      final userService = GetIt.instance<IUserService>();
      if (!userService.isLoggedIn()) {
        await userService.loadUserData(userId);
        LoggingService.logFirestore('AuthRepositoryImpl: User data loaded successfully');
      }
    } catch (e) {
      LoggingService.logError('AuthRepositoryImpl', 'Error loading user data: $e');
      // Continue even if user data loading fails
    }
    
    LoggingService.logFirestore('AuthRepositoryImpl: User is logged in successfully');
    
    // Update the last active timestamp in session
    try {
      await _sessionManager.extendSession(userId);
    } catch (e) {
      // Just log, don't fail auth check
      LoggingService.logError('AuthRepositoryImpl', 'Error extending session during auth check: $e');
    }
    
    return true;
  }

  @override
  Future<String?> getCurrentUserId() async {
    return _sharedPreferences.getString(_userIdKey);
  }

  @override
  Future<void> logout() async {
    LoggingService.logFirestore('AuthRepositoryImpl: Starting logout process');
    final userId = await getCurrentUserId();
    
    // Use SessionManager to invalidate the session
    if (userId != null) {
      try {
        await _sessionManager.invalidateSession(userId);
        LoggingService.logFirestore('AuthRepositoryImpl: Invalidated session for $userId');
      } catch (e) {
        // Just log the error, don't prevent logout
        LoggingService.logError('AuthRepositoryImpl: Error invalidating session', e.toString());
      }
    }
    
    // Clear user data from UserService
    try {
      final userService = GetIt.instance<IUserService>();
      userService.clearCurrentUser();
      LoggingService.logFirestore('AuthRepositoryImpl: Cleared user data from UserService');
    } catch (e) {
      LoggingService.logError('AuthRepositoryImpl: Error clearing UserService data', e.toString());
    }
    
    // Clear ALL authentication data
    await _sharedPreferences.remove(_tokenKey);
    await _sharedPreferences.remove(_userIdKey);
    await _sharedPreferences.remove(AppConstants.userTokenKey);
    await _sharedPreferences.remove(AppConstants.authCompletedKey);
    await _sharedPreferences.remove('last_login_time');
    
    // Clear session data
    await _sharedPreferences.remove('user_session'); // _sessionPrefKey
    await _sharedPreferences.remove('session_token'); // _sessionTokenKey
    await _sharedPreferences.remove('session_created'); // _sessionCreatedKey
    await _sharedPreferences.remove('session_expires'); // _sessionExpiresKey
    await _sharedPreferences.remove('session_user_id'); // _sessionUserIdKey
    
    // We'll keep the phone number for convenience
    // await _sharedPreferences.remove(_phoneNumberKey);
    // await _sharedPreferences.remove(AppConstants.userPhoneKey);
    
    LoggingService.logFirestore('AuthRepositoryImpl: Logout completed successfully');
  }

  @override
  Future<bool> verifyAccessToken(String token) async {
    try {
      return await _otpService.verifyAccessToken(token);
    } catch (e) {
      LoggingService.logError('AuthRepositoryImpl: Token verification error', e.toString());
      return false;
    }
  }
  
  // Helper methods
  
  /// Check if a user with this phone number already exists in Firestore
  Future<bool> _checkUserExistsByPhone(String phoneNumber) async {
    try {
      // Query Firestore for user with matching phone number
      final querySnapshot = await _usersCollection
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();
      
      // If not found in Firestore, check Realtime Database for backward compatibility
      if (querySnapshot.docs.isEmpty) {
        // Fall back to checking Realtime Database
        final usersRef = _realtimeDatabase.ref().child(AppConstants.usersCollection);
        final query = usersRef.orderByChild('phoneNumber').equalTo(phoneNumber);
        final snapshot = await query.get();
        
        return snapshot.exists;
      }
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      LoggingService.logError('AuthRepositoryImpl: Error checking user existence', e.toString());
      return false;
    }
  }
  
  /// Get user ID by phone number, checking both Firestore and Realtime Database
  Future<String?> _getUserIdByPhone(String phoneNumber) async {
    try {
      // First check Firestore
      final querySnapshot = await _usersCollection
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      }
      
      // If not found in Firestore, check Realtime Database
      final usersRef = _realtimeDatabase.ref().child(AppConstants.usersCollection);
      final query = usersRef.orderByChild('phoneNumber').equalTo(phoneNumber);
      final snapshot = await query.get();
      
      if (!snapshot.exists) {
        return null;
      }
      
      // Get the first user with the matching phone number
      final userMap = (snapshot.value as Map).entries.first;
      return userMap.key as String; // The key is the user ID
    } catch (e) {
      LoggingService.logError('AuthRepositoryImpl: Error getting user ID by phone', e.toString());
      return null;
    }
  }
  
  /// Mask phone number for logging
  String _maskPhone(String phone) {
    if (phone.length <= 4) return phone;
    return 'XXXXXX' + phone.substring(phone.length - 4);
  }
}
