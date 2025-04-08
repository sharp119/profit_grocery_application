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
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            // Avatar section - left side
            Container(
              width: 80.w,
              height: 80.w,
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
                    fontSize: 36.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16.w),
            
            // User details - middle section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name
                  Text(
                    user.name ?? 'User',
                    style: TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontSize: 20.sp,
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
            
            // Edit button - right side
            if (onEditProfile != null)
              GestureDetector(
                onTap: onEditProfile,
                child: Container(
                  height: 40.h,
                  width: 40.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryColor,
                    border: Border.all(
                      color: AppTheme.accentColor.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    color: AppTheme.accentColor,
                    size: 20.sp,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
