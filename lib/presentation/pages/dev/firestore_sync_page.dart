import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:profit_grocery_application/core/constants/app_theme.dart';
import 'package:profit_grocery_application/utils/test/firestore_test_data_sync.dart';

class FirestoreSyncPage extends StatefulWidget {
  const FirestoreSyncPage({Key? key}) : super(key: key);

  @override
  State<FirestoreSyncPage> createState() => _FirestoreSyncPageState();
}

class _FirestoreSyncPageState extends State<FirestoreSyncPage> {
  bool _isSyncing = false;
  bool _isDeleting = false;
  String _statusMessage = '';
  final FirestoreTestDataSync _testDataSync = FirestoreTestDataSync();

  Future<void> _syncBakeriesBiscuitsData() async {
    try {
      setState(() {
        _isSyncing = true;
        _statusMessage = 'Syncing Bakeries & Biscuits data to Firestore...';
      });

      await _testDataSync.syncBakeriesBiscuitsCategory();

      setState(() {
        _statusMessage = 'Bakeries & Biscuits data successfully synced to Firestore';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error syncing data: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  Future<void> _cleanupTestData() async {
    try {
      setState(() {
        _isDeleting = true;
        _statusMessage = 'Cleaning up test data from Firestore...';
      });

      await _testDataSync.cleanupTestData();

      setState(() {
        _statusMessage = 'Test data cleanup completed successfully';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error cleaning up data: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isDeleting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      appBar: AppBar(
        title: const Text('Firestore Data Sync'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Developer Tools',
                    style: TextStyle(
                      color: AppTheme.accentColor,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Use these tools to sync test data with Firestore for development purposes. This allows you to test the two-panel category-product view with real Firestore data.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24.h),
            
            // Sync section
            Text(
              'Sync Test Data',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: _isSyncing ? null : _syncBakeriesBiscuitsData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                  vertical: 12.h,
                ),
                minimumSize: Size(double.infinity, 48.h),
              ),
              child: _isSyncing
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20.w,
                          height: 20.h,
                          child: const CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        const Text('Syncing...'),
                      ],
                    )
                  : const Text('Sync Bakeries & Biscuits Data'),
            ),
            
            SizedBox(height: 24.h),
            
            // Cleanup section
            Text(
              'Cleanup Test Data',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Warning: This will delete all test data from Firestore',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12.sp,
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: _isDeleting ? null : _cleanupTestData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                  vertical: 12.h,
                ),
                minimumSize: Size(double.infinity, 48.h),
              ),
              child: _isDeleting
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20.w,
                          height: 20.h,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        const Text('Cleaning up...'),
                      ],
                    )
                  : const Text('Cleanup Test Data'),
            ),
            
            SizedBox(height: 24.h),
            
            // Status section
            if (_statusMessage.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: _statusMessage.contains('Error')
                      ? Colors.red.withOpacity(0.2)
                      : Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: _statusMessage.contains('Error')
                        ? Colors.red
                        : Colors.green,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      _statusMessage,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}