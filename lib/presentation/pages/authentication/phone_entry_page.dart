import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:profit_grocery_application/presentation/pages/authentication/user_registration_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../services/logging_service.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import 'otp_verification_page.dart';

class PhoneEntryPage extends StatefulWidget {
  const PhoneEntryPage({super.key});

  @override
  State<PhoneEntryPage> createState() => _PhoneEntryPageState();
}

class _PhoneEntryPageState extends State<PhoneEntryPage> {
  final TextEditingController _phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // Track user flow state
  bool _isCheckingUserStatus = false;
  bool? _isExistingUser;
  String _flowStatusMessage = '';

  void _submitPhoneNumber() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Sanitize the phone number (remove any spaces or symbols)
    final sanitizedPhone = _phoneController.text.trim().replaceAll(RegExp(r'[^\d]'), '');
    
    // Ensure it's a 10-digit number
    if (sanitizedPhone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Set UI to checking state
    setState(() {
      _isCheckingUserStatus = true;
      _flowStatusMessage = 'Checking phone number...';
    });
    
    try {
      // Check Firestore first since that's our primary database
      final firestore = FirebaseFirestore.instance;
      final usersCollection = firestore.collection(AppConstants.usersCollection);
      
      // Query for user with this phone number
      final querySnapshot = await usersCollection
          .where('phoneNumber', isEqualTo: sanitizedPhone)
          .limit(1)
          .get();
      
      bool userExists = querySnapshot.docs.isNotEmpty;
      String userOrigin = "Firestore";
      
      // If not found in Firestore, check RTDB as fallback
      if (!userExists) {
        userOrigin = "Not found in either database";
        try {
          // Try to query RTDB - might fail if index not set up
          final usersRef = FirebaseDatabase.instance.ref().child(AppConstants.usersCollection);
          final query = usersRef.orderByChild('phoneNumber').equalTo(sanitizedPhone);
          final snapshot = await query.get();
          
          userExists = snapshot.exists;
          if (userExists) {
            userOrigin = "RTDB";
          }
        } catch (rtdbError) {
          // Log the specific RTDB error but continue with Firestore result
          LoggingService.logError('PhoneEntryPage', 'RTDB query error: $rtdbError');
          
          // Check if it's an indexing error
          if (rtdbError.toString().contains('index-not-defined')) {
            LoggingService.logFirestore('PhoneEntryPage: RTDB index not defined error - you need to add ".indexOn": ["phoneNumber"] to your database rules');
          }
        }
      }
      
      setState(() {
        _isExistingUser = userExists;
        _flowStatusMessage = userExists 
            ? 'Welcome back! Sending verification code...' 
            : 'Welcome to ProfitGrocery! We\'ll set up your account.';
        _isCheckingUserStatus = false;
      });
      
      // Log the results of our user check
      LoggingService.logFirestore(
        'PhoneEntryPage: User exists check for ${sanitizedPhone.substring(sanitizedPhone.length - 4, sanitizedPhone.length)}: ' +
        '$userExists (source: $userOrigin)'
      );
      
      // Store the user existence status for use in other pages with better logging
      final prefs = await SharedPreferences.getInstance();
      
      // Log existing values before changing them
      final existingFlag = prefs.getBool('is_existing_user');
      LoggingService.logFirestore(
        'PhoneEntryPage: Current is_existing_user flag: $existingFlag, setting to: $userExists'
      );
      
      await prefs.setBool('is_existing_user', userExists);
      await prefs.setString(AppConstants.userPhoneKey, sanitizedPhone);
      
      // Verify the value was saved correctly
      final savedFlag = prefs.getBool('is_existing_user');
      LoggingService.logFirestore(
        'PhoneEntryPage: Saved is_existing_user flag value: $savedFlag'
      );
      
      // Different flow based on whether user exists or not
      if (userExists) {
        // If user exists, send OTP for verification
        LoggingService.logFirestore('PhoneEntryPage: Existing user - sending OTP for login flow');
        context.read<AuthBloc>().add(SendOtpEvent(sanitizedPhone));
      } else {
        // If new user, navigate to registration page first
        LoggingService.logFirestore('PhoneEntryPage: New user - navigating to registration flow');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserRegistrationPage(
              phoneNumber: sanitizedPhone,
              isPreRegistration: true, // Flag to indicate this is before OTP verification
            ),
          ),
        );
      }
    } catch (e) {
      LoggingService.logError('PhoneEntryPage', 'Error checking user existence: $e');
      
      // Format a more user-friendly error message
      String errorMessage = 'Error checking user status';
      
      // Extract meaningful part of the error
      if (e.toString().contains('index-not-defined')) {
        errorMessage = 'Database indexing issue: Please update Firebase rules';
        LoggingService.logFirestore('PhoneEntryPage: Firebase database indexing error detected');
      } else {
        errorMessage = 'Error checking user status: ${e.toString().split(":").first}';
      }
      
      // Show the error to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$errorMessage. Continuing with registration.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      
      // Default to new user if we can't check
      setState(() {
        _isExistingUser = false;
        _isCheckingUserStatus = false;
        _flowStatusMessage = 'Welcome to ProfitGrocery! We\'ll set up your account.';
      });
      
      // Store phone number in prefs anyway
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_existing_user', false);
      await prefs.setString(AppConstants.userPhoneKey, sanitizedPhone);
      
      // If we can't determine user status, assume new user and navigate to registration
      LoggingService.logFirestore('PhoneEntryPage: Error checking user - defaulting to registration flow');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserRegistrationPage(
            phoneNumber: sanitizedPhone,
            isPreRegistration: true, // Flag to indicate this is before OTP verification
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          LoggingService.logFirestore('PhoneEntryPage listener - AuthState: ${state.status}');
          
          if (state.status == AuthStatus.otpSent && state.requestId != null && state.phoneNumber != null) {
            LoggingService.logFirestore('PhoneEntryPage: OTP sent, navigating to verification page');
            
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OtpVerificationPage(
                  phoneNumber: state.phoneNumber!,
                  requestId: state.requestId!,
                ),
              ),
            );
          } else if (state.status == AuthStatus.error) {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Failed to send OTP'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(AppConstants.defaultPadding.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 40.h),
                    
                    // Text(
                    //   'Welcome to',
                    //   style: TextStyle(
                    //     color: Colors.white,
                    //     fontSize: 24.sp,
                    //     fontWeight: FontWeight.w500,
                    //   ),
                    // ),
                    // App logo/branding
                   
                    Center(
                      child: Stack(
                        children: [
                          Image.asset(
                            'assets/icon/play_store_512.png', // <<< YOUR LOGO PATH HERE
                            width: 350.w,
                            height: 350.w,
                            fit: BoxFit.contain,
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 65.h),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0),
                                    Colors.black.withOpacity(0.7),
                                  ],
                                ),
                              ),
                              child: Text(
                                AppConstants.appTagline,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16.sp,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 60.h),
                    
                    // Phone number field
                    Text(
                      'Enter your phone number',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    SizedBox(height: 16.h),
                    
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(fontSize: 18.sp),
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '+91',
                                style: TextStyle(
                                  color: AppTheme.accentColor,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Container(
                                height: 24.h,
                                width:.5.w,
                                color: Colors.grey,
                              ),
                              SizedBox(width: 8.w),
                            ],
                          ),
                        ),
                        hintText: '10-digit mobile number',
                      ),
                      maxLength: 10,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        if (value.length != 10) {
                          return 'Please enter a valid 10-digit phone number';
                        }
                        return null;
                      },
                    ),
                    
                    SizedBox(height: 24.h),
                    
                    // Flow status message
                    if (_flowStatusMessage.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(bottom: 16.h),
                        child: Container(
                          padding: EdgeInsets.all(12.r),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: _isExistingUser == true 
                                ? Colors.green.withOpacity(0.5)
                                : _isExistingUser == false
                                  ? AppTheme.accentColor.withOpacity(0.5)
                                  : Colors.grey.withOpacity(0.5),
                              width: 1.w,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isExistingUser == true 
                                  ? Icons.person
                                  : _isExistingUser == false
                                    ? Icons.person_add
                                    : Icons.info_outline,
                                color: _isExistingUser == true 
                                  ? Colors.green
                                  : _isExistingUser == false
                                    ? AppTheme.accentColor
                                    : Colors.grey,
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Text(
                                  _flowStatusMessage,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    // Submit button
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final isLoading = state.status == AuthStatus.loading || _isCheckingUserStatus;
                        
                        return SizedBox(
                          width: double.infinity,
                          height: 56.h,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _submitPhoneNumber,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentColor,
                              foregroundColor: AppTheme.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              elevation: 3,
                            ),
                            child: isLoading
                                ? SizedBox(
                                    width: 24.w,
                                    height: 24.w,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3.w,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                    ),
                                  )
                                : Text(
                                    'Continue',
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                    
                    SizedBox(height: 24.h),
                    
                    // Terms and conditions removed - moved to registration page
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}