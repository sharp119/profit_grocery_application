import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../../data/models/user_model.dart';
import '../../../domain/entities/user.dart';
import '../../../services/logging_service.dart';
import '../../blocs/user/user_bloc.dart';
import '../../blocs/user/user_event.dart';
import '../../blocs/user/user_state.dart';
import '../../widgets/base_layout.dart';

class AddressFormPage extends StatefulWidget {
  final Address? address;
  final bool isEditing;

  const AddressFormPage({
    Key? key,
    this.address,
    this.isEditing = false,
  }) : super(key: key);

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressLineController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  late TextEditingController _landmarkController;
  late TextEditingController _phoneController;
  late String _addressType;
  late bool _isDefault;
  
  bool _isSubmitting = false;
  String? _errorMessage;
  
  int _currentStep = 0;
  final List<String> _addressTypes = ['home', 'work', 'other'];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    // Load user data if not available
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
          LoggingService.logFirestore('AddressFormPage: Loading user data for ID: $userId');
          // Dispatch event to load user data
          context.read<UserBloc>().add(LoadUserProfileEvent(userId));
        } else {
          LoggingService.logError('AddressFormPage', 'No user ID found in SharedPreferences');
        }
      } catch (e) {
        LoggingService.logError('AddressFormPage', 'Error loading user data: $e');
      }
    }
  }

  void _initializeControllers() {
    final address = widget.address;
    
    if (address != null) {
      _nameController = TextEditingController(text: address.name);
      _addressLineController = TextEditingController(text: address.addressLine);
      _cityController = TextEditingController(text: address.city);
      _stateController = TextEditingController(text: address.state);
      _pincodeController = TextEditingController(text: address.pincode);
      _landmarkController = TextEditingController(text: address.landmark ?? '');
      _phoneController = TextEditingController(text: address.phone ?? '');
      _addressType = address.addressType;
      _isDefault = address.isDefault;
    } else {
      _nameController = TextEditingController();
      _addressLineController = TextEditingController();
      _cityController = TextEditingController();
      _stateController = TextEditingController();
      _pincodeController = TextEditingController();
      _landmarkController = TextEditingController();
      _phoneController = TextEditingController();
      _addressType = 'home';
      _isDefault = false;
      
      // Set default to true if this is the first address
      _checkIfFirstAddress();
    }
  }
  
  Future<void> _checkIfFirstAddress() async {
    try {
      final userState = context.read<UserBloc>().state;
      final user = userState.user;
      
      if (user != null && user.addresses.isEmpty) {
        setState(() {
          _isDefault = true;
        });
      }
    } catch (e) {
      // Ignore errors, default will remain false
      LoggingService.logError('AddressFormPage', 'Error checking if first address: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressLineController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _landmarkController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      title: widget.isEditing ? 'Edit Address' : 'Add New Address',
      showBackButton: true,
      body: BlocConsumer<UserBloc, UserState>(
        listener: (context, state) {
          if (state.status == UserStatus.updated) {
            setState(() {
              _isSubmitting = false;
              _errorMessage = null;
            });
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  widget.isEditing
                      ? 'Address updated successfully'
                      : 'Address added successfully',
                ),
                backgroundColor: Colors.green,
              ),
            );
            
            // Navigate back to addresses page
            Navigator.of(context).pop();
          } else if (state.status == UserStatus.error) {
            setState(() {
              _isSubmitting = false;
              _errorMessage = state.errorMessage;
            });
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
          
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.dark(
                primary: AppTheme.accentColor,
                surface: AppTheme.secondaryColor,
                background: AppTheme.backgroundColor,
                onSurface: Colors.white,
              ),
            ),
            child: Stepper(
              type: StepperType.vertical,
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep < 2) {
                  if (_validateCurrentStep()) {
                    setState(() {
                      _currentStep += 1;
                    });
                  }
                } else {
                  _saveAddress();
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() {
                    _currentStep -= 1;
                  });
                } else {
                  Navigator.pop(context);
                }
              },
              controlsBuilder: (context, details) {
                return Padding(
                  padding: EdgeInsets.only(top: 20.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: details.onStepContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentColor,
                            foregroundColor: AppTheme.primaryColor,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: Text(
                            _currentStep == 2 ? 'Save Address' : 'Continue',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: details.onStepCancel,
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            side: BorderSide(color: AppTheme.accentColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: Text(
                            _currentStep == 0 ? 'Cancel' : 'Back',
                            style: TextStyle(
                              color: AppTheme.accentColor,
                              fontSize: 16.sp,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              steps: [
                Step(
                  title: const Text('Contact Details'),
                  subtitle: const Text('Name of the person at this address'),
                  isActive: _currentStep >= 0,
                  state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                  content: _buildContactDetailsStep(),
                ),
                Step(
                  title: const Text('Address Details'),
                  subtitle: const Text('Enter your delivery location'),
                  isActive: _currentStep >= 1,
                  state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                  content: _buildAddressDetailsStep(),
                ),
                Step(
                  title: const Text('Address Type'),
                  subtitle: const Text('Categorize this address'),
                  isActive: _currentStep >= 2,
                  content: _buildAddressTypeStep(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _nameController.text.isNotEmpty;
      case 1:
        return _addressLineController.text.isNotEmpty && 
               _cityController.text.isNotEmpty && 
               _stateController.text.isNotEmpty && 
               _pincodeController.text.length == 6;
      default:
        return true;
    }
  }
  
  Widget _buildContactDetailsStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(color: AppTheme.textPrimaryColor),
            decoration: InputDecoration(
              labelText: 'Full Name',
              hintText: 'Enter recipient name',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a name';
              }
              return null;
            },
          ),
          SizedBox(height: 16.h),
          
          Text(
            'This name will be used for delivery to identify the recipient.',
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 14.sp,
              fontStyle: FontStyle.italic,
            ),
          ),
          
          TextFormField(
            controller: _phoneController,
            style: const TextStyle(color: AppTheme.textPrimaryColor),
            decoration: InputDecoration(
              labelText: 'Phone Number',
              hintText: 'Enter contact number for this address',
              prefixIcon: const Icon(Icons.phone),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              counterText: '',
            ),
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a phone number';
              }
              if (value.length != 10 || int.tryParse(value) == null) {
                return 'Please enter a valid 10-digit phone number';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildAddressDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Address Line Field
        TextFormField(
          controller: _addressLineController,
          style: const TextStyle(color: AppTheme.textPrimaryColor),
          decoration: InputDecoration(
            labelText: 'Address Line',
            hintText: 'House/Flat No., Building, Street',
            prefixIcon: const Icon(Icons.home),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter address details';
            }
            return null;
          },
        ),
        SizedBox(height: 16.h),
        
        // Landmark Field (Optional)
        TextFormField(
          controller: _landmarkController,
          style: const TextStyle(color: AppTheme.textPrimaryColor),
          decoration: InputDecoration(
            labelText: 'Landmark (Optional)',
            hintText: 'Nearby landmark for easy location',
            prefixIcon: const Icon(Icons.location_on),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        ),
        SizedBox(height: 16.h),
        
        // City Field
        TextFormField(
          controller: _cityController,
          style: const TextStyle(color: AppTheme.textPrimaryColor),
          decoration: InputDecoration(
            labelText: 'City',
            hintText: 'Enter city name',
            prefixIcon: const Icon(Icons.location_city),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter city name';
            }
            return null;
          },
        ),
        SizedBox(height: 16.h),
        
        // State Field
        TextFormField(
          controller: _stateController,
          style: const TextStyle(color: AppTheme.textPrimaryColor),
          decoration: InputDecoration(
            labelText: 'State',
            hintText: 'Enter state name',
            prefixIcon: const Icon(Icons.map),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter state name';
            }
            return null;
          },
        ),
        SizedBox(height: 16.h),
        
        // Pincode Field
        TextFormField(
          controller: _pincodeController,
          style: const TextStyle(color: AppTheme.textPrimaryColor),
          decoration: InputDecoration(
            labelText: 'Pincode',
            hintText: 'Enter 6-digit pincode',
            prefixIcon: const Icon(Icons.pin_drop),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          keyboardType: TextInputType.number,
          maxLength: 6,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter pincode';
            }
            if (value.length != 6) {
              return 'Pincode must be 6 digits';
            }
            return null;
          },
        ),
      ],
    );
  }
  
  Widget _buildAddressTypeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Address Type',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 16.h),
        
        // Address Type Cards
        Row(
          children: [
            Expanded(
              child: _buildAddressTypeCard(
                type: 'home',
                icon: Icons.home_outlined,
                label: 'Home',
                color: Colors.blue,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildAddressTypeCard(
                type: 'work',
                icon: Icons.work_outline,
                label: 'Work',
                color: Colors.orange,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildAddressTypeCard(
                type: 'other',
                icon: Icons.place_outlined,
                label: 'Other',
                color: Colors.purple,
              ),
            ),
          ],
        ),
        
        SizedBox(height: 24.h),
        
        // Set as Default Checkbox with better styling
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: _isDefault 
                  ? AppTheme.accentColor 
                  : AppTheme.accentColor.withOpacity(0.3),
              width: _isDefault ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24.w,
                height: 24.w,
                child: Checkbox(
                  value: _isDefault,
                  onChanged: (value) {
                    setState(() {
                      _isDefault = value ?? false;
                    });
                  },
                  activeColor: AppTheme.accentColor,
                  checkColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set as default address',
                      style: TextStyle(
                        color: AppTheme.textPrimaryColor,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'This address will be used as the default for all deliveries',
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 14.sp,
                      ),
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
      ],
    );
  }
  
  Widget _buildAddressTypeCard({
    required String type,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isSelected = _addressType == type;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _addressType = type;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : AppTheme.secondaryColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? color : AppTheme.accentColor.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.2) : color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? color : color.withOpacity(0.7),
                size: 24.sp,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppTheme.textPrimaryColor,
                fontSize: 16.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveAddress() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
        _errorMessage = null;
      });
      
      final userState = context.read<UserBloc>().state;
      final user = userState.user;
      
      if (user == null) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'User profile not found';
        });
        return;
      }
      
      // Create address object
      final address = AddressModel(
        id: widget.isEditing ? widget.address!.id : const Uuid().v4(),
        name: _nameController.text.trim(),
        addressLine: _addressLineController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pincode: _pincodeController.text.trim(),
        landmark: _landmarkController.text.trim(),
        isDefault: _isDefault,
        addressType: _addressType,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
      );
      
      // Dispatch event to UserBloc
      if (widget.isEditing) {
        context.read<UserBloc>().add(
              UpdateAddressEvent(
                userId: user.id,
                address: address,
              ),
            );
      } else {
        context.read<UserBloc>().add(
              AddAddressEvent(
                userId: user.id,
                address: address,
              ),
            );
      }
    }
  }
}
