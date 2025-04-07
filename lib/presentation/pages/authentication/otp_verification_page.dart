import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../services/logging_service.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/user/user_bloc.dart';
import '../../blocs/user/user_event.dart';
import 'package:get_it/get_it.dart';
import '../home/home_page.dart';
import 'user_registration_page.dart';

class OtpVerificationPage extends StatefulWidget {
  final String phoneNumber;
  final String requestId;

  const OtpVerificationPage({
    super.key, 
    required this.phoneNumber,
    required this.requestId,
  });

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final TextEditingController _otpController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isResending = false;
  int _remainingTime = 60; // 60 seconds countdown
  bool _isAutoVerifying = false;

  bool _isExistingUser = false;
  
  @override
  void initState() {
    super.initState();
    _startResendTimer();
    _checkUserStatus();
    LoggingService.logFirestore('OtpVerificationPage: Initialized with requestId: ${widget.requestId}');
  }
  
  Future<void> _checkUserStatus() async {
    // Read the isExistingUser flag from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isExistingUser = prefs.getBool('is_existing_user') ?? false;
    });
    LoggingService.logFirestore('OtpVerificationPage: User status check - isExistingUser: $_isExistingUser');
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          if (_remainingTime > 0) {
            _remainingTime--;
            _startResendTimer();
          }
        });
      }
    });
  }

  void _resendOtp() async {
    if (_remainingTime > 0) return;
    
    setState(() {
      _isResending = true;
    });
    
    LoggingService.logFirestore('OtpVerificationPage: Resending OTP to phone: ${widget.phoneNumber}');
    
    // Send OTP request again
    context.read<AuthBloc>().add(SendOtpEvent(widget.phoneNumber));
    
    setState(() {
      _isResending = false;
      _remainingTime = 60;
    });
    
    _startResendTimer();
  }

  void _verifyOtp() {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isAutoVerifying = true;
    });
    
    LoggingService.logFirestore('OtpVerificationPage: Verifying OTP for requestId: ${widget.requestId}');
    
    // Verify OTP through AuthBloc
    context.read<AuthBloc>().add(
      VerifyOtpEvent(
        requestId: widget.requestId,
        otp: _otpController.text,
        phoneNumber: widget.phoneNumber,
      ),
    );
  }

  // Navigate to registration page
  void _navigateToRegistration() {
    LoggingService.logFirestore('OtpVerificationPage: Navigating to registration page');
    // Small delay to make sure navigation feels smooth
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => UserRegistrationPage(
              phoneNumber: widget.phoneNumber,
            ),
          ),
          (route) => false, // Clear navigation stack
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Define the default and focused pin themes
    final defaultPinTheme = PinTheme(
      width: 56.w,
      height: 56.h,
      textStyle: TextStyle(
        fontSize: 20.sp,
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: AppTheme.accentColor, width: 2.w),
      borderRadius: BorderRadius.circular(12.r),
      boxShadow: [
        BoxShadow(
          color: AppTheme.accentColor.withOpacity(0.3),
          blurRadius: 8,
          spreadRadius: 2,
        ),
      ],
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: AppTheme.accentColor.withOpacity(0.2),
      ),
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Verify Phone'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          LoggingService.logFirestore('OtpVerificationPage listener - AuthState: ${state.status}');
          
          if (state.status == AuthStatus.authenticated) {
            final userId = state.userId;
            LoggingService.logFirestore(
              'OtpVerificationPage: User authenticated with ID: ${userId ?? "unknown"}, '
              'isExistingUser: $_isExistingUser'
            );
            
            // Make sure we have a userId before proceeding
            if (userId != null) {
              // Explicitly load user profile before navigation
              // This ensures the UI will have user data immediately
              LoggingService.logFirestore('OtpVerificationPage: Explicitly loading user data for UI update');
              context.read<UserBloc>().add(LoadUserProfileEvent(userId));
              
              if (_isExistingUser) {
                // For existing users, go directly to home page
                LoggingService.logFirestore('OtpVerificationPage: Existing user - navigating to home page');
                
                // Add a small delay to allow user data to be processed
                // This ensures the UI will have user data when HomePage is built
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          // Create a fresh UserBloc with pre-loaded data
                          return BlocProvider(
                            create: (context) => GetIt.instance<UserBloc>()
                              ..add(LoadUserProfileEvent(userId)),
                            child: const HomePage(),
                          );
                        }
                      ),
                      (route) => false, // Remove all previous routes
                    );
                  }
                });
              } else {
                // For new users, check if we have pre-registration data
                LoggingService.logFirestore('OtpVerificationPage: New user - checking for pre-registration data');
                
                // Check for pre-filled registration data in SharedPreferences
                SharedPreferences.getInstance().then((prefs) {
                  final hasPreRegData = prefs.containsKey('temp_user_name');
                  
                  if (hasPreRegData) {
                    LoggingService.logFirestore('OtpVerificationPage: Found pre-registration data, creating profile');
                    
                    // Extract pre-registration data
                    final name = prefs.getString('temp_user_name') ?? '';
                    final email = prefs.getString('temp_user_email') ?? '';
                    final marketingOptIn = prefs.getBool('temp_user_marketing_opt_in') ?? false;
                    
                    // Auto-create user profile with pre-registration data
                    if (name.isNotEmpty) {
                      context.read<UserBloc>().add(
                        CreateUserProfileEvent(
                          phoneNumber: widget.phoneNumber,
                          name: name,
                          email: email.isEmpty ? null : email,
                          isOptedInForMarketing: marketingOptIn,
                        ),
                      );
                      
                      // Wait for profile creation and then navigate to home
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomePage(),
                            ),
                            (route) => false, // Clear navigation stack
                          );
                        }
                      });
                    } else {
                      // If name is empty, still navigate to registration
                      _navigateToRegistration();
                    }
                  } else {
                    // No pre-registration data, navigate to registration
                    _navigateToRegistration();
                  }
                });
              }
            } else {
              // Show error if userId is null
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Authentication error: User ID is missing'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } else if (state.status == AuthStatus.otpSent) {
            // Show toast/snackbar for OTP resent
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('OTP sent successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state.status == AuthStatus.error) {
            setState(() {
              _isAutoVerifying = false;
            });
            
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Failed to verify OTP'),
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
                    
                    // Heading
                    Text(
                      'Verification Code',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    SizedBox(height: 16.h),
                    
                    Text(
                      'We have sent a 4-digit verification code to',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16.sp,
                      ),
                    ),
                    
                    SizedBox(height: 8.h),
                    
                    Row(
                      children: [
                        Text(
                          '+91 ${widget.phoneNumber}',
                          style: TextStyle(
                            color: AppTheme.accentColor,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Change?',
                            style: TextStyle(
                              color: AppTheme.accentColor,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 40.h),
                    
                    // OTP input field
                    Center(
                      child: Column(
                        children: [
                          Pinput(
                            controller: _otpController,
                            length: 4, // 4-digit OTP
                            defaultPinTheme: defaultPinTheme,
                            focusedPinTheme: focusedPinTheme,
                            submittedPinTheme: submittedPinTheme,
                            pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                            showCursor: true,
                            onCompleted: (pin) {
                              // Auto-verify when all digits are entered
                              if (!_isAutoVerifying) {
                                _verifyOtp();
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the OTP';
                              }
                              if (value.length != 4) {
                                return 'Please enter a valid 4-digit OTP';
                              }
                              return null;
                            },
                          ),
                          
                          // OTP auto-verification message
                          if (_isAutoVerifying)
                            Padding(
                              padding: EdgeInsets.only(top: 16.h),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 16.w,
                                    height: 16.w,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.w,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'Verifying your code...',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 24.h),
                    
                    // Resend OTP button
                    Center(
                      child: TextButton(
                        onPressed: _remainingTime > 0 ? null : _resendOtp,
                        child: _isResending
                            ? SizedBox(
                                width: 20.w,
                                height: 20.w,
                                child: CircularProgressIndicator(
                                  color: AppTheme.accentColor,
                                  strokeWidth: 2.w,
                                ),
                              )
                            : Text(
                                _remainingTime > 0
                                    ? 'Resend OTP in $_remainingTime seconds'
                                    : 'Resend OTP',
                                style: TextStyle(
                                  color: _remainingTime > 0
                                      ? Colors.grey
                                      : AppTheme.accentColor,
                                  fontSize: 16.sp,
                                ),
                              ),
                      ),
                    ),
                    
                    SizedBox(height: 40.h),
                    
                    // Verify button
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final isLoading = state.status == AuthStatus.loading || _isAutoVerifying;
                        
                        return SizedBox(
                          width: double.infinity,
                          height: 56.h,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _verifyOtp,
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
                                    'Verify & Continue',
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                    
                    // Didn't receive OTP?
                    if (_remainingTime == 0)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 24.h),
                          child: Text(
                            "Didn't receive the OTP? Try resending it.",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14.sp,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
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