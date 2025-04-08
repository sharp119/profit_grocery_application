import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/user.dart';

class ProfileCompletionBanner extends StatelessWidget {
  final User user;
  final VoidCallback? onAddAddressTap;
  
  const ProfileCompletionBanner({
    Key? key,
    required this.user,
    this.onAddAddressTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Calculate profile completion percentage
    final bool hasName = user.name != null && user.name!.isNotEmpty;
    final bool hasEmail = user.email != null && user.email!.isNotEmpty;
    final bool hasAddress = user.addresses.isNotEmpty;
    
    final int completedFields = [hasName, hasEmail, hasAddress].where((field) => field).length;
    final int totalFields = 3; // Name, email, and at least one address
    
    final double completionPercentage = (completedFields / totalFields) * 100;
    
    // Only show banner if profile is incomplete
    if (completionPercentage >= 100) {
      return const SizedBox.shrink();
    }
    
    // Determine which field is missing
    String promptText = '';
    VoidCallback? actionCallback;
    
    if (!hasName || !hasEmail) {
      promptText = 'Complete your profile for a better experience';
      actionCallback = () => Navigator.of(context).pushNamed(AppConstants.profileEditRoute);
    } else if (!hasAddress) {
      promptText = 'Add a delivery address to speed up checkout';
      actionCallback = onAddAddressTap ?? 
        () => Navigator.of(context).pushNamed(AppConstants.addressesRoute);
    }
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accentColor.withOpacity(0.7),
            AppTheme.accentColor,
          ],
        ),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: actionCallback,
          borderRadius: BorderRadius.circular(12.r),
          splashColor: Colors.white.withOpacity(0.1),
          highlightColor: Colors.white.withOpacity(0.05),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                // Circular progress indicator
                Container(
                  width: 50.w,
                  height: 50.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryColor.withOpacity(0.3),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: SizedBox(
                          width: 40.w,
                          height: 40.w,
                          child: CircularProgressIndicator(
                            value: completionPercentage / 100,
                            strokeWidth: 4.w,
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          '${completionPercentage.toInt()}%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16.w),
                
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Complete Your Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        promptText,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Arrow icon
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
