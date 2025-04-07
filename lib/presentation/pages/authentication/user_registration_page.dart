import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../services/logging_service.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/user/user_bloc.dart';
import '../../blocs/user/user_event.dart';
import '../../blocs/user/user_state.dart';
import '../home/home_page.dart';

class UserRegistrationPage extends StatefulWidget {
  final String phoneNumber;

  const UserRegistrationPage({
    super.key, 
    required this.phoneNumber,
  });

  @override
  State<UserRegistrationPage> createState() => _UserRegistrationPageState();
}

class _UserRegistrationPageState extends State<UserRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  
  bool _isOptedInForMarketing = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submitProfile() {
    if (!_formKey.currentState!.validate()) return;
    
    // Check if user is authenticated
    final authState = context.read<AuthBloc>().state;
    final userId = authState.userId;
    
    LoggingService.logFirestore('UserRegistrationPage: Creating user profile for ${widget.phoneNumber}, Auth status: ${authState.status}, User ID: ${userId ?? "unknown"}');
    
    // Create user profile with entered data
    context.read<UserBloc>().add(
      CreateUserProfileEvent(
        phoneNumber: widget.phoneNumber,
        name: _nameController.text,
        email: _emailController.text.isEmpty ? null : _emailController.text,
        isOptedInForMarketing: _isOptedInForMarketing,
      ),
    );
  }

  void _skipProfileCreation() {
    // Check if user is authenticated
    final authState = context.read<AuthBloc>().state;
    final userId = authState.userId;
    
    LoggingService.logFirestore('UserRegistrationPage: Skipping profile creation for ${widget.phoneNumber}, Auth status: ${authState.status}, User ID: ${userId ?? "unknown"}');
    
    // Create minimal user profile with just phone number
    context.read<UserBloc>().add(
      CreateUserProfileEvent(
        phoneNumber: widget.phoneNumber,
        isOptedInForMarketing: false,
      ),
    );
  }

  void _navigateToHome() {
    LoggingService.logFirestore('UserRegistrationPage: Navigating to home page');
    
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        automaticallyImplyLeading: false,
      ),
      body: BlocListener<UserBloc, UserState>(
        listener: (context, state) {
          LoggingService.logFirestore('UserRegistrationPage listener - UserState: ${state.status}');
          
          if (state.status == UserStatus.created) {
            LoggingService.logFirestore('UserRegistrationPage: Profile created successfully');
            
            // Profile created successfully, navigate to home
            _navigateToHome();
          } else if (state.status == UserStatus.error) {
            LoggingService.logFirestore('UserRegistrationPage: Error creating profile - ${state.errorMessage}');
            
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Failed to create profile'),
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
                    SizedBox(height: 24.h),
                    
                    // Welcome message
                    Text(
                      'Welcome to ${AppConstants.appName}!',
                      style: TextStyle(
                        color: AppTheme.accentColor,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    SizedBox(height: 16.h),
                    
                    Text(
                      'Please complete your profile to continue. Your phone number has been verified.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16.sp,
                      ),
                    ),
                    
                    SizedBox(height: 40.h),
                    
                    // Phone number (non-editable)
                    TextFormField(
                      initialValue: '+91 ${widget.phoneNumber}',
                      readOnly: true,
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.white70,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                    
                    SizedBox(height: 24.h),
                    
                    // Name field
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      style: TextStyle(fontSize: 16.sp),
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person),
                        hintText: 'Enter your full name',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    
                    SizedBox(height: 24.h),
                    
                    // Email field (optional)
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(fontSize: 16.sp),
                      decoration: const InputDecoration(
                        labelText: 'Email (Optional)',
                        prefixIcon: Icon(Icons.email),
                        hintText: 'Enter your email address',
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegExp.hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                        }
                        return null;
                      },
                    ),
                    
                    SizedBox(height: 32.h),
                    
                    // Marketing opt-in
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppTheme.secondaryColor,
                          width: 1.w,
                        ),
                      ),
                      child: SwitchListTile(
                        value: _isOptedInForMarketing,
                        onChanged: (value) {
                          setState(() {
                            _isOptedInForMarketing = value;
                          });
                        },
                        title: Text(
                          'Receive offers and updates',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          'Get notified about exclusive deals and discounts',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14.sp,
                          ),
                        ),
                        activeColor: AppTheme.accentColor,
                        activeTrackColor: AppTheme.accentColor.withOpacity(0.4),
                        inactiveTrackColor: Colors.grey.withOpacity(0.5),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 40.h),
                    
                    // Submit button
                    BlocBuilder<UserBloc, UserState>(
                      builder: (context, state) {
                        final isLoading = state.status == UserStatus.loading;
                        
                        return SizedBox(
                          width: double.infinity,
                          height: 56.h,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _submitProfile,
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
                                    'Continue to Shop',
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
                    
                    // Skip button
                    BlocBuilder<UserBloc, UserState>(
                      builder: (context, state) {
                        final isLoading = state.status == UserStatus.loading;
                        
                        return SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: isLoading ? null : _skipProfileCreation,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                            ),
                            child: Text(
                              'Skip for now',
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: AppTheme.accentColor.withOpacity(0.8),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    SizedBox(height: 16.h),
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