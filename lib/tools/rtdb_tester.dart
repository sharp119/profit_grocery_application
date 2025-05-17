import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../services/logging_service.dart';

/// A utility class for testing and debugging Firebase Realtime Database issues
class RTDBTester {
  // Singleton pattern
  static final RTDBTester _instance = RTDBTester._internal();
  factory RTDBTester() => _instance;
  RTDBTester._internal();

  final _database = FirebaseDatabase.instance;
  final Map<String, StreamSubscription<DatabaseEvent>> _subscriptions = {};

  /// Test connection to Firebase RTDB
  Future<bool> testConnection() async {
    try {
      LoggingService.logFirestore('RTDB_TESTER: Testing Firebase connection...');
      
      // Write to test path
      final testRef = _database.ref().child('test_connection');
      await testRef.set({
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'testValue': 'Connection test ${DateTime.now()}',
      });
      
      LoggingService.logFirestore('RTDB_TESTER: Connection test successful');
      return true;
    } catch (e) {
      LoggingService.logError('RTDB_TESTER', 'Connection test failed: $e');
      return false;
    }
  }

  /// Directly monitor a path for changes
  void monitorPath(String path) {
    // Remove any existing subscription
    _subscriptions[path]?.cancel();
    
    LoggingService.logFirestore('RTDB_TESTER: Starting to monitor path: $path');
    
    final ref = _database.ref(path);
    
    // Initial state read
    ref.get().then((snapshot) {
      if (snapshot.exists) {
        LoggingService.logFirestore('RTDB_TESTER: Initial value at $path: ${snapshot.value}');
      } else {
        LoggingService.logFirestore('RTDB_TESTER: Path $path does not exist or is empty');
      }
    }).catchError((error) {
      LoggingService.logError('RTDB_TESTER', 'Error reading initial value at $path: $error');
    });
    
    // Setup change listener
    _subscriptions[path] = ref.onValue.listen((event) {
      if (event.snapshot.exists) {
        LoggingService.logFirestore(
          'RTDB_TESTER: Value changed at $path: ${event.snapshot.value}'
          ' (Event type: ${event.type})'
        );
      } else {
        LoggingService.logFirestore('RTDB_TESTER: Path $path was deleted or is empty');
      }
    }, onError: (error) {
      LoggingService.logError('RTDB_TESTER', 'Error in listener for $path: $error');
    });
    
    // Also monitor child events for more detailed tracking
    ref.onChildAdded.listen((event) {
      LoggingService.logFirestore(
        'RTDB_TESTER: Child added at $path/${event.snapshot.key}: ${event.snapshot.value}'
      );
    });
    
    ref.onChildChanged.listen((event) {
      LoggingService.logFirestore(
        'RTDB_TESTER: Child changed at $path/${event.snapshot.key}: ${event.snapshot.value}'
      );
    });

    ref.onChildRemoved.listen((event) {
      LoggingService.logFirestore(
        'RTDB_TESTER: Child removed at $path/${event.snapshot.key}'
      );
    });
  }

  /// Directly update a value at a path
  Future<bool> updateValue(String path, dynamic value) async {
    try {
      LoggingService.logFirestore('RTDB_TESTER: Updating value at $path: $value');
      
      final ref = _database.ref(path);
      await ref.set(value);
      
      LoggingService.logFirestore('RTDB_TESTER: Value updated successfully');
      return true;
    } catch (e) {
      LoggingService.logError('RTDB_TESTER', 'Error updating value at $path: $e');
      return false;
    }
  }

  /// Stop monitoring a path
  void stopMonitoring(String path) {
    _subscriptions[path]?.cancel();
    _subscriptions.remove(path);
    LoggingService.logFirestore('RTDB_TESTER: Stopped monitoring path: $path');
  }

  /// Stop monitoring all paths
  void stopAll() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
    LoggingService.logFirestore('RTDB_TESTER: Stopped monitoring all paths');
  }

  /// Configure database settings
  Future<void> configureDatabase({bool persistenceEnabled = true}) async {
    try {
      LoggingService.logFirestore('RTDB_TESTER: Configuring Firebase Realtime Database...');
      
      // Toggle persistence
      _database.setPersistenceEnabled(persistenceEnabled);
      
      // Set cache size if persistence enabled
      if (persistenceEnabled) {
        _database.setPersistenceCacheSizeBytes(10 * 1024 * 1024); // 10 MB
      }
      
      LoggingService.logFirestore(
        'RTDB_TESTER: Database configured (Persistence: $persistenceEnabled)'
      );
    } catch (e) {
      LoggingService.logError('RTDB_TESTER', 'Error configuring database: $e');
    }
  }
} 