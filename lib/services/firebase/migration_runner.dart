import 'package:flutter/material.dart';
import 'package:profit_grocery_application/services/firebase/data_migration_service.dart';
import 'package:profit_grocery_application/services/logging_service.dart';

/// A utility class to run data migrations in the app
class MigrationRunner {
  final DataMigrationService _migrationService = DataMigrationService();
  
  // Singleton pattern
  static final MigrationRunner _instance = MigrationRunner._internal();
  factory MigrationRunner() => _instance;
  MigrationRunner._internal();
  
  // State variables
  bool _isRunning = false;
  double _progress = 0.0;
  String _currentTask = '';
  
  // Getters
  bool get isRunning => _isRunning;
  double get progress => _progress;
  String get currentTask => _currentTask;
  
  // Status callbacks
  VoidCallback? onMigrationStarted;
  Function(String)? onTaskUpdate;
  Function(double)? onProgressUpdate;
  Function(bool, String)? onMigrationComplete;
  
  /// Run data migrations for the app
  /// Returns a Future that completes when all migrations are done
  Future<bool> runMigrations({BuildContext? context}) async {
    if (_isRunning) {
      LoggingService.logFirestore('Migration already running, skipping');
      return false;
    }
    
    _isRunning = true;
    _progress = 0.0;
    _currentTask = 'Starting migrations...';
    
    // Notify listeners that migration has started
    if (onMigrationStarted != null) {
      onMigrationStarted!();
    }
    
    // Set up migration service callbacks
    _migrationService.onTaskUpdate = (task) {
      _currentTask = task;
      if (onTaskUpdate != null) {
        onTaskUpdate!(task);
      }
      LoggingService.logFirestore(task);
    };
    
    _migrationService.onProgressUpdate = (progress) {
      _progress = progress;
      if (onProgressUpdate != null) {
        onProgressUpdate!(progress);
      }
    };
    
    _migrationService.onMigrationComplete = (success, message) {
      if (onMigrationComplete != null) {
        onMigrationComplete!(success, message);
      }
      
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
      
      _isRunning = false;
    };
    
    // Run the product migration
    await _migrationService.migrateProducts();
    
    return true;
  }
  
  /// Show a dialog to run migrations with progress tracking
  static Future<void> showMigrationDialog(BuildContext context) async {
    final runner = MigrationRunner();
    
    // Set up the dialog state management
    bool isComplete = false;
    String statusMessage = 'Starting migration...';
    double progressValue = 0.0;
    bool isSuccess = true;
    
    // Show the dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Set up callbacks to update the dialog
            runner.onTaskUpdate = (task) {
              setState(() {
                statusMessage = task;
              });
            };
            
            runner.onProgressUpdate = (progress) {
              setState(() {
                progressValue = progress;
              });
            };
            
            runner.onMigrationComplete = (success, message) {
              setState(() {
                isComplete = true;
                statusMessage = message;
                isSuccess = success;
              });
            };
            
            // Start the migration if it's not already running
            if (!runner.isRunning && !isComplete) {
              Future.microtask(() => runner.runMigrations());
            }
            
            return AlertDialog(
              title: Text(isComplete 
                ? (isSuccess ? 'Migration Complete' : 'Migration Failed')
                : 'Migrating Data Structure'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(statusMessage),
                  const SizedBox(height: 20),
                  LinearProgressIndicator(value: progressValue),
                  const SizedBox(height: 10),
                  Text('${(progressValue * 100).toStringAsFixed(1)}%'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isComplete 
                    ? () => Navigator.of(context).pop()
                    : null,
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}