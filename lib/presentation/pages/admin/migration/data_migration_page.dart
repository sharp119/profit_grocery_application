import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../services/firebase/migration_runner.dart';
import '../../../../utils/migration/database_migrator.dart';
import '../../../widgets/base_layout.dart';

/// Admin screen to migrate data between Realtime Database and Firestore
class DataMigrationPage extends StatefulWidget {
  const DataMigrationPage({super.key});

  @override
  State<DataMigrationPage> createState() => _DataMigrationPageState();
}

class _DataMigrationPageState extends State<DataMigrationPage> {
  bool _isMigrating = false;
  String _status = 'Ready to migrate data';
  final Map<String, String> _migrationResults = {};
  int _currentProgress = 0;
  static const int _totalCollections = 5; // users, sessions, products, categories, orders

  late final DatabaseMigrator _migrator;

  @override
  void initState() {
    super.initState();
    _migrator = DatabaseMigrator(
      realtimeDatabase: GetIt.instance<FirebaseDatabase>(),
      firestore: GetIt.instance<FirebaseFirestore>(),
    );
  }

  Future<void> _migrateAllData() async {
    if (_isMigrating) return;

    setState(() {
      _isMigrating = true;
      _status = 'Migration in progress...';
      _migrationResults.clear();
      _currentProgress = 0;
    });

    try {
      // Migrate users
      setState(() {
        _status = 'Migrating users...';
      });
      final usersResult = await _migrator.migrateUsers();
      setState(() {
        _migrationResults['Users'] = usersResult.toString();
        _currentProgress += 1;
      });

      // Migrate sessions
      setState(() {
        _status = 'Migrating sessions...';
      });
      final sessionsResult = await _migrator.migrateSessions();
      setState(() {
        _migrationResults['Sessions'] = sessionsResult.toString();
        _currentProgress += 1;
      });

      // Migrate products
      setState(() {
        _status = 'Migrating products...';
      });
      final productsResult = await _migrator.migrateProducts();
      setState(() {
        _migrationResults['Products'] = productsResult.toString();
        _currentProgress += 1;
      });

      // Migrate categories
      setState(() {
        _status = 'Migrating categories...';
      });
      final categoriesResult = await _migrator.migrateCategories();
      setState(() {
        _migrationResults['Categories'] = categoriesResult.toString();
        _currentProgress += 1;
      });

      // Migrate orders
      setState(() {
        _status = 'Migrating orders...';
      });
      final ordersResult = await _migrator.migrateOrders();
      setState(() {
        _migrationResults['Orders'] = ordersResult.toString();
        _currentProgress += 1;
      });

      setState(() {
        _status = 'Migration completed';
        _isMigrating = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Migration failed: $e';
        _isMigrating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      title: 'Database Migration',
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Migration Tool',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.accentColor,
              ),
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Migrate data from Realtime Database to Firestore',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'This tool will copy all data from the Realtime Database to Firestore. '
                    'Existing data in Firestore will not be overwritten. '
                    'The process can take some time depending on the amount of data.',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  if (_isMigrating) ...[
                    Text(
                      _status,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppTheme.accentColor,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    LinearProgressIndicator(
                      value: _currentProgress / _totalCollections,
                      backgroundColor: Colors.grey[800],
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
                    ),
                  ] else ...[
                    Text(
                      _status,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: _status.contains('failed')
                            ? Colors.red
                            : _status.contains('completed')
                                ? Colors.green
                                : Colors.white,
                      ),
                    ),
                  ],
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isMigrating ? null : _migrateAllData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                        foregroundColor: AppTheme.primaryColor,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: _isMigrating
                          ? SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.w,
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                              ),
                            )
                          : Text(
                              'Start Migration',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            
            // Product Structure Migration Section
            Text(
              'Product Structure Migration',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.accentColor,
              ),
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Migrate product structure',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'This will reorganize existing products to correct the structure. '
                    'Products will be moved to be nested under their respective category items '
                    'rather than directly under category groups. '
                    'Images will also be reorganized in Firebase Storage.',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isMigrating 
                        ? null 
                        : () => MigrationRunner.showMigrationDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: AppTheme.primaryColor,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        'Start Product Structure Migration',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24.h),
            if (_migrationResults.isNotEmpty) ...[
              Text(
                'Migration Results',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentColor,
                ),
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _migrationResults.entries.map((entry) {
                    final bool isSuccess = !entry.value.contains('failed');
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Row(
                        children: [
                          Icon(
                            isSuccess ? Icons.check_circle : Icons.error,
                            color: isSuccess ? Colors.green : Colors.red,
                            size: 20.w,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.key,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  entry.value,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}