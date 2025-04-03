import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';

abstract class AuthRepository {
  /// Send OTP to phone number
  Future<Either<Failure, String>> sendOTP(String phoneNumber);
  
  /// Verify OTP and login/register user
  Future<Either<Failure, String>> verifyOTP({
    required String requestId,
    required String otp,
    required String phoneNumber,
  });
  
  /// Check if user is logged in
  Future<bool> isLoggedIn();
  
  /// Get current user ID
  Future<String?> getCurrentUserId();
  
  /// Logout user
  Future<void> logout();
  
  /// Verify access token
  Future<bool> verifyAccessToken(String token);
}