// lib/services/otp_service.dart

import 'dart:convert';
import 'package:sendotp_flutter_sdk/sendotp_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:profit_grocery_application/services/logging_service.dart';

class OTPService {
  // Singleton pattern
  static final OTPService _instance = OTPService._internal();
  factory OTPService() => _instance;
  OTPService._internal();

  // Constants
  static const String WIDGET_ID = '356373625657393734323036'; // Your widget ID
  static const String AUTH_TOKEN = '444220TAsnah6V67da3129P1'; // Your auth token
  static const String VERIFY_TOKEN_URL = 'https://control.msg91.com/api/v5/widget/verifyAccessToken';
  static const String AUTH_KEY = '444220AWZ0RfzSl67da321dP1'; // Your auth key
  
  bool _isInitialized = false;

  /// Initialize the OTP service
  Future<void> initialize() async {
    if (!_isInitialized) {
      try {
        LoggingService.logFirestore('OTPService: Initializing');
        OTPWidget.initializeWidget(WIDGET_ID, AUTH_TOKEN);
        _isInitialized = true;
        LoggingService.logFirestore('OTPService: Initialized successfully');
      } catch (e) {
        LoggingService.logError('OTPService: Error during initialization', e);
        throw Exception('Failed to initialize OTP service: $e');
      }
    }
  }

  /// Send OTP to the provided phone number
  /// Returns request ID needed for verification
  Future<String> sendOTP(String phoneNumber) async {
    try {
      LoggingService.logFirestore('OTPService: Sending OTP to ${_maskPhone(phoneNumber)}');
      
      if (!_isInitialized) {
        await initialize();
      }
      
      final data = {'identifier': '91$phoneNumber'};
      final response = await OTPWidget.sendOTP(data);
      
      if (response == null || response['message'] == null) {
        throw Exception('Invalid response from OTP service');
      }
      
      final reqId = response['message'];
      LoggingService.logFirestore('OTPService: OTP sent successfully, reqId: $reqId');
      
      return reqId;
    } catch (e) {
      LoggingService.logError('OTPService: Error sending OTP', e);
      throw Exception('Failed to send OTP: $e');
    }
  }

  /// Verify the OTP code
  /// Returns access token on success
  Future<String> verifyOTP(String reqId, String otp) async {
    try {
      LoggingService.logFirestore('OTPService: Verifying OTP');
      
      if (!_isInitialized) {
        await initialize();
      }
      
      final data = {
        'reqId': reqId,
        'otp': otp
      };
      
      final response = await OTPWidget.verifyOTP(data);
      
      if (response == null || response['message'] == null) {
        throw Exception('Invalid response from OTP verification');
      }
      
      final accessToken = response['message'];
      LoggingService.logFirestore('OTPService: OTP verified successfully');
      
      // Verify the access token with the server
      final isValid = await _verifyAccessToken(accessToken);
      
      if (!isValid) {
        throw Exception('Access token verification failed');
      }
      
      return accessToken;
    } catch (e) {
      LoggingService.logError('OTPService: Error verifying OTP', e);
      throw Exception('Failed to verify OTP: $e');
    }
  }

  /// Public method for external verification of access token
  Future<bool> verifyAccessToken(String accessToken) async {
    return await _verifyAccessToken(accessToken);
  }

  /// Verify the access token with the MSG91 server
  Future<bool> _verifyAccessToken(String accessToken) async {
    try {
      LoggingService.logFirestore('OTPService: Verifying access token');
      
      final headers = {
        'Content-Type': 'application/json'
      };
      
      final body = jsonEncode({
        'authkey': AUTH_KEY,
        'access-token': accessToken
      });
      
      final response = await http.post(
        Uri.parse(VERIFY_TOKEN_URL),
        headers: headers,
        body: body,
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Case 1: Success response
        if (responseData['type'] == 'success') {
          LoggingService.logFirestore('OTPService: Access token verified successfully');
          return true;
        }
        
        // Case 2: "Already verified" error (code 702) - This is actually valid
        if (responseData['code'] == 702 || 
            (responseData['message'] != null && 
             responseData['message'].toString().contains('already verified'))) {
          LoggingService.logFirestore('OTPService: Token already verified (valid)');
          return true;
        }
      }
      
      LoggingService.logError('OTPService: Access token verification failed', response.body);
      return false;
    } catch (e) {
      LoggingService.logError('OTPService: Error verifying access token', e);
      return false;
    }
  }
  
  // Mask phone number for logging
  String _maskPhone(String phone) {
    if (phone.length <= 4) return phone;
    return 'XXXXXX' + phone.substring(phone.length - 4);
  }
}