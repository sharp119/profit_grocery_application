import 'package:dartz/dartz.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../services/logging_service.dart';
import '../../services/otp_service.dart';
import '../../services/session_manager.dart';

class AuthRepositoryImpl implements AuthRepository {
  final OTPService _otpService;
  final SharedPreferences _sharedPreferences;
  final FirebaseDatabase _firebaseDatabase;
  final SessionManager _sessionManager;

  // Keys for SharedPreferences
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = AppConstants.userTokenKey; // Use the same key as in UserRepository
  static const String _phoneNumberKey = AppConstants.userPhoneKey; // Use the consistent key for phone

  AuthRepositoryImpl({
    required OTPService otpService,
    required SharedPreferences sharedPreferences,
    required FirebaseDatabase firebaseDatabase,
    SessionManager? sessionManager,
  })  : _otpService = otpService,
        _sharedPreferences = sharedPreferences,
        _firebaseDatabase = firebaseDatabase,
        _sessionManager = sessionManager ?? SessionManager();

  @override
  Future<Either<Failure, String>> sendOTP(String phoneNumber) async {
    try {
      // Validate phone number
      if (phoneNumber.isEmpty || phoneNumber.length != 10) {
        return Left(ValidationFailure(
            message: 'Please enter a valid 10-digit phone number'));
      }

      // Check if user exists by phone number
      final userExists = await _checkUserExistsByPhone(phoneNumber);
      LoggingService.logFirestore('AuthRepositoryImpl: User exists check for ${_maskPhone(phoneNumber)}: $userExists');

      // Send OTP to the provided phone number
      final requestId = await _otpService.sendOTP(phoneNumber);
      
      // Store the phone number temporarily for the verification step
      await _sharedPreferences.setString(_phoneNumberKey, phoneNumber);
      
      // Also store whether this is a login or registration flow
      await _sharedPreferences.setBool('is_existing_user', userExists);
      
      return Right(requestId);
    } catch (e) {
      LoggingService.logError('AuthRepositoryImpl: Failed to send OTP', e.toString());
      return Left(ServerFailure(
          message: 'Failed to send OTP: ${e.toString()}'));
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
      final accessToken = await _otpService.verifyOTP(requestId, otp);

      // Store access token in SharedPreferences
      await _sharedPreferences.setString(_tokenKey, accessToken);
      
      // Check if this is a login or registration
      final isExistingUser = _sharedPreferences.getBool('is_existing_user') ?? false;
      
      String userId;
      
      if (isExistingUser) {
        // If user exists, get their user ID from the database
        final userIdResult = await _getUserIdByPhone(phoneNumber);
        
        if (userIdResult == null) {
          return Left(AuthFailure(message: 'User exists but ID could not be retrieved'));
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

      // Create and track session using SessionManager
      await _sessionManager.createSession(userId);

      LoggingService.logFirestore('AuthRepositoryImpl: Authentication successful. UserID: $userId, isExistingUser: $isExistingUser');

      return Right(accessToken);
    } catch (e) {
      LoggingService.logError('AuthRepositoryImpl: Failed to verify OTP', e.toString());
      return Left(AuthFailure(
          message: 'Failed to verify OTP: ${e.toString()}'));
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = _sharedPreferences.getString(_tokenKey);
    final userId = _sharedPreferences.getString(_userIdKey);
    
    if (token == null || token.isEmpty || userId == null || userId.isEmpty) {
      return false;
    }

    // First check if session is active using SessionManager
    if (!await _sessionManager.hasActiveSession()) {
      LoggingService.logFirestore('AuthRepositoryImpl: No active session found');
      return false;
    }
    
    // Also verify token validity with the service
    try {
      final isValid = await _otpService.verifyAccessToken(token);
      if (!isValid) {
        // If token is invalid, log out the user
        await logout();
        return false;
      }
      return true;
    } catch (e) {
      LoggingService.logError('AuthRepositoryImpl: Token validation error', e.toString());
      return false;
    }
  }

  @override
  Future<String?> getCurrentUserId() async {
    return _sharedPreferences.getString(_userIdKey);
  }

  @override
  Future<void> logout() async {
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
    
    // Clear authentication data
    await _sharedPreferences.remove(_tokenKey);
    await _sharedPreferences.remove(_userIdKey);
    await _sharedPreferences.remove(AppConstants.userTokenKey);
    // We'll keep the phone number for convenience
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
  
  /// Check if a user with this phone number already exists
  Future<bool> _checkUserExistsByPhone(String phoneNumber) async {
    try {
      final usersRef = _firebaseDatabase.ref().child(AppConstants.usersCollection);
      final query = usersRef.orderByChild('phoneNumber').equalTo(phoneNumber);
      final snapshot = await query.get();
      
      return snapshot.exists;
    } catch (e) {
      LoggingService.logError('AuthRepositoryImpl: Error checking user existence', e.toString());
      return false;
    }
  }
  
  /// Get user ID by phone number
  Future<String?> _getUserIdByPhone(String phoneNumber) async {
    try {
      final usersRef = _firebaseDatabase.ref().child(AppConstants.usersCollection);
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