import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/failures.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../services/otp_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final OTPService _otpService;
  final SharedPreferences _sharedPreferences;

  // Keys for SharedPreferences
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _phoneNumberKey = 'phone_number';

  AuthRepositoryImpl({
    required OTPService otpService,
    required SharedPreferences sharedPreferences,
  })  : _otpService = otpService,
        _sharedPreferences = sharedPreferences;

  @override
  Future<Either<Failure, String>> sendOTP(String phoneNumber) async {
    try {
      // Validate phone number
      if (phoneNumber.isEmpty || phoneNumber.length != 10) {
        return Left(ValidationFailure(
            message: 'Please enter a valid 10-digit phone number'));
      }

      // Send OTP to the provided phone number
      final requestId = await _otpService.sendOTP(phoneNumber);
      return Right(requestId);
    } catch (e) {
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
      
      // For demo purposes, we're using a simple UUID as user ID
      // In a real app, you'd get this from the backend
      final userId = DateTime.now().millisecondsSinceEpoch.toString();
      await _sharedPreferences.setString(_userIdKey, userId);
      
      // Store phone number for future reference
      await _sharedPreferences.setString(_phoneNumberKey, phoneNumber);

      return Right(accessToken);
    } catch (e) {
      return Left(AuthFailure(
          message: 'Failed to verify OTP: ${e.toString()}'));
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = _sharedPreferences.getString(_tokenKey);
    if (token == null || token.isEmpty) {
      return false;
    }

    // For a simple app, we'll just check if the token exists
    // In a real app, you'd also verify the token's validity
    return true;
  }

  @override
  Future<String?> getCurrentUserId() async {
    return _sharedPreferences.getString(_userIdKey);
  }

  @override
  Future<void> logout() async {
    await _sharedPreferences.remove(_tokenKey);
    await _sharedPreferences.remove(_userIdKey);
    // We'll keep the phone number for convenience
  }

  @override
  Future<bool> verifyAccessToken(String token) async {
    try {
      return await _otpService.verifyAccessToken(token);
    } catch (e) {
      return false;
    }
  }
}