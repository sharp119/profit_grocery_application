import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/errors/global_error_handler.dart';
import '../../../services/logging_service.dart';
import '../../../services/session_manager.dart';
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
  void initState() {
    super.initState();
    
    // Hide any "User not found" error message
    GlobalErrorHandler.hideNewUserWelcome();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool _isCreatingSession = false;
  
  Future<void> _submitProfile() async {
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

  Future<void> _skipProfileCreation() async {
    setState(() {
      _isCreatingSession = true;
    });
    
    // Check if user is authenticated
    final authState = context.read<AuthBloc>().state;
    final userId = authState.userId;
    
    LoggingService.logFirestore('UserRegistrationPage: Skipping profile creation for ${widget.phoneNumber}, Auth status: ${authState.status}, User ID: ${userId ?? "unknown"}');
    
    // Show toast to indicate creating basic profile
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Creating basic profile...'),
        duration: Duration(seconds: 1),
      ),
    );
    
    // Create minimal user profile with just phone number
    context.read<UserBloc>().add(
      CreateUserProfileEvent(
        phoneNumber: widget.phoneNumber,
        isOptedInForMarketing: false,
      ),
    );
  }

  Future<void> _navigateToHome() async {
    LoggingService.logFirestore('UserRegistrationPage: Navigating to home page');
    
    try {
      // Get the userId
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userTokenKey);
      
      if (userId != null) {
        // Create a session for auto-login
        final sessionManager = SessionManager();
        await sessionManager.createSession(userId);
        LoggingService.logFirestore('UserRegistrationPage: Created login session for user $userId');
        
        // Explicitly trigger a user profile load for immediate UI update
        context.read<UserBloc>().add(LoadUserProfileEvent(userId));
      }
    } catch (e) {
      LoggingService.logError('UserRegistrationPage', 'Error creating session: $e');
      // Continue with navigation even if session creation fails
    }
    
    // Delay navigation slightly to allow UI to complete any animations
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) {
              // Get the userId for the BlocProvider
              final prefs = SharedPreferences.getInstance();
              final futures = [prefs];
              
              return FutureBuilder(
                future: Future.wait(futures),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    final userId = (snapshot.data?[0] as SharedPreferences).getString(AppConstants.userTokenKey);
                    
                    // Create a fresh UserBloc with pre-loaded data if we have userId
                    if (userId != null) {
                      return BlocProvider(
                        create: (context) => GetIt.instance<UserBloc>()
                          ..add(LoadUserProfileEvent(userId)),
                        child: const HomePage(),
                      );
                    }
                    
                    // Fallback if no userId
                    return const HomePage();
                  }
                  
                  // Show loading while getting userId
                  return Scaffold(
                    backgroundColor: AppTheme.backgroundColor,
                    body: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          (route) => false, // Remove all previous routes
        );
      }
    });
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
            LoggingService.logFirestore('UserRegistrationPage: Profile created successfully for user: ${state.user?.id}');
            
            // Profile created successfully, navigate to home
            _navigateToHome();
            
          } else if (state.status == UserStatus.error) {
            LoggingService.logFirestore('UserRegistrationPage: Error creating profile - ${state.errorMessage}');
            
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Failed to create profile'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Try Again',
                  onPressed: () {
                    // Reset the form and let the user try again
                    _formKey.currentState?.reset();
                  },
                ),
              ),
            );
            
          } else if (state.status == UserStatus.loading) {
            // Show loading indicator (already handled by BlocBuilder)
            LoggingService.logFirestore('UserRegistrationPage: Loading state - creating profile');
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
                        final isLoading = state.status == UserStatus.loading || _isCreatingSession;
                        
                        return SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: isLoading ? null : _skipProfileCreation,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                            ),
                            child: isLoading && _isCreatingSession
                                ? Row(
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
                                        'Creating basic profile...',
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          color: AppTheme.accentColor.withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
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
                    
                    // Terms and conditions - moved from login page to registration page
                    Center(
                      child: Text(
                        'By continuing, you agree to our',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 8.h),
                    
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {
                              // Navigate to Terms & Conditions
                            },
                            child: Text(
                              'Terms & Conditions',
                              style: TextStyle(
                                color: AppTheme.accentColor,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                          Text(
                            'and',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14.sp,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Navigate to Privacy Policy
                            },
                            child: Text(
                              'Privacy Policy',
                              style: TextStyle(
                                color: AppTheme.accentColor,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
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