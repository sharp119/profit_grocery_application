import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import '../../../main.dart'; // For GetIt singleton (sl)
import 'package:profit_grocery_application/core/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/user.dart';
import '../../../services/logging_service.dart';
import '../../blocs/user/user_bloc.dart';
import '../../blocs/user/user_event.dart';
import '../../blocs/user/user_state.dart';
import '../../widgets/base_layout.dart';
import '../../widgets/profile/profile_summary_card.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // For consistency with bottom navigation, ensure we're using the BlocProvider
    // that may already exist in the widget tree
    try {
      // Check if UserBloc is already available in context
      BlocProvider.of<UserBloc>(context, listen: false);
      // If available, use existing UserBloc
      return const _ProfilePageContent();
    } catch (e) {
      // If not available, create a new one
      return BlocProvider(
        create: (context) => sl<UserBloc>(),
        child: const _ProfilePageContent(),
      );
    }
  }
}

class _ProfilePageContent extends StatefulWidget {
  const _ProfilePageContent({Key? key}) : super(key: key);

  @override
  State<_ProfilePageContent> createState() => _ProfilePageContentState();
}

class _ProfilePageContentState extends State<_ProfilePageContent> {
  bool _isDarkMode = true; // Default to dark mode

  @override
  void initState() {
    super.initState();
    // Load user data when page is initialized
    _loadUserData();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isDarkMode = prefs.getBool(AppConstants.isDarkModeKey) ?? true;
      });
    } catch (e) {
      LoggingService.logError('ProfilePage', 'Error loading theme preference: $e');
    }
  }

  Future<void> _saveThemePreference(bool isDarkMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.isDarkModeKey, isDarkMode);
      setState(() {
        _isDarkMode = isDarkMode;
      });
    } catch (e) {
      LoggingService.logError('ProfilePage', 'Error saving theme preference: $e');
    }
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
          LoggingService.logFirestore('ProfilePage: Loading user data for ID: $userId');
          // Dispatch event to load user data
          context.read<UserBloc>().add(LoadUserProfileEvent(userId));
        } else {
          LoggingService.logError('ProfilePage', 'No user ID found in SharedPreferences');
        }
      } catch (e) {
        LoggingService.logError('ProfilePage', 'Error loading user data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      title: 'My Profile',
      showBackButton: true,
      body: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          if (state.status == UserStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.accentColor,
              ),
            );
          }

          if (state.status == UserStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error loading profile',
                    style: TextStyle(
                      color: AppTheme.errorColor,
                      fontSize: 18.sp,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    state.errorMessage ?? 'Unknown error',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: _loadUserData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final user = state.user;
          if (user == null) {
            return _buildProfileNotFound();
          }

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(context, user),
                SizedBox(height: 32.h),
                _buildProfileMenu(context, user),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileNotFound() {
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
              // Navigate to create profile
              Navigator.of(context).pushNamed(AppConstants.profileEditRoute);
            },
            child: Text(
              'Set Up Your Profile',
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

  Widget _buildProfileHeader(BuildContext context, User user) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.secondaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Horizontal profile information layout
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // User avatar with gold border
              Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor,
                  border: Border.all(
                    color: AppTheme.accentColor,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentColor.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    user.name != null && user.name!.isNotEmpty
                        ? user.name![0].toUpperCase()
                        : user.phoneNumber[0],
                    style: TextStyle(
                      color: AppTheme.accentColor,
                      fontSize: 36.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 20.w),
              
              // User information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User name with larger font
                    Text(
                      user.name ?? 'User',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    
                    // Phone number with icon
                    Row(
                      children: [
                        Icon(
                          Icons.phone_android,
                          color: AppTheme.accentColor,
                          size: 16.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          user.phoneNumber,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16.sp,
                          ),
                        ),
                      ],
                    ),
                    
                    // Email if available
                    if (user.email != null && user.email!.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            color: AppTheme.accentColor,
                            size: 16.sp,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              user.email!,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16.sp,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          
          // Edit profile button with better styling
          SizedBox(height: 24.h),
          OutlinedButton.icon(
            onPressed: () => _navigateToEditProfile(context, user),
            icon: const Icon(Icons.edit, color: AppTheme.accentColor, size: 18),
            label: Text(
              'Edit Profile', 
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16.sp,
              )
            ),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              side: const BorderSide(color: AppTheme.accentColor, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.r),
              ),
              foregroundColor: AppTheme.accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenu(BuildContext context, User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title with better typography
        Padding(
          padding: EdgeInsets.only(left: 8.w, top: 8.h, bottom: 16.h),
          child: Text(
            'My Account',
            style: TextStyle(
              color: AppTheme.accentColor,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        
        // Orders section
        _buildMenuCard(
          title: 'My Orders',
          icon: Icons.shopping_bag_outlined,
          subtitle: 'Track your orders and view history',
          onTap: () => _navigateToOrders(context),
        ),
        
        // Addresses section with count indicator
        _buildMenuCard(
          title: 'Delivery Addresses',
          icon: Icons.location_on_outlined,
          subtitle: user.addresses.isEmpty 
              ? 'Add your delivery addresses' 
              : '${user.addresses.length} saved address${user.addresses.length > 1 ? 'es' : ''}',
          indicatorCount: user.addresses.isEmpty ? null : user.addresses.length,
          onTap: () => _navigateToAddresses(context, user),
        ),
        
        // Wallet & Payments placeholder
        _buildMenuCard(
          title: 'Payment Methods',
          icon: Icons.payment_outlined,
          subtitle: 'Manage your payment options',
          onTap: () => _showComingSoonDialog(context, 'Payment Methods'),
        ),
        
        // Preferences section title
        Padding(
          padding: EdgeInsets.only(left: 8.w, top: 24.h, bottom: 16.h),
          child: Text(
            'App Preferences',
            style: TextStyle(
              color: AppTheme.accentColor,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        
        // Theme toggle card
        _buildThemeToggleCard(),
        
        // Notification preferences
        _buildMenuCard(
          title: 'Notification Settings',
          icon: Icons.notifications_outlined,
          subtitle: 'Manage your alerts and notifications',
          onTap: () => _showComingSoonDialog(context, 'Notification Settings'),
        ),
        
        // Support section title
        Padding(
          padding: EdgeInsets.only(left: 8.w, top: 24.h, bottom: 16.h),
          child: Text(
            'Support',
            style: TextStyle(
              color: AppTheme.accentColor,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        
        // Help & Support
        _buildMenuCard(
          title: 'Help & Support',
          icon: Icons.help_outline,
          subtitle: 'Contact us, FAQs, and more',
          onTap: () => _showComingSoonDialog(context, 'Help & Support'),
        ),
        
        // About the app
        _buildMenuCard(
          title: 'About ProfitGrocery',
          icon: Icons.info_outline,
          subtitle: 'Version ${AppConstants.appVersion}',
          onTap: () => _showAboutDialog(context),
        ),
        
        SizedBox(height: 24.h),
        
        // Logout button
        _buildLogoutButton(context),
        
        SizedBox(height: 32.h),
      ],
    );
  }

  Widget _buildMenuCard({
    required String title,
    required IconData icon,
    required String subtitle,
    VoidCallback? onTap,
    int? indicatorCount,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      color: AppTheme.secondaryColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(
          color: AppTheme.accentColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        splashColor: AppTheme.accentColor.withOpacity(0.1),
        highlightColor: AppTheme.accentColor.withOpacity(0.05),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: AppTheme.accentColor,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              ),
              if (indicatorCount != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    indicatorCount.toString(),
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.accentColor,
                  size: 16.sp,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeToggleCard() {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      color: AppTheme.secondaryColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(
          color: AppTheme.accentColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                color: AppTheme.accentColor,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dark Mode',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _isDarkMode ? 'On' : 'Off',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _isDarkMode,
              onChanged: (value) => _saveThemePreference(value),
              activeColor: AppTheme.accentColor,
              inactiveTrackColor: Colors.grey.withOpacity(0.5),
              thumbColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.selected)) {
                    return AppTheme.primaryColor;
                  }
                  return Colors.white;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppTheme.errorColor),
      ),
      child: TextButton.icon(
        onPressed: () => _confirmLogout(context),
        icon: Icon(
          Icons.logout,
          color: AppTheme.errorColor,
          size: 24.sp,
        ),
        label: Text(
          'Logout',
          style: TextStyle(
            color: AppTheme.errorColor,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }

  void _navigateToEditProfile(BuildContext context, User user) {
    // Navigate to edit profile page
    Navigator.of(context).pushNamed(AppConstants.profileEditRoute);
  }

  void _navigateToOrders(BuildContext context) {
    // Navigate to orders page
    Navigator.of(context).pushNamed(AppConstants.ordersRoute);
  }

  void _navigateToAddresses(BuildContext context, User user) {
    // Navigate to addresses page
    Navigator.of(context).pushNamed(AppConstants.addressesRoute);
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Coming Soon'),
        content: Text('$feature will be available in the next update!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AboutDialog(
        applicationName: AppConstants.appName,
        applicationVersion: 'v${AppConstants.appVersion}',
        applicationIcon: Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primaryColor,
            border: Border.all(
              color: AppTheme.accentColor,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              'PG',
              style: TextStyle(
                color: AppTheme.accentColor,
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
              ),
            ),
          ),
        ),
        children: [
          SizedBox(height: 16.h),
          Text(
            AppConstants.appTagline,
            style: TextStyle(
              fontSize: 14.sp,
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 8.h),
          const Text(
            'ProfitGrocery is a premium grocery shopping app offering great deals and exclusive offers.',
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Call logout function
              _logout(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    // Implement your logout logic here
    // This might include clearing authentication tokens, resetting state, etc.
    
    // Navigate to login page and clear navigation stack
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/auth/phone',
      (route) => false,
    );
  }
}