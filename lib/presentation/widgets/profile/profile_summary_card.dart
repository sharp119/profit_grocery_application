import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/user.dart';

class ProfileSummaryCard extends StatelessWidget {
  final User user;
  final VoidCallback? onEditProfile;
  
  const ProfileSummaryCard({
    Key? key,
    required this.user,
    this.onEditProfile,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      color: AppTheme.accentColor,
                      size: 24.sp,
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'Account Information',
                      style: TextStyle(
                        color: AppTheme.accentColor,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (onEditProfile != null)
                  IconButton(
                    onPressed: onEditProfile,
                    icon: Icon(
                      Icons.edit_outlined,
                      color: AppTheme.accentColor,
                      size: 22.sp,
                    ),
                    tooltip: 'Edit Profile',
                  ),
              ],
            ),
          ),
          
          const Divider(height: 1, color: AppTheme.secondaryColor),
          
          // Profile info
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 50.w,
                  height: 50.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.accentColor.withOpacity(0.2),
                    border: Border.all(
                      color: AppTheme.accentColor,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      user.name != null && user.name!.isNotEmpty
                          ? user.name![0].toUpperCase()
                          : user.phoneNumber[0],
                      style: TextStyle(
                        color: AppTheme.accentColor,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                
                // User details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        user.name ?? 'User',
                        style: TextStyle(
                          color: AppTheme.textPrimaryColor,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      
                      // Phone
                      Row(
                        children: [
                          Icon(
                            Icons.phone_android,
                            color: AppTheme.accentColor.withOpacity(0.7),
                            size: 14.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            user.phoneNumber,
                            style: TextStyle(
                              color: AppTheme.textSecondaryColor,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      
                      // Email if available
                      if (user.email != null && user.email!.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              color: AppTheme.accentColor.withOpacity(0.7),
                              size: 14.sp,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                user.email!,
                                style: TextStyle(
                                  color: AppTheme.textSecondaryColor,
                                  fontSize: 14.sp,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Default address section if available
          if (user.addresses.isNotEmpty) ...[
            const Divider(height: 1, color: AppTheme.secondaryColor),
            
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: AppTheme.accentColor,
                        size: 24.sp,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'Default Address',
                        style: TextStyle(
                          color: AppTheme.accentColor,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  
                  // Get default address or first address
                  _buildDefaultAddress(user),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildDefaultAddress(User user) {
    // Find default address or use the first one
    final Address address = user.addresses.firstWhere(
      (address) => address.isDefault,
      orElse: () => user.addresses.first,
    );
    
    // Get icon based on address type
    IconData addressTypeIcon;
    switch (address.addressType) {
      case 'home':
        addressTypeIcon = Icons.home_outlined;
        break;
      case 'work':
        addressTypeIcon = Icons.work_outline;
        break;
      default:
        addressTypeIcon = Icons.place_outlined;
    }
    
    return Container(
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
          // Name and type badge
          Row(
            children: [
              Icon(
                addressTypeIcon,
                color: AppTheme.accentColor,
                size: 18.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                address.name,
                style: TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8.w,
                  vertical: 2.h,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4.r),
                  border: Border.all(
                    color: AppTheme.accentColor.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  address.addressType.toUpperCase(),
                  style: TextStyle(
                    color: AppTheme.accentColor,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          
          // Address details
          Text(
            address.addressLine,
            style: TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 14.sp,
            ),
          ),
          
          if (address.landmark != null && address.landmark!.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              'Landmark: ${address.landmark}',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 14.sp,
              ),
            ),
          ],
          
          SizedBox(height: 4.h),
          Text(
            '${address.city}, ${address.state} - ${address.pincode}',
            style: TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }
}
