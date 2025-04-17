import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:profit_grocery_application/core/constants/app_theme.dart';
import 'package:profit_grocery_application/services/firebase/data_setup_service.dart';

class DataSetupDialog extends StatefulWidget {
  const DataSetupDialog({Key? key}) : super(key: key);

  @override
  State<DataSetupDialog> createState() => _DataSetupDialogState();
}

class _DataSetupDialogState extends State<DataSetupDialog> {
  final DataSetupService _setupService = DataSetupService();
  bool _isSettingUp = false;
  double _progress = 0.0;
  String _currentTask = 'Initializing...';
  String _errorMessage = '';
  bool _isComplete = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _setupService.onTaskUpdate = (task) {
      if (mounted) {
        setState(() {
          _currentTask = task;
        });
      }
    };
    
    _setupService.onProgressUpdate = (progress) {
      if (mounted) {
        setState(() {
          _progress = progress;
        });
      }
    };
    
    _setupService.onSetupComplete = (success, message) {
      if (mounted) {
        setState(() {
          _isSettingUp = false;
          _isComplete = true;
          _isSuccess = success;
          _errorMessage = success ? '' : message;
        });
      }
    };
    
    // Start setup process
    _startSetup();
  }

  void _startSetup() async {
    setState(() {
      _isSettingUp = true;
      _progress = 0.0;
      _currentTask = 'Initializing...';
      _errorMessage = '';
      _isComplete = false;
      _isSuccess = false;
    });

    // Run setup in background
    _setupService.setupFirebaseData();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.secondaryColor,
      title: Text(
        _isComplete 
            ? _isSuccess 
                ? 'Setup Complete'
                : 'Setup Failed'
            : 'Setting Up Firebase Data',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isSettingUp || !_isComplete) ...[
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: AppTheme.backgroundColor,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
              ),
              SizedBox(height: 16.h),
              Text(
                _currentTask,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                '${(_progress * 100).toInt()}% complete',
                style: TextStyle(
                  color: AppTheme.accentColor,
                  fontSize: 12.sp,
                ),
              ),
            ],
            
            if (_isComplete && _isSuccess) ...[
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48.r,
              ),
              SizedBox(height: 16.h),
              Text(
                'All data has been successfully set up in Firebase. The app is now ready to use.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14.sp,
                ),
              ),
            ],
            
            if (_isComplete && !_isSuccess) ...[
              Icon(
                Icons.error,
                color: Colors.red,
                size: 48.r,
              ),
              SizedBox(height: 16.h),
              Text(
                'Failed to set up data in Firebase. Please try again.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                _errorMessage,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (_isComplete) ...[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              'Close',
              style: TextStyle(
                color: AppTheme.accentColor,
              ),
            ),
          ),
          if (!_isSuccess)
            ElevatedButton(
              onPressed: _isSettingUp ? null : _startSetup,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.black,
              ),
              child: Text('Try Again'),
            ),
        ] else ...[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ],
    );
  }
}