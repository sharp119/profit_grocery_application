import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/user.dart';

class AddressSelectionCard extends StatelessWidget {
  final Address? selectedAddress;
  final List<Address> addresses;
  final Function(Address) onAddressSelected;
  final VoidCallback onAddNewAddress;
  
  const AddressSelectionCard({
    Key? key,
    this.selectedAddress,
    required this.addresses,
    required this.onAddressSelected,
    required this.onAddNewAddress,
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
                Text(
                  'Delivery Address',
                  style: TextStyle(
                    color: AppTheme.accentColor,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (addresses.isNotEmpty)
                  TextButton.icon(
                    onPressed: onAddNewAddress,
                    icon: Icon(
                      Icons.add_location_alt_outlined,
                      size: 18.sp,
                      color: AppTheme.accentColor,
                    ),
                    label: Text(
                      'Add New',
                      style: TextStyle(
                        color: AppTheme.accentColor,
                        fontSize: 14.sp,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    ),
                  ),
              ],
            ),
          ),
          
          const Divider(height: 1, color: AppTheme.secondaryColor),
          
          // Address list or empty state
          addresses.isEmpty
              ? _buildEmptyAddressState()
              : _buildAddressList(),
        ],
      ),
    );
  }
  
  Widget _buildEmptyAddressState() {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off_outlined,
            color: AppTheme.accentColor.withOpacity(0.7),
            size: 48.sp,
          ),
          SizedBox(height: 16.h),
          Text(
            'No Delivery Address Found',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Please add an address to continue',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 24.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAddNewAddress,
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Add New Address'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: AppTheme.primaryColor,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAddressList() {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      itemCount: addresses.length,
      separatorBuilder: (context, index) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final address = addresses[index];
        final isSelected = selectedAddress?.id == address.id;
        
        // Get icon based on address type
        IconData addressIcon;
        switch (address.addressType) {
          case 'home':
            addressIcon = Icons.home_outlined;
            break;
          case 'work':
            addressIcon = Icons.work_outline;
            break;
          default:
            addressIcon = Icons.place_outlined;
        }
        
        return InkWell(
          onTap: () => onAddressSelected(address),
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.accentColor.withOpacity(0.1)
                  : AppTheme.primaryColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isSelected
                    ? AppTheme.accentColor
                    : AppTheme.accentColor.withOpacity(0.2),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Radio button
                Radio(
                  value: address.id,
                  groupValue: selectedAddress?.id,
                  onChanged: (_) => onAddressSelected(address),
                  activeColor: AppTheme.accentColor,
                ),
                SizedBox(width: 12.w),
                
                // Address icon
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    addressIcon,
                    color: AppTheme.accentColor,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                
                // Address details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and address type badge
                      Row(
                        children: [
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
                          
                          if (address.isDefault) ...[
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4.r),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'DEFAULT',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 4.h),
                      
                      // Address line
                      Text(
                        address.addressLine,
                        style: TextStyle(
                          color: AppTheme.textPrimaryColor,
                          fontSize: 14.sp,
                        ),
                      ),
                      
                      // City, State, Pincode
                      Text(
                        '${address.city}, ${address.state} - ${address.pincode}',
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
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
