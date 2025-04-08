import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:profit_grocery_application/core/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/user.dart';
import '../../../services/logging_service.dart';
import '../../blocs/user/user_bloc.dart';
import '../../blocs/user/user_event.dart';
import '../../blocs/user/user_state.dart';
import '../../widgets/base_layout.dart';

class AddressesPage extends StatefulWidget {
  const AddressesPage({Key? key}) : super(key: key);

  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Load user data when page is initialized
    _loadUserData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          LoggingService.logFirestore('AddressesPage: Loading user data for ID: $userId');
          // Dispatch event to load user data
          context.read<UserBloc>().add(LoadUserProfileEvent(userId));
        } else {
          LoggingService.logError('AddressesPage', 'No user ID found in SharedPreferences');
        }
      } catch (e) {
        LoggingService.logError('AddressesPage', 'Error loading user data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      title: 'My Addresses',
      showBackButton: true,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.accentColor,
        child: const Icon(
          Icons.add,
          color: AppTheme.primaryColor,
        ),
        onPressed: () => _navigateToAddAddress(context),
      ),
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
                    'Error loading addresses',
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'User profile not found',
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 18.sp,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: _loadUserData,
                    child: const Text('Reload Profile'),
                  ),
                ],
              ),
            );
          }

          final addresses = user.addresses;
          if (addresses.isEmpty) {
            return _buildEmptyAddresses(context);
          }

          // Group addresses by type
          final homeAddresses = addresses.where((a) => a.addressType == 'home').toList();
          final workAddresses = addresses.where((a) => a.addressType == 'work').toList();
          final otherAddresses = addresses.where((a) => a.addressType == 'other').toList();

          return Column(
            children: [
              // Tab bar for filtering addresses
              Container(
                height: 60.h,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.accentColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppTheme.accentColor,
                  indicatorWeight: 3,
                  labelColor: AppTheme.accentColor,
                  unselectedLabelColor: Colors.white70,
                  tabs: [
                    Tab(
                      icon: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.home_outlined),
                          SizedBox(width: 6.w),
                          Text('Home (${homeAddresses.length})'),
                        ],
                      ),
                    ),
                    Tab(
                      icon: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.work_outline),
                          SizedBox(width: 6.w),
                          Text('Work (${workAddresses.length})'),
                        ],
                      ),
                    ),
                    Tab(
                      icon: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.place_outlined),
                          SizedBox(width: 6.w),
                          Text('Other (${otherAddresses.length})'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Tab views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAddressList(context, homeAddresses, user.id),
                    _buildAddressList(context, workAddresses, user.id),
                    _buildAddressList(context, otherAddresses, user.id),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAddressList(BuildContext context, List<Address> addresses, String userId) {
    if (addresses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_outlined,
              color: AppTheme.textSecondaryColor,
              size: 64.sp,
            ),
            SizedBox(height: 16.h),
            Text(
              'No addresses found',
              style: TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Tap the + button to add a new address',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: addresses.length,
      separatorBuilder: (context, index) => SizedBox(height: 16.h),
      itemBuilder: (context, index) {
        final address = addresses[index];
        return _buildAddressCard(context, address, userId);
      },
    );
  }

  Widget _buildEmptyAddresses(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          Container(
            width: 120.w,
            height: 120.w,
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.accentColor.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.location_off_outlined,
              color: AppTheme.accentColor,
              size: 60.sp,
            ),
          ),
          SizedBox(height: 32.h),
          
          Text(
            'No Saved Addresses',
            style: TextStyle(
              color: AppTheme.accentColor,
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),
          
          Text(
            'Add your delivery addresses to make checkout faster and easier.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 32.h),
          
          // Add address button
          SizedBox(
            width: double.infinity,
            height: 56.h,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToAddAddress(context),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: Text(
                'Add New Address',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: AppTheme.primaryColor,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, Address address, String userId) {
    final isDefault = address.isDefault;
    final addressType = address.addressType.toUpperCase();
    
    // Select icon based on address type
    IconData typeIcon;
    Color typeIconBgColor;
    
    switch (address.addressType) {
      case 'home':
        typeIcon = Icons.home_outlined;
        typeIconBgColor = Colors.blue.withOpacity(0.2);
        break;
      case 'work':
        typeIcon = Icons.work_outline;
        typeIconBgColor = Colors.orange.withOpacity(0.2);
        break;
      default:
        typeIcon = Icons.place_outlined;
        typeIconBgColor = Colors.purple.withOpacity(0.2);
    }
    
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
        border: Border.all(
          color: isDefault 
              ? AppTheme.accentColor 
              : AppTheme.accentColor.withOpacity(0.3),
          width: isDefault ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Address Type & Default Badge
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 12.h,
            ),
            decoration: BoxDecoration(
              color: isDefault 
                  ? AppTheme.accentColor.withOpacity(0.1)
                  : AppTheme.secondaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.accentColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Type icon
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: typeIconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    typeIcon,
                    color: AppTheme.accentColor,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                
                // Type label
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(
                      color: AppTheme.accentColor,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    addressType,
                    style: TextStyle(
                      color: AppTheme.accentColor,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isDefault) ...[
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(
                        color: Colors.green,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 12.sp,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'DEFAULT',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                
                // Menu for actions
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: AppTheme.accentColor,
                    size: 24.sp,
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _navigateToEditAddress(context, address);
                    } else if (value == 'delete') {
                      _confirmDeleteAddress(context, address, userId);
                    } else if (value == 'default') {
                      _setAsDefaultAddress(context, address.id, userId);
                    }
                  },
                  itemBuilder: (context) => [
                    if (!isDefault)
                      PopupMenuItem(
                        value: 'default',
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: Colors.green,
                              size: 20.sp,
                            ),
                            SizedBox(width: 8.w),
                            const Text('Set as Default'),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            color: AppTheme.accentColor,
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          const Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: AppTheme.errorColor,
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          const Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Address Details
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  address.name,
                  style: TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12.h),
                
                // Address details in a card with subtle background
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: AppTheme.accentColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Address Line
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.home,
                            color: AppTheme.accentColor.withOpacity(0.7),
                            size: 16.sp,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              address.addressLine,
                              style: TextStyle(
                                color: AppTheme.textPrimaryColor,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      if (address.landmark != null && address.landmark!.isNotEmpty) ...[
                        SizedBox(height: 8.h),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.location_on,
                              color: AppTheme.accentColor.withOpacity(0.7),
                              size: 16.sp,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                'Landmark: ${address.landmark}',
                                style: TextStyle(
                                  color: AppTheme.textPrimaryColor,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      
                      SizedBox(height: 8.h),
                      
                      // City, State, Pincode
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_city,
                            color: AppTheme.accentColor.withOpacity(0.7),
                            size: 16.sp,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              '${address.city}, ${address.state} - ${address.pincode}',
                              style: TextStyle(
                                color: AppTheme.textPrimaryColor,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Action buttons row
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Edit button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _navigateToEditAddress(context, address),
                        icon: Icon(
                          Icons.edit_outlined,
                          size: 18.sp,
                        ),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.accentColor,
                          side: BorderSide(color: AppTheme.accentColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    
                    // Set as default / Delete button
                    Expanded(
                      child: isDefault
                          ? OutlinedButton.icon(
                              onPressed: () => _confirmDeleteAddress(context, address, userId),
                              icon: Icon(
                                Icons.delete_outline,
                                size: 18.sp,
                              ),
                              label: const Text('Delete'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.errorColor,
                                side: BorderSide(color: AppTheme.errorColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                            )
                          : ElevatedButton.icon(
                              onPressed: () => _setAsDefaultAddress(context, address.id, userId),
                              icon: Icon(
                                Icons.check_circle_outline,
                                size: 18.sp,
                              ),
                              label: const Text('Set Default'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAddAddress(BuildContext context) {
    // Navigate to add address page
    Navigator.of(context).pushNamed(AppConstants.addAddressRoute);
  }

  void _navigateToEditAddress(BuildContext context, Address address) {
    // Navigate to edit address page with address data
    Navigator.of(context).pushNamed(
      AppConstants.editAddressRoute,
      arguments: address,
    );
  }

  void _confirmDeleteAddress(BuildContext context, Address address, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteAddress(context, address.id, userId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteAddress(BuildContext context, String addressId, String userId) {
    // Dispatch remove address event to UserBloc
    context.read<UserBloc>().add(
          RemoveAddressEvent(
            userId: userId,
            addressId: addressId,
          ),
        );
  }

  void _setAsDefaultAddress(BuildContext context, String addressId, String userId) {
    // Dispatch set default address event to UserBloc
    context.read<UserBloc>().add(
          SetDefaultAddressEvent(
            userId: userId,
            addressId: addressId,
          ),
        );
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Default address updated successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
