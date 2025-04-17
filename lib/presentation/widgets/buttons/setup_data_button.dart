import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:profit_grocery_application/core/constants/app_theme.dart';
import 'package:profit_grocery_application/presentation/widgets/dialogs/data_setup_dialog.dart';

class SetupDataButton extends StatelessWidget {
  final bool isAdmin;
  
  const SetupDataButton({
    Key? key,
    this.isAdmin = false,
  }) : super(key: key);

  void _showSetupDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const DataSetupDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only show the button if user is admin
    if (!isAdmin) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: EdgeInsets.only(top: 16.h, left: 16.w, right: 16.w),
      child: ElevatedButton(
        onPressed: () {
          // Show confirmation dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppTheme.secondaryColor,
              title: Text(
                'Initialize Firebase Data',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                'This will set up all product and category data in Firebase Firestore and Storage. This action should only be performed once during initial setup. Continue?',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14.sp,
                ),
              ),
              actions: [
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
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showSetupDialog(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    foregroundColor: Colors.black,
                  ),
                  child: Text('Continue'),
                ),
              ],
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storage, size: 24.r),
            SizedBox(width: 8.w),
            Text(
              'Initialize Firebase Data',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}