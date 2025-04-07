import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
      // Get Firebase reference to check if user exists
      final usersRef = FirebaseDatabase.instance.ref().child(AppConstants.usersCollection);
      final query = usersRef.orderByChild('phoneNumber').equalTo(sanitizedPhone);
      final snapshot = await query.get();
      
      setState(() {
        _isExistingUser = snapshot.exists;
        _flowStatusMessage = snapshot.exists 
            ? 'Welcome back! Sending verification code...' 
            : 'Welcome to ProfitGrocery! Sending verification code...';
        _isCheckingUserStatus = false;
      });
      
      LoggingService.logFirestore(
        'PhoneEntryPage: User exists check for ${sanitizedPhone.substring(6)}XXXX: $_isExistingUser'
      );
    } catch (e) {
      LoggingService.logError('PhoneEntryPage', 'Error checking user existence: $e');
      // Default to new user if we can't check
      setState(() {
        _isExistingUser = false;
        _isCheckingUserStatus = false;
        _flowStatusMessage = '';
      });
    }
    
    LoggingService.logFirestore('PhoneEntryPage: Submitting phone number: ${sanitizedPhone.substring(6)}XXXX');
    
    // Submit the phone number to the AuthBloc
    context.read<AuthBloc>().add(SendOtpEvent(sanitizedPhone));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
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
                    
                    // App logo/branding
                    Center(
                      child: Container(
                        width: 120.w,
                        height: 120.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryColor,
                          border: Border.all(
                            color: AppTheme.accentColor,
                            width: 2.w,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentColor.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'PG',
                            style: TextStyle(
                              color: AppTheme.accentColor,
                              fontSize: 48.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 40.h),
                    
                    // Heading
                    Text(
                      'Welcome to',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    SizedBox(height: 8.h),
                    
                    Text(
                      AppConstants.appName,
                      style: TextStyle(
                        color: AppTheme.accentColor,
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    SizedBox(height: 8.h),
                    
                    Text(
                      AppConstants.appTagline,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16.sp,
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