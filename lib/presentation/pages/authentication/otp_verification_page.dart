import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pinput/pinput.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';

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

  @override
  void initState() {
    super.initState();
    _startResendTimer();
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
    
    // Verify OTP through AuthBloc
    context.read<AuthBloc>().add(
      VerifyOtpEvent(
        requestId: widget.requestId,
        otp: _otpController.text,
        phoneNumber: widget.phoneNumber,
      ),
    );
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
        borderRadius: BorderRadius.circular(8.r),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: AppTheme.accentColor, width: 2.w),
      borderRadius: BorderRadius.circular(8.r),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: AppTheme.accentColor.withOpacity(0.2),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Phone'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.authenticated) {
            // Pop all routes and go to homepage (already handled in MyApp widget)
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else if (state.status == AuthStatus.otpSent) {
            // Show toast/snackbar for OTP resent
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('OTP sent successfully!'),
                backgroundColor: Colors.green,
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
                      child: Pinput(
                        controller: _otpController,
                        length: 4, // Changed from 6 to 4 digits
                        defaultPinTheme: defaultPinTheme,
                        focusedPinTheme: focusedPinTheme,
                        submittedPinTheme: submittedPinTheme,
                        pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                        showCursor: true,
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
                    ),
                    
                    SizedBox(height: 24.h),
                    
                    // Resend OTP button
                    Center(
                      child: TextButton(
                        onPressed: _remainingTime > 0 ? null : _resendOtp,
                        child: _isResending
                            ? const CircularProgressIndicator(
                                color: AppTheme.accentColor,
                                strokeWidth: 2,
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
                        final isLoading = state.status == AuthStatus.loading;
                        
                        return SizedBox(
                          width: double.infinity,
                          height: 56.h,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _verifyOtp,
                            child: isLoading
                                ? const CircularProgressIndicator()
                                : const Text('Verify & Continue'),
                          ),
                        );
                      },
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