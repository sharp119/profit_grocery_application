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
import '../../widgets/profile/address_selection_card.dart';
import '../profile/address_form_page.dart';

class AddressSelectionPage extends StatefulWidget {
  final Function(Address) onAddressSelected;
  final Address? initialAddress;
  
  const AddressSelectionPage({
    Key? key,
    required this.onAddressSelected,
    this.initialAddress,
  }) : super(key: key);

  @override
  State<AddressSelectionPage> createState() => _AddressSelectionPageState();
}

class _AddressSelectionPageState extends State<AddressSelectionPage> {
  Address? _selectedAddress;
  
  @override
  void initState() {
    super.initState();
    _selectedAddress = widget.initialAddress;
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
          LoggingService.logFirestore('AddressSelectionPage: Loading user data for ID: $userId');
          // Dispatch event to load user data
          context.read<UserBloc>().add(LoadUserProfileEvent(userId));
        } else {
          LoggingService.logError('AddressSelectionPage', 'No user ID found in SharedPreferences');
        }
      } catch (e) {
        LoggingService.logError('AddressSelectionPage', 'Error loading user data: $e');
      }
    } else if (userState.user != null) {
      // If user is already loaded and has addresses, try to select default address if none selected
      final user = userState.user!;
      if (_selectedAddress == null && user.addresses.isNotEmpty) {
        // First try to find default address
        final defaultAddress = user.addresses.firstWhere(
          (address) => address.isDefault,
          orElse: () => user.addresses.first,
        );
        
        setState(() {
          _selectedAddress = defaultAddress;
        });
      }
    }
  }
  
  void _navigateToAddNewAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddressFormPage(isEditing: false),
      ),
    );
    
    // Refresh user data after adding address
    _loadUserData();
  }
  
  void _selectAddressAndReturn() {
    if (_selectedAddress != null) {
      widget.onAddressSelected(_selectedAddress!);
      Navigator.pop(context);
    } else {
      // Show error toast
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an address to continue'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      title: 'Select Delivery Address',
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
          
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Delivery address card
                      AddressSelectionCard(
                        selectedAddress: _selectedAddress,
                        addresses: addresses,
                        onAddressSelected: (address) {
                          setState(() {
                            _selectedAddress = address;
                          });
                        },
                        onAddNewAddress: _navigateToAddNewAddress,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Bottom action button
              if (addresses.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      height: 56.h,
                      child: ElevatedButton(
                        onPressed: _selectAddressAndReturn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentColor,
                          foregroundColor: AppTheme.primaryColor,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          'Deliver to this Address',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
