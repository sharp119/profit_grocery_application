import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/user.dart';
import '../../../services/logging_service.dart';
import '../../blocs/user/user_bloc.dart';
import '../../blocs/user/user_event.dart';
import '../../blocs/user/user_state.dart';
import '../../widgets/base_layout.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({Key? key}) : super(key: key);

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late bool _isOptedInForMarketing;
  bool _isSubmitting = false;
  String? _errorMessage;
  String _initialLetter = '';

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // Get the current state of UserBloc
    final userState = context.read<UserBloc>().state;
    
    // Only try to load user data if it's not already loaded or being loaded
    if (userState.user == null && userState.status != UserStatus.loading) {
      try {
        // Get the userId from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString(AppConstants.userTokenKey);
        
        if (userId != null && userId.isNotEmpty) {
          LoggingService.logFirestore('ProfileEditPage: Loading user data for ID: $userId');
          // Dispatch event to load user data
          context.read<UserBloc>().add(LoadUserProfileEvent(userId));
        } else {
          LoggingService.logError('ProfileEditPage', 'No user ID found in SharedPreferences');
        }
      } catch (e) {
        LoggingService.logError('ProfileEditPage', 'Error loading user data: $e');
      }
    }
  }
  
  void _initializeControllers() {
    final userState = context.read<UserBloc>().state;
    final user = userState.user;
    
    if (user != null) {
      _nameController = TextEditingController(text: user.name ?? '');
      _emailController = TextEditingController(text: user.email ?? '');
      
      // Set initial letter for avatar
      _setInitialLetter(user);
      
      // For marketing opt-in, we need to cast to UserModel to access isOptedInForMarketing
      // Or use a default value if not accessible
      _isOptedInForMarketing = true; // Default value
      
      // You might need to adjust this depending on how you've implemented the user model
      // If your User entity has isOptedInForMarketing, you can directly access it
    } else {
      _nameController = TextEditingController();
      _emailController = TextEditingController();
      _isOptedInForMarketing = true;
    }
  }
  
  void _setInitialLetter(User user) {
    if (user.name != null && user.name!.isNotEmpty) {
      setState(() {
        _initialLetter = user.name![0].toUpperCase();
      });
    } else if (user.phoneNumber.isNotEmpty) {
      setState(() {
        _initialLetter = user.phoneNumber[0];
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      title: 'Edit Profile',
      showBackButton: true,
      body: BlocConsumer<UserBloc, UserState>(
        listener: (context, state) {
          if (state.status == UserStatus.updated) {
            setState(() {
              _isSubmitting = false;
              _errorMessage = null;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated successfully'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            
            // Navigate back to profile page
            Navigator.of(context).pop();
          } else if (state.status == UserStatus.error) {
            setState(() {
              _isSubmitting = false;
              _errorMessage = state.errorMessage;
            });
          } else if (state.status == UserStatus.loaded) {
            // Update the controllers with new data if user is loaded
            _updateControllersWithUserData(state.user);
          }
        },
        builder: (context, state) {
          if (state.status == UserStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.accentColor,
              ),
            );
          }
          
          final user = state.user;
          
          if (user == null) {
            return _buildUserNotFound();
          }
          
          return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile avatar with animated gradient
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 120.w,
                          height: 120.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              colors: [
                                AppTheme.accentColor,
                                AppTheme.accentColor.withOpacity(0.3),
                                AppTheme.accentColor.withOpacity(0.1),
                                AppTheme.accentColor.withOpacity(0.3),
                                AppTheme.accentColor,
                              ],
                              stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(3.w),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primaryColor,
                              ),
                              child: Center(
                                child: Text(
                                  _initialLetter,
                                  style: TextStyle(
                                    color: AppTheme.accentColor,
                                    fontSize: 56.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Edit icon overlay
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 36.w,
                            height: 36.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.accentColor,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: AppTheme.primaryColor,
                              size: 20.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32.h),
                  
                  // Card for personal info
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: AppTheme.accentColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Padding(
                          padding: EdgeInsets.all(16.w),
                          child: Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                color: AppTheme.accentColor,
                                size: 24.sp,
                              ),
                              SizedBox(width: 12.w),
                              Text(
                                'Personal Information',
                                style: TextStyle(
                                  color: AppTheme.accentColor,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const Divider(
                          color: AppTheme.secondaryColor,
                          height: 1,
                        ),
                        
                        // Form fields
                        Padding(
                          padding: EdgeInsets.all(16.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name Field
                              TextFormField(
                                controller: _nameController,
                                textCapitalization: TextCapitalization.words,
                                style: const TextStyle(color: AppTheme.textPrimaryColor),
                                decoration: InputDecoration(
                                  labelText: 'Full Name',
                                  floatingLabelStyle: TextStyle(
                                    color: AppTheme.accentColor,
                                    fontSize: 16.sp,
                                  ),
                                  prefixIcon: const Icon(Icons.person_outline, color: AppTheme.accentColor),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                    borderSide: BorderSide(
                                      color: AppTheme.accentColor.withOpacity(0.3),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                    borderSide: const BorderSide(
                                      color: AppTheme.accentColor,
                                      width: 2,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                    borderSide: BorderSide(
                                      color: AppTheme.errorColor,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your name';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  if (value.isNotEmpty) {
                                    setState(() {
                                      _initialLetter = value[0].toUpperCase();
                                    });
                                  }
                                },
                              ),
                              SizedBox(height: 20.h),
                              
                              // Email Field
                              TextFormField(
                                controller: _emailController,
                                style: const TextStyle(color: AppTheme.textPrimaryColor),
                                decoration: InputDecoration(
                                  labelText: 'Email Address',
                                  floatingLabelStyle: TextStyle(
                                    color: AppTheme.accentColor,
                                    fontSize: 16.sp,
                                  ),
                                  prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.accentColor),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                    borderSide: BorderSide(
                                      color: AppTheme.accentColor.withOpacity(0.3),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                    borderSide: const BorderSide(
                                      color: AppTheme.accentColor,
                                      width: 2,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                    borderSide: BorderSide(
                                      color: AppTheme.errorColor,
                                    ),
                                  ),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    // Simple email validation
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                      return 'Please enter a valid email address';
                                    }
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 20.h),
                              
                              // Phone Number (Read-only) with better styling
                              TextFormField(
                                initialValue: user.phoneNumber,
                                style: const TextStyle(color: AppTheme.textSecondaryColor),
                                decoration: InputDecoration(
                                  labelText: 'Phone Number',
                                  floatingLabelStyle: TextStyle(
                                    color: AppTheme.accentColor,
                                    fontSize: 16.sp,
                                  ),
                                  prefixIcon: const Icon(Icons.phone_outlined, color: AppTheme.accentColor),
                                  suffixIcon: const Icon(Icons.lock_outlined, color: AppTheme.textSecondaryColor),
                                  enabled: false,
                                  disabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                    borderSide: BorderSide(
                                      color: AppTheme.accentColor.withOpacity(0.2),
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: AppTheme.primaryColor.withOpacity(0.5),
                                ),
                                readOnly: true,
                              ),
                              SizedBox(height: 8.h),
                              
                              // Help text for phone
                              Text(
                                'Phone number cannot be changed',
                                style: TextStyle(
                                  color: AppTheme.textSecondaryColor,
                                  fontSize: 12.sp,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 24.h),
                  
                  // Card for preferences
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: AppTheme.accentColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Padding(
                          padding: EdgeInsets.all(16.w),
                          child: Row(
                            children: [
                              Icon(
                                Icons.notifications_outlined,
                                color: AppTheme.accentColor,
                                size: 24.sp,
                              ),
                              SizedBox(width: 12.w),
                              Text(
                                'Notification Preferences',
                                style: TextStyle(
                                  color: AppTheme.accentColor,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const Divider(
                          color: AppTheme.secondaryColor,
                          height: 1,
                        ),
                        
                        // Marketing Opt-in Switch with better styling
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Marketing Messages',
                                      style: TextStyle(
                                        color: AppTheme.textPrimaryColor,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      'Receive special offers, discounts, and promotional updates',
                                      style: TextStyle(
                                        color: AppTheme.textSecondaryColor,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _isOptedInForMarketing,
                                onChanged: (value) {
                                  setState(() {
                                    _isOptedInForMarketing = value;
                                  });
                                },
                                activeColor: AppTheme.accentColor,
                                activeTrackColor: AppTheme.accentColor.withOpacity(0.3),
                                inactiveThumbColor: Colors.grey,
                                inactiveTrackColor: Colors.grey.withOpacity(0.3),
                              ),
                            ],
                          ),
                        ),
                        
                        // Add more preference options here
                        const Divider(
                          color: AppTheme.secondaryColor,
                          height: 1,
                        ),
                        
                        // Order notifications
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Order Updates',
                                      style: TextStyle(
                                        color: AppTheme.textPrimaryColor,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      'Status changes and delivery notifications',
                                      style: TextStyle(
                                        color: AppTheme.textSecondaryColor,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: true, // Always on
                                onChanged: null, // Cannot be changed
                                activeColor: AppTheme.accentColor,
                                activeTrackColor: AppTheme.accentColor.withOpacity(0.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Error Message
                  if (_errorMessage != null) ...[
                    SizedBox(height: 16.h),
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: AppTheme.errorColor,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: AppTheme.errorColor,
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: AppTheme.errorColor,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  SizedBox(height: 32.h),
                  
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                        foregroundColor: AppTheme.primaryColor,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: _isSubmitting
                          ? SizedBox(
                              height: 24.h,
                              width: 24.h,
                              child: CircularProgressIndicator(
                                color: AppTheme.primaryColor,
                                strokeWidth: 3.w,
                              ),
                            )
                          : Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildUserNotFound() {
    return Container(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with gold gradient
          Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.accentColor.withOpacity(0.7),
                  AppTheme.accentColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_off_outlined,
              color: AppTheme.primaryColor,
              size: 40.sp,
            ),
          ),
          SizedBox(height: 24.h),
          
          Text(
            'Profile Not Found',
            style: TextStyle(
              color: AppTheme.accentColor,
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12.h),
          
          Text(
            'We couldn\'t find your profile information. Please try reloading or complete your profile setup.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 32.h),
          
          // Action button with premium style
          SizedBox(
            width: double.infinity,
            height: 56.h,
            child: ElevatedButton(
              onPressed: _loadUserData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: AppTheme.primaryColor,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'Reload Profile',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          
          TextButton(
            onPressed: () {
              // Navigate back to home
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppConstants.homeRoute,
                (route) => false,
              );
            },
            child: Text(
              'Return to Home',
              style: TextStyle(
                color: AppTheme.accentColor,
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateControllersWithUserData(User? user) {
    if (user != null) {
      setState(() {
        _nameController.text = user.name ?? '';
        _emailController.text = user.email ?? '';
        _setInitialLetter(user);
        // Update marketing opt-in status if available
      });
    }
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
        _errorMessage = null;
      });
      
      // Dispatch update event to UserBloc
      context.read<UserBloc>().add(
            UpdateUserProfileEvent(
              name: _nameController.text.trim(),
              email: _emailController.text.trim(),
              isOptedInForMarketing: _isOptedInForMarketing,
            ),
          );
    }
  }
}
